-- =====================================================
-- STORED PROCEDURES
-- =====================================================

USE hospital_management_system;

DELIMITER $$

-- =====================================================
-- SECTION 1: USER MANAGEMENT & AUTHENTICATION
-- =====================================================

-- -----------------------------------------------------
-- SP: Create User with Default Password
-- Description: Creates system users with hashed passwords and role assignment
-- Authorization: ADMIN only
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_user_with_default_password$$
CREATE PROCEDURE sp_create_user_with_default_password(
    IN p_username VARCHAR(100),
    IN p_role_name VARCHAR(50),
    IN p_admin_user_id INT,
    OUT p_new_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_default_password VARCHAR(255) DEFAULT 'Hospital@123';
    DECLARE v_admin_role_count INT;
    DECLARE v_role_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error creating user: Transaction rolled back';
        SET p_new_user_id = NULL;
    END;

    -- Verify admin authorization
    SELECT COUNT(*) INTO v_admin_role_count
    FROM UserRole
    WHERE user_id = p_admin_user_id AND role_name = 'ADMIN';

    IF v_admin_role_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only ADMIN can create users';
        SET p_new_user_id = NULL;
    ELSE
        -- Verify role exists
        SELECT COUNT(*) INTO v_role_exists
        FROM Role WHERE role_name = p_role_name;

        IF v_role_exists = 0 THEN
            SET p_status_code = 404;
            SET p_message = 'Role not found';
            SET p_new_user_id = NULL;
        ELSE
            START TRANSACTION;

            -- Create user with hashed password
            INSERT INTO User (username, password_hash, status, must_change_password)
            VALUES (
                p_username,
                SHA2(v_default_password, 256),
                'ACTIVE',
                TRUE
            );

            SET p_new_user_id = LAST_INSERT_ID();

            -- Assign role
            INSERT INTO UserRole (user_id, role_name)
            VALUES (p_new_user_id, p_role_name);

            COMMIT;

            SET p_status_code = 200;
            SET p_message = CONCAT('User created successfully. Default password must be changed on first login.');
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Change Password
-- Description: Allows users to change their password securely
-- Authorization: All authenticated users
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_change_password$$
CREATE PROCEDURE sp_change_password(
    IN p_user_id INT,
    IN p_old_password VARCHAR(255),
    IN p_new_password VARCHAR(255),
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_user_status ENUM('ACTIVE', 'LOCKED');
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error changing password';
    END;

    -- Get current password hash and status
    SELECT password_hash, status INTO v_stored_hash, v_user_status
    FROM User
    WHERE user_id = p_user_id;

    IF v_stored_hash IS NULL THEN
        SET p_status_code = 404;
        SET p_message = 'User not found';
    ELSEIF v_user_status = 'LOCKED' THEN
        SET p_status_code = 403;
        SET p_message = 'Account is locked';
    ELSEIF SHA2(p_old_password, 256) != v_stored_hash THEN
        SET p_status_code = 401;
        SET p_message = 'Current password is incorrect';
    ELSEIF LENGTH(p_new_password) < 8 THEN
        SET p_status_code = 400;
        SET p_message = 'New password must be at least 8 characters';
    ELSE
        START TRANSACTION;

        UPDATE User
        SET password_hash = SHA2(p_new_password, 256),
            must_change_password = FALSE
        WHERE user_id = p_user_id;

        COMMIT;

        SET p_status_code = 200;
        SET p_message = 'Password changed successfully';
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Update User Role
-- Description: Changes user roles with authorization checks
-- Authorization: ADMIN only
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_update_user_role$$
CREATE PROCEDURE sp_update_user_role(
    IN p_target_user_id INT,
    IN p_new_role_name VARCHAR(50),
    IN p_admin_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_admin_role_count INT;
    DECLARE v_role_exists INT;
    DECLARE v_old_role VARCHAR(50);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error updating user role';
    END;

    -- Verify admin authorization
    SELECT COUNT(*) INTO v_admin_role_count
    FROM UserRole
    WHERE user_id = p_admin_user_id AND role_name = 'ADMIN';

    IF v_admin_role_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only ADMIN can update user roles';
    ELSE
        -- Verify new role exists
        SELECT COUNT(*) INTO v_role_exists
        FROM Role WHERE role_name = p_new_role_name;

        IF v_role_exists = 0 THEN
            SET p_status_code = 404;
            SET p_message = 'Role not found';
        ELSE
            START TRANSACTION;

            -- Get old role
            SELECT role_name INTO v_old_role
            FROM UserRole
            WHERE user_id = p_target_user_id
            LIMIT 1;

            -- Delete old role assignments
            DELETE FROM UserRole WHERE user_id = p_target_user_id;

            -- Insert new role
            INSERT INTO UserRole (user_id, role_name)
            VALUES (p_target_user_id, p_new_role_name);

            COMMIT;

            SET p_status_code = 200;
            SET p_message = 'User role updated successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Deactivate User
-- Description: Soft-deactivates users while preserving records
-- Authorization: ADMIN only
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_deactivate_user$$
CREATE PROCEDURE sp_deactivate_user(
    IN p_target_user_id INT,
    IN p_admin_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_admin_role_count INT;
    DECLARE v_username VARCHAR(100);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error deactivating user';
    END;

    -- Verify admin authorization
    SELECT COUNT(*) INTO v_admin_role_count
    FROM UserRole
    WHERE user_id = p_admin_user_id AND role_name = 'ADMIN';

    IF v_admin_role_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only ADMIN can deactivate users';
    ELSE
        START TRANSACTION;

        -- Get username
        SELECT username INTO v_username
        FROM User WHERE user_id = p_target_user_id;

        IF v_username IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'User not found';
        ELSE
            -- Deactivate user
            UPDATE User
            SET status = 'LOCKED'
            WHERE user_id = p_target_user_id;

            COMMIT;

            SET p_status_code = 200;
            SET p_message = CONCAT('User ', v_username, ' deactivated successfully');
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Verify Login
-- Description: Verifies user credentials and logs login attempt
-- Authorization: SYSTEM
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_verify_login$$
CREATE PROCEDURE sp_verify_login(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_ip_address VARCHAR(45),
    OUT p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255),
    OUT p_must_change_password BOOLEAN
)
BEGIN
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_user_status ENUM('ACTIVE', 'LOCKED');
    DECLARE v_must_change BOOLEAN;

    -- Get user details
    SELECT user_id, password_hash, `status`, must_change_password
    INTO p_user_id, v_stored_hash, v_user_status, v_must_change
    FROM `User`
    WHERE username = p_username;

    IF p_user_id IS NULL THEN
        -- User not found
        SET p_status_code = 401;
        SET p_message = 'Invalid username or password';
        SET p_user_id = NULL;
        SET p_must_change_password = FALSE;
    ELSEIF v_user_status = 'LOCKED' THEN
        -- Account locked
        INSERT INTO Login_History (user_id, login_status, ip_address)
        VALUES (p_user_id, 'FAILED', p_ip_address);
        
        SET p_status_code = 403;
        SET p_message = 'Account is locked';
        SET p_user_id = NULL;
        SET p_must_change_password = FALSE;
    ELSEIF SHA2(p_password, 256) != v_stored_hash THEN
        -- Wrong password
        INSERT INTO Login_History (user_id, login_status, ip_address)
        VALUES (p_user_id, 'FAILED', p_ip_address);
        
        SET p_status_code = 401;
        SET p_message = 'Invalid username or password';
        SET p_user_id = NULL;
        SET p_must_change_password = FALSE;
    ELSE
        -- Successful login
        INSERT INTO Login_History (user_id, login_status, ip_address)
        VALUES (p_user_id, 'SUCCESS', p_ip_address);
        
        SET p_status_code = 200;
        SET p_message = 'Login successful';
        SET p_must_change_password = v_must_change;
    END IF;
END$$

-- =====================================================
-- SECTION 2: DEPARTMENT MANAGEMENT
-- =====================================================

-- -----------------------------------------------------
-- SP: Create Department
-- Description: Adds new departments with validation
-- Authorization: ADMIN only
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_department$$
CREATE PROCEDURE sp_create_department(
    IN p_department_name VARCHAR(100),
    IN p_description TEXT,
    IN p_admin_user_id INT,
    OUT p_department_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_admin_role_count INT;
    DECLARE v_duplicate_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error creating department';
        SET p_department_id = NULL;
    END;

    -- Verify admin authorization
    SELECT COUNT(*) INTO v_admin_role_count
    FROM UserRole
    WHERE user_id = p_admin_user_id AND role_name = 'ADMIN';

    IF v_admin_role_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only ADMIN can create departments';
        SET p_department_id = NULL;
    ELSE
        -- Check for duplicate name
        SELECT COUNT(*) INTO v_duplicate_count
        FROM Department
        WHERE department_name = p_department_name;

        IF v_duplicate_count > 0 THEN
            SET p_status_code = 409;
            SET p_message = 'Department name already exists';
            SET p_department_id = NULL;
        ELSE
            START TRANSACTION;

            INSERT INTO Department (department_name, `description`)
            VALUES (p_department_name, p_description);

            SET p_department_id = LAST_INSERT_ID();

            COMMIT;

            SET p_status_code = 200;
            SET p_message = 'Department created successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Assign Department Lead
-- Description: Assigns department leadership with automatic end-date handling
-- Authorization: ADMIN only
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_assign_department_lead$$
CREATE PROCEDURE sp_assign_department_lead(
    IN p_department_id INT,
    IN p_doctor_id INT,
    IN p_start_date DATE,
    IN p_admin_user_id INT,
    OUT p_leadership_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_admin_role_count INT;
    DECLARE v_doctor_department INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error assigning department lead';
        SET p_leadership_id = NULL;
    END;

    -- Verify admin authorization
    SELECT COUNT(*) INTO v_admin_role_count
    FROM UserRole
    WHERE user_id = p_admin_user_id AND role_name = 'ADMIN';

    IF v_admin_role_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only ADMIN can assign department leads';
        SET p_leadership_id = NULL;
    ELSE
        -- Verify doctor belongs to department
        SELECT department_id INTO v_doctor_department
        FROM Doctor
        WHERE doctor_id = p_doctor_id;

        IF v_doctor_department IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Doctor not found';
            SET p_leadership_id = NULL;
        ELSEIF v_doctor_department != p_department_id THEN
            SET p_status_code = 400;
            SET p_message = 'Doctor does not belong to this department';
            SET p_leadership_id = NULL;
        ELSE
            START TRANSACTION;

            -- End current leadership
            UPDATE Department_Leadership
            SET end_date = DATE_SUB(p_start_date, INTERVAL 1 DAY)
            WHERE department_id = p_department_id
              AND end_date IS NULL;

            -- Create new leadership
            INSERT INTO Department_Leadership (department_id, doctor_id, start_date, end_date)
            VALUES (p_department_id, p_doctor_id, p_start_date, NULL);

            SET p_leadership_id = LAST_INSERT_ID();

            COMMIT;

            SET p_status_code = 200;
            SET p_message = 'Department lead assigned successfully';
        END IF;
    END IF;
END$$

-- =====================================================
-- SECTION 3: DOCTOR SCHEDULING
-- =====================================================

-- -----------------------------------------------------
-- SP: Create Doctor Availability
-- Description: Publishes doctor availability slots
-- Authorization: DOCTOR only
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_doctor_availability$$
CREATE PROCEDURE sp_create_doctor_availability(
    IN p_doctor_id INT,
    IN p_timeslot_id INT,
    IN p_available_date DATE,
    IN p_is_available BOOLEAN,
    IN p_user_id INT,
    OUT p_availability_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_doctor_role_count INT;
    DECLARE v_timeslot_exists INT;
    DECLARE v_duplicate_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error creating availability';
        SET p_availability_id = NULL;
    END;

    -- Verify doctor authorization
    SELECT COUNT(*) INTO v_doctor_role_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name = 'DOCTOR';

    IF v_doctor_role_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only DOCTOR can set availability';
        SET p_availability_id = NULL;
    ELSE
        -- Verify timeslot exists
        SELECT COUNT(*) INTO v_timeslot_exists
        FROM TimeSlot WHERE timeslot_id = p_timeslot_id;

        IF v_timeslot_exists = 0 THEN
            SET p_status_code = 404;
            SET p_message = 'Time slot not found';
            SET p_availability_id = NULL;
        ELSEIF p_available_date < CURDATE() THEN
            SET p_status_code = 400;
            SET p_message = 'Cannot set availability for past dates';
            SET p_availability_id = NULL;
        ELSE
            -- Check for duplicates
            SELECT COUNT(*) INTO v_duplicate_count
            FROM Doctor_Availability
            WHERE doctor_id = p_doctor_id
              AND timeslot_id = p_timeslot_id
              AND available_date = p_available_date;

            IF v_duplicate_count > 0 THEN
                -- Update existing record
                START TRANSACTION;

                UPDATE Doctor_Availability
                SET is_available = p_is_available
                WHERE doctor_id = p_doctor_id
                  AND timeslot_id = p_timeslot_id
                  AND available_date = p_available_date;

                SELECT availability_id INTO p_availability_id
                FROM Doctor_Availability
                WHERE doctor_id = p_doctor_id
                  AND timeslot_id = p_timeslot_id
                  AND available_date = p_available_date;

                COMMIT;

                SET p_status_code = 200;
                SET p_message = 'Availability updated successfully';
            ELSE
                -- Insert new record
                START TRANSACTION;

                INSERT INTO Doctor_Availability (doctor_id, timeslot_id, available_date, is_available)
                VALUES (p_doctor_id, p_timeslot_id, p_available_date, p_is_available);

                SET p_availability_id = LAST_INSERT_ID();

                COMMIT;

                SET p_status_code = 201;
                SET p_message = 'Availability created successfully';
            END IF;
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Get Doctor Schedule
-- Description: Retrieves doctor schedules efficiently
-- Authorization: DOCTOR, RECEPTIONIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_doctor_schedule$$
CREATE PROCEDURE sp_get_doctor_schedule(
    IN p_doctor_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_authorized INT;

    -- Verify authorization
    SELECT COUNT(*) INTO v_authorized
    FROM UserRole
    WHERE user_id = p_user_id
      AND role_name IN ('DOCTOR', 'RECEPTIONIST', 'ADMIN');

    IF v_authorized = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized access';
    ELSE
        -- Return schedule with appointments
        SELECT 
            da.available_date,
            ts.start_time,
            ts.end_time,
            da.is_available,
            a.appointment_id,
            a.current_status AS appointment_status,
            p.full_name AS patient_name,
            a.reason
        FROM Doctor_Availability da
        JOIN TimeSlot ts ON da.timeslot_id = ts.timeslot_id
        LEFT JOIN Appointment a ON a.doctor_id = da.doctor_id
            AND a.appointment_date = da.available_date
            AND a.timeslot_id = da.timeslot_id
        LEFT JOIN Patient p ON a.patient_id = p.patient_id
        WHERE da.doctor_id = p_doctor_id
          AND da.available_date BETWEEN p_start_date AND p_end_date
        ORDER BY da.available_date, ts.start_time;

        SET p_status_code = 200;
        SET p_message = 'Schedule retrieved successfully';
    END IF;
END$$

-- =====================================================
-- SECTION 4: APPOINTMENT MANAGEMENT
-- =====================================================

-- -----------------------------------------------------
-- SP: Register Patient
-- Description: Registers new patients with duplicate detection
-- Authorization: RECEPTIONIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_register_patient$$
CREATE PROCEDURE sp_register_patient(
    IN p_full_name VARCHAR(255),
    IN p_date_of_birth DATE,
    IN p_gender ENUM('Male','Female','Other'),
    IN p_phone VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_address VARCHAR(255),
    IN p_user_id INT,
    OUT p_patient_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_receptionist_count INT;
    DECLARE v_duplicate_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error registering patient';
        SET p_patient_id = NULL;
    END;

    -- Verify receptionist authorization
    SELECT COUNT(*) INTO v_receptionist_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('RECEPTIONIST', 'ADMIN');

    IF v_receptionist_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only RECEPTIONIST can register patients';
        SET p_patient_id = NULL;
    ELSE
        -- Check for duplicates
        SELECT COUNT(*) INTO v_duplicate_count
        FROM Patient
        WHERE (phone = p_phone OR email = p_email)
          AND phone IS NOT NULL
          AND email IS NOT NULL;

        IF v_duplicate_count > 0 THEN
            -- Return existing patient
            SELECT patient_id INTO p_patient_id
            FROM Patient
            WHERE phone = p_phone OR email = p_email
            LIMIT 1;

            SET p_status_code = 409;
            SET p_message = 'Patient with this phone/email already exists';
        ELSE
            START TRANSACTION;

            INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address)
            VALUES (p_full_name, p_date_of_birth, p_gender, p_phone, p_email, p_address);

            SET p_patient_id = LAST_INSERT_ID();

            COMMIT;

            SET p_status_code = 201;
            SET p_message = 'Patient registered successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Book Appointment
-- Description: Books appointments with conflict prevention
-- Authorization: RECEPTIONIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_book_appointment$$
CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_timeslot_id INT,
    IN p_appointment_date DATE,
    IN p_reason TEXT,
    IN p_user_id INT,
    OUT p_appointment_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_receptionist_count INT;
    DECLARE v_is_available BOOLEAN;
    DECLARE v_conflict_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error booking appointment';
        SET p_appointment_id = NULL;
    END;

    -- Verify authorization
    SELECT COUNT(*) INTO v_receptionist_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('RECEPTIONIST', 'ADMIN');

    IF v_receptionist_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only RECEPTIONIST can book appointments';
        SET p_appointment_id = NULL;
    ELSEIF p_appointment_date < CURDATE() THEN
        SET p_status_code = 400;
        SET p_message = 'Cannot book appointments in the past';
        SET p_appointment_id = NULL;
    ELSE
        -- Check doctor availability
        SELECT is_available INTO v_is_available
        FROM Doctor_Availability
        WHERE doctor_id = p_doctor_id
          AND timeslot_id = p_timeslot_id
          AND available_date = p_appointment_date;

        IF v_is_available IS NULL OR v_is_available = FALSE THEN
            SET p_status_code = 409;
            SET p_message = 'Doctor not available at this time';
            SET p_appointment_id = NULL;
        ELSE
            -- Check for conflicts
            SELECT COUNT(*) INTO v_conflict_count
            FROM Appointment
            WHERE doctor_id = p_doctor_id
              AND appointment_date = p_appointment_date
              AND timeslot_id = p_timeslot_id
              AND current_status NOT IN ('CANCELLED');

            IF v_conflict_count > 0 THEN
                SET p_status_code = 409;
                SET p_message = 'Time slot already booked';
                SET p_appointment_id = NULL;
            ELSE
                START TRANSACTION;

                -- Create appointment
                INSERT INTO Appointment (patient_id, doctor_id, timeslot_id, appointment_date, reason, current_status)
                VALUES (p_patient_id, p_doctor_id, p_timeslot_id, p_appointment_date, p_reason, 'CREATED');

                SET p_appointment_id = LAST_INSERT_ID();

                -- Record status history
                INSERT INTO Appointment_Status_History (appointment_id, old_status, new_status, changed_by)
                VALUES (p_appointment_id, NULL, 'CREATED', p_user_id);

                -- Update availability
                UPDATE Doctor_Availability
                SET is_available = FALSE
                WHERE doctor_id = p_doctor_id
                  AND timeslot_id = p_timeslot_id
                  AND available_date = p_appointment_date;

                COMMIT;

                SET p_status_code = 201;
                SET p_message = 'Appointment booked successfully';
            END IF;
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Update Appointment Status
-- Description: Updates appointment status with history tracking
-- Authorization: DOCTOR, RECEPTIONIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_update_appointment_status$$
CREATE PROCEDURE sp_update_appointment_status(
    IN p_appointment_id INT,
    IN p_new_status ENUM('CREATED','CONFIRMED','CANCELLED','COMPLETED'),
    IN p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_authorized INT;
    DECLARE v_old_status ENUM('CREATED','CONFIRMED','CANCELLED','COMPLETED');
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error updating appointment status';
    END;

    -- Verify authorization
    SELECT COUNT(*) INTO v_authorized
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('DOCTOR', 'RECEPTIONIST', 'ADMIN');

    IF v_authorized = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized access';
    ELSE
        -- Get current status
        SELECT current_status INTO v_old_status
        FROM Appointment
        WHERE appointment_id = p_appointment_id;

        IF v_old_status IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Appointment not found';
        ELSEIF v_old_status = p_new_status THEN
            SET p_status_code = 400;
            SET p_message = 'Status is already set to this value';
        ELSE
            START TRANSACTION;

            -- Update appointment
            UPDATE Appointment
            SET current_status = p_new_status
            WHERE appointment_id = p_appointment_id;

            -- Record status history
            INSERT INTO Appointment_Status_History (appointment_id, old_status, new_status, changed_by)
            VALUES (p_appointment_id, v_old_status, p_new_status, p_user_id);

            COMMIT;

            SET p_status_code = 200;
            SET p_message = 'Appointment status updated successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Cancel Appointment
-- Description: Cancels appointments and restores availability
-- Authorization: RECEPTIONIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cancel_appointment$$
CREATE PROCEDURE sp_cancel_appointment(
    IN p_appointment_id INT,
    IN p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_authorized INT;
    DECLARE v_doctor_id INT;
    DECLARE v_timeslot_id INT;
    DECLARE v_appointment_date DATE;
    DECLARE v_current_status ENUM('CREATED','CONFIRMED','CANCELLED','COMPLETED');
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error cancelling appointment';
    END;

    -- Verify authorization
    SELECT COUNT(*) INTO v_authorized
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('RECEPTIONIST', 'ADMIN');

    IF v_authorized = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only RECEPTIONIST can cancel appointments';
    ELSE
        -- Get appointment details
        SELECT doctor_id, timeslot_id, appointment_date, current_status
        INTO v_doctor_id, v_timeslot_id, v_appointment_date, v_current_status
        FROM Appointment
        WHERE appointment_id = p_appointment_id;

        IF v_doctor_id IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Appointment not found';
        ELSEIF v_current_status = 'CANCELLED' THEN
            SET p_status_code = 400;
            SET p_message = 'Appointment already cancelled';
        ELSEIF v_current_status = 'COMPLETED' THEN
            SET p_status_code = 400;
            SET p_message = 'Cannot cancel completed appointment';
        ELSE
            START TRANSACTION;

            -- Update appointment status
            UPDATE Appointment
            SET current_status = 'CANCELLED'
            WHERE appointment_id = p_appointment_id;

            COMMIT;

            SET p_status_code = 200;
            SET p_message = 'Appointment cancelled successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Get Patient History
-- Description: Retrieves patient visit and appointment history
-- Authorization: RECEPTIONIST, DOCTOR
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_patient_history$$
CREATE PROCEDURE sp_get_patient_history(
    IN p_patient_id INT,
    IN p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_authorized INT;

    -- Verify authorization
    SELECT COUNT(*) INTO v_authorized
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('DOCTOR', 'RECEPTIONIST', 'ADMIN');

    IF v_authorized = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized access';
    ELSE
        -- Return appointment history
        SELECT 
            a.appointment_id,
            a.appointment_date,
            ts.start_time,
            ts.end_time,
            a.current_status,
            d.full_name AS doctor_name,
            dept.department_name,
            a.reason,
            v.visit_id,
            v.clinical_note
        FROM Appointment a
        JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id
        JOIN Doctor d ON a.doctor_id = d.doctor_id
        JOIN Department dept ON d.department_id = dept.department_id
        LEFT JOIN Visit v ON a.appointment_id = v.appointment_id
        WHERE a.patient_id = p_patient_id
        ORDER BY a.appointment_date DESC, ts.start_time DESC;

        SET p_status_code = 200;
        SET p_message = 'Patient history retrieved successfully';
    END IF;
END$$

-- =====================================================
-- SECTION 5: CLINICAL VISIT MANAGEMENT
-- =====================================================

-- -----------------------------------------------------
-- SP: Start Visit
-- Description: Transitions confirmed appointment to active visit
-- Authorization: DOCTOR
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_start_visit$$
CREATE PROCEDURE sp_start_visit(
    IN p_appointment_id INT,
    IN p_doctor_id INT,
    IN p_user_id INT,
    OUT p_visit_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_doctor_count INT;
    DECLARE v_patient_id INT;
    DECLARE v_appointment_doctor INT;
    DECLARE v_appointment_status ENUM('CREATED','CONFIRMED','CANCELLED','COMPLETED');
    DECLARE v_visit_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error starting visit';
        SET p_visit_id = NULL;
    END;

    -- Verify doctor authorization
    SELECT COUNT(*) INTO v_doctor_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name = 'DOCTOR';

    IF v_doctor_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only DOCTOR can start visits';
        SET p_visit_id = NULL;
    ELSE
        -- Get appointment details
        SELECT patient_id, doctor_id, current_status
        INTO v_patient_id, v_appointment_doctor, v_appointment_status
        FROM Appointment
        WHERE appointment_id = p_appointment_id;

        IF v_patient_id IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Appointment not found';
            SET p_visit_id = NULL;
        ELSEIF v_appointment_doctor != p_doctor_id THEN
            SET p_status_code = 403;
            SET p_message = 'This appointment is assigned to another doctor';
            SET p_visit_id = NULL;
        ELSEIF v_appointment_status NOT IN ('CONFIRMED', 'CREATED') THEN
            SET p_status_code = 400;
            SET p_message = 'Appointment must be confirmed to start visit';
            SET p_visit_id = NULL;
        ELSE
            -- Check if visit already exists
            SELECT COUNT(*) INTO v_visit_exists
            FROM Visit WHERE appointment_id = p_appointment_id;

            IF v_visit_exists > 0 THEN
                SET p_status_code = 409;
                SET p_message = 'Visit already exists for this appointment';
                SELECT visit_id INTO p_visit_id FROM Visit WHERE appointment_id = p_appointment_id;
            ELSE
                START TRANSACTION;

                -- Create visit
                INSERT INTO Visit (appointment_id, patient_id, doctor_id, visit_start_time)
                VALUES (p_appointment_id, v_patient_id, p_doctor_id, NOW());

                SET p_visit_id = LAST_INSERT_ID();

                -- Update appointment status
                UPDATE Appointment
                SET current_status = 'COMPLETED'
                WHERE appointment_id = p_appointment_id;

                -- Record status history
                INSERT INTO Appointment_Status_History (appointment_id, old_status, new_status, changed_by)
                VALUES (p_appointment_id, v_appointment_status, 'COMPLETED', p_user_id);

                COMMIT;

                SET p_status_code = 201;
                SET p_message = 'Visit started successfully';
            END IF;
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Add Diagnosis
-- Description: Adds medical diagnoses to visits
-- Authorization: DOCTOR
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_add_diagnosis$$
CREATE PROCEDURE sp_add_diagnosis(
    IN p_visit_id INT,
    IN p_diagnosis_id INT,
    IN p_doctor_id INT,
    IN p_doctor_note TEXT,
    IN p_user_id INT,
    OUT p_visit_diagnosis_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_doctor_count INT;
    DECLARE v_visit_doctor INT;
    DECLARE v_duplicate_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error adding diagnosis';
        SET p_visit_diagnosis_id = NULL;
    END;

    -- Verify doctor authorization
    SELECT COUNT(*) INTO v_doctor_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name = 'DOCTOR';

    IF v_doctor_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only DOCTOR can add diagnoses';
        SET p_visit_diagnosis_id = NULL;
    ELSE
        -- Verify doctor owns this visit
        SELECT doctor_id INTO v_visit_doctor
        FROM Visit WHERE visit_id = p_visit_id;

        IF v_visit_doctor IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Visit not found';
            SET p_visit_diagnosis_id = NULL;
        ELSEIF v_visit_doctor != p_doctor_id THEN
            SET p_status_code = 403;
            SET p_message = 'This visit belongs to another doctor';
            SET p_visit_diagnosis_id = NULL;
        ELSE
            -- Check for duplicates
            SELECT COUNT(*) INTO v_duplicate_count
            FROM Visit_Diagnosis
            WHERE visit_id = p_visit_id AND diagnosis_id = p_diagnosis_id;

            IF v_duplicate_count > 0 THEN
                SET p_status_code = 409;
                SET p_message = 'Diagnosis already added to this visit';
                SET p_visit_diagnosis_id = NULL;
            ELSE
                START TRANSACTION;

                INSERT INTO Visit_Diagnosis (visit_id, diagnosis_id, doctor_id, doctor_note)
                VALUES (p_visit_id, p_diagnosis_id, p_doctor_id, p_doctor_note);

                SET p_visit_diagnosis_id = LAST_INSERT_ID();

                COMMIT;

                SET p_status_code = 201;
                SET p_message = 'Diagnosis added successfully';
            END IF;
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Create Prescription
-- Description: Creates prescriptions linked to visits
-- Authorization: DOCTOR
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_prescription$$
CREATE PROCEDURE sp_create_prescription(
    IN p_visit_id INT,
    IN p_doctor_id INT,
    IN p_note TEXT,
    IN p_user_id INT,
    OUT p_prescription_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_doctor_count INT;
    DECLARE v_visit_doctor INT;
    DECLARE v_prescription_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error creating prescription';
        SET p_prescription_id = NULL;
    END;

    -- Verify doctor authorization
    SELECT COUNT(*) INTO v_doctor_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name = 'DOCTOR';

    IF v_doctor_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only DOCTOR can create prescriptions';
        SET p_prescription_id = NULL;
    ELSE
        -- Verify doctor owns this visit
        SELECT doctor_id INTO v_visit_doctor
        FROM Visit WHERE visit_id = p_visit_id;

        IF v_visit_doctor IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Visit not found';
            SET p_prescription_id = NULL;
        ELSEIF v_visit_doctor != p_doctor_id THEN
            SET p_status_code = 403;
            SET p_message = 'This visit belongs to another doctor';
            SET p_prescription_id = NULL;
        ELSE
            -- Check if prescription already exists
            SELECT COUNT(*) INTO v_prescription_exists
            FROM Prescription WHERE visit_id = p_visit_id;

            IF v_prescription_exists > 0 THEN
                SET p_status_code = 409;
                SET p_message = 'Prescription already exists for this visit';
                SELECT prescription_id INTO p_prescription_id FROM Prescription WHERE visit_id = p_visit_id;
            ELSE
                START TRANSACTION;

                INSERT INTO Prescription (visit_id, doctor_id, note)
                VALUES (p_visit_id, p_doctor_id, p_note);

                SET p_prescription_id = LAST_INSERT_ID();

                COMMIT;

                SET p_status_code = 201;
                SET p_message = 'Prescription created successfully';
            END IF;
        END IF;
    END IF;
END$$

-- =====================================================
-- SECTION 6: PHARMACY MANAGEMENT
-- =====================================================

-- -----------------------------------------------------
-- SP: Add Pharmacy Batch
-- Description: Adds pharmacy inventory batches with validation
-- Authorization: PHARMACIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_add_pharmacy_batch$$
CREATE PROCEDURE sp_add_pharmacy_batch(
    IN p_item_id INT,
    IN p_supplier_id INT,
    IN p_batch_number VARCHAR(100),
    IN p_expiry_date DATE,
    IN p_selling_unit_price DECIMAL(10,2),
    IN p_supply_unit_price DECIMAL(10,2),
    IN p_quantity INT,
    IN p_user_id INT,
    OUT p_batch_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_pharmacist_count INT;
    DECLARE v_duplicate_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error adding pharmacy batch';
        SET p_batch_id = NULL;
    END;

    -- Verify pharmacist authorization
    SELECT COUNT(*) INTO v_pharmacist_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('PHARMACIST', 'ADMIN');

    IF v_pharmacist_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only PHARMACIST can add batches';
        SET p_batch_id = NULL;
    ELSEIF p_expiry_date <= CURDATE() THEN
        SET p_status_code = 400;
        SET p_message = 'Expiry date must be in the future';
        SET p_batch_id = NULL;
    ELSEIF p_quantity <= 0 THEN
        SET p_status_code = 400;
        SET p_message = 'Quantity must be positive';
        SET p_batch_id = NULL;
    ELSEIF p_selling_unit_price < 0 OR p_supply_unit_price < 0 THEN
        SET p_status_code = 400;
        SET p_message = 'Prices cannot be negative';
        SET p_batch_id = NULL;
    ELSE
        -- Check for duplicate batch
        SELECT COUNT(*) INTO v_duplicate_count
        FROM PharmacyBatch
        WHERE item_id = p_item_id AND batch_number = p_batch_number;

        IF v_duplicate_count > 0 THEN
            SET p_status_code = 409;
            SET p_message = 'Batch number already exists for this item';
            SET p_batch_id = NULL;
        ELSE
            START TRANSACTION;

            INSERT INTO PharmacyBatch (item_id, supplier_id, batch_number, expiry_date, 
                                       selling_unit_price, supply_unit_price, quantity)
            VALUES (p_item_id, p_supplier_id, p_batch_number, p_expiry_date,
                    p_selling_unit_price, p_supply_unit_price, p_quantity);

            SET p_batch_id = LAST_INSERT_ID();

            -- Record stock movement IN
            INSERT INTO StockMovement (batch_id, movement_type, quantity, reference_type, reference_id)
            VALUES (p_batch_id, 'IN', p_quantity, 'PURCHASE', p_supplier_id);

            COMMIT;

            SET p_status_code = 201;
            SET p_message = 'Pharmacy batch added successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Dispense Medication
-- Description: Dispenses medication using FIFO logic
-- Authorization: PHARMACIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_dispense_medication$$
CREATE PROCEDURE sp_dispense_medication(
    IN p_prescription_id INT,
    IN p_item_id INT,
    IN p_quantity_needed INT,
    IN p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_pharmacist_count INT;
    DECLARE v_total_available INT DEFAULT 0;
    DECLARE v_batch_id INT;
    DECLARE v_batch_quantity INT;
    DECLARE v_quantity_to_dispense INT;
    DECLARE v_remaining_needed INT;
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE batch_cursor CURSOR FOR
        SELECT batch_id, quantity
        FROM PharmacyBatch
        WHERE item_id = p_item_id
          AND quantity > 0
          AND expiry_date > CURDATE()
        ORDER BY expiry_date ASC
        FOR UPDATE;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error dispensing medication';
    END;

    -- Verify pharmacist authorization
    SELECT COUNT(*) INTO v_pharmacist_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('PHARMACIST', 'ADMIN');

    IF v_pharmacist_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only PHARMACIST can dispense medication';
    ELSE
        -- Check total available quantity
        SELECT COALESCE(SUM(quantity), 0) INTO v_total_available
        FROM PharmacyBatch
        WHERE item_id = p_item_id
          AND quantity > 0
          AND expiry_date > CURDATE();

        IF v_total_available < p_quantity_needed THEN
            SET p_status_code = 400;
            SET p_message = CONCAT('Insufficient stock. Available: ', v_total_available, ', Needed: ', p_quantity_needed);
        ELSE
            START TRANSACTION;

            SET v_remaining_needed = p_quantity_needed;

            -- FIFO dispensing
            OPEN batch_cursor;

            read_loop: LOOP
                FETCH batch_cursor INTO v_batch_id, v_batch_quantity;
                
                IF done OR v_remaining_needed <= 0 THEN
                    LEAVE read_loop;
                END IF;

                -- Calculate quantity to dispense from this batch
                IF v_batch_quantity >= v_remaining_needed THEN
                    SET v_quantity_to_dispense = v_remaining_needed;
                ELSE
                    SET v_quantity_to_dispense = v_batch_quantity;
                END IF;

                -- Update batch quantity
                UPDATE PharmacyBatch
                SET quantity = quantity - v_quantity_to_dispense
                WHERE batch_id = v_batch_id;

                -- Record stock movement OUT
                INSERT INTO StockMovement (batch_id, movement_type, quantity, reference_type, reference_id)
                VALUES (v_batch_id, 'OUT', v_quantity_to_dispense, 'PRESCRIPTION', p_prescription_id);

                SET v_remaining_needed = v_remaining_needed - v_quantity_to_dispense;
            END LOOP;

            CLOSE batch_cursor;

            COMMIT;

            SET p_status_code = 200;
            SET p_message = 'Medication dispensed successfully';
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Check Low Stock
-- Description: Identifies low-stock pharmacy items
-- Authorization: PHARMACIST
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_check_low_stock$$
CREATE PROCEDURE sp_check_low_stock(
    IN p_threshold INT,
    IN p_user_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_pharmacist_count INT;

    -- Verify authorization
    SELECT COUNT(*) INTO v_pharmacist_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('PHARMACIST', 'ADMIN');

    IF v_pharmacist_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized access';
    ELSE
        -- Return low stock items
        SELECT 
            pi.item_id,
            pi.item_name,
            pi.unit,
            SUM(pb.quantity) AS total_stock,
            MIN(pb.expiry_date) AS nearest_expiry
        FROM PharmacyItem pi
        LEFT JOIN PharmacyBatch pb ON pi.item_id = pb.item_id 
            AND pb.quantity > 0
            AND pb.expiry_date > CURDATE()
        GROUP BY pi.item_id, pi.item_name, pi.unit
        HAVING COALESCE(total_stock, 0) < p_threshold
        ORDER BY total_stock ASC;

        SET p_status_code = 200;
        SET p_message = 'Low stock items retrieved successfully';
    END IF;
END$$

-- =====================================================
-- SECTION 7: BILLING & FINANCE
-- =====================================================

-- -----------------------------------------------------
-- SP: Generate Patient Invoice
-- Description: Generates invoices from visits automatically
-- Authorization: FINANCE
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_generate_patient_invoice$$
CREATE PROCEDURE sp_generate_patient_invoice(
    IN p_visit_id INT,
    IN p_user_id INT,
    OUT p_invoice_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_finance_count INT;
    DECLARE v_invoice_exists INT;
    DECLARE v_total_amount DECIMAL(15,2) DEFAULT 0;
    DECLARE v_service_id INT;
    DECLARE v_service_quantity INT;
    DECLARE v_service_fee DECIMAL(10,2);
    DECLARE v_line_total DECIMAL(12,2);
    DECLARE v_item_id INT;
    DECLARE v_item_quantity INT;
    DECLARE v_item_price DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE service_cursor CURSOR FOR
        SELECT vs.service_id, vs.quantity, ms.service_fee
        FROM Visit_Service vs
        JOIN MedicalService ms ON vs.service_id = ms.service_id
        WHERE vs.visit_id = p_visit_id;
    
    DECLARE medicine_cursor CURSOR FOR
        SELECT pi_item.item_id, pi_item.quantity, 
               (SELECT AVG(selling_unit_price) 
                FROM PharmacyBatch pb 
                WHERE pb.item_id = pi_item.item_id) AS avg_price
        FROM Prescription p
        JOIN Prescription_Item pi_item ON p.prescription_id = pi_item.prescription_id
        WHERE p.visit_id = p_visit_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error generating invoice';
        SET p_invoice_id = NULL;
    END;

    -- Verify finance authorization
    SELECT COUNT(*) INTO v_finance_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('FINANCE', 'ADMIN');

    IF v_finance_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only FINANCE can generate invoices';
        SET p_invoice_id = NULL;
    ELSE
        -- Check if invoice already exists
        SELECT COUNT(*) INTO v_invoice_exists
        FROM PatientInvoice WHERE visit_id = p_visit_id;

        IF v_invoice_exists > 0 THEN
            SET p_status_code = 409;
            SET p_message = 'Invoice already exists for this visit';
            SELECT patient_invoice_id INTO p_invoice_id FROM PatientInvoice WHERE visit_id = p_visit_id;
        ELSE
            START TRANSACTION;

            -- Create invoice header
            INSERT INTO PatientInvoice (visit_id, invoice_date, total_amount, status)
            VALUES (p_visit_id, CURDATE(), 0, 'NOT PAID');

            SET p_invoice_id = LAST_INSERT_ID();

            -- Add service items
            OPEN service_cursor;
            service_loop: LOOP
                FETCH service_cursor INTO v_service_id, v_service_quantity, v_service_fee;
                IF done THEN
                    LEAVE service_loop;
                END IF;

                SET v_line_total = v_service_quantity * v_service_fee;
                SET v_total_amount = v_total_amount + v_line_total;

                INSERT INTO PatientInvoice_Item (patient_invoice_id, item_type, reference_id, 
                                                  quantity, unit_price, line_total)
                VALUES (p_invoice_id, 'SERVICE', v_service_id, 
                        v_service_quantity, v_service_fee, v_line_total);
            END LOOP;
            CLOSE service_cursor;

            -- Add medicine items
            SET done = FALSE;
            OPEN medicine_cursor;
            medicine_loop: LOOP
                FETCH medicine_cursor INTO v_item_id, v_item_quantity, v_item_price;
                IF done THEN
                    LEAVE medicine_loop;
                END IF;

                IF v_item_price IS NOT NULL THEN
                    SET v_line_total = v_item_quantity * v_item_price;
                    SET v_total_amount = v_total_amount + v_line_total;

                    INSERT INTO PatientInvoice_Item (patient_invoice_id, item_type, reference_id,
                                                      quantity, unit_price, line_total)
                    VALUES (p_invoice_id, 'MEDICINE', v_item_id,
                            v_item_quantity, v_item_price, v_line_total);
                END IF;
            END LOOP;
            CLOSE medicine_cursor;

            -- Update total amount
            UPDATE PatientInvoice
            SET total_amount = v_total_amount
            WHERE patient_invoice_id = p_invoice_id;

            COMMIT;

            SET p_status_code = 201;
            SET p_message = CONCAT('Invoice generated successfully. Total: ', v_total_amount);
        END IF;
    END IF;
END$$

-- -----------------------------------------------------
-- SP: Record Payment
-- Description: Records payments and updates invoice status
-- Authorization: FINANCE
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_payment$$
CREATE PROCEDURE sp_record_payment(
    IN p_invoice_id INT,
    IN p_amount DECIMAL(12,2),
    IN p_payment_method VARCHAR(50),
    IN p_user_id INT,
    OUT p_payment_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_finance_count INT;
    DECLARE v_invoice_total DECIMAL(15,2);
    DECLARE v_paid_amount DECIMAL(15,2) DEFAULT 0;
    DECLARE v_remaining DECIMAL(15,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error recording payment';
        SET p_payment_id = NULL;
    END;

    -- Verify finance authorization
    SELECT COUNT(*) INTO v_finance_count
    FROM UserRole
    WHERE user_id = p_user_id AND role_name IN ('FINANCE', 'ADMIN');

    IF v_finance_count = 0 THEN
        SET p_status_code = 403;
        SET p_message = 'Unauthorized: Only FINANCE can record payments';
        SET p_payment_id = NULL;
    ELSEIF p_amount <= 0 THEN
        SET p_status_code = 400;
        SET p_message = 'Payment amount must be positive';
        SET p_payment_id = NULL;
    ELSE
        -- Get invoice total
        SELECT total_amount INTO v_invoice_total
        FROM PatientInvoice
        WHERE patient_invoice_id = p_invoice_id;

        IF v_invoice_total IS NULL THEN
            SET p_status_code = 404;
            SET p_message = 'Invoice not found';
            SET p_payment_id = NULL;
        ELSE
            -- Calculate total paid
            SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
            FROM Payment
            WHERE invoice_id = p_invoice_id;

            SET v_remaining = v_invoice_total - v_paid_amount;

            IF p_amount > v_remaining THEN
                SET p_status_code = 400;
                SET p_message = CONCAT('Payment exceeds remaining balance: ', v_remaining);
                SET p_payment_id = NULL;
            ELSE
                START TRANSACTION;

                -- Record payment
                INSERT INTO Payment (invoice_id, amount, payment_method)
                VALUES (p_invoice_id, p_amount, p_payment_method);

                SET p_payment_id = LAST_INSERT_ID();

                -- Update invoice status if fully paid
                IF v_paid_amount + p_amount >= v_invoice_total THEN
                    UPDATE PatientInvoice
                    SET status = 'PAID'
                    WHERE patient_invoice_id = p_invoice_id;
                END IF;

                COMMIT;

                SET p_status_code = 201;
                SET p_message = 'Payment recorded successfully';
            END IF;
        END IF;
    END IF;
END$$

-- =====================================================
-- SECTION 8: SYSTEM UTILITIES
-- =====================================================

-- -----------------------------------------------------
-- SP: Create Notification
-- Description: Creates system notifications for users
-- Authorization: SYSTEM, ADMIN
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_notification$$
CREATE PROCEDURE sp_create_notification(
    IN p_user_id INT,
    IN p_notification_type_id INT,
    IN p_content TEXT,
    OUT p_notification_id INT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = -1;
        SET p_message = 'Error creating notification';
        SET p_notification_id = NULL;
    END;

    START TRANSACTION;

    INSERT INTO Notification (user_id, notification_type_id, content, is_read)
    VALUES (p_user_id, p_notification_type_id, p_content, FALSE);

    SET p_notification_id = LAST_INSERT_ID();

    COMMIT;

    SET p_status_code = 201;
    SET p_message = 'Notification created successfully';
END$$

-- -----------------------------------------------------
-- SP: Log Audit Event
-- Description: Centralized audit logging
-- Authorization: SYSTEM
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_log_audit_event$$
CREATE PROCEDURE sp_log_audit_event(
    IN p_user_id INT,
    IN p_table_name VARCHAR(100),
    IN p_field_name VARCHAR(100),
    IN p_old_value TEXT,
    IN p_new_value TEXT,
    IN p_action_type ENUM('INSERT','UPDATE','DELETE')
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Silently fail to avoid cascading errors
        -- In production, this could write to error log
    END;

    INSERT INTO AuditLog (user_id, `table_name`, field_name, old_value, new_value, action_type)
    VALUES (p_user_id, p_table_name, p_field_name, p_old_value, p_new_value, p_action_type);
END$$

DELIMITER ;