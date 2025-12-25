<?php
require_once __DIR__ . '/session.php';
requireLogin();

$currentUser = getCurrentUser();
$role = $currentUser['role'];
$username = $currentUser['username'];

// Get role-specific menu items
$menuItems = [];
switch(strtolower($role)) {
    case 'admin':
        $menuItems = [
            ['name' => 'Dashboard', 'icon' => 'tachometer-alt', 'url' => '/hospital_management/modules/admin/dashboard.php'],
            ['name' => 'Users', 'icon' => 'users', 'url' => '/hospital_management/modules/admin/users.php'],
            ['name' => 'Audit Logs', 'icon' => 'clipboard-list', 'url' => '/hospital_management/modules/admin/audit_logs.php'],
            ['name' => 'Analytics', 'icon' => 'chart-line', 'url' => '/hospital_management/modules/admin/analytics.php'],
        ];
        break;
    case 'doctor':
        $menuItems = [
            ['name' => 'Dashboard', 'icon' => 'tachometer-alt', 'url' => '/hospital_management/modules/doctor/dashboard.php'],
            ['name' => 'Appointments', 'icon' => 'calendar-check', 'url' => '/hospital_management/modules/doctor/appointments.php'],
            ['name' => 'Patients', 'icon' => 'user-injured', 'url' => '/hospital_management/modules/doctor/patients.php'],
        ];
        break;
    case 'pharmacist':
        $menuItems = [
            ['name' => 'Dashboard', 'icon' => 'tachometer-alt', 'url' => '/hospital_management/modules/pharmacist/dashboard.php'],
            ['name' => 'Inventory', 'icon' => 'boxes', 'url' => '/hospital_management/modules/pharmacist/inventory.php'],
            ['name' => 'Dispense', 'icon' => 'prescription-bottle', 'url' => '/hospital_management/modules/pharmacist/dispense.php'],
            ['name' => 'Alerts', 'icon' => 'exclamation-triangle', 'url' => '/hospital_management/modules/pharmacist/alerts.php'],
        ];
        break;
    case 'finance':
        $menuItems = [
            ['name' => 'Dashboard', 'icon' => 'tachometer-alt', 'url' => '/hospital_management/modules/finance/dashboard.php'],
            ['name' => 'Invoices', 'icon' => 'file-invoice-dollar', 'url' => '/hospital_management/modules/finance/invoices.php'],
            ['name' => 'Payments', 'icon' => 'money-bill-wave', 'url' => '/hospital_management/modules/finance/payments.php'],
            ['name' => 'Reports', 'icon' => 'chart-bar', 'url' => '/hospital_management/modules/finance/reports.php'],
        ];
        break;
    case 'receptionist':
        $menuItems = [
            ['name' => 'Dashboard', 'icon' => 'tachometer-alt', 'url' => '/hospital_management/modules/receptionist/dashboard.php'],
            ['name' => 'Patients', 'icon' => 'users', 'url' => '/hospital_management/modules/receptionist/patients.php'],
            ['name' => 'Appointments', 'icon' => 'calendar-alt', 'url' => '/hospital_management/modules/receptionist/appointments.php'],
            ['name' => 'Check-In', 'icon' => 'clipboard-check', 'url' => '/hospital_management/modules/receptionist/check_in.php'],
        ];
        break;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $pageTitle ?? 'Hospital Management System'; ?></title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="/hospital_management/assets/css/style.css">
</head>
<body>
    <div class="wrapper">
        <!-- Sidebar -->
        <nav id="sidebar" class="bg-dark">
            <div class="sidebar-header">
                <h3><i class="fas fa-hospital"></i> HMS</h3>
                <small class="text-muted"><?php echo ucfirst($role); ?> Portal</small>
            </div>
            
            <ul class="list-unstyled components">
                <?php foreach($menuItems as $item): ?>
                <li>
                    <a href="<?php echo $item['url']; ?>">
                        <i class="fas fa-<?php echo $item['icon']; ?>"></i>
                        <?php echo $item['name']; ?>
                    </a>
                </li>
                <?php endforeach; ?>
            </ul>
        </nav>

        <!-- Page Content -->
        <div id="content">
            <!-- Top Navigation Bar -->
            <nav class="navbar navbar-expand-lg navbar-light bg-light">
                <div class="container-fluid">
                    <button type="button" id="sidebarCollapse" class="btn btn-info">
                        <i class="fas fa-bars"></i>
                    </button>
                    
                    <div class="ms-auto d-flex align-items-center">
                        <div class="dropdown me-3">
                            <button class="btn btn-link text-decoration-none" type="button" id="notificationDropdown" data-bs-toggle="dropdown">
                                <i class="fas fa-bell fa-lg"></i>
                                <span class="badge bg-danger" id="notificationCount">0</span>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end" id="notificationList">
                                <li><span class="dropdown-item-text">No new notifications</span></li>
                            </ul>
                        </div>
                        
                        <div class="dropdown">
                            <button class="btn btn-link text-decoration-none text-dark" type="button" id="userDropdown" data-bs-toggle="dropdown">
                                <i class="fas fa-user-circle fa-lg"></i>
                                <span class="ms-2"><?php echo htmlspecialchars($username); ?></span>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><span class="dropdown-item-text"><strong><?php echo ucfirst($role); ?></strong></span></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="/hospital_management/api/logout.php"><i class="fas fa-sign-out-alt"></i> Logout</a></li>
                            </ul>
                        </div>
                    </div>
                </div>
            </nav>

            <!-- Flash Messages -->
            <?php if (isset($_SESSION['flash_message'])): ?>
                <?php 
                    $flash = $_SESSION['flash_message'];
                    $msgText = is_array($flash) ? $flash['text'] : $flash;
                    $msgClass = (is_array($flash) && isset($flash['type'])) ? $flash['type'] : 'info';
                ?>
                <div class="alert alert-<?php echo $msgClass; ?> alert-dismissible fade show" role="alert">
                    <?php echo htmlspecialchars($msgText); ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <?php unset($_SESSION['flash_message']); ?>
            <?php endif; ?>

            <!-- Main Content Area -->
            <div class="container-fluid p-4">