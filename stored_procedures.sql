DELIMITER $$

-- =====================================================
-- SECTION 1: USER & SECURITY
-- =====================================================

-- 1. Create User
DROP PROCEDURE IF EXISTS sp_create_user_with_default_password$$
CREATE PROCEDURE sp_create_user_with_default_password(
    IN p_username VARCHAR(100), IN p_role_name VARCHAR(50), IN p_admin_id INT,
    OUT p_new_user_id INT, OUT p_status_code INT, OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_auth INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SET p_status_code = -1; SET p_message = 'Error creating user'; END;
    SET @current_user_id = p_admin_id;
    SELECT COUNT(*) INTO v_auth FROM UserRole WHERE user_id = p_admin_id AND role_name = 'ADMIN';
    IF v_auth = 0 THEN SET p_status_code = 403; SET p_message = 'Forbidden';
    ELSE
        START TRANSACTION;
        INSERT INTO User (username, password_hash, status, must_change_password)
        VALUES (p_username, SHA2('Hospital@123', 256), 'ACTIVE', TRUE);
        SET p_new_user_id = LAST_INSERT_ID();
        INSERT INTO UserRole (user_id, role_name) VALUES (p_new_user_id, p_role_name);
        COMMIT;
        SET p_status_code = 201; SET p_message = 'User created';
    END IF;
END$$

-- 2. Change Password
DROP PROCEDURE IF EXISTS sp_change_password$$
CREATE PROCEDURE sp_change_password(
    IN p_user_id INT, IN p_old_pwd VARCHAR(255), IN p_new_pwd VARCHAR(255),
    OUT p_status_code INT, OUT p_message VARCHAR(255)
)
BEGIN
    SET @current_user_id = p_user_id;
    IF (SELECT password_hash FROM User WHERE user_id = p_user_id) = SHA2(p_old_pwd, 256) THEN
        UPDATE User SET password_hash = SHA2(p_new_pwd, 256), must_change_password = FALSE WHERE user_id = p_user_id;
        SET p_status_code = 200; SET p_message = 'Password updated';
    ELSE SET p_status_code = 401; SET p_message = 'Old password incorrect';
    END IF;
END$$

-- 3. Update User Role
DROP PROCEDURE IF EXISTS sp_update_user_role$$
CREATE PROCEDURE sp_update_user_role(IN p_target_uid INT, IN p_role VARCHAR(50), IN p_admin_id INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_admin_id;
    START TRANSACTION;
    DELETE FROM UserRole WHERE user_id = p_target_uid;
    INSERT INTO UserRole (user_id, role_name) VALUES (p_target_uid, p_role);
    COMMIT;
    SET p_status = 200; SET p_msg = 'Role updated';
END$$

-- 4. Deactivate User
DROP PROCEDURE IF EXISTS sp_deactivate_user$$
CREATE PROCEDURE sp_deactivate_user(IN p_target_uid INT, IN p_admin_id INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_admin_id;
    UPDATE User SET status = 'LOCKED' WHERE user_id = p_target_uid;
    SET p_status = 200; SET p_msg = 'Account locked';
END$$

-- 5. Verify Login
DROP PROCEDURE IF EXISTS sp_verify_login$$
CREATE PROCEDURE sp_verify_login(
    IN p_username VARCHAR(100), IN p_password VARCHAR(255), IN p_ip VARCHAR(45),
    OUT p_user_id INT, OUT p_status_code INT, OUT p_message VARCHAR(255), OUT p_must_change BOOLEAN
)
BEGIN
    SET p_user_id = NULL;
    SELECT user_id, must_change_password INTO p_user_id, p_must_change
    FROM User WHERE username = p_username AND password_hash = SHA2(p_password, 256) AND status = 'ACTIVE';
    IF p_user_id IS NOT NULL THEN
        INSERT INTO Login_History (user_id, login_status, ip_address) VALUES (p_user_id, 'SUCCESS', p_ip);
        SET p_status_code = 200; SET p_message = 'Login successful';
    ELSE
        SET p_status_code = 401; SET p_message = 'Invalid credentials';
    END IF;
END$$

-- =====================================================
-- SECTION 2: FRONT DESK & SCHEDULING
-- =====================================================

-- 6. Register Patient
DROP PROCEDURE IF EXISTS sp_register_patient$$
CREATE PROCEDURE sp_register_patient(IN p_name VARCHAR(255), IN p_dob DATE, IN p_gender VARCHAR(10), IN p_phone VARCHAR(20), IN p_email VARCHAR(100), IN p_addr VARCHAR(255), IN p_uid INT, OUT p_pid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address) VALUES (p_name, p_dob, p_gender, p_phone, p_email, p_addr);
    SET p_pid = LAST_INSERT_ID(); SET p_status = 201; SET p_msg = 'Patient registered';
END$$

-- 7. Set Doctor Availability
DROP PROCEDURE IF EXISTS sp_create_doctor_availability$$
CREATE PROCEDURE sp_create_doctor_availability(IN p_doc_id INT, IN p_ts_id INT, IN p_date DATE, IN p_avail BOOLEAN, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Doctor_Availability (doctor_id, timeslot_id, available_date, is_available)
    VALUES (p_doc_id, p_ts_id, p_date, p_avail) ON DUPLICATE KEY UPDATE is_available = p_avail;
    SET p_status = 200; SET p_msg = 'Availability updated';
END$$

-- 8. Book Appointment
DROP PROCEDURE IF EXISTS sp_book_appointment$$
CREATE PROCEDURE sp_book_appointment(IN p_pid INT, IN p_doc_id INT, IN p_ts_id INT, IN p_date DATE, IN p_reason TEXT, IN p_uid INT, OUT p_aid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    IF (SELECT is_available FROM Doctor_Availability WHERE doctor_id = p_doc_id AND timeslot_id = p_ts_id AND available_date = p_date) = TRUE THEN
        START TRANSACTION;
        INSERT INTO Appointment (patient_id, doctor_id, timeslot_id, appointment_date, reason, current_status)
        VALUES (p_pid, p_doc_id, p_ts_id, p_date, p_reason, 'CREATED');
        SET p_aid = LAST_INSERT_ID();
        UPDATE Doctor_Availability SET is_available = FALSE WHERE doctor_id = p_doc_id AND timeslot_id = p_ts_id AND available_date = p_date;
        COMMIT;
        SET p_status = 201; SET p_msg = 'Booked';
    ELSE SET p_status = 409; SET p_msg = 'Conflict';
    END IF;
END$$

-- 9. Check-in (Confirm) Appointment
DROP PROCEDURE IF EXISTS sp_confirm_appointment$$
CREATE PROCEDURE sp_confirm_appointment(IN p_aid INT, IN p_uid INT, OUT p_stat INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    UPDATE Appointment SET current_status = 'CONFIRMED' WHERE appointment_id = p_aid;
    SET p_stat = 200; SET p_msg = 'Confirmed';
END$$

-- 10. Cancel Appointment
DROP PROCEDURE IF EXISTS sp_cancel_appointment$$
CREATE PROCEDURE sp_cancel_appointment(IN p_aid INT, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    UPDATE Appointment SET current_status = 'CANCELLED' WHERE appointment_id = p_aid;
    SET p_status = 200; SET p_msg = 'Cancelled';
END$$

-- =====================================================
-- SECTION 3: CLINICAL OPERATIONS
-- =====================================================

-- 11. Start Visit (Set to IN_PROGRESS)
DROP PROCEDURE IF EXISTS sp_start_visit$$
CREATE PROCEDURE sp_start_visit(IN p_aid INT, IN p_doc_id INT, IN p_uid INT, OUT p_vid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    START TRANSACTION;
    UPDATE Appointment SET current_status = 'IN_PROGRESS' WHERE appointment_id = p_aid;
    INSERT INTO Visit (appointment_id, patient_id, doctor_id, visit_start_time)
    SELECT p_aid, patient_id, doctor_id, NOW() FROM Appointment WHERE appointment_id = p_aid;
    SET p_vid = LAST_INSERT_ID();
    COMMIT;
    SET p_status = 201; SET p_msg = 'Visit started';
END$$

-- 12. Add Diagnosis
DROP PROCEDURE IF EXISTS sp_add_diagnosis$$
CREATE PROCEDURE sp_add_diagnosis(IN p_vid INT, IN p_diag_id INT, IN p_doc_id INT, IN p_note TEXT, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Visit_Diagnosis (visit_id, diagnosis_id, doctor_id, doctor_note) VALUES (p_vid, p_diag_id, p_doc_id, p_note);
    SET p_status = 201; SET p_msg = 'Added';
END$$

-- 13. Add Service
DROP PROCEDURE IF EXISTS sp_add_visit_service$$
CREATE PROCEDURE sp_add_visit_service(IN p_vid INT, IN p_service_id INT, IN p_qty INT, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Visit_Service (visit_id, service_id, quantity) VALUES (p_vid, p_service_id, p_qty);
    SET p_status = 201; SET p_msg = 'Service added';
END$$

-- 14. Add Attachment
DROP PROCEDURE IF EXISTS sp_add_visit_attachment$$
CREATE PROCEDURE sp_add_visit_attachment(IN p_vid INT, IN p_name VARCHAR(255), IN p_path VARCHAR(255), IN p_type VARCHAR(50), IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Attachment (visit_id, file_name, file_path, file_type) VALUES (p_vid, p_name, p_path, p_type);
    SET p_status = 201; SET p_msg = 'File attached';
END$$

-- 15. Create Prescription Header
DROP PROCEDURE IF EXISTS sp_create_prescription$$
CREATE PROCEDURE sp_create_prescription(IN p_vid INT, IN p_doc_id INT, IN p_note TEXT, IN p_uid INT, OUT p_prid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Prescription (visit_id, doctor_id, note) VALUES (p_vid, p_doc_id, p_note);
    SET p_prid = LAST_INSERT_ID(); SET p_status = 201; SET p_msg = 'Prescription header created';
END$$

-- 16. Add Prescription Item
DROP PROCEDURE IF EXISTS sp_add_prescription_item$$
CREATE PROCEDURE sp_add_prescription_item(IN p_prid INT, IN p_item_id INT, IN p_qty INT, IN p_dosage VARCHAR(100), IN p_inst TEXT, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Prescription_Item (prescription_id, item_id, quantity, dosage, usage_instruction)
    VALUES (p_prid, p_item_id, p_qty, p_dosage, p_inst);
    SET p_status = 201; SET p_msg = 'Medicine added';
END$$

-- 17. End Visit (Set to COMPLETED)
DROP PROCEDURE IF EXISTS sp_end_visit$$
CREATE PROCEDURE sp_end_visit(IN p_vid INT, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    DECLARE v_aid INT;
    SET @current_user_id = p_uid;
    SELECT appointment_id INTO v_aid FROM Visit WHERE visit_id = p_vid;
    START TRANSACTION;
    UPDATE Visit SET visit_end_time = NOW() WHERE visit_id = p_vid;
    UPDATE Appointment SET current_status = 'COMPLETED' WHERE appointment_id = v_aid;
    COMMIT;
    SET p_status = 200; SET p_msg = 'Visit finished';
END$$

-- =====================================================
-- SECTION 4: PHARMACY & INVENTORY
-- =====================================================

-- 18. Add Pharmacy Batch
DROP PROCEDURE IF EXISTS sp_add_pharmacy_batch$$
CREATE PROCEDURE sp_add_pharmacy_batch(IN p_item INT, IN p_sup INT, IN p_batch VARCHAR(100), IN p_exp DATE, IN p_sell DEC(10,2), IN p_buy DEC(10,2), IN p_qty INT, IN p_uid INT, OUT p_bid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO PharmacyBatch (item_id, supplier_id, batch_number, expiry_date, selling_unit_price, supply_unit_price, quantity)
    VALUES (p_item, p_sup, p_batch, p_exp, p_sell, p_buy, p_qty);
    SET p_bid = LAST_INSERT_ID(); SET p_status = 201; SET p_msg = 'Batch added';
END$$

-- 19. Create Supplier Invoice
DROP PROCEDURE IF EXISTS sp_create_supplier_invoice$$
CREATE PROCEDURE sp_create_supplier_invoice(IN p_sup_id INT, IN p_bid INT, IN p_date DATE, IN p_amt DEC(15,2), IN p_status ENUM('PAID','NOT PAID'), IN p_uid INT, OUT p_siid INT, OUT p_stat INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO SupplierInvoice (supplier_id, batch_id, invoice_date, total_amount, status)
    VALUES (p_sup_id, p_bid, p_date, p_amt, p_status);
    SET p_siid = LAST_INSERT_ID(); SET p_stat = 201; SET p_msg = 'Invoice created';
END$$

-- 20. Dispense Medication (FIFO)
DROP PROCEDURE IF EXISTS sp_dispense_medication$$
CREATE PROCEDURE sp_dispense_medication(IN p_prid INT, IN p_item_id INT, IN p_qty_needed INT, IN p_uid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    DECLARE v_batch_id INT;
    DECLARE v_batch_qty INT;
    DECLARE v_rem INT DEFAULT p_qty_needed;
    DECLARE done INT DEFAULT FALSE;
    DECLARE batch_cursor CURSOR FOR 
        SELECT batch_id, quantity FROM PharmacyBatch 
        WHERE item_id = p_item_id AND quantity > 0 AND expiry_date > CURDATE() 
        ORDER BY expiry_date ASC FOR UPDATE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET @current_user_id = p_uid;

    IF (SELECT SUM(quantity) FROM PharmacyBatch WHERE item_id = p_item_id AND expiry_date > CURDATE()) < p_qty_needed THEN
        SET p_status = 400; SET p_msg = 'Insufficient stock';
    ELSE
        START TRANSACTION;
        OPEN batch_cursor;
        read_loop: LOOP
            FETCH batch_cursor INTO v_batch_id, v_batch_qty;
            IF done OR v_rem <= 0 THEN LEAVE read_loop; END IF;
            INSERT INTO StockMovement (batch_id, movement_type, quantity, reference_type, reference_id)
            VALUES (v_batch_id, 'OUT', IF(v_batch_qty >= v_rem, v_rem, v_batch_qty), 'PRESCRIPTION', p_prid);
            SET v_rem = v_rem - IF(v_batch_qty >= v_rem, v_rem, v_batch_qty);
        END LOOP;
        CLOSE batch_cursor;
        COMMIT;
        SET p_status = 200; SET p_msg = 'Dispensed';
    END IF;
END$$

-- =====================================================
-- SECTION 5: FINANCE & SYSTEM
-- =====================================================

-- 21. Generate Patient Invoice (Auto-calculation)
DROP PROCEDURE IF EXISTS sp_generate_patient_invoice$$
CREATE PROCEDURE sp_generate_patient_invoice(IN p_visit_id INT, IN p_uid INT, OUT p_invoice_id INT, OUT p_status_code INT, OUT p_message VARCHAR(255))
BEGIN
    DECLARE v_total DECIMAL(15,2) DEFAULT 0;
    SET @current_user_id = p_uid;
    START TRANSACTION;
    -- Header
    INSERT INTO PatientInvoice (visit_id, invoice_date, total_amount, status) VALUES (p_visit_id, CURDATE(), 0, 'NOT PAID');
    SET p_invoice_id = LAST_INSERT_ID();
    -- Services
    INSERT INTO PatientInvoice_Item (patient_invoice_id, item_type, reference_id, quantity, unit_price, line_total)
    SELECT p_invoice_id, 'SERVICE', vs.service_id, vs.quantity, ms.service_fee, (vs.quantity * ms.service_fee)
    FROM Visit_Service vs JOIN MedicalService ms ON vs.service_id = ms.service_id WHERE vs.visit_id = p_visit_id;
    -- Medicines
    INSERT INTO PatientInvoice_Item (patient_invoice_id, item_type, reference_id, quantity, unit_price, line_total)
    SELECT p_invoice_id, 'MEDICINE', pb.item_id, sm.quantity, pb.selling_unit_price, (sm.quantity * pb.selling_unit_price)
    FROM Prescription pr JOIN StockMovement sm ON sm.reference_id = pr.prescription_id AND sm.reference_type = 'PRESCRIPTION'
    JOIN PharmacyBatch pb ON sm.batch_id = pb.batch_id WHERE pr.visit_id = p_visit_id;
    -- Update Total
    UPDATE PatientInvoice SET total_amount = (SELECT SUM(line_total) FROM PatientInvoice_Item WHERE patient_invoice_id = p_invoice_id) WHERE patient_invoice_id = p_invoice_id;
    COMMIT;
    SET p_status_code = 201; SET p_message = 'Invoice generated';
END$$

-- 22. Record Payment
DROP PROCEDURE IF EXISTS sp_record_payment$$
CREATE PROCEDURE sp_record_payment(IN p_inv_id INT, IN p_amt DEC(12,2), IN p_method VARCHAR(50), IN p_uid INT, OUT p_pay_id INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_uid;
    INSERT INTO Payment (invoice_id, amount, payment_method) VALUES (p_inv_id, p_amt, p_method);
    SET p_pay_id = LAST_INSERT_ID(); SET p_status = 201; SET p_msg = 'Paid';
END$$

-- 23. Create Department
DROP PROCEDURE IF EXISTS sp_create_department$$
CREATE PROCEDURE sp_create_department(IN p_name VARCHAR(100), IN p_desc TEXT, IN p_admin_id INT, OUT p_id INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_admin_id;
    INSERT INTO Department (department_name, description) VALUES (p_name, p_desc);
    SET p_id = LAST_INSERT_ID(); SET p_status = 201; SET p_msg = 'Created';
END$$

-- 24. Assign Dept Lead
DROP PROCEDURE IF EXISTS sp_assign_department_lead$$
CREATE PROCEDURE sp_assign_department_lead(IN p_dept_id INT, IN p_doc_id INT, IN p_start DATE, IN p_admin_id INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    SET @current_user_id = p_admin_id;
    UPDATE Department_Leadership SET end_date = CURDATE() WHERE department_id = p_dept_id AND end_date IS NULL;
    INSERT INTO Department_Leadership (department_id, doctor_id, start_date) VALUES (p_dept_id, p_doc_id, p_start);
    SET p_status = 200; SET p_msg = 'Lead assigned';
END$$

-- 25. Create Notification
DROP PROCEDURE IF EXISTS sp_create_notification$$
CREATE PROCEDURE sp_create_notification(IN p_uid INT, IN p_type INT, IN p_content TEXT, OUT p_nid INT, OUT p_status INT, OUT p_msg VARCHAR(255))
BEGIN
    INSERT INTO Notification (user_id, notification_type_id, content) VALUES (p_uid, p_type, p_content);
    SET p_nid = LAST_INSERT_ID(); SET p_status = 201; SET p_msg = 'Sent';
END$$

-- 26. Get EMR
DROP PROCEDURE IF EXISTS sp_get_patient_emr$$
CREATE PROCEDURE sp_get_patient_emr(IN p_pid INT, IN p_uid INT)
BEGIN
    SELECT * FROM v_patient_medical_history WHERE patient_id = p_pid;
END$$

-- 27. Internal Audit Helper
DROP PROCEDURE IF EXISTS sp_log_audit_event$$
CREATE PROCEDURE sp_log_audit_event(IN p_user_id INT, IN p_table VARCHAR(100), IN p_field VARCHAR(100), IN p_old TEXT, IN p_new TEXT, IN p_action ENUM('INSERT','UPDATE','DELETE'))
BEGIN
    INSERT INTO AuditLog (user_id, table_name, field_name, old_value, new_value, action_type)
    VALUES (p_user_id, p_table, p_field, p_old, p_new, p_action);
END$$

DELIMITER ;