## PROJECT STRUCTURE OVERVIEW
hospital_management/
├── config/          # Database connectivity
├── includes/        # Reusable page components
├── assets/          # Frontend resources (CSS, JS)
├── modules/         # Role-specific pages (5 roles × 4 pages each)
├── api/             # AJAX endpoints
├── index.php        # Entry point/router
└── login.php        # Authentication

### `Config/`
- `database.php`: database configuration + central management using PDO

### `login.php`
- call sp_verify_login

### index.php
Routes to appropriate dashboard based on role
### includes/
#### session.php
Session management: Handles user authentication and role-based access
#### header.php footer.php
reusable components

### api/
#### notifications.php
 call sp_mark_all_notifications_read
 v_user_unread_notification_count
 v_user_notifications

### admin/
#### dashboard.php
views:  
- v_user_security_activity
- v_doctor_performance
- v_patient_visit_frequency
- v_daily_appointments
- v_audit_readable_log
- v_user_role_directory

#### users.php
views:
- v_user_role_directory
sp:
- sp_deactivate_user
- sp_create_user_with_default_password

#### audit_logs.php
- v_audit_readable_log

#### analytics.php
- v_daily_appointments
- v_doctor_performance
- v_patient_visit_frequency
- v_service_popularity

### doctor/
#### dashboard.php
- v_doctor_schedule_detail
- v_doctor_schedule_summary
- v_patient_medical_history

#### appointments.php
- v_doctor_schedule_detail

#### 