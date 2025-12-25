<?php
$pageTitle = "Financial Reports";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('FINANCE');

$db = new Database();
$conn = $db->getConnection();

// Get monthly revenue
$stmt = $conn->query("SELECT * FROM v_monthly_revenue ORDER BY month DESC LIMIT 12");
$monthlyRevenue = $stmt->fetchAll();

// Get financial summary
$stmt = $conn->query("SELECT * FROM v_financial_summary ORDER BY month DESC LIMIT 12");
$financialSummary = $stmt->fetchAll();
?>

<h2><i class="fas fa-chart-line"></i> Financial Reports & Analytics</h2>

<!-- Summary Cards -->
<div class="row mt-4">
    <?php
    $currentMonth = $monthlyRevenue[0] ?? null;
    if ($currentMonth):
    ?>
    <div class="col-md-4">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo number_format($currentMonth['total_revenue']); ?> ₫</h3>
            <p>Total Revenue (Current Month)</p>
        </div>
    </div>
    <div class="col-md-4">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo number_format($currentMonth['paid_revenue']); ?> ₫</h3>
            <p>Collected</p>
        </div>
    </div>
    <div class="col-md-4">
        <div class="kpi-card bg-warning text-white">
            <h3><?php echo number_format($currentMonth['unpaid_revenue']); ?> ₫</h3>
            <p>Outstanding</p>
        </div>
    </div>
    <?php endif; ?>
</div>

<!-- Revenue Chart -->
<div class="card mt-4">
    <div class="card-header">
        <i class="fas fa-chart-bar"></i> Monthly Revenue Trend
    </div>
    <div class="card-body">
        <canvas id="revenueChart" height="100"></canvas>
    </div>
</div>

<!-- Income vs Expense -->
<div class="card mt-4">
    <div class="card-header">
        <i class="fas fa-balance-scale"></i> Income vs Expense Analysis
    </div>
    <div class="card-body">
        <canvas id="incomeExpenseChart" height="100"></canvas>
    </div>
</div>

<?php
$pageScripts = "
<script>
    // Revenue Chart
    const revenueData = " . json_encode(array_reverse($monthlyRevenue)) . ";
    const revenueLabels = revenueData.map(d => d.month);
    const revenueAmounts = revenueData.map(d => parseFloat(d.total_revenue));
    
    new Chart(document.getElementById('revenueChart'), {
        type: 'line',
        data: {
            labels: revenueLabels,
            datasets: [{
                label: 'Total Revenue',
                data: revenueAmounts,
                borderColor: '#007bff',
                backgroundColor: 'rgba(0, 123, 255, 0.1)',
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom' }
            },
            scales: {
                y: { beginAtZero: true }
            }
        }
    });
    
    // Income vs Expense Chart
    const finData = " . json_encode(array_reverse($financialSummary)) . ";
    const finLabels = finData.map(d => d.month);
    const incomeData = finData.map(d => parseFloat(d.total_income));
    const expenseData = finData.map(d => parseFloat(d.total_expense));
    
    new Chart(document.getElementById('incomeExpenseChart'), {
        type: 'bar',
        data: {
            labels: finLabels,
            datasets: [
                {
                    label: 'Income',
                    data: incomeData,
                    backgroundColor: '#28a745'
                },
                {
                    label: 'Expense',
                    data: expenseData,
                    backgroundColor: '#dc3545'
                }
            ]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom' }
            },
            scales: {
                y: { beginAtZero: true }
            }
        }
    });
</script>
";

require_once '../../includes/footer.php';
?>