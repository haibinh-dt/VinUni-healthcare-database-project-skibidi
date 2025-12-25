/* ===========================================================
   optimization_tests.sql
   Hospital Management System - Indexing & Performance Testing
   Includes: final indexes, seed data, baseline vs optimized tests,
             and cleanup of PERF_TEST data.
   =========================================================== */

USE hospital_management_system;

-- -----------------------------------------------------------
-- 0) OPTIONAL: Safety checks (quick sanity)
-- -----------------------------------------------------------
SELECT 'Patients', COUNT(*) FROM Patient;
SELECT 'Doctors', COUNT(*) FROM Doctor;
SELECT 'Timeslots', COUNT(*) FROM TimeSlot;

-- -----------------------------------------------------------
-- 1) FINAL INDEXES (these should remain in the project)
--    NOTE: If some already exist, you'll get "Duplicate key name"
-- -----------------------------------------------------------

-- Appointment: FK helper + doctor schedule
CREATE INDEX idx_appointment_patient_date ON Appointment(patient_id, appointment_date);

-- Doctor_Availability: conflict checks / slot search
-- If you frequently filter by doctor + date:
CREATE INDEX idx_availability_doctor_date ON Doctor_Availability(doctor_id, available_date);

-- -----------------------------------------------------------
-- 2) SEED: Doctor availability for next N days (no ON DUPLICATE)
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS seed_doctor_availability;
DELIMITER $$

CREATE PROCEDURE seed_doctor_availability(IN p_days INT)
BEGIN
  DECLARE d INT DEFAULT 0;

  WHILE d < p_days DO
    INSERT INTO Doctor_Availability (doctor_id, timeslot_id, available_date, is_available)
    SELECT doc.doctor_id, ts.timeslot_id, DATE_ADD(CURDATE(), INTERVAL d DAY), TRUE
    FROM Doctor doc
    CROSS JOIN TimeSlot ts
    WHERE NOT EXISTS (
      SELECT 1
      FROM Doctor_Availability da
      WHERE da.doctor_id = doc.doctor_id
        AND da.timeslot_id = ts.timeslot_id
        AND da.available_date = DATE_ADD(CURDATE(), INTERVAL d DAY)
    );

    SET d = d + 1;
  END WHILE;
END$$

DELIMITER ;

-- Create enough slots (doctors * 8 timeslots * days)
CALL seed_doctor_availability(60);

SELECT COUNT(*) AS available_slots
FROM Doctor_Availability
WHERE is_available = TRUE;

-- -----------------------------------------------------------
-- 3) SEED: PERF_TEST appointments using ONLY available slots
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS seed_perf_test_appointments_from_avail;
DELIMITER $$

CREATE PROCEDURE seed_perf_test_appointments_from_avail(IN p_n INT)
BEGIN
  DECLARE inserted INT DEFAULT 0;
  DECLARE attempts INT DEFAULT 0;

  DECLARE v_doc INT;
  DECLARE v_ts INT;
  DECLARE v_date DATE;

  DECLARE v_aid INT;
  DECLARE v_status INT;
  DECLARE v_msg VARCHAR(255);

  -- Stop if there are not enough available slots
  IF (SELECT COUNT(*) FROM Doctor_Availability WHERE is_available = TRUE) = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No available slots in Doctor_Availability. Seed availability first.';
  END IF;

  WHILE inserted < p_n AND attempts < p_n * 30 DO
    SET attempts = attempts + 1;

    -- pick a currently available slot
    SELECT doctor_id, timeslot_id, available_date
    INTO v_doc, v_ts, v_date
    FROM Doctor_Availability
    WHERE is_available = TRUE
    ORDER BY RAND()
    LIMIT 1;

    SET v_aid = NULL; SET v_status = NULL; SET v_msg = NULL;

    CALL sp_book_appointment(
      (SELECT patient_id FROM Patient ORDER BY RAND() LIMIT 1),
      v_doc,
      v_ts,
      v_date,
      'PERF_TEST',
      1,
      v_aid,
      v_status,
      v_msg
    );

    IF v_aid IS NOT NULL OR v_status IN (200, 201) THEN
      SET inserted = inserted + 1;
    END IF;
  END WHILE;

  SELECT inserted AS inserted_successfully,
         attempts AS total_attempts;
END$$

DELIMITER ;

CALL seed_perf_test_appointments_from_avail(200);

SELECT COUNT(*) AS perf_rows
FROM Appointment
WHERE reason='PERF_TEST';

SELECT appointment_id, patient_id, doctor_id, timeslot_id, appointment_date, reason
FROM Appointment
WHERE reason='PERF_TEST'
ORDER BY appointment_id DESC
LIMIT 10;

-- Update stats
ANALYZE TABLE Appointment;

-- -----------------------------------------------------------
-- 4) PERFORMANCE TESTS
--    We compare SINGLE-COLUMN index vs COMPOSITE index.
--    IMPORTANT: if FK requires an index, we keep a single-column index.
-- -----------------------------------------------------------

/* =======================
   Test A: Patient history
   Query pattern:
     WHERE patient_id = ? ORDER BY appointment_date DESC
   ======================= */

-- A1) BASELINE: keep single-column patient index ONLY
-- Your CREATE TABLE has idx_appointment_patient(patient_id) already.
-- Drop composite patient+date index temporarily:
DROP INDEX idx_appointment_patient_date ON Appointment;

ANALYZE TABLE Appointment;

EXPLAIN FORMAT=TRADITIONAL
SELECT *
FROM Appointment
WHERE patient_id = 5
ORDER BY appointment_date DESC;

-- Time (profiling) - optional
SET profiling = 1;
SELECT *
FROM Appointment
WHERE patient_id = 5
ORDER BY appointment_date DESC;
SHOW PROFILES;

-- Handler counters (recommended)
FLUSH STATUS;
SELECT *
FROM Appointment
WHERE patient_id = 5
ORDER BY appointment_date DESC;
SHOW STATUS LIKE 'Handler_read%';

-- A2) OPTIMIZED: add composite index (patient_id, appointment_date)
CREATE INDEX idx_appointment_patient_date ON Appointment(patient_id, appointment_date);
ANALYZE TABLE Appointment;

EXPLAIN FORMAT=TRADITIONAL
SELECT *
FROM Appointment
WHERE patient_id = 5
ORDER BY appointment_date DESC;

SET profiling = 1;
SELECT *
FROM Appointment
WHERE patient_id = 5
ORDER BY appointment_date DESC;
SHOW PROFILES;

FLUSH STATUS;
SELECT *
FROM Appointment
WHERE patient_id = 5
ORDER BY appointment_date DESC;
SHOW STATUS LIKE 'Handler_read%';


/* =======================
   Test B: Doctor schedule
   Query pattern:
     WHERE doctor_id=? AND appointment_date BETWEEN ... AND ...
   ======================= */

-- B1) BASELINE: keep single-column doctor index only
-- If you DO NOT have a doctor-only index, create it.
-- But you already have idx_appointment_doctor_date(doctor_id, appointment_date) in CREATE TABLE,
-- so create a doctor-only helper for baseline:
CREATE INDEX idx_appointment_doctor_only ON Appointment(doctor_id);

-- Now drop composite doctor+date temporarily:
DROP INDEX idx_appointment_doctor_date ON Appointment;
ANALYZE TABLE Appointment;

EXPLAIN FORMAT=TRADITIONAL
SELECT *
FROM Appointment
WHERE doctor_id = 3
  AND appointment_date BETWEEN '2025-01-01' AND '2025-01-07';

FLUSH STATUS;
SELECT *
FROM Appointment
WHERE doctor_id = 3
  AND appointment_date BETWEEN '2025-01-01' AND '2025-01-07';
SHOW STATUS LIKE 'Handler_read%';

-- B2) OPTIMIZED: recreate composite index
CREATE INDEX idx_appointment_doctor_date ON Appointment(doctor_id, appointment_date);
ANALYZE TABLE Appointment;

EXPLAIN FORMAT=TRADITIONAL
SELECT *
FROM Appointment
WHERE doctor_id = 3
  AND appointment_date BETWEEN '2025-01-01' AND '2025-01-07';

FLUSH STATUS;
SELECT *
FROM Appointment
WHERE doctor_id = 3
  AND appointment_date BETWEEN '2025-01-01' AND '2025-01-07';
SHOW STATUS LIKE 'Handler_read%';

-- Optional: remove helper doctor-only index (not needed in final)
DROP INDEX idx_appointment_doctor_only ON Appointment;

-- -----------------------------------------------------------
-- 5) CHECK AGAINST PROPOSAL (indexes list)
-- -----------------------------------------------------------
SHOW INDEX FROM Appointment;
SHOW INDEX FROM Doctor_Availability;

-- -----------------------------------------------------------
-- 6) CLEANUP (remove PERF_TEST data + reset availability)
-- -----------------------------------------------------------

-- Delete test appointments
DELETE FROM Appointment
WHERE reason = 'PERF_TEST';

-- Reset all availability to TRUE (so you can reseed again)
UPDATE Doctor_Availability
SET is_available = TRUE
WHERE available_date >= CURDATE();

ANALYZE TABLE Appointment;

SELECT COUNT(*) AS remaining_perf_rows
FROM Appointment
WHERE reason='PERF_TEST';

SHOW INDEX FROM appointment;