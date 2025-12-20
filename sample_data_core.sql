-- Sample data for Department table
INSERT INTO Department (department_name, description)
VALUES 
('Cardiology', 'Heart and blood vessel treatments'),
('Neurology', 'Brain and nervous system treatments'),
('Pediatrics', 'Children’s health care'),
('Orthopedics', 'Musculoskeletal system treatments'),
('Dermatology', 'Skin and cosmetic treatments');

-- Sample data for Doctor table
INSERT INTO Doctor (department_id, full_name, title, phone, email, status)
VALUES 
(1, 'Dr. John Smith', 'Cardiologist', '123-456-7890', 'john.smith@hospital.com', 'Active'),
(2, 'Dr. Emily Johnson', 'Neurologist', '987-654-3210', 'emily.johnson@hospital.com', 'Active'),
(3, 'Dr. Michael Brown', 'Pediatrician', '555-123-4567', 'michael.brown@hospital.com', 'Active'),
(1, 'Dr. Lisa White', 'Cardiologist', '333-456-7890', 'lisa.white@hospital.com', 'Active'),
(2, 'Dr. William Green', 'Neurologist', '444-555-6666', 'william.green@hospital.com', 'Active'),
(1, 'Dr. Sarah Lee', 'Cardiologist', '555-123-9876', 'sarah.lee@hospital.com', 'Active'),
(3, 'Dr. James Moore', 'Pediatrician', '555-789-6543', 'james.moore@hospital.com', 'Active'),
(2, 'Dr. Laura King', 'Neurologist', '555-321-7654', 'laura.king@hospital.com', 'Active'),
(4, 'Dr. Olivia Evans', 'Orthopedic Surgeon', '555-654-3210', 'olivia.evans@hospital.com', 'Active'),
(5, 'Dr. Emma Davis', 'Dermatologist', '555-987-1234', 'emma.davis@hospital.com', 'Active');

-- Sample data for Patient table
INSERT INTO Patient (full_name, date_of_birth, gender, phone, email, address)
VALUES 
('Alice Davis', '1990-06-15', 'Female', '555-234-5678', 'alice.davis@domain.com', '123 Maple Street'),
('Bob Miller', '1985-04-22', 'Male', '555-345-6789', 'bob.miller@domain.com', '456 Oak Avenue'),
('Charlie Brown', '2000-11-02', 'Male', '555-456-7890', 'charlie.brown@domain.com', '789 Pine Road'),
('Diana Clark', '1995-02-10', 'Female', '555-567-8901', 'diana.clark@domain.com', '321 Birch Lane'),
('Eva Taylor', '1988-09-12', 'Female', '555-678-9012', 'eva.taylor@domain.com', '654 Cedar Drive'),
('Frank Walker', '1978-12-30', 'Male', '555-789-0123', 'frank.walker@domain.com', '987 Willow Blvd'),
('Grace Lewis', '1993-05-25', 'Female', '555-890-1234', 'grace.lewis@domain.com', '246 Elm Street'),
('Henry Walker', '1983-07-17', 'Male', '555-901-2345', 'henry.walker@domain.com', '135 Maple Lane'),
('Ivy Harris', '2002-07-08', 'Female', '555-234-9876', 'ivy.harris@domain.com', '135 Birch Avenue'),
('Jack White', '1997-05-19', 'Male', '555-543-2109', 'jack.white@domain.com', '246 Cedar Blvd'),
('Lily Adams', '1983-03-29', 'Female', '555-987-6543', 'lily.adams@domain.com', '369 Oak Street'),
('Mason Scott', '1992-12-11', 'Male', '555-876-5432', 'mason.scott@domain.com', '481 Maple Road'),
('Nina Hall', '2005-02-14', 'Female', '555-678-9012', 'nina.hall@domain.com', '502 Pine Street');

-- Sample data for MedicalService table
INSERT INTO MedicalService (service_name, service_fee, description)
VALUES 
('X-ray', 50.00, 'Diagnostic imaging service'),
('MRI Scan', 200.00, 'Magnetic resonance imaging service'),
('Blood Test', 30.00, 'Laboratory testing for various conditions'),
('Consultation', 80.00, 'Consultation with doctor for diagnosis'),
('Surgery', 1000.00, 'Surgical operations for treatments'),
('Vaccination', 20.00, 'Administering preventive vaccines'),
('ECG', 75.00, 'Electrocardiogram for heart function'),
('CT Scan', 250.00, 'Computed tomography scan'),
('Ultrasound', 150.00, 'Ultrasound imaging service'),
('Consultation with Specialist', 120.00, 'Consultation for specialized care');

-- Sample data for TimeSlot table
INSERT INTO TimeSlot (start_time, end_time)
VALUES
('08:00:00', '09:00:00'),
('09:00:00', '10:00:00'),
('10:00:00', '11:00:00'),
('11:00:00', '12:00:00'),
('12:00:00', '13:00:00'),
('13:00:00', '14:00:00'),
('14:00:00', '15:00:00'),
('15:00:00', '16:00:00'),
('16:00:00', '17:00:00');
