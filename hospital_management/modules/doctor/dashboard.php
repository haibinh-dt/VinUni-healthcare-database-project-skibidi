<?php
$pageTitle = "Doctor Dashboard";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('DOCTOR');

$db = new Database();
$conn = $db->getConnection();

$userId = $_SESSION['user_id'] ?? 0;

// Get doctor profile
$doctorProfile = $db->queryView(
    "Doctor d JOIN Department dept ON d.department_id = dept.department_id", 
    "d.user_id = ?", 
    [$userId],
    "",
    "1",
    "d.*, dept.department_name" 
);

$doctor = $doctorProfile[0] ?? null;
$doctorId = $doctor['doctor_id'] ?? 0;

if (!$doctor) {
    die("Error: Doctor profile not found for this user.");
}

// Get today's schedule
$todaySchedule = $db->queryView(
    "v_doctor_schedule_detail", 
    "doctor_id = ? AND appointment_date = CURDATE()", 
    [$doctorId], 
    "start_time ASC"
);

// Get statistics
$dailySummary = $db->queryView(
    "v_doctor_schedule_summary", 
    "doctor_id = ? AND appointment_date = CURDATE()", 
    [$doctorId]
);

$stats = [
    'total_appointments' => $dailySummary[0]['total_appointments'] ?? 0,
    'confirmed' => $dailySummary[0]['confirmed_count'] ?? 0,
    'completed' => $dailySummary[0]['completed_count'] ?? 0,
    'canceled' => $dailySummary[0]['cancelled_count'] ?? 0,
];

// Recent patients
$recentPatients = $db->queryView(
    "v_patient_medical_history",
    "consulting_doctor_id = ?",
    [$doctorId],
    "visit_start_time DESC",
    "5"
);
?>

<!-- Welcome Card -->
<div class="row mb-4">
    <div class="col-12">
        <div class="card border-0 shadow-sm bg-white p-3">
            <div class="d-flex align-items-center">
                <div class="flex-shrink-0">
                    <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center" style="width: 60px; height: 60px;">
                        <i class="fas fa-user-md fa-2x"></i>
                    </div>
                </div>
                <div class="ms-3">
                    <h4 class="mb-0"> <?php echo htmlspecialchars($doctor['title'] . ' ' . $doctor['full_name']); ?></h4>
                    <p class="text-muted mb-0">
                        <i class="fas fa-hospital-symbol text-info"></i> 
                        Department: <strong><?php echo htmlspecialchars($doctor['department_name']); ?></strong>
                    </p>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- KPI Cards -->
<div class="row">
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Today's Appointments</p>
                    <h3><?php echo $stats['total_appointments']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-calendar-day"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Confirmed</p>
                    <h3><?php echo $stats['confirmed']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-check-circle"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Completed</p>
                    <h3><?php echo $stats['completed']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-clipboard-check"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="kpi-card bg-danger text-white">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <p class="mb-1">Canceled</p>
                    <h3><?php echo $stats['canceled']; ?></h3>
                </div>
                <div class="icon">
                    <i class="fas fa-times-circle"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Today's Schedule -->
<div class="row mt-4">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-clock"></i> Today's Schedule - <?php echo date('l, F j, Y'); ?>
            </div>
            <div class="card-body">
                <?php if (empty($todaySchedule)): ?>
                    <p class="text-muted text-center py-4">
                        <i class="fas fa-info-circle"></i> No appointments scheduled for today
                    </p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>Patient</th>
                                    <th>Reason</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach($todaySchedule as $appt): ?>
                                <tr>
                                    <td>
                                        <?php echo date('H:i', strtotime($appt['start_time'])); ?> - 
                                        <?php echo date('H:i', strtotime($appt['end_time'])); ?>
                                    </td>
                                    <td>
                                        <strong><?php echo htmlspecialchars($appt['patient_name']); ?></strong>
                                    </td>
                                    <td><?php echo htmlspecialchars($appt['reason'] ?? 'General consultation'); ?></td>
                                    <td>
                                        <span class="badge status-<?php echo strtolower($appt['current_status']); ?>">
                                            <?php echo $appt['current_status']; ?>
                                        </span>
                                    </td>
                                    <td>
                                        <?php if ($appt['current_status'] == 'CONFIRMED'): ?>
                                            <a href="visit_detail.php?appointment_id=<?php echo $appt['appointment_id']; ?>" 
                                               class="btn btn-sm btn-primary">
                                                <i class="fas fa-notes-medical"></i> Start Visit
                                            </a>
                                        <?php elseif ($appt['current_status'] == 'IN_PROGRESS'): ?>
                                            <a href="visit_detail.php?appointment_id=<?php echo $appt['appointment_id']; ?>" 
                                               class="btn btn-sm btn-info">
                                                <i class="fas fa-edit"></i> Continue
                                            </a>
                                        <?php else: ?>
                                            <button class="btn btn-sm btn-secondary" disabled>
                                                <i class="fas fa-check"></i> Completed
                                            </button>
                                        <?php endif; ?>
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
    
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-history"></i> Recent Patients
            </div>
            <div class="card-body">
                <div class="list-group">
                    <?php foreach($recentPatients as $patient): ?>
                    <a href="patients.php?patient_id=<?php echo $patient['patient_id']; ?>" 
                       class="list-group-item list-group-item-action">
                        <div class="d-flex w-100 justify-content-between">
                            <h6 class="mb-1"><?php echo htmlspecialchars($patient['full_name']); ?></h6>
                            <small class="text-muted">
                                <?php echo date('M d', strtotime($patient['visit_start_time'])); ?>
                            </small>
                        </div>
                        <small class="text-muted">
                            <i class="fas fa-phone"></i> <?php echo htmlspecialchars($patient['phone']); ?>
                        </small>
                    </a>
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
                <a href="appointments.php" class="btn btn-primary me-2">
                    <i class="fas fa-calendar"></i> View All Appointments
                </a>
                <a href="patients.php" class="btn btn-info me-2">
                    <i class="fas fa-users"></i> Patient List
                </a>
                <button class="btn btn-success" onclick="window.location.reload()">
                    <i class="fas fa-sync-alt"></i> Refresh Schedule
                </button>
            </div>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>