<?php
$pageTitle = "System Analytics";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('ADMIN');

$db = new Database();
$conn = $db->getConnection();

// Daily appointments trend
$dailyAppointments = $db->queryView("v_daily_appointments", "", [], "appointment_date DESC", "30");

// Doctor performance
$doctorPerformance = $db->queryView("v_doctor_performance", "", [], "total_visits DESC");

// Patient visit frequency
$frequentPatients = $db->queryView("v_patient_visit_frequency", "", [], "total_visits DESC", "10");

// Service popularity
$popularServices = $db->queryView("v_service_popularity", "", [], "usage_count DESC", "10");

// Department statistics
$rawPerf = $db->queryView("v_doctor_performance");
$departmentStats = [];
foreach ($rawPerf as $row) {
    $deptName = $row['department_name'];
    if (!isset($departmentStats[$deptName])) {
        $departmentStats[$deptName] = ['department_name' => $deptName, 'doctor_count' => 0, 'visit_count' => 0];
    }
    $departmentStats[$deptName]['doctor_count']++;
    $departmentStats[$deptName]['visit_count'] += $row['total_visits'];
}
// Convert to indexed array
usort($departmentStats, fn($a, $b) => $b['visit_count'] <=> $a['visit_count']);
?>

<h2><i class="fas fa-chart-line"></i> System Analytics & Insights</h2>

<!-- Overview Cards -->
<div class="row mt-4">
    <?php
    $monthlyAppointments = array_sum(array_column($dailyAppointments, 'total_appointments'));
    
    $monthlyVisits = array_sum(array_column($doctorPerformance, 'total_visits'));
    
    $uniquePatientsData = $db->queryView("v_patient_visit_frequency", "last_visit_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)");
    $uniquePatients = count($uniquePatientsData);
    
    $allDurations = array_filter(array_column($doctorPerformance, 'avg_visit_duration_minutes'));
    $avgVisitDuration = !empty($allDurations) ? round(array_sum($allDurations) / count($allDurations)) : 0;
    ?>
    
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo $monthlyAppointments; ?></h3>
            <p>Appointments (30 days)</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo $monthlyVisits; ?></h3>
            <p>Completed Visits (30 days)</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <h3><?php echo $uniquePatients; ?></h3>
            <p>Unique Patients (30 days)</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-warning text-white">
            <h3><?php echo $avgVisitDuration; ?> min</h3>
            <p>Avg Visit Duration</p>
        </div>
    </div>
</div>

<!-- Charts Row 1 -->
<div class="row mt-4">
    <!-- Daily Appointments Trend -->
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-chart-area"></i> Daily Appointments Trend (Last 30 Days)
            </div>
            <div class="card-body">
                <canvas id="appointmentTrendChart" height="80"></canvas>
            </div>
        </div>
    </div>
    
    <!-- Appointment Status Breakdown -->
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-chart-pie"></i> Today's Appointment Status
            </div>
            <div class="card-body">
                <canvas id="statusBreakdownChart"></canvas>
            </div>
        </div>
    </div>
</div>

<!-- Charts Row 2 -->
<div class="row mt-4">
    <!-- Doctor Performance -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-user-md"></i> Doctor Performance (30 days)
            </div>
            <div class="card-body">
                <canvas id="doctorPerformanceChart" height="100"></canvas>
            </div>
        </div>
    </div>
    
    <!-- Department Activity -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-hospital"></i> Department Activity (30 days)
            </div>
            <div class="card-body">
                <canvas id="departmentChart" height="100"></canvas>
            </div>
        </div>
    </div>
</div>

<!-- Tables Row -->
<div class="row mt-4">
    <!-- Most Frequent Patients -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-star"></i> Most Frequent Patients
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-sm table-hover">
                        <thead>
                            <tr>
                                <th>Patient Name</th>
                                <th class="text-center">Total Visits</th>
                                <th>Last Visit</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($frequentPatients as $patient): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($patient['patient_name']); ?></td>
                                <td class="text-center">
                                    <span class="badge bg-primary"><?php echo $patient['total_visits']; ?></span>
                                </td>
                                <td>
                                    <small class="text-muted">
                                        <?php echo date('M d, Y', strtotime($patient['last_visit_date'])); ?>
                                    </small>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Popular Services -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-chart-bar"></i> Most Popular Services
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-sm table-hover">
                        <thead>
                            <tr>
                                <th>Service Name</th>
                                <th class="text-center">Usage Count</th>
                                <th class="text-end">Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($popularServices as $service): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($service['service_name']); ?></td>
                                <td class="text-center">
                                    <span class="badge bg-success"><?php echo $service['usage_count']; ?></span>
                                </td>
                                <td class="text-end">
                                    <strong><?php echo number_format($service['total_revenue']); ?> ₫</strong>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
$pageScripts = "
<script>
    // Appointment Trend Chart
    const appointmentData = " . json_encode(array_reverse($dailyAppointments)) . ";
    const trendLabels = appointmentData.map(d => {
        const date = new Date(d.appointment_date);
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    new Chart(document.getElementById('appointmentTrendChart'), {
        type: 'line',
        data: {
            labels: trendLabels,
            datasets: [
                {
                    label: 'Total',
                    data: appointmentData.map(d => d.total_appointments),
                    borderColor: '#007bff',
                    backgroundColor: 'rgba(0, 123, 255, 0.1)',
                    tension: 0.4
                },
                {
                    label: 'Completed',
                    data: appointmentData.map(d => d.completed),
                    borderColor: '#28a745',
                    backgroundColor: 'rgba(40, 167, 69, 0.1)',
                    tension: 0.4
                },
                {
                    label: 'Cancelled',
                    data: appointmentData.map(d => d.cancelled),
                    borderColor: '#dc3545',
                    backgroundColor: 'rgba(220, 53, 69, 0.1)',
                    tension: 0.4
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
    
    // Status Breakdown
    const latestDay = appointmentData[appointmentData.length - 1];
    new Chart(document.getElementById('statusBreakdownChart'), {
        type: 'doughnut',
        data: {
            labels: ['Completed', 'Confirmed', 'Cancelled', 'Pending'],
            datasets: [{
                data: [
                    latestDay.completed,
                    latestDay.confirmed,
                    latestDay.cancelled,
                    latestDay.pending
                ],
                backgroundColor: ['#28a745', '#17a2b8', '#dc3545', '#ffc107']
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom' }
            }
        }
    });
    
    // Doctor Performance
    const doctorData = " . json_encode(array_slice($doctorPerformance, 0, 10)) . ";
    new Chart(document.getElementById('doctorPerformanceChart'), {
        type: 'bar',
        data: {
            labels: doctorData.map(d => d.doctor_name.split(' ').pop()),
            datasets: [{
                label: 'Total Visits',
                data: doctorData.map(d => d.total_visits),
                backgroundColor: '#007bff'
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: { beginAtZero: true }
            }
        }
    });
    
    // Department Chart
    const deptData = " . json_encode($departmentStats) . ";
    new Chart(document.getElementById('departmentChart'), {
        type: 'bar',
        data: {
            labels: deptData.map(d => d.department_name.split(' ')[0]),
            datasets: [
                {
                    label: 'Doctors',
                    data: deptData.map(d => d.doctor_count),
                    backgroundColor: '#17a2b8'
                },
                {
                    label: 'Visits',
                    data: deptData.map(d => d.visit_count),
                    backgroundColor: '#28a745'
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