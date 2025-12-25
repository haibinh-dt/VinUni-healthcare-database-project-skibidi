<?php
$pageTitle = "Audit Logs";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('ADMIN');

$db = new Database();
$conn = $db->getConnection();

// Pagination
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = 50;
$offset = ($page - 1) * $perPage;

// Filters
$filterUser = $_GET['user'] ?? '';
$filterAction = $_GET['action'] ?? '';
$filterTable = $_GET['table'] ?? '';
$filterDateFrom = $_GET['date_from'] ?? '';
$filterDateTo = $_GET['date_to'] ?? '';

// Build WHERE clause
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

$whereClause = '';
if (!empty($whereConditions)) {
    $whereClause = 'WHERE ' . implode(' AND ', $whereConditions);
}

// Get total count
$allRecords = $db->queryView("v_audit_readable_log", $whereClause, $params);
$totalRecords = count($allRecords);
$totalPages = ceil($totalRecords / $perPage);

// Get audit logs
$limitStr = "$offset, $perPage"; 
$auditLogs = $db->queryView(
    "v_audit_readable_log", 
    $whereClause, 
    $params, 
    "changed_at DESC", 
    $limitStr
);

// Get distinct users for filter
$stmt = $conn->query("SELECT DISTINCT username FROM User ORDER BY username");
$users = $stmt->fetchAll();

// Get distinct tables for filter
$stmt = $conn->query("SELECT DISTINCT table_name FROM AuditLog ORDER BY table_name");
$tables = $stmt->fetchAll();
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="fas fa-clipboard-list"></i> System Audit Logs</h2>
    <a class="btn btn-secondary"
    href="../../api/export_audit_logs.php?<?php echo http_build_query($_GET); ?>">
        <i class="fas fa-download"></i> Export Logs
    </a>
</div>

<!-- Statistics -->
<div class="row mb-4">
    <?php
    $where = "DATE(changed_at) = CURDATE()";
    $auditToday = $db->queryView("v_audit_readable_log", $where);
    $todayStats = [
        'total' => count($auditToday),
        'inserts' => count(array_filter($auditToday, fn($log) => $log['action_type'] === 'INSERT')),
        'updates' => count(array_filter($auditToday, fn($log) => $log['action_type'] === 'UPDATE')),
        'deletes' => count(array_filter($auditToday, fn($log) => $log['action_type'] === 'DELETE')),
    ];
    ?>
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo $todayStats['total']; ?></h3>
            <p>Total Actions Today</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo $todayStats['inserts']; ?></h3>
            <p>Inserts</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <h3><?php echo $todayStats['updates']; ?></h3>
            <p>Updates</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-danger text-white">
            <h3><?php echo $todayStats['deletes']; ?></h3>
            <p>Deletes</p>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card mb-4">
    <div class="card-header">
        <i class="fas fa-filter"></i> Filters
    </div>
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-3">
                <label class="form-label">User</label>
                <select class="form-select" name="user">
                    <option value="">All Users</option>
                    <?php foreach($users as $user): ?>
                        <option value="<?php echo htmlspecialchars($user['username']); ?>"
                                <?php echo $filterUser === $user['username'] ? 'selected' : ''; ?>>
                            <?php echo htmlspecialchars($user['username']); ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            
            <div class="col-md-2">
                <label class="form-label">Action Type</label>
                <select class="form-select" name="action">
                    <option value="">All Actions</option>
                    <option value="INSERT" <?php echo $filterAction === 'INSERT' ? 'selected' : ''; ?>>INSERT</option>
                    <option value="UPDATE" <?php echo $filterAction === 'UPDATE' ? 'selected' : ''; ?>>UPDATE</option>
                    <option value="DELETE" <?php echo $filterAction === 'DELETE' ? 'selected' : ''; ?>>DELETE</option>
                </select>
            </div>
            
            <div class="col-md-2">
                <label class="form-label">Table</label>
                <select class="form-select" name="table">
                    <option value="">All Tables</option>
                    <?php foreach($tables as $table): ?>
                        <option value="<?php echo htmlspecialchars($table['table_name']); ?>"
                                <?php echo $filterTable === $table['table_name'] ? 'selected' : ''; ?>>
                            <?php echo htmlspecialchars($table['table_name']); ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            
            <div class="col-md-2">
                <label class="form-label">Date From</label>
                <input type="date" class="form-control" name="date_from" value="<?php echo $filterDateFrom; ?>">
            </div>
            
            <div class="col-md-2">
                <label class="form-label">Date To</label>
                <input type="date" class="form-control" name="date_to" value="<?php echo $filterDateTo; ?>">
            </div>
            
            <div class="col-md-1 d-flex align-items-end">
                <button type="submit" class="btn btn-primary w-100">
                    <i class="fas fa-search"></i>
                </button>
            </div>
        </form>
        
        <?php if($filterUser || $filterAction || $filterTable || $filterDateFrom || $filterDateTo): ?>
            <div class="mt-3">
                <a href="audit_logs.php" class="btn btn-secondary btn-sm">
                    <i class="fas fa-times"></i> Clear Filters
                </a>
            </div>
        <?php endif; ?>
    </div>
</div>

<!-- Audit Log Table -->
<div class="card">
    <div class="card-header">
        <i class="fas fa-list"></i> Audit Trail
        <span class="badge bg-secondary"><?php echo $totalRecords; ?> records</span>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover table-sm">
                <thead>
                    <tr>
                        <th>Timestamp</th>
                        <th>User</th>
                        <th>Action</th>
                        <th>Table</th>
                        <th>Field</th>
                        <th>Old Value</th>
                        <th>New Value</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if(empty($auditLogs)): ?>
                        <tr>
                            <td colspan="7" class="text-center text-muted">No audit logs found</td>
                        </tr>
                    <?php else: ?>
                        <?php foreach($auditLogs as $log): ?>
                        <tr>
                            <td>
                                <small><?php echo date('M d, Y H:i:s', strtotime($log['changed_at'])); ?></small>
                            </td>
                            <td>
                                <i class="fas fa-user"></i>
                                <strong><?php echo htmlspecialchars($log['performer']); ?></strong>
                            </td>
                            <td>
                                <span class="badge bg-<?php 
                                    echo $log['action_type'] === 'INSERT' ? 'success' : 
                                        ($log['action_type'] === 'DELETE' ? 'danger' : 'info'); 
                                ?>">
                                    <?php echo $log['action_type']; ?>
                                </span>
                            </td>
                            <td><code><?php echo htmlspecialchars($log['table_name']); ?></code></td>
                            <td><?php echo htmlspecialchars($log['field_name'] ?? '-'); ?></td>
                            <td>
                                <small class="text-muted">
                                    <?php 
                                    $oldVal = $log['old_value'];
                                    echo $oldVal ? (strlen($oldVal) > 30 ? substr($oldVal, 0, 30) . '...' : $oldVal) : '-';
                                    ?>
                                </small>
                            </td>
                            <td>
                                <small>
                                    <?php 
                                    $newVal = $log['new_value'];
                                    echo $newVal ? (strlen($newVal) > 30 ? substr($newVal, 0, 30) . '...' : $newVal) : '-';
                                    ?>
                                </small>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
        
        <!-- Pagination -->
        <?php if($totalPages > 1): ?>
        <nav class="mt-3">
            <ul class="pagination justify-content-center">
                <li class="page-item <?php echo $page <= 1 ? 'disabled' : ''; ?>">
                    <a class="page-link" href="?page=<?php echo $page - 1; ?>&<?php echo http_build_query(array_filter($_GET, fn($k) => $k !== 'page', ARRAY_FILTER_USE_KEY)); ?>">
                        Previous
                    </a>
                </li>
                
                <?php for($i = max(1, $page - 2); $i <= min($totalPages, $page + 2); $i++): ?>
                    <li class="page-item <?php echo $i === $page ? 'active' : ''; ?>">
                        <a class="page-link" href="?page=<?php echo $i; ?>&<?php echo http_build_query(array_filter($_GET, fn($k) => $k !== 'page', ARRAY_FILTER_USE_KEY)); ?>">
                            <?php echo $i; ?>
                        </a>
                    </li>
                <?php endfor; ?>
                
                <li class="page-item <?php echo $page >= $totalPages ? 'disabled' : ''; ?>">
                    <a class="page-link" href="?page=<?php echo $page + 1; ?>&<?php echo http_build_query(array_filter($_GET, fn($k) => $k !== 'page', ARRAY_FILTER_USE_KEY)); ?>">
                        Next
                    </a>
                </li>
            </ul>
        </nav>
        <?php endif; ?>
    </div>
</div>

<?php

require_once '../../includes/footer.php';
?>