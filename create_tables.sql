-- =====================================================
-- DDL SCRIPT: TABLES CREATION
-- =====================================================


-- =========================
-- STEP 1: INDEPENDENT TABLES
-- =========================

CREATE TABLE IF NOT EXISTS Department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    `description` TEXT
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Diagnosis (
    diagnosis_id INT AUTO_INCREMENT PRIMARY KEY,
    diagnosis_code VARCHAR(20) NOT NULL,
    diagnosis_name VARCHAR(255) NOT NULL,
    `description` TEXT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS MedicalService (
    service_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(255) NOT NULL,
    service_fee DECIMAL(10,2) NOT NULL,
    `description` TEXT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Supplier (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS TimeSlot (
    timeslot_id INT AUTO_INCREMENT PRIMARY KEY,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (start_time < end_time)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `Role` (
    role_name VARCHAR(50) PRIMARY KEY,
    permission_scope JSON NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Notification_Type (
    notification_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    `description` TEXT
);


-- =========================
-- STEP 2: USER & SECURITY
-- =========================

CREATE TABLE IF NOT EXISTS `User` (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    `status` ENUM('ACTIVE', 'LOCKED') NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    must_change_password BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS UserRole (
    user_role_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role_name VARCHAR(50) NOT NULL,

    UNIQUE (user_id, role_name),

    FOREIGN KEY (user_id)
        REFERENCES User(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (role_name)
        REFERENCES Role(role_name)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Login_History (
    login_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    login_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    login_status ENUM('SUCCESS','FAILED') NOT NULL,
    ip_address VARCHAR(45),

    INDEX idx_login_user_time (user_id, login_time),

    FOREIGN KEY (user_id)
        REFERENCES User(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =========================
-- STEP 3: CLINICAL CORE ENTITIES
-- =========================

CREATE TABLE IF NOT EXISTS Patient (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male','Female','Other'),
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Doctor (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    title VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    `status` VARCHAR(50),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_doctor_department (department_id),

    FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Department_Leadership (
    leadership_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    doctor_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,

    UNIQUE (department_id, start_date),

    INDEX idx_leadership_department_dates (department_id, start_date, end_date),
    INDEX idx_leadership_doctor (doctor_id),

    CHECK (end_date IS NULL OR end_date > start_date),

    FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
        
	
) ENGINE=InnoDB;



-- =========================
-- STEP 4: SCHEDULING
-- =========================

CREATE TABLE IF NOT EXISTS Appointment (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    timeslot_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    reason TEXT,
    current_status ENUM('CREATED','CONFIRMED','CANCELLED','IN_PROGRESS','COMPLETED') NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (doctor_id, appointment_date, timeslot_id),
    INDEX idx_appointment_patient (patient_id),
    INDEX idx_appointment_doctor_date (doctor_id, appointment_date),

    FOREIGN KEY (patient_id)
        REFERENCES Patient(patient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (timeslot_id)
        REFERENCES TimeSlot(timeslot_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Appointment_Status_History (
    status_history_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    old_status ENUM('CREATED','CONFIRMED','CANCELLED','IN_PROGRESS','COMPLETED'),
    new_status ENUM('CREATED','CONFIRMED','CANCELLED','IN_PROGRESS','COMPLETED') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by INT NOT NULL,

    INDEX idx_ash_appointment_time (appointment_id, changed_at),

    FOREIGN KEY (appointment_id)
        REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (changed_by)
        REFERENCES User(user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Doctor_Availability (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    timeslot_id INT NOT NULL,
    available_date DATE NOT NULL,
    is_available BOOLEAN NOT NULL,

    UNIQUE (doctor_id, timeslot_id, available_date),
    INDEX idx_availability_date (available_date),

    FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (timeslot_id)
        REFERENCES TimeSlot(timeslot_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =========================
-- STEP 5: VISITS & MEDICAL RECORDS
-- =========================

CREATE TABLE IF NOT EXISTS Visit (
    visit_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    visit_start_time DATETIME NOT NULL,
    visit_end_time DATETIME,
    clinical_note TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_visit_patient (patient_id),
    INDEX idx_visit_doctor (doctor_id),

    FOREIGN KEY (appointment_id)
        REFERENCES Appointment(appointment_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (patient_id)
        REFERENCES Patient(patient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Attachment (
    attachment_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50),
    file_path VARCHAR(255) NOT NULL,
    time_uploaded DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_attachment_visit (visit_id),

    FOREIGN KEY (visit_id)
        REFERENCES Visit(visit_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Visit_Diagnosis (
    visit_diagnosis_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL,
    diagnosis_id INT NOT NULL,
    doctor_id INT NOT NULL,
    doctor_note TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (visit_id, diagnosis_id),
    INDEX idx_vd_doctor (doctor_id),

    FOREIGN KEY (visit_id)
        REFERENCES Visit(visit_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (diagnosis_id)
        REFERENCES Diagnosis(diagnosis_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Visit_Service (
    visit_service_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL,
    service_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),

    UNIQUE (visit_id, service_id),

    FOREIGN KEY (visit_id)
        REFERENCES Visit(visit_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (service_id)
        REFERENCES MedicalService(service_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =========================
-- STEP 6: PHARMACY & INVENTORY
-- =========================
CREATE TABLE IF NOT EXISTS Prescription (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL UNIQUE,
    doctor_id INT NOT NULL,
    prescribed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note TEXT,

    FOREIGN KEY (visit_id)
        REFERENCES Visit(visit_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS PharmacyItem (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL UNIQUE,
    unit VARCHAR(50),
    description TEXT
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Prescription_Item (
    prescription_item_id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    dosage VARCHAR(100),
    usage_instruction TEXT,

    UNIQUE (prescription_id, item_id),

    FOREIGN KEY (prescription_id)
        REFERENCES Prescription(prescription_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (item_id)
        REFERENCES PharmacyItem(item_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS PharmacyBatch (
    batch_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    supplier_id INT NOT NULL,
    batch_number VARCHAR(100) NOT NULL,
    expiry_date DATE NOT NULL CHECK (expiry_date > CURRENT_DATE),
    selling_unit_price DECIMAL(10,2) NOT NULL CHECK (selling_unit_price >= 0),
    supply_unit_price DECIMAL(10,2) NOT NULL CHECK (supply_unit_price >= 0),
    quantity INT NOT NULL CHECK (quantity >= 0),

    UNIQUE (item_id, batch_number),

    FOREIGN KEY (item_id)
        REFERENCES PharmacyItem(item_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (supplier_id)
        REFERENCES Supplier(supplier_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS StockMovement (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    movement_type ENUM('IN','OUT') NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    reference_type VARCHAR(50),
    reference_id INT,
    moved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_stockmovement_batch_time (batch_id, moved_at),

    FOREIGN KEY (batch_id)
        REFERENCES PharmacyBatch(batch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS SupplierInvoice (
    supplier_invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    batch_id INT NOT NULL,
    invoice_date DATE NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount >= 0),
    status ENUM('PAID','NOT PAID') NOT NULL,

    FOREIGN KEY (supplier_id)
        REFERENCES Supplier(supplier_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (batch_id)
        REFERENCES PharmacyBatch(batch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =========================
-- STEP 7: BILLING & FINANCE
-- =========================

CREATE TABLE IF NOT EXISTS PatientInvoice (
    patient_invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL UNIQUE,
    invoice_date DATE NOT NULL,
    total_amount DECIMAL(15,2) CHECK (total_amount >= 0),
    `status` ENUM('PAID','NOT PAID') NOT NULL,

    FOREIGN KEY (visit_id)
        REFERENCES Visit(visit_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS PatientInvoice_Item (
    patient_invoice_item_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_invoice_id INT NOT NULL,
    item_type ENUM('SERVICE','MEDICINE') NOT NULL,
    reference_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),

    INDEX idx_invoice_item_invoice (patient_invoice_id),

    FOREIGN KEY (patient_invoice_id)
        REFERENCES PatientInvoice(patient_invoice_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50),

    INDEX idx_payment_invoice (invoice_id),

    FOREIGN KEY (invoice_id)
        REFERENCES PatientInvoice(patient_invoice_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS FinancialTransaction (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_type ENUM('INCOME','EXPENSE') NOT NULL,
    reference_type ENUM('PATIENT_INVOICE','SUPPLIER_INVOICE','OTHER') NOT NULL,
    reference_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    transaction_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT
) ENGINE=InnoDB;


-- =========================
-- STEP 8: AUDIT & NOTIFICATION
-- =========================
CREATE TABLE IF NOT EXISTS AuditLog (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    `table_name` VARCHAR(100) NOT NULL,
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    action_type ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_audit_user_time (user_id, changed_at),

    FOREIGN KEY (user_id)
        REFERENCES User(user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS Notification (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    notification_type_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    INDEX idx_notification_user (user_id),

    FOREIGN KEY (user_id)
        REFERENCES User(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (notification_type_id)
        REFERENCES Notification_Type(notification_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;
