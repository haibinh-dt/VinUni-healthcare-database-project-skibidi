<?php
/**
 * Index Page - Routes to appropriate dashboard based on role
 */

require_once 'includes/session.php';

// Require login
requireLogin();

// Get current user
$user = getCurrentUser();

// Redirect to role-specific dashboard
$dashboardPath = getDashboardPath($user['role']);
header("Location: $dashboardPath");
exit();
?>