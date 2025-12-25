<?php
$pageTitle = "Admin Dashboard";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('ADMIN');

$db = new Database();
$conn = $db->getConnection(); 

// Get system statistics
$stats = []; 

try {
    // Total Users
    $allUsers = $db->queryView("v_user_security_activity");
    $stats['total_users'] = count($allUsers);

    // Total Doctors
    $allDoctors = $db->queryView("v_doctor_performance");
    $stats['total_doctors'] = count($allDoctors);

    // Total Patients
    $allPatients = $db->queryView("v_patient_visit_frequency");
    $stats['total_patients'] = count($allPatients);

    // Today's Appointments
    $todayApptData = $db->queryView("v_daily_appointments", "appointment_date = CURDATE()");
    $stats['today_appointments'] = !empty($todayApptData) ? $todayApptData[0]['total_appointments'] : 0;

    // Recent Audit Activity
    $recentAudits = $db->queryView("v_audit_readable_log", "", [], "changed_at DESC", "10");

    // User Role Distribution
    $roleData = $db->queryView("v_user_role_directory");
    $roleDistribution = [];
    foreach ($roleData as $row) {
        $roleName = $row['role_name'];
        if (!isset($roleDistribution[$roleName])) {
            $roleDistribution[$roleName] = 0;
        }
        $roleDistribution[$roleName]++;
    }

    // Prepare data for chart
    $chartLabels = array_keys($roleDistribution);
    $chartData = array_values($roleDistribution);

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>

<!-- KPI Cards -->
<div class="row">
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Active Users</p>
                    <h3><?php echo $stats['total_users']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-users"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Active Doctors</p>
                    <h3><?php echo $stats['total_doctors']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-user-md"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Total Patients</p>
                    <h3><?php echo $stats['total_patients']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-user-injured"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-warning text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Today's Appointments</p>
                    <h3><?php echo $stats['today_appointments']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-calendar-check"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Charts Row -->
<div class="row mt-4">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-chart-pie"></i> User Role Distribution
            </div>
            <div class="card-body">
                <canvas id="roleDistributionChart"></canvas>
            </div>
        </div>
    </div>
    
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-history"></i> Recent System Activity
            </div>
            <div class="card-body" style="max-height: 400px; overflow-y: auto;">
                <div class="list-group">
                    <?php foreach($recentAudits as $audit): ?>
                    <div class="list-group-item">
                        <div class="d-flex w-100 justify-content-between">
                            <h6 class="mb-1">
                                <i class="fas fa-user"></i> <?php echo htmlspecialchars($audit['performer']); ?>
                            </h6>
                            <small class="text-muted">
                                <?php echo date('M d, H:i', strtotime($audit['changed_at'])); ?>
                            </small>
                        </div>
                        <p class="mb-1">
                            <span class="badge bg-<?php 
                                echo $audit['action_type'] == 'INSERT' ? 'success' : 
                                    ($audit['action_type'] == 'DELETE' ? 'danger' : 'info'); 
                            ?>">
                                <?php echo $audit['action_type']; ?>
                            </span>
                            <?php echo htmlspecialchars($audit['table_name']); ?>
                            <?php if($audit['field_name']): ?>
                                - <?php echo htmlspecialchars($audit['field_name']); ?>
                            <?php endif; ?>
                        </p>
                    </div>
                    <?php endforeach; ?>
                </div>
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
                        <a href="users.php" class="btn btn-primary w-100 mb-2">
                            <i class="fas fa-user-plus"></i> Manage Users
                        </a>
                    </div>
                    <div class="col-md-3">
                        <a href="audit_logs.php" class="btn btn-info w-100 mb-2">
                            <i class="fas fa-clipboard-list"></i> View Audit Logs
                        </a>
                    </div>
                    <div class="col-md-3">
                        <a href="analytics.php" class="btn btn-success w-100 mb-2">
                            <i class="fas fa-chart-line"></i> System Analytics
                        </a>
                    </div>
                    <div class="col-md-3">
                        <button class="btn btn-warning w-100 mb-2" onclick="refreshSystemStats()">
                            <i class="fas fa-sync-alt"></i> Refresh Stats
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
$pageScripts = "
<script>
    // Role Distribution Chart
    const roleLabels = " . json_encode($chartLabels) . ";
    const roleCounts = " . json_encode($chartData) . ";
    
    const roleCtx = document.getElementById('roleDistributionChart').getContext('2d');
    new Chart(roleCtx, {
        type: 'doughnut',
        data: {
            labels: roleLabels,
            datasets: [{
                data: roleCounts,
                backgroundColor: [
                    '#007bff',
                    '#28a745',
                    '#17a2b8',
                    '#ffc107',
                    '#6c757d'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
    
    function refreshSystemStats() {
        showLoading();
        setTimeout(() => {
            window.location.reload();
        }, 1000);
    }
</script>
";

require_once '../../includes/footer.php';
?>