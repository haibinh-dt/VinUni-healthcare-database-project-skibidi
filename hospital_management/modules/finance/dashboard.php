<?php
$pageTitle = "Finance Dashboard";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('FINANCE');

$db = new Database();
$conn = $db->getConnection();

// Get statistics
$stmt = $conn->query("
    SELECT 
        SUM(total_amount) as total_revenue,
        SUM(CASE WHEN status = 'PAID' THEN total_amount ELSE 0 END) as collected,
        SUM(CASE WHEN status = 'NOT PAID' THEN total_amount ELSE 0 END) as outstanding,
        COUNT(*) as invoice_count
    FROM PatientInvoice
    WHERE MONTH(invoice_date) = MONTH(CURDATE())
");
$monthlyStats = $stmt->fetch();

$stmt = $conn->query("
    SELECT * FROM v_monthly_revenue 
    ORDER BY month DESC LIMIT 6
");
$revenueData = $stmt->fetchAll();

$stmt = $conn->query("
    SELECT * FROM v_invoice_payment_tracker 
    WHERE payment_status = 'NOT PAID'
    ORDER BY patient_invoice_id DESC LIMIT 10
");
$unpaidInvoices = $stmt->fetchAll();
?>

<!-- KPI Cards -->
<div class="row">
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo number_format($monthlyStats['total_revenue']); ?> ₫</h3>
            <p>Total Revenue (This Month)</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo number_format($monthlyStats['collected']); ?> ₫</h3>
            <p>Collected</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-warning text-white">
            <h3><?php echo number_format($monthlyStats['outstanding']); ?> ₫</h3>
            <p>Outstanding</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <h3><?php echo $monthlyStats['invoice_count']; ?></h3>
            <p>Invoices This Month</p>
        </div>
    </div>
</div>

<!-- Charts -->
<div class="row mt-4">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-chart-line"></i> Monthly Revenue Trend
            </div>
            <div class="card-body">
                <canvas id="revenueChart" height="80"></canvas>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-exclamation-triangle"></i> Unpaid Invoices
            </div>
            <div class="card-body" style="max-height: 400px; overflow-y: auto;">
                <?php foreach ($unpaidInvoices as $inv): ?>
                <div class="mb-2">
                    <strong>#<?php echo $inv['patient_invoice_id']; ?></strong><br>
                    <small><?php echo htmlspecialchars($inv['patient_name']); ?></small><br>
                    <span class="badge bg-danger"><?php echo number_format($inv['balance_due']); ?> ₫</span>
                </div>
                <hr>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</div>

<?php
$pageScripts = "
<script>
    const revData = " . json_encode(array_reverse($revenueData)) . ";
    new Chart(document.getElementById('revenueChart'), {
        type: 'line',
        data: {
            labels: revData.map(d => d.month),
            datasets: [{
                label: 'Revenue',
                data: revData.map(d => parseFloat(d.total_revenue)),
                borderColor: '#007bff',
                backgroundColor: 'rgba(0, 123, 255, 0.1)',
                tension: 0.4
            }]
        }
    });
</script>
";
require_once '../../includes/footer.php';
?>