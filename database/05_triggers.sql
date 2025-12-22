-- =====================================================
-- TRIGGERS
-- =====================================================
USE hospital_management_system;

DELIMITER $$

-- =============================================================================
-- 1. APPOINTMENT (AFTER UPDATE)
-- Purpose: Audit Status, Record History, and Restore Doctor Availability
-- =============================================================================
DROP TRIGGER IF EXISTS trg_appointment_after_update$$
CREATE TRIGGER trg_appointment_after_update
AFTER UPDATE ON Appointment FOR EACH ROW
BEGIN
    IF OLD.current_status <> NEW.current_status THEN
        -- Audit & History
        CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Appointment', 'current_status', OLD.current_status, NEW.current_status, 'UPDATE');
        INSERT INTO Appointment_Status_History (appointment_id, old_status, new_status, changed_by)
        VALUES (NEW.appointment_id, OLD.current_status, NEW.current_status, COALESCE(@current_user_id, 1));

        -- Restore slot ONLY if Cancelled
        IF NEW.current_status = 'CANCELLED' THEN
            UPDATE Doctor_Availability SET is_available = TRUE 
            WHERE doctor_id = NEW.doctor_id AND timeslot_id = NEW.timeslot_id AND available_date = NEW.appointment_date;
        END IF;
    END IF;
END$$

-- =============================================================================
-- 2. STOCKMOVEMENT (AFTER INSERT)
-- Purpose: Sync Physical Stock and Audit Entry
-- =============================================================================
DROP TRIGGER IF EXISTS trg_stock_movement_after_insert$$
CREATE TRIGGER trg_stock_movement_after_insert
AFTER INSERT ON StockMovement FOR EACH ROW
BEGIN
    -- Sync Physical Stock
    IF NEW.movement_type = 'IN' THEN
        UPDATE PharmacyBatch SET quantity = quantity + NEW.quantity WHERE batch_id = NEW.batch_id;
    ELSEIF NEW.movement_type = 'OUT' THEN
        UPDATE PharmacyBatch SET quantity = quantity - NEW.quantity WHERE batch_id = NEW.batch_id;
    END IF;
    -- Audit
    CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'StockMovement', 'quantity', NULL, CAST(NEW.quantity AS CHAR), 'INSERT');
END$$

-- =============================================================================
-- 3. PHARMACYBATCH (AFTER UPDATE)
-- Purpose: Audit changes and Generate Automated Alerts (Low Stock / Expiry)
-- =============================================================================
DROP TRIGGER IF EXISTS trg_pharmacy_batch_after_update$$
CREATE TRIGGER trg_pharmacy_batch_after_update
AFTER UPDATE ON PharmacyBatch
FOR EACH ROW
BEGIN
    DECLARE v_low_stock_type INT;
    DECLARE v_expiry_type INT;
    DECLARE v_total_item_stock INT;

    -- A. Audit Price or Quantity changes
    IF OLD.selling_unit_price <> NEW.selling_unit_price THEN
        CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'PharmacyBatch', 'selling_unit_price', CAST(OLD.selling_unit_price AS CHAR), CAST(NEW.selling_unit_price AS CHAR), 'UPDATE');
    END IF;

    -- B. Low Stock Check (Triggers if batch falls below threshold)
    IF NEW.quantity < 10 AND OLD.quantity >= 10 THEN
        SELECT notification_type_id INTO v_low_stock_type FROM Notification_Type WHERE type_name = 'LOW_STOCK_ALERT' LIMIT 1;
        -- Notify all Pharmacists (simulated by finding users with the role)
        INSERT INTO Notification (user_id, notification_type_id, content)
        SELECT ur.user_id, v_low_stock_type, CONCAT('Low stock warning for ', (SELECT item_name FROM PharmacyItem WHERE item_id = NEW.item_id), ' in Batch: ', NEW.batch_number)
        FROM UserRole ur WHERE ur.role_name = 'PHARMACIST';
    END IF;
END$$

-- =============================================================================
-- 4. PATIENTINVOICE (AFTER UPDATE)
-- Purpose: Audit Invoice and Log Automated INCOME Transaction
-- =============================================================================
DROP TRIGGER IF EXISTS trg_patient_invoice_after_update$$
CREATE TRIGGER trg_patient_invoice_after_update
AFTER UPDATE ON PatientInvoice
FOR EACH ROW
BEGIN
    -- A. Audit status change
    IF OLD.status <> NEW.status THEN
        CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'PatientInvoice', 'status', OLD.status, NEW.status, 'UPDATE');

        -- B. If status becomes PAID, record financial transaction
        IF NEW.status = 'PAID' THEN
            INSERT INTO FinancialTransaction (transaction_type, reference_type, reference_id, amount, description)
            VALUES ('INCOME', 'PATIENT_INVOICE', NEW.patient_invoice_id, NEW.total_amount, 'Payment received for patient visit');
        END IF;
    END IF;
END$$

-- =============================================================================
-- 5. SUPPLIERINVOICE (AFTER UPDATE)
-- Purpose: Audit and Log Automated EXPENSE Transaction
-- =============================================================================
DROP TRIGGER IF EXISTS trg_supplier_invoice_after_update$$
CREATE TRIGGER trg_supplier_invoice_after_update
AFTER UPDATE ON SupplierInvoice
FOR EACH ROW
BEGIN
    -- A. Audit status change
    IF OLD.status <> NEW.status THEN
        CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'SupplierInvoice', 'status', OLD.status, NEW.status, 'UPDATE');

        -- B. If status becomes PAID, record expense
        IF NEW.status = 'PAID' THEN
            INSERT INTO FinancialTransaction (transaction_type, reference_type, reference_id, amount, description)
            VALUES ('EXPENSE', 'SUPPLIER_INVOICE', NEW.supplier_invoice_id, NEW.total_amount, 'Payment settled for medical supplies');
        END IF;
    END IF;
END$$

-- =============================================================================
-- 6. PAYMENT (AFTER INSERT)
-- Purpose: Audit Payment and Auto-update Invoice Status to PAID
-- =============================================================================
DROP TRIGGER IF EXISTS trg_payment_after_insert$$
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON Payment FOR EACH ROW
BEGIN
    DECLARE v_paid DEC(15,2);
    DECLARE v_total DEC(15,2);

    SELECT COALESCE(SUM(amount), 0) INTO v_paid FROM Payment WHERE invoice_id = NEW.invoice_id;
    SELECT total_amount INTO v_total FROM PatientInvoice WHERE patient_invoice_id = NEW.invoice_id;

    IF v_paid >= v_total THEN
        UPDATE PatientInvoice SET status = 'PAID' WHERE patient_invoice_id = NEW.invoice_id;
    END IF;
    CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Payment', NULL, NULL, CAST(NEW.amount AS CHAR), 'INSERT');
END$$

-- =============================================================================
-- 7. PHARMACY BATCH (BEFORE INSERT)
-- Purpose: Check if expiry date before insert date
-- =============================================================================
DROP TRIGGER IF EXISTS check_expiry_before_insert$$
CREATE TRIGGER check_expiry_before_insert
BEFORE INSERT ON PharmacyBatch
FOR EACH ROW
BEGIN
    IF NEW.expiry_date <= CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Expiry date must be greater than today';
    END IF;
END$$

-- 8. One trigger per table to handle all tracked field changes.

DROP TRIGGER IF EXISTS trg_audit_user_update$$
CREATE TRIGGER trg_audit_user_update AFTER UPDATE ON `User` FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'User', 'status', OLD.status, NEW.status, 'UPDATE'); END IF;
    IF OLD.username <> NEW.username THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'User', 'username', OLD.username, NEW.username, 'UPDATE'); END IF;
END$$

DROP TRIGGER IF EXISTS trg_audit_patient_update$$
CREATE TRIGGER trg_audit_patient_update AFTER UPDATE ON Patient FOR EACH ROW
BEGIN
    IF OLD.phone <> NEW.phone THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Patient', 'phone', OLD.phone, NEW.phone, 'UPDATE'); END IF;
    IF OLD.address <> NEW.address THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Patient', 'address', OLD.address, NEW.address, 'UPDATE'); END IF;
END$$

DROP TRIGGER IF EXISTS trg_audit_doctor_update$$
CREATE TRIGGER trg_audit_doctor_update AFTER UPDATE ON Doctor FOR EACH ROW
BEGIN
    IF OLD.department_id <> NEW.department_id THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Doctor', 'dept_id', CAST(OLD.department_id AS CHAR), CAST(NEW.department_id AS CHAR), 'UPDATE'); END IF;
END$$

-- Simple INSERT audits for structural tables
DROP TRIGGER IF EXISTS trg_audit_userrole_insert$$
CREATE TRIGGER trg_audit_userrole_insert AFTER INSERT ON UserRole FOR EACH ROW
BEGIN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'UserRole', 'role_name', NULL, NEW.role_name, 'INSERT'); END$$

DROP TRIGGER IF EXISTS trg_audit_deptlead_insert$$
CREATE TRIGGER trg_audit_deptlead_insert AFTER INSERT ON Department_Leadership FOR EACH ROW
BEGIN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'DeptLeadership', NULL, NULL, CAST(NEW.doctor_id AS CHAR), 'INSERT'); END$$

DROP TRIGGER IF EXISTS trg_audit_medservice_update$$
CREATE TRIGGER trg_audit_medservice_update AFTER UPDATE ON MedicalService FOR EACH ROW
BEGIN IF OLD.service_fee <> NEW.service_fee THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'MedicalService', 'fee', CAST(OLD.service_fee AS CHAR), CAST(NEW.service_fee AS CHAR), 'UPDATE'); END IF; END$$

DROP TRIGGER IF EXISTS trg_audit_visit_insert$$
CREATE TRIGGER trg_audit_visit_insert AFTER INSERT ON Visit FOR EACH ROW
BEGIN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Visit', NULL, NULL, CAST(NEW.visit_id AS CHAR), 'INSERT'); END$$

DROP TRIGGER IF EXISTS trg_audit_prescription_insert$$
CREATE TRIGGER trg_audit_prescription_insert AFTER INSERT ON Prescription FOR EACH ROW
BEGIN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Prescription', NULL, NULL, CAST(NEW.prescription_id AS CHAR), 'INSERT'); END$$

DROP TRIGGER IF EXISTS trg_audit_dept_update$$
CREATE TRIGGER trg_audit_dept_update AFTER UPDATE ON Department FOR EACH ROW
BEGIN IF OLD.department_name <> NEW.department_name THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Department', 'name', OLD.department_name, NEW.department_name, 'UPDATE'); END IF; END$$

DROP TRIGGER IF EXISTS trg_audit_role_update$$
CREATE TRIGGER trg_audit_role_update AFTER UPDATE ON `Role` FOR EACH ROW
BEGIN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Role', 'permissions', NULL, 'Permissions Updated', 'UPDATE'); END$$

DROP TRIGGER IF EXISTS trg_audit_supplier_update$$
CREATE TRIGGER trg_audit_supplier_update AFTER UPDATE ON Supplier FOR EACH ROW
BEGIN IF OLD.supplier_name <> NEW.supplier_name THEN CALL sp_log_audit_event(COALESCE(@current_user_id, 1), 'Supplier', 'name', OLD.supplier_name, NEW.supplier_name, 'UPDATE'); END IF; END$$

DELIMITER ;
