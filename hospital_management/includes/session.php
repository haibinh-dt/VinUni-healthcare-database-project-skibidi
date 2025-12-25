<?php
/**
 * Session Management
 * Handles user authentication and role-based access
 */

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Check if user is logged in
 */
function isLoggedIn() {
    return isset($_SESSION['user_id']) && isset($_SESSION['role']);
}

/**
 * Require login - redirect if not authenticated
 */
function requireLogin() {
    if (!isLoggedIn()) {
        header("Location: /hospital_management/login.php");
        exit();
    }
}

/**
 * Require specific role - redirect if wrong role
 */
function requireRole($allowedRoles) {
    requireLogin();
    
    if (!is_array($allowedRoles)) {
        $allowedRoles = [$allowedRoles];
    }
    
    if (!in_array($_SESSION['role'], $allowedRoles)) {
        header("Location: /hospital_management/index.php");
        exit();
    }
}

/**
 * Get current user data
 */
function getCurrentUser() {
    if (!isLoggedIn()) {
        return null;
    }
    
    return [
        'user_id' => $_SESSION['user_id'],
        'username' => $_SESSION['username'] ?? null,
        'role' => $_SESSION['role']
    ];
}

/**
 * Get dashboard path for role
 */
function getDashboardPath($role) {
    $role = strtolower($role);
    return "/hospital_management/modules/$role/dashboard.php";
}

/**
 * Logout user
 */
function logout() {
    session_unset();
    session_destroy();
    header("Location: /hospital_management/login.php");
    exit();
}

/**
 * Set flash message
 */
function setFlashMessage($message, $type = 'info') {
    $_SESSION['flash_message'] = $message;
    $_SESSION['flash_type'] = $type;
}

/**
 * Get and clear flash message
 */
function getFlashMessage() {
    if (isset($_SESSION['flash_message'])) {
        $message = [
            'text' => $_SESSION['flash_message'],
            'type' => $_SESSION['flash_type'] ?? 'info'
        ];
        unset($_SESSION['flash_message']);
        unset($_SESSION['flash_type']);
        return $message;
    }
    return null;
}
?>