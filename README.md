# VinUni Database Project: Hospital Management System (HMS)
## Brief Description  
Our Hospital Management System (HMS) is a web-based information system designed to streamline core hospital operations through a centralized MySQL database. The system integrates patient management, appointment scheduling, clinical visits, pharmacy inventory, billing, and financial tracking into a unified and secure platform.
## Functional & Non-functional Requirements
### **Functional Requirements**
- Patient registration and profile management
- Smart appointment scheduling with doctor assignment and availability checking
- Visit/consultation management to record diagnoses and clinical notes
- Prescription management linked to pharmacy inventory
- Pharmacy inventory management (stock levels, expiry dates, suppliers)
- Automatic stock updates based on prescription records
- Billing and invoice generation based on medical services provided
- Financial transaction tracking (income and expense records)
- Analytical reports for hospital operations, pharmacy usage, and revenue
- Role-based authentication and authorization (admin, staff, pharmacist)

| **Admin**                                            |**Staff (Doctors/Nurses/Clerks)**                    | **Pharmacist**                                  |
|------------------------------------------------------|-----------------------------------------------------|------------------------------                   |
| Full access to all system modules                    | Manage patient records, appointments, and visits    | Manage pharmacy inventory and prescriptions     |
| User and role management                             | Create medical services and billing records         | Update stock levels and monitor expiry dates    |
| Access to financial reports and system-wide analytics| No access to system configuration or role management| Read-only access to relevant billing information|
### **Non-functional Requirements**
- Secure authentication and protection of sensitive medical and financial data
- Enforcement of role-based access control at both database and application levels
- Stable performance under concurrent hospital workloads
- Scalable and modular backend design
- Backup and recovery support at the database level
- Maintainable and well-structured codebase
- Responsive and user-friendly web interface
## Planned Core Entities
To support a complete hospital workflow and avoid schema redesign in later stages, the system plans the following core entities:
- Patient: personal information and identifiers
- Doctor: specialization, availability, and assigned appointments
- Appointment: scheduled time slots linking patients and doctors
- Visit (Consultation): records of actual medical encounters, diagnoses, and notes
- Prescription: medications prescribed during visits
- PharmacyItem: medication details, stock quantity, expiry date, and supplier
- MedicalService / Procedure: billable services provided during visits
- Invoice: invoices generated from services and prescriptions
- FinancialTransaction: income and expense tracking
- User: login credentials and assigned system roles

These entities will be normalized to Third Normal Form (3NF) and connected through appropriate primary and foreign key relationships.
## Database Design and Optimization Strategy
The database design emphasizes integrity, performance, and auditability:
- Use of primary keys, foreign keys, NOT NULL constraints, and cascading rules
- Stored procedures for common operations (adding appointments, generating invoices)
- Triggers for:
  - Audit logging of sensitive updates (medical records, billing, stock changes)
  - Automatic pharmacy stock validation and decrement
- Views for frequent reporting tasks (daily appointments, low-stock warnings, revenue summaries)
- Indexing strategy on frequently queried columns such as:
  - `appointment_date`
  - `doctor_id`
  - `patient_id`
  - `expiry_date` in pharmacy inventory
## System Workflow Overview
A typical workflow in the system is as follows:
1. A patient registers and books an appointment with a doctor.
2. The appointment results in a visit record during the consultation.
3. Medical services and prescriptions are created during the visit.
4. Prescriptions trigger pharmacy stock updates.
5. Billing records and invoices are generated based on services and medications.
6. Financial transactions are recorded for reporting and analytics.
## Tech Stack
- **Frontend**: HTML, CSS, JavaScript  
- **Backend**: PHP  
- **Database**: MySQL  
- **Server**: XAMPP 
- **Security**:
  - MySQL password hashing functions
  - Database-level roles and privileges
  - Prepared statements to prevent SQL injection
## Team Members and Roles
| **Member**                 |**Project Role**                    | **Responsibilities**  |
|---------------------------|-------------------------------------|-----------------------|
| **Đỗ Thị Hải Bình**       | Database Architect & Developer      | ERD design • Physical schema • Table creation • PK/FK design |
| **Lê Thảo Vy**            | MySQL Logic & Optimization Engineer | Stored procedures • Triggers • Views • Indexing • Query optimization |
| **Nguyễn Thị Phương Thảo**| Security & Testing Engineer         | MySQL users & privileges • RBAC enforcement • Password security • Testing workflow |
| **All Members**           | Web Integration & Reporting Dev     | Frontend–backend connection • Dashboards • Reports • Final refinement |

## Timeline (Planned Milestones)
| **Date Range**  | **Milestone**                                                      |
| --------------- | ------------------------------------------------------------------ |
| Dec 1           | Team registration, topic selection, GitHub setup                   |
| Dec 2 – Dec 5   | Finalize requirements, ERD outline, schema planning                |
| Dec 6 – Dec 10  | Database schema implementation, authentication, patient CRUD       |
| Dec 11 – Dec 15 | Appointments, visits, prescriptions, procedures, triggers, indexes |
| Dec 16 – Dec 18 | Frontend integration, dashboards, reporting                        |
| Dec 19 – Dec 20 | System testing, RBAC validation, bug fixes                         |
| Dec 21          | Final integration, documentation, presentation preparation         |
| Dec 22          | Final submission and presentation                                  |
