# Guide to Recreating the Hospital Management System Web App

This guide provides step-by-step instructions to recreate the Hospital Management System (HMS) project, a web-based application for managing hospital operations including patient records, appointments, pharmacy inventory, billing, and user role management.

## Project Overview

The HMS is built using:
- **Backend**: MySQL database with stored procedures, triggers, and views
- **Frontend**: PHP-based web application with role-based access control
- **Architecture**: Modular design with separate modules for admin, doctor, finance, pharmacist, and receptionist roles

## Project Structure

```
project/
├── database/                           # Database setup scripts
│   ├── 01_db_setup.sql                 # Database creation
│   ├── 02_create_tables.sql            # Table definitions
│   ├── 03_views.sql                    # Database views
│   ├── 04_stored_procedures.sql        # Stored procedures
│   ├── 05_triggers.sql                 # Database triggers
│   ├── 06_expiry_check_event.sql       # Scheduled events
│   ├── 07_load_initial_sample_data.sql # Sample data
│   └── run_all.bat                     # Batch file to run all scripts
├── hospital_management/                # Main web application
│   ├── index.php                       # Main entry point (redirects based on role)
│   ├── login.php                       # User authentication
│   ├── api/                            # API endpoints
│   │   ├── export_audit_logs.php
│   │   ├── get_patient_emr.php
│   │   ├── logout.php
│   │   └── notifications.php
│   ├── assets/                         # Static assets
│   │   ├── css/
│   │   │   └── style.css
│   │   └── js/
│   │       └── main.js
│   ├── config/                         # Configuration files
│   │   └── database.php                # Database connection settings
│   ├── includes/                       # Shared PHP includes
│   │   ├── footer.php
│   │   ├── header.php
│   │   └── session.php                 # Session management
│   └── modules/                        # Role-based modules
│       ├── admin/                      # Administrator functions
│       │   ├── analytics.php
│       │   ├── audit_logs.php
│       │   ├── dashboard.php
│       │   └── users.php
│       ├── doctor/                     # Doctor functions
│       │   ├── appointments.php
│       │   ├── dashboard.php
│       │   ├── patients.php
│       │   └── visit_detail.php
│       ├── finance/                    # Finance functions
│       │   ├── dashboard.php
│       │   ├── invoices.php
│       │   ├── payments.php
│       │   └── reports.php
│       ├── pharmacist/                 # Pharmacist functions
│       │   ├── alerts.php
│       │   ├── dashboard.php
│       │   ├── dispense.php
│       │   └── inventory.php
│       └── receptionist/               # Receptionist functions
│           ├── appointments.php
│           ├── check_in.php
│           ├── dashboard.php1
│           └── patients.php
├── indexing_perf_demo.sql              # Performance demonstration scripts
├── partitioning_perf_demo.sql          # Partitioning examples
├── project_guide.md                    # This guide
└── README.md                           # Project documentation
```

## Prerequisites

Before setting up the project, ensure you have the following installed:

1. **Web Server**: Apache
2. **PHP**: Version 7.4 or higher with PDO extension enabled
3. **MySQL**: Version 5.7 or higher (MariaDB also works)
4. **Development Environment**: XAMPP (includes Apache, PHP, and MySQL)

### How to Download & Install XAMPP

1. Go to: https://www.apachefriends.org
2. Download XAMPP for Windows
3. Run the installer
4. During installation, make sure Apache and MySQL are selected
5. Finish installation

## Step-by-Step Setup Instructions

### Step 1: Database Setup

1. **Start Apache & MySQL**
- Open XAMPP Control Panel
- Click Start for:
    - Apache
    - MySQL
- Ensure both services show status Running (green)

2. **Access MySQL Command Line**
- Open command prompt/terminal
- Navigate to MySQL bin directory in XAMPP folder
```
cd C:\xampp\mysql\bin    # Example directory
```
- Login as root user (choose one of the two commands below):
```
.\mysql.exe -u root      # For default new user (no password)
.\mysql.exe -u root -p   # For users with password
```

3. **Create Database and Tables**
- Edit `run_all.bat`:
    - Paste your full project/database path into this placeholder:
    ```
    set "SQL_DIR=PUT_YOUR_PROJECT/DATABASE_PATH_HERE"
    ```
    - Make sure this line matches your MySQL path:
    ```
    C:\xampp\mysql\bin\mysql.exe    # default
    ```
- Double-click on `run_all.bat` to execute all `.sql` files

### Step 2: Web Application Setup

1. **Place Files in `htdocs`**  
XAMPP serves PHP projects from the `htdocs` directory.
- Copy the `hospital_management` folder to `htdocs` in the `xampp` folder.  
- Default path: `C:\xampp\htdocs\hospital_management\`

2. **Configure Database Connection**
- Open `hospital_management/config/database.php`
- Update database credentials if different from defaults:
    ```php
    private $host = "localhost";
    private $db_name = "hospital_management_system";
    private $username = "root";  // Change if different
    private $password = "";      // Change if you have a password
    ```

### Step 3: Access the Application

1. **Access Application**
- Open web browser
- Navigate to: `http://localhost/hospital_management/login.php`
- Use the demo credentials already shown on login page

2. **Access the Database**
- Open: `http://localhost/phpmyadmin`
- You will see the `hospital_management_system` database if set up correctly.

## Key Features and Modules

### User Roles and Permissions
- **Admin**: Full system access, user management, analytics
- **Doctor**: Patient management, appointments, medical records
- **Receptionist**: Appointment scheduling, patient check-in
- **Pharmacist**: Inventory management, prescription dispensing
- **Finance**: Billing, payments, financial reports

### Database Features
- **Normalization**: 3NF compliant schema
- **Security**: Role-based access control, audit logging
- **Performance**: Indexes, stored procedures, triggers
- **Integrity**: Foreign key constraints, cascading rules

### Web Application Features
- **Responsive Design**: CSS-based styling
- **Session Management**: Secure PHP sessions
- **API Endpoints**: JSON-based data exchange
- **Modular Architecture**: Organized by user roles

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Verify MySQL is running
   - Check credentials in `config/database.php`
   - Ensure database exists

2. **Permission Errors**
   - Check file permissions
   - Verify web server user has access to files

3. **PHP Errors**
   - Enable error reporting in PHP configuration
   - Check PHP logs for detailed error messages

4. **Blank Pages**
   - Check PHP syntax errors
   - Verify all required files are present

### Performance Optimization

Run the indexing and partitioning demo scripts to understand performance improvements  
```
indexing_perf_demo.sql
partitioning_perf_demo.sql
```

## Development Notes

- The application uses PDO for database interactions
- Triggers automatically handle audit logging and stock management
- The system supports Vietnamese characters through UTF8MB4 encoding