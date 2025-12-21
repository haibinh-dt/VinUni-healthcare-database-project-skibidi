-- =====================================================
-- VIEWS DEFINITION
-- =====================================================

USE hospital_management_system;

-- =========================
-- SECTION 1: SCHEDULING & RECEPTION
-- =========================

-- 1. Today's Patient Queue
-- Roles: RECEPTIONIST, DOCTOR
-- UI: Dashboard arrivals list with status colors
CREATE OR REPLACE VIEW v_reception_daily_queue AS
SELECT 
    a.appointment_id, a.appointment_date, ts.start_time, ts.end_time,
    p.patient_id, p.full_name AS patient_name, p.phone AS patient_phone,
    d.full_name AS doctor_name, dept.department_name,
    a.current_status,
    CASE 
        WHEN a.current_status = 'CREATED' THEN 'warning'
        WHEN a.current_status = 'CONFIRMED' THEN 'success'
        WHEN a.current_status = 'CANCELLED' THEN 'danger'
        ELSE 'secondary'
    END AS status_color
FROM Appointment a
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Department dept ON d.department_id = dept.department_id
JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id
WHERE a.appointment_date = CURDATE();

-- 2. Real-time Doctor Availability Browser
-- Roles: RECEPTIONIST
-- UI: Searchable grid for booking new appointments
CREATE OR REPLACE VIEW v_doc_availability_browser AS
SELECT 
    da.availability_id, da.available_date, ts.start_time, ts.end_time,
    d.doctor_id, d.full_name AS doctor_name, dept.department_name,
    CASE 
        WHEN da.available_date = CURDATE() THEN 'Today'
        WHEN da.available_date = DATE_ADD(CURDATE(), INTERVAL 1 DAY) THEN 'Tomorrow'
        ELSE DATE_FORMAT(da.available_date, '%W')
    END AS date_label
FROM Doctor_Availability da
JOIN Doctor d ON da.doctor_id = d.doctor_id
JOIN Department dept ON d.department_id = dept.department_id
JOIN TimeSlot ts ON da.timeslot_id = ts.timeslot_id
WHERE da.is_available = TRUE AND da.available_date >= CURDATE();

-- 3. Appointment Detailed Record
-- Roles: RECEPTIONIST, ADMIN
-- UI: Appointment detail/edit page
CREATE OR REPLACE VIEW v_appointment_details AS
SELECT 
    a.appointment_id, a.appointment_date, ts.start_time, ts.end_time,
    a.current_status, a.reason, p.patient_id, p.full_name AS patient_name,
    p.phone AS patient_phone, d.doctor_id, d.full_name AS doctor_name,
    dep.department_name
FROM Appointment a
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id;

-- 4. Doctor Daily Agenda
-- Roles: DOCTOR
-- UI: Doctor's personal daily schedule
CREATE OR REPLACE VIEW v_doctor_schedule_detail AS
SELECT 
    d.doctor_id, a.appointment_date, ts.start_time, ts.end_time,
    a.appointment_id, a.current_status, p.full_name AS patient_name,
    a.reason, a.created_at AS booked_at
FROM Appointment a
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Patient p ON a.patient_id = p.patient_id
JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id;

-- 5. Doctor Workload Summary
-- Roles: ADMIN, RECEPTIONIST
-- UI: Statistics widgets showing status counts per doctor
CREATE OR REPLACE VIEW v_doctor_schedule_summary AS
SELECT 
    d.doctor_id, d.full_name AS doctor_name, a.appointment_date,
    COUNT(CASE WHEN a.current_status = 'CONFIRMED' THEN 1 END) AS confirmed_count,
    COUNT(CASE WHEN a.current_status = 'COMPLETED' THEN 1 END) AS completed_count,
    COUNT(CASE WHEN a.current_status = 'CANCELLED' THEN 1 END) AS cancelled_count,
    COUNT(*) AS total_appointments
FROM Appointment a
JOIN Doctor d ON a.doctor_id = d.doctor_id
GROUP BY d.doctor_id, d.full_name, a.appointment_date;

-- =========================
-- SECTION 2: CLINICAL RECORDS
-- =========================

-- 6. Patient Master Record (The "Patient Book")
-- Roles: ALL ROLES
-- UI: Main searchable patient directory
CREATE OR REPLACE VIEW v_patient_master_record AS
SELECT 
    p.patient_id, p.full_name, p.phone, p.gender,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    (SELECT MAX(visit_start_time) FROM Visit WHERE patient_id = p.patient_id) AS last_visit
FROM Patient p;

-- 7. Visit Clinical Statistics
-- Roles: DOCTOR, ADMIN
-- UI: Overview of services and diagnoses count per visit
CREATE OR REPLACE VIEW v_visit_clinical_summary AS
SELECT 
    v.visit_id, v.visit_start_time, p.full_name AS patient_name,
    d.full_name AS doctor_name,
    (SELECT COUNT(*) FROM Visit_Diagnosis WHERE visit_id = v.visit_id) AS diagnosis_count,
    (SELECT COUNT(*) FROM Visit_Service WHERE visit_id = v.visit_id) AS service_count
FROM Visit v
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor d ON v.doctor_id = d.doctor_id;

-- 8. Visit Diagnosis Deep-Dive
-- Roles: DOCTOR
-- UI: Clinical detail page for a specific visit
CREATE OR REPLACE VIEW v_visit_diagnoses_detail AS
SELECT 
    vd.visit_id, dg.diagnosis_code, dg.diagnosis_name, 
    vd.doctor_note, d.full_name AS diagnosed_by
FROM Visit_Diagnosis vd
JOIN Diagnosis dg ON vd.diagnosis_id = dg.diagnosis_id
JOIN Doctor d ON vd.doctor_id = d.doctor_id;

-- 9. Patient Master EMR (Timeline)
-- Roles: DOCTOR
-- UI: Holistic view of patient's history across all visits
CREATE OR REPLACE VIEW v_patient_medical_history AS
SELECT 
    p.patient_id, p.full_name, v.visit_id, v.visit_start_time,
    d.full_name AS consulting_doctor, dept.department_name,
    v.clinical_note,
    (SELECT GROUP_CONCAT(diag.diagnosis_name SEPARATOR '; ') 
     FROM Visit_Diagnosis vd JOIN Diagnosis diag ON vd.diagnosis_id = diag.diagnosis_id 
     WHERE vd.visit_id = v.visit_id) AS all_diagnoses
FROM Patient p
JOIN Visit v ON p.patient_id = v.patient_id
JOIN Doctor d ON v.doctor_id = d.doctor_id
JOIN Department dept ON d.department_id = dept.department_id;

-- =========================
-- SECTION 3: PHARMACY
-- =========================

-- 10. Prescription Dispensing View
-- Roles: PHARMACIST, DOCTOR
-- UI: Dispensing interface for medication fulfillment
CREATE OR REPLACE VIEW v_prescription_for_pharmacy AS
SELECT
    pr.prescription_id, pr.prescribed_at, p.full_name AS patient_name,
    d.full_name AS doctor_name, pi.item_id, pi.item_name,
    pri.quantity, pri.dosage, pri.usage_instruction, pr.note AS doctor_note
FROM Prescription pr
JOIN Visit v ON pr.visit_id = v.visit_id
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor d ON pr.doctor_id = d.doctor_id
JOIN Prescription_Item pri ON pr.prescription_id = pri.prescription_id
JOIN PharmacyItem pi ON pri.item_id = pi.item_id;

-- 11. Inventory Batch Status
-- Roles: PHARMACIST
-- UI: Batch-level stock monitoring and expiry flagging
CREATE OR REPLACE VIEW v_inventory_batch_status AS
SELECT 
    pb.batch_id, pi.item_name, pb.batch_number, pb.expiry_date,
    pb.quantity AS current_stock, s.supplier_name,
    (pb.expiry_date <= CURDATE()) AS is_expired
FROM PharmacyBatch pb
JOIN PharmacyItem pi ON pb.item_id = pi.item_id
JOIN Supplier s ON pb.supplier_id = s.supplier_id;

-- 12. Stock Health Dashboard (Alerts)
-- Roles: PHARMACIST, ADMIN
-- UI: Widgets showing critical stock levels
CREATE OR REPLACE VIEW v_pharmacy_stock_alerts AS
SELECT 
    pi.item_id, pi.item_name, SUM(pb.quantity) AS total_stock,
    MIN(pb.expiry_date) AS nearest_expiry,
    CASE 
        WHEN SUM(pb.quantity) < 20 THEN 'CRITICAL'
        WHEN SUM(pb.quantity) < 50 THEN 'LOW'
        ELSE 'HEALTHY'
    END AS stock_status
FROM PharmacyItem pi
LEFT JOIN PharmacyBatch pb ON pi.item_id = pb.item_id 
GROUP BY pi.item_id, pi.item_name;

-- =========================
-- SECTION 4: FINANCE
-- =========================

-- 13. Patient Invoice Balance Tracker
-- Roles: FINANCE, RECEPTIONIST
-- UI: Real-time unpaid balance lookup
CREATE OR REPLACE VIEW v_invoice_payment_tracker AS
SELECT
    pi.patient_invoice_id, p.full_name AS patient_name, pi.total_amount,
    COALESCE((SELECT SUM(amount) FROM Payment WHERE invoice_id = pi.patient_invoice_id), 0) AS total_paid,
    (COALESCE(pi.total_amount, 0) - COALESCE((SELECT SUM(amount) FROM Payment WHERE invoice_id = pi.patient_invoice_id), 0)) AS balance_due,
    pi.status AS payment_status
FROM PatientInvoice pi
JOIN Visit v ON pi.visit_id = v.visit_id
JOIN Patient p ON v.patient_id = p.patient_id;

-- 14. Financial Invoice Summary
-- Roles: FINANCE
-- UI: Master billing overview for accounting
CREATE OR REPLACE VIEW v_invoice_payment_summary AS
SELECT 
    pi.patient_invoice_id, pi.invoice_date, pi.status, pi.total_amount,
    p.full_name AS patient_name, d.full_name AS doctor_name,
    COALESCE(SUM(pay.amount), 0) AS amount_paid
FROM PatientInvoice pi
JOIN Visit v ON pi.visit_id = v.visit_id
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor d ON v.doctor_id = d.doctor_id
LEFT JOIN Payment pay ON pi.patient_invoice_id = pay.invoice_id
GROUP BY pi.patient_invoice_id, pi.invoice_date, pi.status, pi.total_amount, p.full_name, d.full_name;

-- 15. Product Margin Analysis
-- Roles: FINANCE, PHARMACIST
-- UI: Profitability reporting (Cost vs Sell)
CREATE OR REPLACE VIEW v_supplier_procurement AS
SELECT 
    pi.item_name, pb.batch_number, pb.supply_unit_price, pb.selling_unit_price,
    (pb.selling_unit_price - pb.supply_unit_price) AS unit_margin,
    s.supplier_name
FROM PharmacyBatch pb
JOIN PharmacyItem pi ON pb.item_id = pi.item_id
JOIN Supplier s ON pb.supplier_id = s.supplier_id;

-- 16. Supplier Invoice Deep-Dive
-- Roles: FINANCE
-- UI: Procurement history for accounting
CREATE OR REPLACE VIEW v_supplier_invoice_details AS
SELECT 
    si.supplier_invoice_id, si.invoice_date, s.supplier_name,
    pb.batch_number, pi.item_name, si.total_amount, si.status
FROM SupplierInvoice si
JOIN Supplier s ON si.supplier_id = s.supplier_id
JOIN PharmacyBatch pb ON si.batch_id = pb.batch_id
JOIN PharmacyItem pi ON pb.item_id = pi.item_id;

-- 17. Master Financial Ledger (Cash Flow)
-- Roles: FINANCE, ADMIN
-- UI: Daily income vs. expense report
CREATE OR REPLACE VIEW v_financial_cash_flow AS
SELECT 
    transaction_at AS date, transaction_type, reference_type, 
    amount, description
FROM FinancialTransaction;

-- =========================
-- SECTION 5: ADMIN & SECURITY
-- =========================

-- 18. Human-Readable Audit Trail
-- Roles: ADMIN
-- UI: Security monitoring logs
CREATE OR REPLACE VIEW v_audit_readable_log AS
SELECT 
    al.audit_id, al.changed_at, u.username AS performer,
    al.action_type, al.table_name, al.field_name,
    al.old_value, al.new_value
FROM AuditLog al
JOIN User u ON al.user_id = u.user_id;

-- 19. Appointment Status History Audit
-- Roles: ADMIN
-- UI: Tracking who changed appointment statuses
CREATE OR REPLACE VIEW v_appointment_status_audit AS
SELECT 
    ash.changed_at, p.full_name AS patient_name, d.full_name AS doctor_name,
    ash.old_status, ash.new_status, u.username AS updated_by
FROM Appointment_Status_History ash
JOIN Appointment a ON ash.appointment_id = a.appointment_id
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN User u ON ash.changed_by = u.user_id;

-- 20. Security Watchdog (Logins & Attempts)
-- Roles: ADMIN
-- UI: Security dashboard showing failed logins and active IPs
CREATE OR REPLACE VIEW v_user_security_activity AS
SELECT 
    u.user_id, u.username, u.status,
    (SELECT GROUP_CONCAT(role_name) FROM UserRole WHERE user_id = u.user_id) AS assigned_roles,
    COUNT(CASE WHEN lh.login_status = 'FAILED' THEN 1 END) AS failed_attempts,
    MAX(lh.login_time) AS last_login_time
FROM User u
LEFT JOIN Login_History lh ON u.user_id = lh.user_id
GROUP BY u.user_id, u.username, u.status;

-- 21. User Role Matrix
-- Roles: ADMIN
-- UI: User management and role assignment table
CREATE OR REPLACE VIEW v_user_role_directory AS
SELECT 
    u.user_id, u.username, u.status AS account_status,
    ur.role_name, r.permission_scope
FROM User u
JOIN UserRole ur ON u.user_id = ur.user_id
JOIN Role r ON ur.role_name = r.role_name;