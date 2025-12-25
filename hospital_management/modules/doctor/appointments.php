<?php
$pageTitle = "My Appointments";
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

// Date filter
$filterDate = $_GET['date'] ?? date('Y-m-d');
$filterStatus = $_GET['status'] ?? '';

// Build query
$whereConditions = ["doctor_id = ?"];
$params = [$doctorId];

if ($filterDate) {
    $whereConditions[] = "appointment_date = ?";
    $params[] = $filterDate;
}

if ($filterStatus) {
    $whereConditions[] = "current_status = ?";
    $params[] = $filterStatus;
}

$whereClause = implode(' AND ', $whereConditions);

// Get appointments
$appointments = $db->queryView(
    "v_doctor_schedule_detail",
    $whereClause,
    $params,
    "appointment_date DESC, start_time ASC"
);

// Get statistics

$stmt = $conn->prepare("SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN current_status = 'CONFIRMED' THEN 1 END) as confirmed,
        COUNT(CASE WHEN current_status = 'COMPLETED' THEN 1 END) as completed,
        COUNT(CASE WHEN current_status = 'CANCELLED' THEN 1 END) as cancelled
    FROM Appointment
    WHERE doctor_id = ? AND appointment_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
");

$stmt->execute([$doctorId]);

$stats = $stmt->fetch();
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="fas fa-calendar-check"></i> My Appointments</h2>
</div>

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

<!-- Statistics -->
<div class="row mb-4">
    <div class="col-md-3">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo $stats['total']; ?></h3>
            <p>Total (30 days)</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo $stats['confirmed']; ?></h3>
            <p>Confirmed</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-info text-white">
            <h3><?php echo $stats['completed']; ?></h3>
            <p>Completed</p>
        </div>
    </div>
    <div class="col-md-3">
        <div class="kpi-card bg-danger text-white">
            <h3><?php echo $stats['cancelled']; ?></h3>
            <p>Cancelled</p>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card mb-4">
    <div class="card-header">
        <i class="fas fa-filter"></i> Filter Appointments
    </div>
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-3">
                <label class="form-label">Date</label>
                <input type="date" class="form-control" name="date" value="<?php echo $filterDate; ?>">
            </div>
            
            <div class="col-md-3">
                <label class="form-label">Status</label>
                <select class="form-select" name="status">
                    <option value="">All Statuses</option>
                    <option value="CREATED" <?php echo $filterStatus === 'CREATED' ? 'selected' : ''; ?>>Created</option>
                    <option value="CONFIRMED" <?php echo $filterStatus === 'CONFIRMED' ? 'selected' : ''; ?>>Confirmed</option>
                    <option value="IN_PROGRESS" <?php echo $filterStatus === 'IN_PROGRESS' ? 'selected' : ''; ?>>In Progress</option>
                    <option value="COMPLETED" <?php echo $filterStatus === 'COMPLETED' ? 'selected' : ''; ?>>Completed</option>
                    <option value="CANCELLED" <?php echo $filterStatus === 'CANCELLED' ? 'selected' : ''; ?>>Cancelled</option>
                </select>
            </div>
            
            <div class="col-md-2 d-flex align-items-end">
                <button type="submit" class="btn btn-primary w-100">
                    <i class="fas fa-search"></i> Filter
                </button>
            </div>
            
            <div class="col-md-2 d-flex align-items-end">
                <a href="appointments.php" class="btn btn-secondary w-100">
                    <i class="fas fa-times"></i> Clear
                </a>
            </div>
            
            <div class="col-md-2 d-flex align-items-end">
                <button type="button" class="btn btn-info w-100" onclick="setToday()">
                    <i class="fas fa-calendar-day"></i> Today
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Appointments List -->
<div class="card">
    <div class="card-header">
        <i class="fas fa-list"></i> Appointment List
        <?php if ($filterDate): ?>
            <span class="badge bg-info">
                <?php echo date('F j, Y', strtotime($filterDate)); ?>
            </span>
        <?php endif; ?>
        <span class="badge bg-secondary"><?php echo count($appointments); ?> appointments</span>
    </div>
    <div class="card-body">
        <?php if (empty($appointments)): ?>
            <div class="alert alert-info text-center">
                <i class="fas fa-info-circle"></i> No appointments found for the selected date and status.
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Date & Time</th>
                            <th>Patient</th>
                            <th>Reason</th>
                            <th>Status</th>
                            <th>Booked At</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($appointments as $appt): ?>
                        <tr>
                            <td><strong>#<?php echo $appt['appointment_id']; ?></strong></td>
                            <td>
                                <div>
                                    <i class="fas fa-calendar"></i>
                                    <?php echo date('M d, Y', strtotime($appt['appointment_date'])); ?>
                                </div>
                                <div>
                                    <i class="fas fa-clock"></i>
                                    <small class="text-muted">
                                        <?php echo date('H:i', strtotime($appt['start_time'])); ?> - 
                                        <?php echo date('H:i', strtotime($appt['end_time'])); ?>
                                    </small>
                                </div>
                            </td>
                            <td>
                                <i class="fas fa-user"></i>
                                <strong><?php echo htmlspecialchars($appt['patient_name']); ?></strong>
                            </td>
                            <td>
                                <small><?php echo htmlspecialchars($appt['reason'] ?? 'General consultation'); ?></small>
                            </td>
                            <td>
                                <span class="badge status-<?php echo strtolower($appt['current_status']); ?>">
                                    <?php echo $appt['current_status']; ?>
                                </span>
                            </td>
                            <td>
                                <small class="text-muted">
                                    <?php echo date('M d, H:i', strtotime($appt['booked_at'])); ?>
                                </small>
                            </td>
                            <td>
                                <?php if ($appt['current_status'] === 'CONFIRMED'): ?>
                                    <a href="visit_detail.php?appointment_id=<?php echo $appt['appointment_id']; ?>" 
                                       class="btn btn-sm btn-primary">
                                        <i class="fas fa-notes-medical"></i> Start Visit
                                    </a>
                                <?php elseif ($appt['current_status'] === 'IN_PROGRESS'): ?>
                                    <a href="visit_detail.php?appointment_id=<?php echo $appt['appointment_id']; ?>" 
                                       class="btn btn-sm btn-info">
                                        <i class="fas fa-edit"></i> Continue
                                    </a>
                                <?php elseif ($appt['current_status'] === 'COMPLETED'): ?>
                                    <button class="btn btn-sm btn-success" disabled>
                                        <i class="fas fa-check"></i> Completed
                                    </button>
                                <?php else: ?>
                                    <button class="btn btn-sm btn-secondary" disabled>
                                        <?php echo $appt['current_status']; ?>
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

<!-- Quick Date Navigation -->
<div class="card mt-4">
    <div class="card-body text-center">
        <div class="btn-group" role="group">
            <a href="?date=<?php echo date('Y-m-d', strtotime('-1 day', strtotime($filterDate))); ?>" 
               class="btn btn-outline-primary">
                <i class="fas fa-chevron-left"></i> Previous Day
            </a>
            <a href="?date=<?php echo date('Y-m-d'); ?>" class="btn btn-outline-primary">
                <i class="fas fa-calendar-day"></i> Today
            </a>
            <a href="?date=<?php echo date('Y-m-d', strtotime('+1 day', strtotime($filterDate))); ?>" 
               class="btn btn-outline-primary">
                Next Day <i class="fas fa-chevron-right"></i>
            </a>
        </div>
    </div>
</div>

<?php
$pageScripts = "
<script>
    function setToday() {
        const today = new Date().toISOString().split('T')[0];
        document.querySelector('input[name=\"date\"]').value = today;
        document.querySelector('form').submit();
    }
</script>
";

require_once '../../includes/footer.php';
?>