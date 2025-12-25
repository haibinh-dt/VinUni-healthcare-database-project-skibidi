<?php
$pageTitle = "Inventory Alerts";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('PHARMACIST');

$db = new Database();
$conn = $db->getConnection();

// Get all stock alerts
$stmt = $conn->query("SELECT * FROM v_pharmacy_stock_alerts ORDER BY stock_status, total_stock");
$stockAlerts = $stmt->fetchAll();

// Get expiring items (next 30 days)
$stmt = $conn->query("
    SELECT * FROM v_inventory_batch_status 
    WHERE is_expired = FALSE 
    AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
    ORDER BY expiry_date
");
$expiringItems = $stmt->fetchAll();

// Get expired items
$stmt = $conn->query("
    SELECT * FROM v_inventory_batch_status 
    WHERE is_expired = TRUE 
    AND current_stock > 0
    ORDER BY expiry_date DESC
");
$expiredItems = $stmt->fetchAll();

// Count alerts by severity
$critical = count(array_filter($stockAlerts, fn($a) => $a['stock_status'] === 'CRITICAL'));
$low = count(array_filter($stockAlerts, fn($a) => $a['stock_status'] === 'LOW'));
$expiringSoon = count($expiringItems);
$expired = count($expiredItems);
?>

<h2><i class="fas fa-exclamation-triangle"></i> Inventory Alerts & Warnings</h2>

<!-- Alert Summary -->
<div class="row mt-4">
    <div class="col-md-3">
        <div class="kpi-card bg-danger text-white">
            <h3><?php echo $critical; ?></h3>
            <p>Critical Stock Levels</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-warning text-white">
            <h3><?php echo $low; ?></h3>
            <p>Low Stock Items</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <h3><?php echo $expiringSoon; ?></h3>
            <p>Expiring in 30 Days</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-dark text-white">
            <h3><?php echo $expired; ?></h3>
            <p>Expired Items</p>
        </div>
    </div>
</div>

<!-- Tabs -->
<ul class="nav nav-tabs mt-4" role="tablist">
    <li class="nav-item">
        <a class="nav-link active" data-bs-toggle="tab" href="#stock-alerts">
            <i class="fas fa-boxes"></i> Stock Alerts
            <?php if ($critical + $low > 0): ?>
                <span class="badge bg-danger"><?php echo $critical + $low; ?></span>
            <?php endif; ?>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link" data-bs-toggle="tab" href="#expiring">
            <i class="fas fa-hourglass-half"></i> Expiring Soon
            <?php if ($expiringSoon > 0): ?>
                <span class="badge bg-warning"><?php echo $expiringSoon; ?></span>
            <?php endif; ?>
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link" data-bs-toggle="tab" href="#expired">
            <i class="fas fa-ban"></i> Expired Items
            <?php if ($expired > 0): ?>
                <span class="badge bg-dark"><?php echo $expired; ?></span>
            <?php endif; ?>
        </a>
    </li>
</ul>

<div class="tab-content mt-3">
    <!-- Stock Alerts Tab -->
    <div class="tab-pane fade show active" id="stock-alerts">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-exclamation-circle"></i> Stock Level Alerts
            </div>
            <div class="card-body">
                <?php if (empty($stockAlerts)): ?>
                    <div class="alert alert-success text-center">
                        <i class="fas fa-check-circle"></i> All items have healthy stock levels!
                    </div>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Item Name</th>
                                    <th class="text-center">Current Stock</th>
                                    <th>Nearest Expiry</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($stockAlerts as $alert): ?>
                                <tr class="<?php echo $alert['stock_status'] === 'CRITICAL' ? 'table-danger' : ($alert['stock_status'] === 'LOW' ? 'table-warning' : ''); ?>">
                                    <td><strong><?php echo htmlspecialchars($alert['item_name']); ?></strong></td>
                                    <td class="text-center">
                                        <span class="badge bg-<?php echo $alert['stock_status'] === 'CRITICAL' ? 'danger' : ($alert['stock_status'] === 'LOW' ? 'warning' : 'success'); ?>">
                                            <?php echo $alert['total_stock']; ?> units
                                        </span>
                                    </td>
                                    <td>
                                        <?php if ($alert['nearest_expiry']): ?>
                                            <?php echo date('M d, Y', strtotime($alert['nearest_expiry'])); ?>
                                        <?php else: ?>
                                            <span class="text-muted">N/A</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?php 
                                            echo $alert['stock_status'] === 'CRITICAL' ? 'danger' : 
                                                ($alert['stock_status'] === 'LOW' ? 'warning' : 'success'); 
                                        ?>">
                                            <?php echo $alert['stock_status']; ?>
                                        </span>
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
    
    <!-- Expiring Tab -->
    <div class="tab-pane fade" id="expiring">
        <div class="card">
            <div class="card-header bg-warning">
                <i class="fas fa-clock"></i> Items Expiring in Next 30 Days
            </div>
            <div class="card-body">
                <?php if (empty($expiringItems)): ?>
                    <div class="alert alert-success text-center">
                        <i class="fas fa-check-circle"></i> No items expiring in the next 30 days!
                    </div>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Item Name</th>
                                    <th>Batch Number</th>
                                    <th>Supplier</th>
                                    <th>Current Stock</th>
                                    <th>Expiry Date</th>
                                    <th>Days Until Expiry</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($expiringItems as $item): ?>
                                <?php
                                $daysUntilExpiry = floor((strtotime($item['expiry_date']) - time()) / 86400);
                                $urgency = $daysUntilExpiry < 7 ? 'danger' : ($daysUntilExpiry < 14 ? 'warning' : 'info');
                                ?>
                                <tr class="table-<?php echo $urgency; ?>">
                                    <td><strong><?php echo htmlspecialchars($item['item_name']); ?></strong></td>
                                    <td><?php echo htmlspecialchars($item['batch_number']); ?></td>
                                    <td><?php echo htmlspecialchars($item['supplier_name']); ?></td>
                                    <td><?php echo $item['current_stock']; ?> units</td>
                                    <td><?php echo date('M d, Y', strtotime($item['expiry_date'])); ?></td>
                                    <td>
                                        <span class="badge bg-<?php echo $urgency; ?>">
                                            <?php echo $daysUntilExpiry; ?> days
                                        </span>
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
    
    <!-- Expired Tab -->
    <div class="tab-pane fade" id="expired">
        <div class="card">
            <div class="card-header bg-danger text-white">
                <i class="fas fa-ban"></i> Expired Items - DO NOT DISPENSE
            </div>
            <div class="card-body">
                <?php if (empty($expiredItems)): ?>
                    <div class="alert alert-success text-center">
                        <i class="fas fa-check-circle"></i> No expired items in inventory!
                    </div>
                <?php else: ?>
                    <div class="alert alert-danger">
                        <i class="fas fa-exclamation-triangle"></i> 
                        <strong>WARNING:</strong> These items have expired and must be removed from inventory immediately. 
                        Do NOT dispense these medications under any circumstances.
                    </div>
                    
                    <div class="table-responsive">
                        <table class="table table-hover table-danger">
                            <thead>
                                <tr>
                                    <th>Item Name</th>
                                    <th>Batch Number</th>
                                    <th>Supplier</th>
                                    <th>Current Stock</th>
                                    <th>Expired Date</th>
                                    <th>Days Expired</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($expiredItems as $item): ?>
                                <?php
                                $daysExpired = floor((time() - strtotime($item['expiry_date'])) / 86400);
                                ?>
                                <tr>
                                    <td><strong><?php echo htmlspecialchars($item['item_name']); ?></strong></td>
                                    <td><?php echo htmlspecialchars($item['batch_number']); ?></td>
                                    <td><?php echo htmlspecialchars($item['supplier_name']); ?></td>
                                    <td><?php echo $item['current_stock']; ?> units</td>
                                    <td><?php echo date('M d, Y', strtotime($item['expiry_date'])); ?></td>
                                    <td>
                                        <span class="badge bg-dark">
                                            <?php echo $daysExpired; ?> days ago
                                        </span>
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
</div>

<?php
$pageScripts = "
<script>
    function orderStock(itemId, itemName) {
        alert('Stock Order System\\n\\nIn production, this would:\\n1. Create purchase order\\n2. Notify suppliers\\n3. Track order status\\n\\nItem: ' + itemName + '\\nID: ' + itemId);
    }
    
    function markForDisposal(batchId, itemName) {
        if (confirm('Mark batch for disposal?\\n\\nItem: ' + itemName + '\\nBatch ID: ' + batchId + '\\n\\nThis will flag the batch as needing disposal.')) {
            alert('In production, this would:\\n1. Flag batch in system\\n2. Prevent dispensing\\n3. Generate disposal report\\n4. Notify management');
        }
    }
</script>
";

require_once '../../includes/footer.php';
?>