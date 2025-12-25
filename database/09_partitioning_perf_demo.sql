/* ============================================================
   Database: hospital_management_system

   Goal:
   - Apply partitioning to FK-safe time-series table(s)
   - Create partitioned "report/shadow" tables for FK-heavy tables
     (because MySQL does NOT allow partitioning with foreign keys)
   - Seed fake data (~1000 rows each)
   - Show partition distribution + execution evidence
   - Cleanup fake data

   IMPORTANT NOTE:
   - MySQL Workbench version does NOT equal MySQL Server version.
   - Partitioning + foreign keys => Error 1506 (expected).
   ============================================================ */

USE hospital_management_system;

-- ============================================================
-- A) QUICK CHECKS (optional but helpful)
-- ============================================================

-- 1) Confirm which schema you're using
SELECT DATABASE() AS current_db;

-- 2) Confirm server version
SELECT VERSION() AS mysql_server_version;

-- 3) List partitioned tables in current schema (after you run this file)
-- SELECT DISTINCT TABLE_NAME
-- FROM information_schema.PARTITIONS
-- WHERE TABLE_SCHEMA = DATABASE()
--   AND PARTITION_NAME IS NOT NULL
-- ORDER BY TABLE_NAME;


-- ============================================================
-- B) APPLY REAL PARTITIONING (FK-SAFE TABLE)
--    FinancialTransaction has NO foreign keys in your schema, so
--    MySQL allows partitioning directly here.
-- ============================================================

/* ---- B1) Apply monthly partitions for year 2025 + pMAX ----
   Why: to enable partition pruning for time-range queries on transaction_at
   Rule: any PRIMARY/UNIQUE key must include the partition column.
*/
-- If this table is already partitioned, this ALTER may error.
-- In that case, skip B1 and continue with the rest of the file.

ALTER TABLE FinancialTransaction
  DROP PRIMARY KEY,
  ADD PRIMARY KEY (transaction_id, transaction_at)
PARTITION BY RANGE (TO_DAYS(transaction_at)) (
  PARTITION p2025_01 VALUES LESS THAN (TO_DAYS('2025-02-01')),
  PARTITION p2025_02 VALUES LESS THAN (TO_DAYS('2025-03-01')),
  PARTITION p2025_03 VALUES LESS THAN (TO_DAYS('2025-04-01')),
  PARTITION p2025_04 VALUES LESS THAN (TO_DAYS('2025-05-01')),
  PARTITION p2025_05 VALUES LESS THAN (TO_DAYS('2025-06-01')),
  PARTITION p2025_06 VALUES LESS THAN (TO_DAYS('2025-07-01')),
  PARTITION p2025_07 VALUES LESS THAN (TO_DAYS('2025-08-01')),
  PARTITION p2025_08 VALUES LESS THAN (TO_DAYS('2025-09-01')),
  PARTITION p2025_09 VALUES LESS THAN (TO_DAYS('2025-10-01')),
  PARTITION p2025_10 VALUES LESS THAN (TO_DAYS('2025-11-01')),
  PARTITION p2025_11 VALUES LESS THAN (TO_DAYS('2025-12-01')),
  PARTITION p2025_12 VALUES LESS THAN (TO_DAYS('2026-01-01')),
  PARTITION pMAX     VALUES LESS THAN (MAXVALUE)
);

-- ---- B2) Verify partitions exist (even if TABLE_ROWS are 0, partitions should list) ----
SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'FinancialTransaction'
  AND PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_ORDINAL_POSITION;


-- ============================================================
-- C) CREATE PARTITIONED REPORT TABLES (NO FKs)
--    Reason: Your real tables Appointment/AuditLog/StockMovement
--    have foreign keys. MySQL forbids partitioning with FKs.
--    Workaround: create FK-free shadow tables dedicated for reports.
-- ============================================================

/* ---- C1) appointment_report_part (shadow of Appointment) ---- */
DROP TABLE IF EXISTS appointment_report_part;

CREATE TABLE appointment_report_part (
  appointment_id   INT NOT NULL,
  appointment_date DATE NOT NULL,
  patient_id       INT NOT NULL,
  doctor_id        INT NOT NULL,
  timeslot_id      INT NOT NULL,
  current_status   ENUM('CREATED','CONFIRMED','CANCELLED','IN_PROGRESS','COMPLETED') NOT NULL,
  created_at       DATETIME NOT NULL,

  PRIMARY KEY (appointment_id, appointment_date),
  INDEX idx_ar_doctor_date  (doctor_id, appointment_date),
  INDEX idx_ar_patient_date (patient_id, appointment_date),
  INDEX idx_ar_status_date  (current_status, appointment_date)
)
ENGINE=InnoDB
PARTITION BY RANGE COLUMNS (appointment_date) (
  PARTITION p2025_01 VALUES LESS THAN ('2025-02-01'),
  PARTITION p2025_02 VALUES LESS THAN ('2025-03-01'),
  PARTITION p2025_03 VALUES LESS THAN ('2025-04-01'),
  PARTITION p2025_04 VALUES LESS THAN ('2025-05-01'),
  PARTITION p2025_05 VALUES LESS THAN ('2025-06-01'),
  PARTITION p2025_06 VALUES LESS THAN ('2025-07-01'),
  PARTITION p2025_07 VALUES LESS THAN ('2025-08-01'),
  PARTITION p2025_08 VALUES LESS THAN ('2025-09-01'),
  PARTITION p2025_09 VALUES LESS THAN ('2025-10-01'),
  PARTITION p2025_10 VALUES LESS THAN ('2025-11-01'),
  PARTITION p2025_11 VALUES LESS THAN ('2025-12-01'),
  PARTITION p2025_12 VALUES LESS THAN ('2026-01-01'),
  PARTITION pMAX     VALUES LESS THAN (MAXVALUE)
);

/* ---- C2) auditlog_report_part (shadow of AuditLog) ---- */
DROP TABLE IF EXISTS auditlog_report_part;

CREATE TABLE auditlog_report_part (
  audit_id     INT NOT NULL,
  changed_at   DATETIME NOT NULL,
  user_id      INT NOT NULL,
  table_name   VARCHAR(100) NOT NULL,
  field_name   VARCHAR(100),
  old_value    TEXT,
  new_value    TEXT,
  action_type  ENUM('INSERT','UPDATE','DELETE') NOT NULL,

  PRIMARY KEY (audit_id, changed_at),
  INDEX idx_alr_user_time (user_id, changed_at)
)
ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(changed_at)) (
  PARTITION p2025_01 VALUES LESS THAN (TO_DAYS('2025-02-01')),
  PARTITION p2025_02 VALUES LESS THAN (TO_DAYS('2025-03-01')),
  PARTITION p2025_03 VALUES LESS THAN (TO_DAYS('2025-04-01')),
  PARTITION p2025_04 VALUES LESS THAN (TO_DAYS('2025-05-01')),
  PARTITION p2025_05 VALUES LESS THAN (TO_DAYS('2025-06-01')),
  PARTITION p2025_06 VALUES LESS THAN (TO_DAYS('2025-07-01')),
  PARTITION p2025_07 VALUES LESS THAN (TO_DAYS('2025-08-01')),
  PARTITION p2025_08 VALUES LESS THAN (TO_DAYS('2025-09-01')),
  PARTITION p2025_09 VALUES LESS THAN (TO_DAYS('2025-10-01')),
  PARTITION p2025_10 VALUES LESS THAN (TO_DAYS('2025-11-01')),
  PARTITION p2025_11 VALUES LESS THAN (TO_DAYS('2025-12-01')),
  PARTITION p2025_12 VALUES LESS THAN (TO_DAYS('2026-01-01')),
  PARTITION pMAX     VALUES LESS THAN (MAXVALUE)
);

/* ---- C3) stockmovement_report_part (shadow of StockMovement) ----
   Match your real schema:
   StockMovement columns are:
   (movement_id, batch_id, movement_type, quantity, reference_type, reference_id, moved_at)
*/
DROP TABLE IF EXISTS stockmovement_report_part;

CREATE TABLE stockmovement_report_part (
  movement_id     INT NOT NULL,
  moved_at        DATETIME NOT NULL,
  batch_id        INT NOT NULL,
  movement_type   ENUM('IN','OUT') NOT NULL,
  quantity        INT NOT NULL,
  reference_type  VARCHAR(50),
  reference_id    INT,

  PRIMARY KEY (movement_id, moved_at),
  INDEX idx_smr_batch_time (batch_id, moved_at)
)
ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(moved_at)) (
  PARTITION p2025_01 VALUES LESS THAN (TO_DAYS('2025-02-01')),
  PARTITION p2025_02 VALUES LESS THAN (TO_DAYS('2025-03-01')),
  PARTITION p2025_03 VALUES LESS THAN (TO_DAYS('2025-04-01')),
  PARTITION p2025_04 VALUES LESS THAN (TO_DAYS('2025-05-01')),
  PARTITION p2025_05 VALUES LESS THAN (TO_DAYS('2025-06-01')),
  PARTITION p2025_06 VALUES LESS THAN (TO_DAYS('2025-07-01')),
  PARTITION p2025_07 VALUES LESS THAN (TO_DAYS('2025-08-01')),
  PARTITION p2025_08 VALUES LESS THAN (TO_DAYS('2025-09-01')),
  PARTITION p2025_09 VALUES LESS THAN (TO_DAYS('2025-10-01')),
  PARTITION p2025_10 VALUES LESS THAN (TO_DAYS('2025-11-01')),
  PARTITION p2025_11 VALUES LESS THAN (TO_DAYS('2025-12-01')),
  PARTITION p2025_12 VALUES LESS THAN (TO_DAYS('2026-01-01')),
  PARTITION pMAX     VALUES LESS THAN (MAXVALUE)
);


-- ============================================================
-- D) SEED FAKE DATA (~1000 rows each)
--    All fake rows are distributed randomly across year 2025.
-- ============================================================

/* ---- D1) Seed FinancialTransaction (real partitioned table) ----
   Use a marker: description = 'PERF_TEST_FIN'
   so cleanup can delete only fake rows.
*/
DELIMITER $$

DROP PROCEDURE IF EXISTS seed_financial_transactions $$
CREATE PROCEDURE seed_financial_transactions(IN p_n INT)
BEGIN
  DECLARE i INT DEFAULT 0;

  -- Remove old fake rows only (safe cleanup)
  DELETE FROM FinancialTransaction WHERE description = 'PERF_TEST_FIN';

  WHILE i < p_n DO
    INSERT INTO FinancialTransaction
      (transaction_type, reference_type, reference_id, amount, transaction_at, description)
    VALUES
      (
        IF(RAND() < 0.5, 'INCOME', 'EXPENSE'),
        ELT(1 + FLOOR(RAND()*3), 'PATIENT_INVOICE', 'SUPPLIER_INVOICE', 'OTHER'),
        1 + FLOOR(RAND()*5000),
        ROUND(10 + RAND()*10000, 2),
        TIMESTAMPADD(MINUTE, FLOOR(RAND() * 525600), '2025-01-01 00:00:00'),
        'PERF_TEST_FIN'
      );

    SET i = i + 1;
  END WHILE;

  SELECT p_n AS requested, i AS inserted;
END $$

DELIMITER ;

CALL seed_financial_transactions(1000);


/* ---- D2) Seed appointment_report_part ---- */
DELIMITER $$

DROP PROCEDURE IF EXISTS seed_appt_report $$
CREATE PROCEDURE seed_appt_report(IN p_n INT)
BEGIN
  DECLARE i INT DEFAULT 0;

  TRUNCATE TABLE appointment_report_part;

  WHILE i < p_n DO
    INSERT INTO appointment_report_part
      (appointment_id, appointment_date, patient_id, doctor_id, timeslot_id, current_status, created_at)
    VALUES
      (
        10000000 + i,
        DATE_ADD('2025-01-01', INTERVAL FLOOR(RAND()*365) DAY),
        1 + FLOOR(RAND()*200),
        1 + FLOOR(RAND()*50),
        1 + FLOOR(RAND()*12),
        ELT(1 + FLOOR(RAND()*5), 'CREATED','CONFIRMED','CANCELLED','IN_PROGRESS','COMPLETED'),
        TIMESTAMPADD(MINUTE, FLOOR(RAND()*525600), '2025-01-01 00:00:00')
      );
    SET i = i + 1;
  END WHILE;

  SELECT p_n AS inserted;
END $$

DELIMITER ;

CALL seed_appt_report(1000);


/* ---- D3) Seed auditlog_report_part ---- */
DELIMITER $$

DROP PROCEDURE IF EXISTS seed_audit_report $$
CREATE PROCEDURE seed_audit_report(IN p_n INT)
BEGIN
  DECLARE i INT DEFAULT 0;

  TRUNCATE TABLE auditlog_report_part;

  WHILE i < p_n DO
    INSERT INTO auditlog_report_part
      (audit_id, changed_at, user_id, table_name, field_name, old_value, new_value, action_type)
    VALUES
      (
        20000000 + i,
        TIMESTAMPADD(MINUTE, FLOOR(RAND()*525600), '2025-01-01 00:00:00'),
        1 + FLOOR(RAND()*30),
        ELT(1 + FLOOR(RAND()*4), 'Appointment','Visit','Prescription','Payment'),
        ELT(1 + FLOOR(RAND()*3), 'status','amount','note'),
        'old_val',
        'new_val',
        ELT(1 + FLOOR(RAND()*3), 'INSERT','UPDATE','DELETE')
      );
    SET i = i + 1;
  END WHILE;

  SELECT p_n AS inserted;
END $$

DELIMITER ;

CALL seed_audit_report(1000);


/* ---- D4) Seed stockmovement_report_part ----
   Note: batch_id is faked (no FK here). We just need realistic distributions.
*/
DELIMITER $$

DROP PROCEDURE IF EXISTS seed_stock_report $$
CREATE PROCEDURE seed_stock_report(IN p_n INT)
BEGIN
  DECLARE i INT DEFAULT 0;

  TRUNCATE TABLE stockmovement_report_part;

  WHILE i < p_n DO
    INSERT INTO stockmovement_report_part
      (movement_id, moved_at, batch_id, movement_type, quantity, reference_type, reference_id)
    VALUES
      (
        30000000 + i,
        TIMESTAMPADD(MINUTE, FLOOR(RAND()*525600), '2025-01-01 00:00:00'),
        1 + FLOOR(RAND()*500),
        ELT(1 + FLOOR(RAND()*2), 'IN','OUT'),
        1 + FLOOR(RAND()*50),
        ELT(1 + FLOOR(RAND()*3), 'PRESCRIPTION','INVOICE','OTHER'),
        1 + FLOOR(RAND()*5000)
      );
    SET i = i + 1;
  END WHILE;

  SELECT p_n AS inserted;
END $$

DELIMITER ;

CALL seed_stock_report(1000);


-- ============================================================
-- E) VERIFY PARTITION DISTRIBUTION (TABLE_ROWS by partition)
-- ============================================================

-- FinancialTransaction
SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'FinancialTransaction'
  AND PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_ORDINAL_POSITION;

-- appointment_report_part
SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'appointment_report_part'
  AND PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_ORDINAL_POSITION;

-- auditlog_report_part
SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'auditlog_report_part'
  AND PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_ORDINAL_POSITION;

-- stockmovement_report_part
SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'stockmovement_report_part'
  AND PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_ORDINAL_POSITION;


-- ============================================================
-- F) EXECUTION EVIDENCE / BENCHMARKS
--    We show:
--    1) EXPLAIN (plan)
--    2) Handler_read counters for "month filter" vs "full scan"
-- ============================================================

/* ---- F1) FinancialTransaction: month filter vs full scan ---- */
EXPLAIN
SELECT SUM(amount)
FROM FinancialTransaction
WHERE transaction_at >= '2025-06-01'
  AND transaction_at <  '2025-07-01';

-- Month-filter query (should touch fewer partitions/rows)
FLUSH STATUS;
SELECT SUM(amount) AS june_total
FROM FinancialTransaction
WHERE transaction_at >= '2025-06-01'
  AND transaction_at <  '2025-07-01';
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);

-- Full scan query
FLUSH STATUS;
SELECT SUM(amount) AS all_total
FROM FinancialTransaction;
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);


/* ---- F2) appointment_report_part: month filter vs full scan ---- */
EXPLAIN
SELECT COUNT(*)
FROM appointment_report_part
WHERE appointment_date >= '2025-06-01'
  AND appointment_date <  '2025-07-01';

FLUSH STATUS;
SELECT COUNT(*) AS june_cnt
FROM appointment_report_part
WHERE appointment_date >= '2025-06-01'
  AND appointment_date <  '2025-07-01';
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);

FLUSH STATUS;
SELECT COUNT(*) AS all_cnt
FROM appointment_report_part;
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);


/* ---- F3) auditlog_report_part: month filter vs full scan ---- */
EXPLAIN
SELECT COUNT(*)
FROM auditlog_report_part
WHERE changed_at >= '2025-10-01'
  AND changed_at <  '2025-11-01';

FLUSH STATUS;
SELECT COUNT(*) AS oct_cnt
FROM auditlog_report_part
WHERE changed_at >= '2025-10-01'
  AND changed_at <  '2025-11-01';
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);

FLUSH STATUS;
SELECT COUNT(*) AS all_cnt
FROM auditlog_report_part;
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);


/* ---- F4) stockmovement_report_part: month filter vs full scan ---- */
EXPLAIN
SELECT COUNT(*)
FROM stockmovement_report_part
WHERE moved_at >= '2025-03-01'
  AND moved_at <  '2025-04-01';

FLUSH STATUS;
SELECT COUNT(*) AS mar_cnt
FROM stockmovement_report_part
WHERE moved_at >= '2025-03-01'
  AND moved_at <  '2025-04-01';
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);

FLUSH STATUS;
SELECT COUNT(*) AS all_cnt
FROM stockmovement_report_part;
SHOW SESSION STATUS
WHERE Variable_name IN (
  'Handler_read_first','Handler_read_key','Handler_read_next',
  'Handler_read_rnd','Handler_read_rnd_next'
);


-- ============================================================
-- G) CLEANUP (remove synthetic rows after demo)
--    - Report tables: TRUNCATE (fast, safe, no FKs)
--    - FinancialTransaction: delete only fake rows by marker
-- ============================================================

TRUNCATE TABLE appointment_report_part;
TRUNCATE TABLE auditlog_report_part;
TRUNCATE TABLE stockmovement_report_part;

DELETE FROM FinancialTransaction
WHERE description = 'PERF_TEST_FIN';

-- Final confirmation counts
SELECT 'FinancialTransaction(fake rows left)' AS label, COUNT(*) AS cnt
FROM FinancialTransaction
WHERE description = 'PERF_TEST_FIN';

SELECT 'appointment_report_part' AS label, COUNT(*) AS cnt FROM appointment_report_part;
SELECT 'auditlog_report_part' AS label, COUNT(*) AS cnt FROM auditlog_report_part;
SELECT 'stockmovement_report_part' AS label, COUNT(*) AS cnt FROM stockmovement_report_part;