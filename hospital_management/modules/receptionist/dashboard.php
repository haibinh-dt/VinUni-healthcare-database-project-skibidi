<?php
$pageTitle = "Receptionist Dashboard";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('RECEPTIONIST');

$db = new Database();
$conn = $db->getConnection();

// Get today's queue
$stmt = $conn->query("SELECT * FROM v_reception_daily_queue ORDER BY start_time");
$todayQueue = $stmt->fetchAll();

// Statistics
$stmt = $conn->query("
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN current_status = 'CONFIRMED' THEN 1 END) as checked_in,
        COUNT(CASE WHEN current_status = 'CREATED' THEN 1 END) as pending
    FROM Appointment WHERE appointment_date = CURDATE()
");
$stats = $stmt->fetch();

$stmt = $conn->query("SELECT COUNT(*) as count FROM Patient WHERE DATE(created_at) = CURDATE()");
$newPatientsToday = $stmt->fetch()['count'];
?>

<!-- KPI Cards -->
<div class="row">
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo $stats['total']; ?></h3>
            <p>Today's Appointments</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo $stats['checked_in']; ?></h3>
            <p>Checked In</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-warning text-white">
            <h3><?php echo $stats['pending']; ?></h3>
            <p>Pending Check-In</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <h3><?php echo $newPatientsToday; ?></h3>
            <p>New Patients Today</p>
        </div>
    </div>
</div>

<!-- Today's Queue -->
<div class="card mt-4">
    <div class="card-header">
        <i class="fas fa-calendar-day"></i> Today's Patient Queue - <?php echo date('l, F j, Y'); ?>
    </div>
    <div class="card-body">
        <?php if (empty($todayQueue)): ?>
            <p class="text-muted text-center">No appointments scheduled for today</p>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Time</th>
                            <th>Patient</th>
                            <th>Phone</th>
                            <th>Doctor</th>
                            <th>Department</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($todayQueue as $appt): ?>
                        <tr>
                            <td>
                                <?php echo date('H:i', strtotime($appt['start_time'])); ?>
                            </td>
                            <td><?php echo htmlspecialchars($appt['patient_name']); ?></td>
                            <td><?php echo htmlspecialchars($appt['patient_phone']); ?></td>
                            <td><?php echo htmlspecialchars($appt['doctor_name']); ?></td>
                            <td><?php echo htmlspecialchars($appt['department_name']); ?></td>
                            <td>
                                <span class="badge status-<?php echo strtolower($appt['current_status']); ?>">
                                    <?php echo $appt['current_status']; ?>
                                </span>
                            </td>
                            <td>
                                <?php if ($appt['current_status'] === 'CREATED'): ?>
                                    <a href="check_in.php?appointment_id=<?php echo $appt['appointment_id']; ?>" 
                                       class="btn btn-sm btn-success">
                                        <i class="fas fa-check"></i> Check In
                                    </a>
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

<!-- Quick Actions -->
<div class="row mt-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-bolt"></i> Quick Actions
            </div>
            <div class="card-body">
                <a href="patients.php" class="btn btn-primary me-2">
                    <i class="fas fa-user-plus"></i> Register New Patient
                </a>
                <a href="appointments.php" class="btn btn-success me-2">
                    <i class="fas fa-calendar-plus"></i> Book Appointment
                </a>
                <a href="check_in.php" class="btn btn-info">
                    <i class="fas fa-clipboard-check"></i> Check-In System
                </a>
            </div>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>