<?php
$pageTitle = "Pharmacist Dashboard";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('PHARMACIST');

$db = new Database();
$conn = $db->getConnection();

// Get today's prescriptions
$stmt = $conn->query("
    SELECT * FROM v_prescription_for_pharmacy 
    WHERE DATE(prescribed_at) = CURDATE()
    ORDER BY prescribed_at DESC
");
$todayPrescriptions = $stmt->fetchAll();

// Get stock alerts
$stmt = $conn->query("SELECT * FROM v_pharmacy_stock_alerts WHERE stock_status IN ('CRITICAL', 'LOW')");
$stockAlerts = $stmt->fetchAll();

// Get expiring items (next 30 days)
$stmt = $conn->query("
    SELECT * FROM v_inventory_batch_status 
    WHERE is_expired = FALSE 
    AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
    ORDER BY expiry_date
");
$expiringItems = $stmt->fetchAll();

// Statistics
$stmt = $conn->query("SELECT COUNT(*) as count FROM PharmacyItem");
$totalItems = $stmt->fetch()['count'];

$stmt = $conn->query("SELECT COUNT(*) as count FROM v_pharmacy_stock_alerts WHERE stock_status = 'CRITICAL'");
$criticalStock = $stmt->fetch()['count'];

$stmt = $conn->query("
    SELECT COUNT(*) as count FROM PharmacyBatch 
    WHERE expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) 
    AND expiry_date > CURDATE()
    AND quantity > 0
");
$expiringSoon = $stmt->fetch()['count'];

$stmt = $conn->query("
    SELECT COUNT(*) as count FROM PharmacyBatch 
    WHERE expiry_date <= CURDATE() AND quantity > 0
");
$expired = $stmt->fetch()['count'];
?>

<!-- KPI Cards -->
<div class="row">
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Today's Prescriptions</p>
                    <h3><?php echo count($todayPrescriptions); ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-prescription"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-danger text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Critical Stock</p>
                    <h3><?php echo $criticalStock; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-warning text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Expiring Soon (30d)</p>
                    <h3><?php echo $expiringSoon; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-hourglass-half"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-dark text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Expired Items</p>
                    <h3><?php echo $expired; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-ban"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Main Content -->
<div class="row mt-4">
    <!-- Today's Prescriptions -->
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-prescription-bottle"></i> Today's Prescriptions
            </div>
            <div class="card-body" style="max-height: 500px; overflow-y: auto;">
                <?php if (empty($todayPrescriptions)): ?>
                    <p class="text-muted text-center">No prescriptions today</p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover table-sm">
                            <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>Patient</th>
                                    <th>Doctor</th>
                                    <th>Medication</th>
                                    <th>Qty</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($todayPrescriptions as $rx): ?>
                                <tr>
                                    <td><?php echo date('H:i', strtotime($rx['prescribed_at'])); ?></td>
                                    <td><?php echo htmlspecialchars($rx['patient_name']); ?></td>
                                    <td><small><?php echo htmlspecialchars($rx['doctor_name']); ?></small></td>
                                    <td><strong><?php echo htmlspecialchars($rx['item_name']); ?></strong></td>
                                    <td><span class="badge bg-info"><?php echo $rx['quantity']; ?></span></td>
                                    <td>
                                        <a href="dispense.php?prescription_id=<?php echo $rx['prescription_id']; ?>" 
                                           class="btn btn-sm btn-primary">
                                            <i class="fas fa-pills"></i> Dispense
                                        </a>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <!-- Alerts Sidebar -->
    <div class="col-md-4">
        <!-- Stock Alerts -->
        <div class="card mb-3">
            <div class="card-header bg-danger text-white">
                <i class="fas fa-exclamation-circle"></i> Stock Alerts
            </div>
            <div class="card-body" style="max-height: 250px; overflow-y: auto;">
                <?php if (empty($stockAlerts)): ?>
                    <p class="text-muted text-center">No stock alerts</p>
                <?php else: ?>
                    <div class="list-group">
                        <?php foreach ($stockAlerts as $alert): ?>
                        <div class="list-group-item">
                            <div class="d-flex justify-content-between">
                                <strong><?php echo htmlspecialchars($alert['item_name']); ?></strong>
                                <span class="badge bg-<?php echo $alert['stock_status'] === 'CRITICAL' ? 'danger' : 'warning'; ?>">
                                    <?php echo $alert['total_stock']; ?> units
                                </span>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Expiring Items -->
        <div class="card">
            <div class="card-header bg-warning">
                <i class="fas fa-clock"></i> Expiring Soon
            </div>
            <div class="card-body" style="max-height: 200px; overflow-y: auto;">
                <?php if (empty($expiringItems)): ?>
                    <p class="text-muted text-center">No items expiring soon</p>
                <?php else: ?>
                    <div class="list-group">
                        <?php foreach (array_slice($expiringItems, 0, 5) as $item): ?>
                        <div class="list-group-item">
                            <div><strong><?php echo htmlspecialchars($item['item_name']); ?></strong></div>
                            <small class="text-muted">
                                Batch: <?php echo $item['batch_number']; ?><br>
                                Expires: <?php echo date('M d, Y', strtotime($item['expiry_date'])); ?>
                            </small>
                        </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- Quick Actions -->
<div class="row mt-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-bolt"></i> Quick Actions
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3">
                        <a href="inventory.php" class="btn btn-primary w-100 mb-2">
                            <i class="fas fa-boxes"></i> View Inventory
                        </a>
                    </div>
                    <div class="col-md-3">
                        <a href="dispense.php" class="btn btn-success w-100 mb-2">
                            <i class="fas fa-prescription-bottle"></i> Dispense Medication
                        </a>
                    </div>
                    <div class="col-md-3">
                        <a href="alerts.php" class="btn btn-warning w-100 mb-2">
                            <i class="fas fa-bell"></i> View All Alerts
                        </a>
                    </div>
                    <div class="col-md-3">
                        <button class="btn btn-info w-100 mb-2" onclick="window.location.reload()">
                            <i class="fas fa-sync-alt"></i> Refresh Dashboard
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>