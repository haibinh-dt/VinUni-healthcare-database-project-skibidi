<?php
require_once '../includes/session.php';
require_once '../config/database.php';

requireRole('ADMIN');

$db = new Database();
$conn = $db->getConnection();

// Collect filters (same as audit_logs.php)
$filterUser = $_GET['user'] ?? '';
$filterAction = $_GET['action'] ?? '';
$filterTable = $_GET['table'] ?? '';
$filterDateFrom = $_GET['date_from'] ?? '';
$filterDateTo = $_GET['date_to'] ?? '';

$whereConditions = [];
$params = [];

if ($filterUser) {
    $whereConditions[] = "performer LIKE ?";
    $params[] = "%$filterUser%";
}

if ($filterAction) {
    $whereConditions[] = "action_type = ?";
    $params[] = $filterAction;
}

if ($filterTable) {
    $whereConditions[] = "table_name LIKE ?";
    $params[] = "%$filterTable%";
}

if ($filterDateFrom) {
    $whereConditions[] = "DATE(changed_at) >= ?";
    $params[] = $filterDateFrom;
}

if ($filterDateTo) {
    $whereConditions[] = "DATE(changed_at) <= ?";
    $params[] = $filterDateTo;
}

$whereClause = $whereConditions
    ? 'WHERE ' . implode(' AND ', $whereConditions)
    : '';

// Fetch data
$sql = "SELECT changed_at, performer, action_type, table_name, field_name, old_value, new_value
        FROM v_audit_readable_log
        $whereClause
        ORDER BY changed_at DESC";

$stmt = $conn->prepare($sql);
$stmt->execute($params);

// CSV headers
header('Content-Type: text/csv');
header('Content-Disposition: attachment; filename="audit_logs_' . date('Ymd_His') . '.csv"');
header('Pragma: no-cache');
header('Expires: 0');

$output = fopen('php://output', 'w');

// Column headers
fputcsv($output, [
    'Timestamp',
    'User',
    'Action',
    'Table',
    'Field',
    'Old Value',
    'New Value'
]);

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    fputcsv($output, $row);
}

fclose($output);
exit;
