-- Appointment details view
CREATE OR REPLACE VIEW v_appointment_details AS
SELECT
  a.appointment_id,
  a.appointment_date,
  ts.start_time,
  ts.end_time,
  a.current_status,
  a.reason,

  p.patient_id,
  p.full_name AS patient_name,
  p.phone AS patient_phone,

  d.doctor_id,
  d.full_name AS doctor_name,
  d.title AS doctor_title,

  dep.department_id,
  dep.department_name
FROM Appointment a
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id;

-- Visit clinical summary
CREATE OR REPLACE VIEW v_visit_clinical_summary AS
SELECT
  v.visit_id,
  v.appointment_id,
  v.visit_start_time,
  v.visit_end_time,

  p.patient_id,
  p.full_name AS patient_name,

  d.doctor_id,
  d.full_name AS doctor_name,
  dep.department_name,

  COUNT(DISTINCT vd.visit_diagnosis_id) AS diagnosis_count,
  COUNT(DISTINCT vs.visit_service_id) AS service_count
FROM Visit v
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor d ON v.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
LEFT JOIN Visit_Diagnosis vd ON v.visit_id = vd.visit_id
LEFT JOIN Visit_Service vs ON v.visit_id = vs.visit_id
GROUP BY
  v.visit_id, v.appointment_id, v.visit_start_time, v.visit_end_time,
  p.patient_id, p.full_name,
  d.doctor_id, d.full_name, dep.department_name;

-- Visit diagnoses detail 
CREATE OR REPLACE VIEW v_visit_diagnoses AS
SELECT
  v.visit_id,
  v.visit_start_time,

  p.patient_id,
  p.full_name AS patient_name,

  doc.doctor_id,
  doc.full_name AS diagnosed_by,

  dg.diagnosis_id,
  dg.diagnosis_code,
  dg.diagnosis_name,

  vd.doctor_note,
  vd.created_at AS diagnosed_at
FROM Visit_Diagnosis vd
JOIN Visit v ON vd.visit_id = v.visit_id
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor doc ON vd.doctor_id = doc.doctor_id
JOIN Diagnosis dg ON vd.diagnosis_id = dg.diagnosis_id;

-- Doctor schedule
CREATE OR REPLACE VIEW v_doctor_schedule_detail AS
SELECT
  d.doctor_id,
  d.full_name AS doctor_name,
  dep.department_id,
  dep.department_name,

  a.appointment_date,
  ts.start_time,
  ts.end_time,

  a.appointment_id,
  a.current_status,
  p.patient_id,
  p.full_name AS patient_name,
  p.phone AS patient_phone,
  a.reason,
  a.created_at AS appointment_created_at
FROM Appointment a
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
JOIN Patient p ON a.patient_id = p.patient_id
JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id;

CREATE OR REPLACE VIEW v_doctor_daily_schedule_summary AS
SELECT
  d.doctor_id,
  d.full_name AS doctor_name,
  dep.department_name,
  a.appointment_date,

  SUM(a.current_status = 'CREATED')   AS created_count,
  SUM(a.current_status = 'CONFIRMED') AS confirmed_count,
  SUM(a.current_status = 'CANCELLED') AS cancelled_count,
  SUM(a.current_status = 'COMPLETED') AS completed_count,
  COUNT(*) AS total_appointments
FROM Appointment a
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
GROUP BY
  d.doctor_id, d.full_name, dep.department_name, a.appointment_date;

-- Pharmacy-focused prescription detail
CREATE OR REPLACE VIEW v_patient_prescription_for_pharmacy AS
SELECT
  pr.prescription_id,
  pr.prescribed_at,

  p.patient_id,
  p.full_name AS patient_name,
  p.date_of_birth,
  p.gender,
  p.phone,

  d.doctor_id,
  d.full_name AS doctor_name,
  dep.department_name,

  pri.prescription_item_id,
  pi.item_id,
  pi.item_name,
  pri.quantity,
  pri.dosage,
  pri.usage_instruction,
  pr.note AS prescription_note

FROM Prescription pr
JOIN Visit v ON pr.visit_id = v.visit_id
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor d ON pr.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
JOIN Prescription_Item pri ON pr.prescription_id = pri.prescription_id
JOIN PharmacyItem pi ON pri.item_id = pi.item_id;

-- Invoice + payments summary
CREATE OR REPLACE VIEW v_invoice_payment_summary AS
SELECT
  pi.patient_invoice_id,
  pi.invoice_date,
  pi.status,
  pi.total_amount,

  v.visit_id,
  p.patient_id,
  p.full_name AS patient_name,

  d.doctor_id,
  d.full_name AS doctor_name,

  COALESCE(SUM(pay.amount), 0) AS total_paid,
  (COALESCE(pi.total_amount, 0) - COALESCE(SUM(pay.amount), 0)) AS remaining_amount,
  MAX(pay.created_at) AS last_payment_time
FROM PatientInvoice pi
JOIN Visit v ON pi.visit_id = v.visit_id
JOIN Patient p ON v.patient_id = p.patient_id
JOIN Doctor d ON v.doctor_id = d.doctor_id
LEFT JOIN Payment pay ON pay.invoice_id = pi.patient_invoice_id
GROUP BY
  pi.patient_invoice_id, pi.invoice_date, pi.status, pi.total_amount,
  v.visit_id, p.patient_id, p.full_name,
  d.doctor_id, d.full_name;

-- Inventory status view
CREATE OR REPLACE VIEW v_inventory_batch_status AS
SELECT
  b.batch_id,
  i.item_id,
  i.item_name,
  b.batch_number,
  b.expiry_date,
  b.selling_unit_price,
  b.supply_unit_price,

  s.supplier_id,
  s.supplier_name,

  b.quantity AS current_quantity,
  (b.expiry_date < CURDATE()) AS is_expired
FROM PharmacyBatch b
JOIN PharmacyItem i ON b.item_id = i.item_id
JOIN Supplier s ON b.supplier_id = s.supplier_id;

-- Supplier procurement summary
CREATE OR REPLACE VIEW v_supplier_procurement_summary AS
SELECT
  si.supplier_invoice_id,
  si.invoice_date,
  si.status AS invoice_status,
  si.total_amount AS invoice_total_amount,

  s.supplier_id,
  s.supplier_name,
  s.phone AS supplier_phone,
  s.email AS supplier_email,

  b.batch_id,
  b.batch_number,
  b.expiry_date,
  b.quantity AS batch_quantity,
  b.supply_unit_price,
  b.selling_unit_price,
  (b.selling_unit_price - b.supply_unit_price) AS unit_margin,

  i.item_id,
  i.item_name,
  i.unit AS item_unit

FROM SupplierInvoice si
JOIN Supplier s ON si.supplier_id = s.supplier_id
JOIN PharmacyBatch b ON si.batch_id = b.batch_id
JOIN PharmacyItem i ON b.item_id = i.item_id;

-- Appointment status history audit view
CREATE OR REPLACE VIEW v_appointment_status_audit AS
SELECT
  ash.status_history_id,
  ash.appointment_id,

  a.appointment_date,
  ts.start_time,
  ts.end_time,

  p.patient_id,
  p.full_name AS patient_name,

  d.doctor_id,
  d.full_name AS doctor_name,
  dep.department_name,

  ash.old_status,
  ash.new_status,
  ash.changed_at,

  u.user_id AS changed_by_user_id,
  u.username AS changed_by_username
FROM Appointment_Status_History ash
JOIN Appointment a ON ash.appointment_id = a.appointment_id
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Doctor d ON a.doctor_id = d.doctor_id
JOIN Department dep ON d.department_id = dep.department_id
JOIN TimeSlot ts ON a.timeslot_id = ts.timeslot_id
JOIN User u ON ash.changed_by = u.user_id;

-- User activity/security view
CREATE OR REPLACE VIEW v_user_security_activity AS
SELECT
  u.user_id,
  u.username,
  u.status,
  u.created_at AS user_created_at,

  GROUP_CONCAT(DISTINCT ur.role_name ORDER BY ur.role_name SEPARATOR ', ') AS roles,

  MAX(lh.login_time) AS last_login_time,
  SUBSTRING_INDEX(
    GROUP_CONCAT(lh.ip_address ORDER BY lh.login_time DESC SEPARATOR ','),
    ',', 1
  ) AS last_login_ip,

  SUM(lh.login_status = 'FAILED') AS failed_login_count,
  SUM(lh.login_status = 'SUCCESS') AS success_login_count
FROM User u
LEFT JOIN UserRole ur ON u.user_id = ur.user_id
LEFT JOIN Login_History lh ON u.user_id = lh.user_id
GROUP BY
  u.user_id, u.username, u.status, u.created_at;
  
  SHOW FULL TABLES
WHERE Table_type = 'VIEW';