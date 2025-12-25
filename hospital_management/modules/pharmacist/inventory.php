<?php
$pageTitle = "Pharmacy Inventory";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('PHARMACIST');

$db = new Database();
$conn = $db->getConnection();

// Get inventory status
$stmt = $conn->query("SELECT * FROM v_inventory_batch_status ORDER BY item_name, expiry_date");
$inventory = $stmt->fetchAll();

// Get stock alerts
$stmt = $conn->query("SELECT * FROM v_pharmacy_stock_alerts ORDER BY stock_status, total_stock");
$alerts = $stmt->fetchAll();
?>

<h2><i class="fas fa-boxes"></i> Pharmacy Inventory Management</h2>

<!-- Alert Summary -->
<div class="row mt-4">
    <?php
    $critical = count(array_filter($alerts, fn($a) => $a['stock_status'] === 'CRITICAL'));
    $low = count(array_filter($alerts, fn($a) => $a['stock_status'] === 'LOW'));
    $healthy = count(array_filter($alerts, fn($a) => $a['stock_status'] === 'HEALTHY'));
    ?>
    <div class="col-md-4">
        <div class="kpi-card bg-danger text-white">
            <h3><?php echo $critical; ?></h3>
            <p>Critical Stock Items</p>
        </div>
    </div>
    <div class="col-md-4">
        <div class="kpi-card bg-warning text-white">
            <h3><?php echo $low; ?></h3>
            <p>Low Stock Items</p>
        </div>
    </div>
    <div class="col-md-4">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo $healthy; ?></h3>
            <p>Healthy Stock Items</p>
        </div>
    </div>
</div>

<!-- Inventory Table -->
<div class="card mt-4">
    <div class="card-header">
        <i class="fas fa-warehouse"></i> Batch-Level Inventory
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Item Name</th>
                        <th>Batch Number</th>
                        <th>Supplier</th>
                        <th>Current Stock</th>
                        <th>Expiry Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($inventory as $item): ?>
                    <tr class="<?php echo $item['is_expired'] ? 'table-danger' : ''; ?>">
                        <td><strong><?php echo htmlspecialchars($item['item_name']); ?></strong></td>
                        <td><?php echo htmlspecialchars($item['batch_number']); ?></td>
                        <td><?php echo htmlspecialchars($item['supplier_name']); ?></td>
                        <td>
                            <span class="badge <?php 
                                echo $item['current_stock'] < 20 ? 'bg-danger' : 
                                    ($item['current_stock'] < 50 ? 'bg-warning' : 'bg-success'); 
                            ?>">
                                <?php echo $item['current_stock']; ?> units
                            </span>
                        </td>
                        <td><?php echo date('M d, Y', strtotime($item['expiry_date'])); ?></td>
                        <td>
                            <?php if ($item['is_expired']): ?>
                                <span class="badge bg-danger">EXPIRED</span>
                            <?php elseif (strtotime($item['expiry_date']) < strtotime('+30 days')): ?>
                                <span class="badge bg-warning">EXPIRING SOON</span>
                            <?php else: ?>
                                <span class="badge bg-success">VALID</span>
                            <?php endif; ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>