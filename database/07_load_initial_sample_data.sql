-- =====================================================
-- SAMPLE DATA LOADING SCRIPT
-- =====================================================

USE hospital_management_system;

-- Disable foreign key checks for initial load
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- FIXED VALUES
-- =====================================================
INSERT INTO Department (department_name, `description`) VALUES
('Internal Medicine', 'General medical care for adults, treating chronic diseases and complex diagnostic problems'),
('Surgery', 'Surgical procedures including general, trauma, and emergency surgeries'),
('Pediatrics', 'Medical care for infants, children, and adolescents'),
('Neurology', 'Diagnosis and treatment of disorders of the nervous system'),
('Orthopedics', 'Treatment of musculoskeletal system disorders including bones, joints, and muscles'),
('Cardiology', 'Diagnosis and treatment of heart and cardiovascular system disorders'),
('Obstetrics & Gynecology', 'Women\'s health, pregnancy care, and reproductive system treatment'),
('Emergency', 'Immediate treatment for urgent and critical medical conditions');

-- =====================================================
-- TABLE 2: ROLE (5 roles)
-- =====================================================
INSERT INTO Role (role_name, permission_scope)
VALUES
(
  'ADMIN',
  JSON_OBJECT(
    'access', JSON_ARRAY('all'),
    'can_view', JSON_ARRAY('all'),
    'can_modify', JSON_ARRAY('all')
  )
),
(
  'DOCTOR',
  JSON_OBJECT(
    'access', JSON_ARRAY('medical', 'appointments'),
    'can_view', JSON_ARRAY(
      'patient_profile',
      'medical_record',
      'diagnosis',
      'test_result',
      'prescription',
      'schedule'
    ),
    'can_modify', JSON_ARRAY(
      'diagnosis',
      'medical_record',
      'prescription',
      'doctor_availability'
    )
  )
),
(
  'PHARMACIST',
  JSON_OBJECT(
    'access', JSON_ARRAY('pharmacy'),
    'can_view', JSON_ARRAY(
      'prescription',
      'pharmacy_item',
      'inventory'
    ),
    'can_modify', JSON_ARRAY(
      'dispense_status',
      'inventory'
    )
  )
),
(
  'RECEPTIONIST',
  JSON_OBJECT(
    'access', JSON_ARRAY('front_desk'),
    'can_view', JSON_ARRAY(
      'patient_profile',
      'doctor_schedule',
      'appointment'
    ),
    'can_modify', JSON_ARRAY(
      'appointment',
      'patient_profile'
    )
  )
),
(
  'FINANCE',
  JSON_OBJECT(
    'access', JSON_ARRAY('billing'),
    'can_view', JSON_ARRAY(
      'invoice',
      'payment',
      'service_charge'
    ),
    'can_modify', JSON_ARRAY(
      'invoice',
      'payment'
    )
  )
);


INSERT INTO MedicalService (service_name, service_fee, `description`) VALUES
('General Consultation', 150000.00, 'Standard medical consultation with physician'),
('Specialist Consultation', 300000.00, 'Consultation with specialist doctor'),
('Blood Test - Complete Blood Count', 200000.00, 'Comprehensive blood analysis'),
('Blood Test - Lipid Panel', 250000.00, 'Cholesterol and triglyceride levels'),
('Blood Test - Blood Glucose', 100000.00, 'Blood sugar level measurement'),
('X-Ray - Single View', 300000.00, 'Single radiographic image'),
('X-Ray - Multiple Views', 500000.00, 'Multiple angle radiographic images'),
('Ultrasound - Abdomen', 400000.00, 'Abdominal ultrasound examination'),
('Ultrasound - Obstetric', 350000.00, 'Pregnancy ultrasound'),
('ECG (Electrocardiogram)', 150000.00, 'Heart electrical activity recording'),
('CT Scan', 2000000.00, 'Computed tomography imaging'),
('MRI Scan', 3500000.00, 'Magnetic resonance imaging'),
('Minor Surgery', 1500000.00, 'Small surgical procedure'),
('Major Surgery', 15000000.00, 'Complex surgical procedure'),
('Hospital Stay - Per Day', 800000.00, 'Daily hospitalization charge including bed and basic care');

INSERT INTO TimeSlot (start_time, end_time) VALUES
('08:00:00', '09:00:00'),
('09:00:00', '10:00:00'),
('10:00:00', '11:00:00'),
('11:00:00', '12:00:00'),
('13:00:00', '14:00:00'),
('14:00:00', '15:00:00'),
('15:00:00', '16:00:00'),
('16:00:00', '17:00:00');

INSERT INTO Supplier (supplier_name, phone, email, address) VALUES
('PharmaCorp Vietnam', '024-3974-1234', 'sales@pharmacorp.vn', '123 Nguyen Trai, Thanh Xuan, Hanoi'),
('MediSupply International', '024-3821-5678', 'contact@medisupply.com.vn', '456 Giang Vo, Ba Dinh, Hanoi'),
('HealthPlus Distributors', '028-3925-9012', 'info@healthplus.vn', '789 Le Loi, District 1, Ho Chi Minh City'),
('Global Pharma Solutions', '024-3716-3456', 'orders@globalpharma.vn', '321 Tran Duy Hung, Cau Giay, Hanoi'),
('VietMed Supplies', '024-3573-7890', 'support@vietmed.com.vn', '654 Hoang Quoc Viet, Cau Giay, Hanoi'),
('Asia Pacific Pharmaceuticals', '028-3910-2345', 'sales@asiapacificpharma.vn', '987 Vo Van Tan, District 3, Ho Chi Minh City');

INSERT INTO Notification_Type (type_name, `description`) VALUES
('APPOINTMENT_CREATED', 'Notification when a new appointment is created'),
('APPOINTMENT_UPDATED', 'Notification when appointment details are modified'),
('APPOINTMENT_CANCELLED', 'Notification when an appointment is cancelled'),
('DOCTOR_SCHEDULE_CHANGED', 'Notification when doctor availability changes'),
('NEW_VISIT_ASSIGNED', 'Notification when a new visit is assigned to a doctor'),
('TEST_RESULTS_UPLOADED', 'Notification when test/lab results are uploaded'),
('PRESCRIPTION_CREATED', 'Notification when a new prescription is created'),
('PRESCRIPTION_READY', 'Notification when prescription is ready for dispensing'),
('LOW_STOCK_ALERT', 'Alert when pharmacy inventory falls below threshold'),
('STOCK_EXPIRY_WARNING', 'Warning for medications approaching expiry date'),
('INVOICE_CREATED', 'Notification when a patient invoice is generated'),
('PAYMENT_RECEIVED', 'Notification when payment is received'),
('USER_ROLE_CHANGED', 'Notification when user role or permissions are modified'),
('SYSTEM_CONFIG_CHANGED', 'Notification when system configuration is updated'),
('DATA_INTEGRITY_WARNING', 'Warning for potential data integrity issues');

INSERT INTO PharmacyItem (item_name, unit, `description`) VALUES
('Paracetamol 500mg', 'Tablet', 'Analgesic and antipyretic medication'),
('Amoxicillin 500mg', 'Capsule', 'Broad-spectrum antibiotic'),
('Ibuprofen 400mg', 'Tablet', 'Anti-inflammatory and pain relief'),
('Omeprazole 20mg', 'Capsule', 'Proton pump inhibitor for acid reflux'),
('Metformin 500mg', 'Tablet', 'Oral diabetes medication'),
('Amlodipine 5mg', 'Tablet', 'Calcium channel blocker for hypertension'),
('Atorvastatin 10mg', 'Tablet', 'Cholesterol-lowering medication'),
('Cetirizine 10mg', 'Tablet', 'Antihistamine for allergies'),
('Salbutamol Inhaler', 'Inhaler', 'Bronchodilator for asthma'),
('Azithromycin 500mg', 'Tablet', 'Macrolide antibiotic'),
('Losartan 50mg', 'Tablet', 'Angiotensin receptor blocker for hypertension'),
('Clopidogrel 75mg', 'Tablet', 'Antiplatelet medication'),
('Diazepam 5mg', 'Tablet', 'Benzodiazepine for anxiety'),
('Multivitamin', 'Tablet', 'Daily vitamin supplement'),
('Vitamin D3 1000IU', 'Capsule', 'Vitamin D supplement'),
('Calcium Carbonate 500mg', 'Tablet', 'Calcium supplement'),
('Ciprofloxacin 500mg', 'Tablet', 'Fluoroquinolone antibiotic'),
('Dexamethasone 0.5mg', 'Tablet', 'Corticosteroid anti-inflammatory'),
('Ranitidine 150mg', 'Tablet', 'H2 blocker for acid reduction'),
('Loratadine 10mg', 'Tablet', 'Non-sedating antihistamine'),
('Tramadol 50mg', 'Tablet', 'Opioid pain medication'),
('Insulin Glargine', 'Injection', 'Long-acting insulin'),
('Normal Saline 0.9%', '500ml Bag', 'Intravenous fluid'),
('Glucose 5%', '500ml Bag', 'Intravenous dextrose solution'),
('Aspirin 100mg', 'Tablet', 'Antiplatelet and pain relief');

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

INSERT INTO Department_Leadership (department_id, doctor_id, start_date, end_date) VALUES
(1, 1, '2025-12-01', NULL),                    -- Dr. Nguyen Van Minh - Current Head of Internal Medicine
(2, 2, '2025-12-07', NULL),                    -- Dr. Tran Thi Lan - Current Head of Surgery
(4, 4, '2021-01-01', NULL),                    -- Dr. Pham Minh Duc - Current Head of Neurology
(5, 5, '2023-03-01', NULL),                    -- Dr. Hoang Thi Mai - Current Head of Orthopedics
(6, 6, '2020-01-01', '2021-12-31');            -- Dr. Vu Quang Hieu - Former Head of Cardiology (historical record)

INSERT INTO Doctor_Availability
(doctor_id, timeslot_id, available_date, is_available)
VALUES
(1, 1, '2025-12-22', TRUE),
(1, 2, '2025-12-22', TRUE),
(2, 3, '2025-12-22', TRUE),
(3, 4, '2025-12-22', TRUE),
(6, 5, '2025-12-24', TRUE),
(7, 6, '2025-12-23', TRUE);

INSERT INTO Appointment
(patient_id, doctor_id, timeslot_id, appointment_date, reason, current_status)
VALUES
(1, 1, 1, '2025-12-12', 'Routine check-up', 'COMPLETED'),
(2, 2, 3, '2025-12-01', 'Surgery consultation', 'COMPLETED'),
(3, 3, 4, '2025-12-22', 'Child fever', 'COMPLETED'),
(4, 6, 5, '2025-12-22', 'Chest pain', 'CANCELLED'),
(5, 7, 6, '2025-12-22', 'Pregnancy follow-up', 'CONFIRMED');

INSERT INTO Visit
(appointment_id, patient_id, doctor_id, visit_start_time, visit_end_time, clinical_note)
VALUES
(1, 1, 1, '2025-12-19 08:00:00', '2025-12-19 08:30:00', 'Patient stable'),
(2, 2, 2, '2025-12-18 10:00:00', '2025-12-18 11:00:00', 'Surgery planned'),
(3, 3, 3, '2025-12-17 11:00:00', '2025-12-17 11:20:00', 'Prescribed medication');

INSERT INTO Diagnosis (diagnosis_code, diagnosis_name, description)
VALUES
('I10', 'Hypertension', 'High blood pressure'),
('J06', 'Acute Upper Respiratory Infection', 'Common viral infection'),
('R50', 'Fever', 'Elevated body temperature');

INSERT INTO Visit_Diagnosis
(visit_id, diagnosis_id, doctor_id, doctor_note)
VALUES
(1, 1, 1, 'Monitor blood pressure'),
(2, 1, 2, 'Pre-surgery risk'),
(3, 3, 3, 'Likely viral');

INSERT INTO Visit_Service
(visit_id, service_id, quantity)
VALUES
(1, 1, 1),
(2, 2, 1),
(3, 3, 1);

INSERT INTO Prescription
(visit_id, doctor_id, note)
VALUES
(1, 1, 'Blood pressure control'),
(3, 3, 'Fever treatment');

INSERT INTO Prescription_Item
(prescription_id, item_id, quantity, dosage, usage_instruction)
VALUES
(1, 6, 30, '5mg', 'Once daily'),
(2, 1, 10, '500mg', 'Twice daily');

INSERT INTO PharmacyBatch
(item_id, supplier_id, batch_number, expiry_date, selling_unit_price, supply_unit_price, quantity)
VALUES
(1, 1, 'BATCH-PARA-01', '2026-06-30', 1500, 800, 200),
(6, 4, 'BATCH-AMLO-01', '2026-09-15', 2000, 1200, 5);

INSERT INTO PatientInvoice
(visit_id, invoice_date, total_amount, status)
VALUES
(1, '2025-12-22', 150000, 'PAID'),
(2, '2025-12-21', 300000, 'PAID'),
(3, '2025-12-20', 200000, 'NOT PAID');

INSERT INTO PatientInvoice_Item
(patient_invoice_id, item_type, reference_id, quantity, unit_price, line_total)
VALUES
(1, 'SERVICE', 1, 1, 150000, 150000),
(2, 'SERVICE', 2, 1, 300000, 300000),
(3, 'SERVICE', 3, 1, 200000, 200000);

INSERT INTO Payment
(invoice_id, amount, payment_method)
VALUES
(1, 150000, 'CASH'),
(2, 300000, 'CARD');

INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, created_at) VALUES
('Nguyen Thi Hoa', '1985-03-15', 'Female', '0981-111-222', 'nth.hoa@email.com', '12 Tran Hung Dao, Hoan Kiem, Hanoi', '2024-01-10 09:30:00'),
('Tran Van Thanh', '1990-07-20', 'Male', '0982-222-333', 'tv.thanh@email.com', '45 Ba Trieu, Hai Ba Trung, Hanoi', '2024-01-15 10:00:00'),
('Le Thi Mai', '1978-11-30', 'Female', '0983-333-444', 'lt.mai@email.com', '78 Nguyen Chi Thanh, Dong Da, Hanoi', '2024-02-01 11:20:00'),
('Pham Van Dong', '1995-05-12', 'Male', '0984-444-555', 'pv.dong@email.com', '23 Giang Vo, Ba Dinh, Hanoi', '2024-02-10 14:15:00'),
('Hoang Thi Lan', '1988-09-25', 'Female', '0985-555-666', 'ht.lan@email.com', '56 Cau Giay, Cau Giay, Hanoi', '2024-02-20 08:45:00');

INSERT INTO Doctor (department_id, full_name, title, phone, email, `status`, created_at) VALUES
(1, 'Dr. Nguyen Van Minh', 'Associate Professor', '0912-345-678', 'nv.minh@hospital.vn', 'ACTIVE', '2020-01-15 08:00:00'),
(2, 'Dr. Tran Thi Lan', 'Senior Surgeon', '0923-456-789', 'tt.lan@hospital.vn', 'ACTIVE', '2019-03-20 08:00:00'),
(3, 'Dr. Le Hoang Nam', 'Pediatrician', '0934-567-890', 'lh.nam@hospital.vn', 'ACTIVE', '2021-06-10 08:00:00'),
(4, 'Dr. Pham Minh Duc', 'Neurologist', '0945-678-901', 'pm.duc@hospital.vn', 'ACTIVE', '2018-09-05 08:00:00'),
(5, 'Dr. Hoang Thi Mai', 'Orthopedic Surgeon', '0956-789-012', 'ht.mai@hospital.vn', 'ACTIVE', '2020-11-12 08:00:00'),
(6, 'Dr. Vu Quang Hieu', 'Cardiologist', '0967-890-123', 'vq.hieu@hospital.vn', 'ACTIVE', '2019-02-28 08:00:00'),
(7, 'Dr. Do Van Tuan', 'Obstetrician', '0989-012-345', 'dv.tuan@hospital.vn', 'ACTIVE', '2020-07-22 08:00:00'),
(8, 'Dr. Bui Minh Khoa', 'Emergency Medicine Physician', '0901-123-456', 'bm.khoa@hospital.vn', 'ACTIVE', '2022-01-10 08:00:00');

-- -- =====================================================
-- -- Create demo users
-- -- =====================================================
INSERT INTO `User` (username, password_hash, `status`)
VALUES (
    'admin',
    SHA2('Admin123', 256),
    'ACTIVE'
);
INSERT INTO UserRole (user_id, role_name)
VALUES (1, 'ADMIN');

INSERT INTO `User` (username, password_hash, `status`, must_change_password) VALUES
('doctor1', SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('pharmacist1', SHA2('Pharma123', 256), 'ACTIVE', FALSE),
('finance1', SHA2('Finance123', 256), 'ACTIVE', FALSE),
('receptionist1', SHA2('Reception123', 256), 'ACTIVE', FALSE);

-- Assign roles
INSERT INTO UserRole (user_id, role_name) VALUES
(2, 'DOCTOR'),
(3, 'PHARMACIST'),
(4, 'FINANCE'),
(5, 'RECEPTIONIST');

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
