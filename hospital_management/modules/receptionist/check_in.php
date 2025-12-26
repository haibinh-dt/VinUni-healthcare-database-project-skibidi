<?php
require_once '../../config/database.php';
session_start(); // Ensure session is started for Flash Messages

$db = new Database();
$conn = $db->getConnection();

// Handle check-in
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $appointmentId = $_POST['appointment_id'];
    
    try {
        $stmt = $conn->prepare("CALL sp_confirm_appointment(?, ?, @status, @msg)");
        $stmt->execute([$appointmentId, $_SESSION['user_id']]);
        
        $_SESSION['flash_message'] = [
            'text' => 'Patient checked in successfully', 
            'type' => 'success'
        ];
        
        header("Location: check_in.php");
        exit();
    } catch (Exception $e) {
        $_SESSION['flash_message'] = [
            'text' => 'Error: ' . $e->getMessage(), 
            'type' => 'danger'
        ];
    }
}

// Get today's appointments that need check-in
$stmt = $conn->query("
    SELECT * FROM v_reception_daily_queue 
    WHERE current_status = 'CREATED'
    ORDER BY start_time
");
$pendingCheckIns = $stmt->fetchAll();

$pageTitle = "Patient Check-In";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('RECEPTIONIST');
?>

<h2><i class="fas fa-clipboard-check"></i> Patient Check-In System</h2>

<div class="card mt-4">
    <div class="card-header">
        <i class="fas fa-user-check"></i> Pending Check-Ins
    </div>
    <div class="card-body">
        <?php if (empty($pendingCheckIns)): ?>
            <div class="alert alert-success text-center">
                <i class="fas fa-check-circle"></i> All patients have been checked in!
            </div>
        <?php else: ?>
            <div class="row">
                <?php foreach ($pendingCheckIns as $appt): ?>
                <div class="col-md-6 mb-3">
                    <div class="card">
                        <div class="card-body">
                            <h5 class="card-title">
                                <i class="fas fa-user-circle"></i>
                                <?php echo htmlspecialchars($appt['patient_name']); ?>
                            </h5>
                            <hr>
                            <p class="mb-1">
                                <i class="fas fa-clock"></i> 
                                <strong>Time:</strong> 
                                <?php echo date('H:i', strtotime($appt['start_time'])); ?> - 
                                <?php echo date('H:i', strtotime($appt['end_time'])); ?>
                            </p>
                            <p class="mb-1">
                                <i class="fas fa-user-md"></i>
                                <strong>Doctor:</strong> <?php echo htmlspecialchars($appt['doctor_name']); ?>
                            </p>
                            <p class="mb-1">
                                <i class="fas fa-hospital"></i>
                                <strong>Department:</strong> <?php echo htmlspecialchars($appt['department_name']); ?>
                            </p>
                            <p class="mb-1">
                                <i class="fas fa-phone"></i>
                                <strong>Phone:</strong> <?php echo htmlspecialchars($appt['patient_phone']); ?>
                            </p>
                            <hr>
                            <form method="POST">
                                <input type="hidden" name="action" value="check_in">
                                <input type="hidden" name="appointment_id" value="<?php echo $appt['appointment_id']; ?>">
                                <button type="submit" class="btn btn-success w-100">
                                    <i class="fas fa-check-circle"></i> Check In Patient
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>