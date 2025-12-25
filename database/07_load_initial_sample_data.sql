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
('Cetirizine 10mg', 'Tablet', 'Antihistamine for allergies');

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

INSERT INTO `User` (username, password_hash, `status`, must_change_password) VALUES
('doc_minh', SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_lan',  SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_nam',  SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_duc',  SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_mai',  SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_hieu', SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_tuan', SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('doc_khoa', SHA2('Doctor123', 256), 'ACTIVE', FALSE),
('admin', SHA2('Admin123', 256),'ACTIVE', TRUE),
('pharmacist1', SHA2('Pharma123', 256), 'ACTIVE', TRUE),
('finance1', SHA2('Finance123', 256), 'ACTIVE', TRUE),
('receptionist1', SHA2('Reception123', 256), 'ACTIVE', TRUE);

-- Assign roles to demo users
INSERT INTO UserRole (user_id, role_name) VALUES
(1, 'DOCTOR'),
(2, 'DOCTOR'),
(3, 'DOCTOR'),
(4, 'DOCTOR'),
(5, 'DOCTOR'),
(6, 'DOCTOR'),
(7, 'DOCTOR'),
(8, 'DOCTOR'),
(9, 'ADMIN'),
(10, 'PHARMACIST'),
(11, 'FINANCE'),
(12, 'RECEPTIONIST');


INSERT INTO Doctor (user_id, department_id, full_name, title, phone, email, `status`, created_at) VALUES
((SELECT user_id FROM `User` WHERE username = 'doc_minh'), 1, 'Nguyen Van Minh', 'Associate Professor', '0912-345-678', 'nv.minh@hospital.vn', 'ACTIVE', '2020-01-15 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_lan'),  2, 'Tran Thi Lan', 'Senior Surgeon', '0923-456-789', 'tt.lan@hospital.vn', 'ACTIVE', '2019-03-20 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_nam'),  3, 'Le Hoang Nam', 'Pediatrician', '0934-567-890', 'lh.nam@hospital.vn', 'ACTIVE', '2021-06-10 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_duc'),  4, 'Pham Minh Duc', 'Neurologist', '0945-678-901', 'pm.duc@hospital.vn', 'ACTIVE', '2018-09-05 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_mai'),  5, 'Hoang Thi Mai', 'Orthopedic Surgeon', '0956-789-012', 'ht.mai@hospital.vn', 'ACTIVE', '2020-11-12 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_hieu'), 6, 'Vu Quang Hieu', 'Cardiologist', '0967-890-123', 'vq.hieu@hospital.vn', 'ACTIVE', '2019-02-28 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_tuan'), 7, 'Do Van Tuan', 'Obstetrician', '0989-012-345', 'dv.tuan@hospital.vn', 'ACTIVE', '2020-07-22 08:00:00'),
((SELECT user_id FROM `User` WHERE username = 'doc_khoa'), 8, 'Bui Minh Khoa', 'Emergency Medicine Physician', '0901-123-456', 'bm.khoa@hospital.vn', 'ACTIVE', '2022-01-10 08:00:00');

INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address, created_at) VALUES
('Nguyen Thi Hoa', '1985-03-15', 'Female', '0981-111-222', 'nth.hoa@email.com', '12 Tran Hung Dao, Hoan Kiem, Hanoi', '2024-01-10 09:30:00'),
('Tran Van Thanh', '1990-07-20', 'Male', '0982-222-333', 'tv.thanh@email.com', '45 Ba Trieu, Hai Ba Trung, Hanoi', '2024-01-15 10:00:00'),
('Le Thi Mai', '1978-11-30', 'Female', '0983-333-444', 'lt.mai@email.com', '78 Nguyen Chi Thanh, Dong Da, Hanoi', '2024-02-01 11:20:00'),
('Pham Van Dong', '1995-05-12', 'Male', '0984-444-555', 'pv.dong@email.com', '23 Giang Vo, Ba Dinh, Hanoi', '2024-02-10 14:15:00'),
('Hoang Thi Lan', '1988-09-25', 'Female', '0985-555-666', 'ht.lan@email.com', '56 Cau Giay, Cau Giay, Hanoi', '2024-02-20 08:45:00'),
('Vu Van An', '2000-12-05', 'Male', '0986-666-777', 'vv.an@email.com', '89 Le Loi, District 1, Ho Chi Minh City', '2024-03-01 13:00:00'),
('Do Thi Huong', '1992-04-18', 'Female', '0987-777-888', 'dt.huong@email.com', '101 Nguyen Van Linh, District 5, Ho Chi Minh City', '2024-03-15 15:30:00'),
('Bui Van Long', '1983-08-22', 'Male', '0988-888-999', 'bv.long@email.com', '123 Nguyen Trai, District 5, Ho Chi Minh City', '2024-03-20 16:00:00'),
('Pham Thi Huong', '1975-02-14', 'Female', '0989-999-000', 'pth.huong@email.com', '156 Nguyen Van Cu, District 5, Ho Chi Minh City', '2024-03-25 17:00:00'),
('Le Van Hung', '1998-06-30', 'Male', '0990-000-111', 'lv.hung@email.com', '200 Nguyen Duy Hieu, District 5, Ho Chi Minh City', '2024-03-30 18:00:00');

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
(1, 1, 1, CURDATE(), 'Follow-up visit', 'COMPLETED'),      -- ID: 1
(2, 1, 2, CURDATE(), 'Post-surgery check', 'CONFIRMED'),   -- ID: 2
(3, 1, 3, CURDATE(), 'Vaccination', 'IN_PROGRESS'),        -- ID: 3
(4, 1, 4, CURDATE(), 'Neurological assessment', 'CANCELLED'),
(5, 5, 1, CURDATE(), 'Physical therapy', 'CANCELLED'),
(1, 6, 2, CURDATE(), 'Cardiac check-up', 'COMPLETED'),    -- ID: 6
(2, 1, 3, '2025-12-19', 'Pregnancy ultrasound', 'COMPLETED'), -- ID: 7
(3, 1, 4, '2025-12-19', 'Allergy consultation', 'COMPLETED'), -- ID: 8
(4, 1, 1, '2025-12-19', 'Wound assessment', 'COMPLETED'),     -- ID: 9
(5, 1, 2, '2025-12-18', 'Growth monitoring', 'COMPLETED'),    -- ID: 10
(1, 4, 3, '2025-12-18', 'Headache evaluation', 'COMPLETED'),  -- ID: 11
(2, 1, 4, '2025-12-18', 'Joint pain assessment', 'COMPLETED'), -- ID: 12
(3, 6, 1, '2025-12-17', 'Annual heart screening', 'COMPLETED'),-- ID: 13
(4, 7, 2, '2025-12-17', 'Prenatal visit', 'COMPLETED'),        -- ID: 14
(5, 1, 3, '2025-12-17', 'Blood pressure monitoring', 'COMPLETED'),-- ID: 15
(1, 2, 4, '2025-12-16', 'Surgery pre-assessment', 'CONFIRMED'),
(2, 1, 1, '2025-12-16', 'Pediatric check-up', 'CONFIRMED'),
(3, 4, 2, '2025-12-15', 'MRI follow-up discussion', 'COMPLETED'),-- ID: 18
(4, 5, 3, '2025-12-15', 'Fracture recovery check', 'COMPLETED'), -- ID: 19
(5, 6, 4, '2025-12-15', 'Arrhythmia monitoring', 'COMPLETED'),   -- ID: 20
(1, 7, 1, '2025-12-14', 'Obstetric consultation', 'COMPLETED'),  -- ID: 21
(2, 1, 2, '2025-12-14', 'Diabetes management', 'COMPLETED'),     -- ID: 22
(3, 2, 3, '2025-12-13', 'Appendix evaluation', 'COMPLETED'),     -- ID: 23
(4, 3, 4, '2025-12-13', 'Ear infection check', 'COMPLETED'),      -- ID: 24
(5, 4, 1, '2025-12-13', 'Seizure management review', 'COMPLETED'),-- ID: 25
(1, 5, 2, '2025-12-12', 'Knee injury assessment', 'COMPLETED'),   -- ID: 26
(2, 6, 3, '2025-12-12', 'Heart rate variability test', 'COMPLETED'),-- ID: 27
(3, 7, 4, '2025-12-11', 'Third trimester check', 'COMPLETED'),     -- ID: 28
(4, 1, 1, '2025-12-11', 'Cholesterol recheck', 'COMPLETED'),       -- ID: 29
(5, 2, 2, '2025-12-10', 'Hernia repair consultation', 'COMPLETED');-- ID: 30

INSERT INTO Visit
(appointment_id, patient_id, doctor_id, visit_start_time, visit_end_time, clinical_note)
VALUES
-- Today's visits
(1, 1, 1, CONCAT(CURDATE(), ' 08:00:00'), CONCAT(CURDATE(), ' 08:30:00'), 'Follow-up visit: Patient recovers well.'),
(3, 3, 1, CONCAT(CURDATE(), ' 09:30:00'), NULL, 'Vaccination in progress...'),
(6, 1, 6, CONCAT(CURDATE(), ' 10:00:00'), CONCAT(CURDATE(), ' 10:45:00'), 'Cardiac check-up completed.'),
-- Past visits for Dr. Minh
(7, 2, 1, '2025-12-19 08:30:00', '2025-12-19 09:00:00', 'Pregnancy ultrasound: Healthy fetus.'),
(8, 3, 1, '2025-12-19 09:30:00', '2025-12-19 10:00:00', 'Allergy consultation: Avoid seafood.'),
(9, 4, 1, '2025-12-19 10:30:00', '2025-12-19 11:00:00', 'Wound assessment: Healing nicely.'),
(10, 5, 1, '2025-12-18 08:00:00', '2025-12-18 08:30:00', 'Growth monitoring: Normal parameters.'),
(12, 2, 1, '2025-12-18 09:30:00', '2025-12-18 10:00:00', 'Joint pain: Prescribed physical therapy.'),
(15, 5, 1, '2025-12-17 08:30:00', '2025-12-17 09:15:00', 'Blood pressure monitoring: Controlled.'),
(22, 2, 1, '2025-12-14 09:00:00', '2025-12-14 09:30:00', 'Diabetes management: Diet plan updated.'),
(29, 4, 1, '2025-12-11 08:00:00', '2025-12-11 08:30:00', 'Cholesterol recheck: Slightly elevated.'),
(14, 4, 7, '2025-12-17 10:00:00', '2025-12-17 10:30:00', 'Prenatal visit: All clear.'),
-- Past visits for other doctors
(11, 1, 4, '2025-12-18 11:00:00', '2025-12-18 11:45:00', 'Headache evaluation: Stress related.'),
(13, 3, 6, '2025-12-17 14:00:00', '2025-12-17 14:30:00', 'Annual heart screening: Stable.'),
(18, 3, 4, '2025-12-15 08:30:00', '2025-12-15 09:30:00', 'MRI follow-up: No new lesions.'),
(19, 4, 5, '2025-12-15 10:00:00', '2025-12-15 10:45:00', 'Fracture recovery: Cast removed.'),
(20, 5, 6, '2025-12-15 11:30:00', '2025-12-15 12:00:00', 'Arrhythmia monitoring: Regular rhythm.'),
(21, 1, 7, '2025-12-14 08:00:00', '2025-12-14 08:45:00', 'Obstetric consultation: Routine check.'),
(23, 3, 2, '2025-12-13 10:00:00', '2025-12-13 11:00:00', 'Appendix evaluation: Negative.'),
(24, 4, 3, '2025-12-13 13:00:00', '2025-12-13 13:30:00', 'Ear infection: Antibiotics prescribed.'),
(25, 5, 4, '2025-12-13 15:00:00', '2025-12-13 15:30:00', 'Seizure management: No episodes.'),
(26, 1, 5, '2025-12-12 09:00:00', '2025-12-12 09:45:00', 'Knee injury: Mild sprain.'),
(27, 2, 6, '2025-12-12 11:00:00', '2025-12-12 11:30:00', 'Heart rate test: Normal.'),
(28, 3, 7, '2025-12-11 14:00:00', '2025-12-11 14:45:00', 'Third trimester: Baby in position.'),
(30, 5, 2, '2025-12-10 16:00:00', '2025-12-10 17:00:00', 'Hernia repair: Surgery scheduled.');

INSERT INTO Visit_Service
(visit_id, service_id, quantity)
VALUES
(1, 1, 1),
(2, 1, 1),
(3, 1, 1),
(4, 4, 1),
(5, 4, 1),
(6, 6, 1),
(7, 7, 1),
(8, 8, 1),
(9, 9, 1),
(10, 10, 1),
(11, 11, 1),
(12, 12, 1),
(13, 13, 1),
(14, 14, 1),
(15, 15, 1);

INSERT INTO Diagnosis (diagnosis_code, diagnosis_name, description)
VALUES
('I10', 'Hypertension', 'High blood pressure'),
('J06', 'Acute Upper Respiratory Infection', 'Common viral infection'),
('R50', 'Fever', 'Elevated body temperature'),
('J30', 'Allergic Rhinitis', 'Allergic inflammation of the nasal airways'),
('M54', 'Dorsalgia', 'Back pain'),
('R51', 'Headache', 'Pain in the head'),
('M79', 'Myalgia', 'Muscle pain'),
('I48', 'Atrial Fibrillation', 'Irregular heartbeat'),
('O09', 'Supervision of High Risk Pregnancy', 'High risk pregnancy supervision'),
('E11', 'Type 2 Diabetes Mellitus', 'Diabetes mellitus type 2'),
('K40', 'Inguinal Hernia', 'Hernia in the groin area'),
('H66', 'Suppurative and Unspecified Otitis Media', 'Middle ear infection'),
('G40', 'Epilepsy', 'Epileptic seizures'),
('S83', 'Dislocation and Sprain of Joints and Ligaments of Knee', 'Knee injury'),
('I49', 'Other Cardiac Arrhythmias', 'Heart rhythm disorders');

INSERT INTO Visit_Diagnosis
(visit_id, diagnosis_id, doctor_id, doctor_note)
VALUES
(1, 1, 1, 'Monitor blood pressure regularly'),
(2, 1, 6, 'Pre-surgery risk assessment completed'),
(3, 3, 1, 'Likely viral infection, monitor temperature'),
(4, 4, 1, 'Neurological assessment shows no abnormalities'),
(5, 5, 5, 'Physical therapy recommended for back pain'),
(6, 1, 6, 'Cardiac check-up shows controlled hypertension'),
(7, 9, 1, 'Pregnancy ultrasound normal, continue monitoring'),
(8, 4, 1, 'Allergy consultation - prescribed antihistamines'),
(9, 6, 1, 'Wound healing well, follow-up in 2 weeks'),
(10, 7, 1, 'Growth monitoring within normal parameters'),
(11, 6, 1, 'Headache evaluation - tension headache diagnosed'),
(12, 5, 5, 'Joint pain assessment - osteoarthritis suspected'),
(13, 8, 6, 'Annual heart screening - atrial fibrillation detected'),
(14, 9, 1, 'Prenatal visit - healthy pregnancy progress'),
(15, 1, 1, 'Blood pressure monitoring - well controlled');

INSERT INTO Prescription
(visit_id, doctor_id, note)
VALUES
(1, 1, 'Blood pressure control medication'),
(3, 1, 'Fever and pain relief'),
(8, 1, 'Allergy symptom relief'),
(11, 1, 'Headache pain management'),
(13, 6, 'Heart rhythm control'),
(15, 1, 'Hypertension maintenance therapy');

INSERT INTO Prescription_Item
(prescription_id, item_id, quantity, dosage, usage_instruction)
VALUES
(1, 6, 30, '5mg', 'Once daily in the morning'),
(2, 1, 10, '500mg', 'Twice daily after meals'),
(3, 8, 20, '10mg', 'Once daily'),
(4, 1, 15, '500mg', 'As needed for headache, max 3 times daily'),
(5, 6, 60, '5mg', 'Once daily'),
(6, 6, 30, '5mg', 'Once daily');

INSERT INTO PharmacyBatch
(item_id, supplier_id, batch_number, expiry_date, selling_unit_price, supply_unit_price, quantity)
VALUES
(1, 1, 'BATCH-PARA-01', '2026-06-30', 1500, 800, 200),
(6, 4, 'BATCH-AMLO-01', '2026-09-15', 2000, 1200, 50),
(8, 2, 'BATCH-CETI-01', '2026-12-31', 1200, 700, 100),
(2, 3, 'BATCH-AMOX-01', '2026-08-20', 2500, 1500, 150),
(3, 5, 'BATCH-IBUP-01', '2026-10-10', 1800, 1000, 120),
(4, 1, 'BATCH-OMEP-01', '2026-11-05', 3000, 1800, 80);

INSERT INTO PatientInvoice
(visit_id, invoice_date, total_amount, status)
VALUES
(1, '2025-12-19', 150000, 'PAID'),
(2, '2025-12-19', 300000, 'PAID'),
(3, '2025-12-19', 200000, 'NOT PAID'),
(4, '2025-12-19', 200000, 'PAID'),
(5, '2025-12-19', 250000, 'PAID'),
(6, '2025-12-19', 150000, 'PAID'),
(7, '2025-12-19', 350000, 'PAID'),
(8, '2025-12-19', 150000, 'PAID'),
(9, '2025-12-19', 300000, 'PAID'),
(10, '2025-12-18', 150000, 'PAID'),
(11, '2025-12-18', 200000, 'PAID'),
(12, '2025-12-18', 250000, 'PAID'),
(13, '2025-12-17', 150000, 'PAID'),
(14, '2025-12-17', 300000, 'PAID'),
(15, '2025-12-17', 150000, 'PAID');

INSERT INTO PatientInvoice_Item
(patient_invoice_id, item_type, reference_id, quantity, unit_price, line_total)
VALUES
(1, 'SERVICE', 1, 1, 150000, 150000),
(2, 'SERVICE', 2, 1, 300000, 300000),
(3, 'SERVICE', 3, 1, 200000, 200000),
(4, 'SERVICE', 4, 1, 200000, 200000),
(5, 'SERVICE', 5, 1, 250000, 250000),
(6, 'SERVICE', 6, 1, 150000, 150000),
(7, 'SERVICE', 7, 1, 350000, 350000),
(8, 'SERVICE', 8, 1, 150000, 150000),
(9, 'SERVICE', 9, 1, 300000, 300000),
(10, 'SERVICE', 10, 1, 150000, 150000),
(11, 'SERVICE', 11, 1, 200000, 200000),
(12, 'SERVICE', 12, 1, 250000, 250000),
(13, 'SERVICE', 13, 1, 150000, 150000),
(14, 'SERVICE', 14, 1, 300000, 300000),
(15, 'SERVICE', 15, 1, 150000, 150000);

INSERT INTO Payment
(invoice_id, amount, payment_method)
VALUES
(1, 150000, 'CASH'),
(2, 300000, 'CARD'),
(4, 200000, 'CASH'),
(5, 250000, 'CARD'),
(6, 150000, 'CASH'),
(7, 350000, 'CARD'),
(8, 150000, 'CASH'),
(9, 300000, 'CARD'),
(10, 150000, 'CASH'),
(11, 200000, 'CARD'),
(12, 250000, 'CASH'),
(13, 150000, 'CARD'),
(14, 300000, 'CASH'),
(15, 150000, 'CARD');


INSERT INTO Notification (user_id, notification_type_id, content, is_read, created_at) VALUES 
(9, 1, 'New appointment scheduled for Nguyen Thi Hoa', FALSE, '2025-12-22 09:00:00'),
(1, 3, 'Appointment cancelled for patient Tran Van Thanh', FALSE, '2025-12-21 14:30:00'),
(10, 5, 'New visit assigned: Cardiac check-up for Nguyen Thi Hoa', TRUE, '2025-12-19 09:15:00'),
(11, 7, 'Prescription created for patient Le Thi Mai - Fever treatment', FALSE, '2025-12-20 11:45:00'),
(9, 9, 'Low stock alert: Paracetamol 500mg - only 50 units remaining', TRUE, '2025-12-23 08:00:00'),
(9, 11, 'Invoice generated for visit #1 - Nguyen Thi Hoa', FALSE, '2025-12-22 10:30:00'),
(9, 13, 'System configuration updated: New billing rates applied', TRUE, '2025-12-24 12:00:00'),
(1, 5, 'Visit completed: Pregnancy ultrasound for Tran Van Thanh', FALSE, '2025-12-19 10:45:00'),
(10, 7, 'Prescription ready for dispensing: Blood pressure medication', TRUE, '2025-12-22 16:20:00'),
(11, 11, 'Payment received: Invoice #2 - Tran Van Thanh', FALSE, '2025-12-21 15:00:00'),
(9, 9, 'Stock expiry warning: Amoxicillin batch expires in 30 days', TRUE, '2025-12-24 09:00:00'),
(12, 1, 'Appointment confirmed: Pediatric check-up for Hoang Thi Lan', FALSE, '2025-12-16 13:30:00'),
(1, 11, 'Invoice overdue: Visit #3 - Le Thi Mai', TRUE, '2025-12-25 10:00:00');

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
