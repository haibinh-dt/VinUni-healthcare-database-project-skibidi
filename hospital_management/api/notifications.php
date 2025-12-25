<?php
/**
 * Notifications API
 * Handles notification retrieval and marking as read
 */

header('Content-Type: application/json');

require_once '../includes/session.php';
require_once '../config/database.php';

requireLogin();

$user = getCurrentUser();
$userId = $user['user_id'];

try {
    $db = new Database();
    $conn = $db->getConnection();
    
    // Handle POST requests (mark as read)
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = $_POST['action'] ?? '';
        
        if ($action === 'mark_all_read') {
            $db->callProcedure(
                'sp_mark_all_notifications_read',
                [$userId],
                []
            );
            
            echo json_encode(['success' => true, 'message' => 'All notifications marked as read']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
        }
        exit;
    }
    
    // Handle GET requests (retrieve notifications)
    // Get unread count
    $countResult = $db->queryView(
        'v_user_unread_notification_count',
        'user_id = ?',
        [$userId]
    );

    $unreadCount = $countResult[0]['unread_count'] ?? 0;

    
    // Get recent notifications (last 10)
    $notifications = $db->queryView(
        'v_user_notifications',
        'user_id = ? ORDER BY created_at DESC LIMIT 10',
        [$userId]
    );

    
    echo json_encode([
        'success' => true,
        'unread_count' => $unreadCount,
        'notifications' => $notifications
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error loading notifications',
        'error' => $e->getMessage()
    ]);
}
?>