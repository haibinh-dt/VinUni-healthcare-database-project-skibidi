# VinUni Database Project: Hospital Management System (HMS)
## Brief Description  
This Hospital Management System is a web-based platform built to streamline everyday hospital operations. It centralizes patient management, pharmacy inventory, billing, and financial tracking into one secure ecosystem. The system reduces paperwork, prevents data inconsistency across departments, and improves security for sensitive medical and financial information.
## Functional & Non-functional Requirements
### **Functional Requirements**
- Patient registration and management  
- Appointment scheduling and doctor assignment  
- Pharmacy inventory (stock, expiry tracking, suppliers)  
- Billing module with invoice generation  
- Financial tracking (income/expense)  
- Role-based authentication (admin, staff, pharmacist)  
- Reports for operations, pharmacy usage, and revenue  
### **Non-functional Requirements**
- Secure authentication and protected data handling  
- Scalable and modular backend architecture  
- Stable performance under hospital workload  
- Backup and recovery options  
- Responsive, clean UI  
- Maintainable, well-structured codebase  
## Planned Core Entities
- **Patient**: ID, info, medical history  
- **Doctor**: specialization, availability  
- **Appointment**: schedule details, doctor-patient link  
- **PharmacyItem**: name, stock, expiry, supplier  
- **BillingRecord**: amount, services, payment status  
- **User**: login credentials, role  
- **FinancialTransaction**: income/expense details  
## Tech Stack
- **Frontend**: HTML, CSS, JavaScript  
- **Backend**: PHP  
- **Database**: MySQL  
- **Server**: XAMPP 
- **Security**: PHP sessions, password hashing
## Team Members and Roles
| **Member**                 |**Project Role**                    | **Responsibilities**  |
|---------------------------|-------------------------------------|-----------------------|
| **Đỗ Thị Hải Bình**       | Database Architect & Developer      | ERD design • Physical schema • Table creation • PK/FK design |
| **Lê Thảo Vy**            | MySQL Logic & Optimization Engineer | Stored procedures • Triggers • Views • Indexing • Query optimization |
| **Nguyễn Thị Phương Thảo**| Security & Testing Engineer         | MySQL users & privileges • RBAC enforcement • Password security • Testing workflow |
| **All Members**           | Web Integration & Reporting Dev     | Frontend–backend connection • Dashboards • Reports • Final refinement |

## Timeline (Planned Milestones)
| **Date Range**      | **Milestone / Work Package** |
|---------------------|------------------------------|
| **Dec 1**           | Team registration • Topic selection • GitHub setup • Draft requirements & core entities |
| **Dec 2 – Dec 5**   | Finalize system requirements • Define tech stack • Outline ERD & database schema |
| **Dec 6 – Dec 10**  | Build database (tables, PK/FK, constraints) • Implement backend: authentication, staff roles, patient CRUD |
| **Dec 11 – Dec 15** | Implement appointments, visits, prescriptions • Write stored procedures, triggers, indexes • Submit design document |
| **Dec 16 – Dec 18** | Frontend integration (HTML/CSS/JS) • Dashboard & reporting module |
| **Dec 19 – Dec 20** | System testing (RBAC, constraints, workflows) • Bug fixes & refinements |
| **Dec 21**          | Final integration • Documentation • Prepare presentation slides |
| **Dec 22**          | **Final submission & project presentation** |
