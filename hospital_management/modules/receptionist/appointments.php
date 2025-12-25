<?php
$pageTitle = "Appointment Booking";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('RECEPTIONIST');

$db = new Database();
$conn = $db->getConnection();

// Get available time slots
$stmt = $conn->query("SELECT * FROM TimeSlot ORDER BY start_time");
$timeSlots = $stmt->fetchAll();

// Get active doctors
$stmt = $conn->query("SELECT d.doctor_id, d.full_name, dep.department_name 
                      FROM Doctor d 
                      JOIN Department dep ON d.department_id = dep.department_id 
                      WHERE d.status = 'ACTIVE' 
                      ORDER BY dep.department_name, d.full_name");
$doctors = $stmt->fetchAll();

// Handle appointment booking
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $patientId = $_POST['patient_id'];
    $doctorId = $_POST['doctor_id'];
    $timeslotId = $_POST['timeslot_id'];
    $appointmentDate = $_POST['appointment_date'];
    $reason = $_POST['reason'];
    
    try {
        $db->setCurrentUser($_SESSION['user_id']);
        $stmt = $conn->prepare("CALL sp_book_appointment(?, ?, ?, ?, ?, ?, @aid, @status, @msg)");
        $stmt->execute([$patientId, $doctorId, $timeslotId, $appointmentDate, $reason, $_SESSION['user_id']]);
        
        $result = $conn->query("SELECT @aid as appointment_id, @status as status, @msg as message")->fetch();
        
        if ($result['status'] == 201) {
            setFlashMessage('Appointment booked successfully! Appointment ID: ' . $result['appointment_id'], 'success');
        } else {
            setFlashMessage('Error: ' . $result['message'], 'danger');
        }
    } catch (Exception $e) {
        setFlashMessage('Error booking appointment: ' . $e->getMessage(), 'danger');
    }
    
    header("Location: appointments.php");
    exit();
}

// Get today's appointments
$stmt = $conn->query("SELECT * FROM v_reception_daily_queue ORDER BY start_time");
$todayAppointments = $stmt->fetchAll();
?>

<h2><i class="fas fa-calendar-alt"></i> Appointment Management</h2>

<div class="row mt-4">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header bg-primary text-white">
                <i class="fas fa-plus"></i> Book New Appointment
            </div>
            <div class="card-body">
                <form method="POST" id="bookingForm">
                    <div class="mb-3">
                        <label class="form-label">Patient ID *</label>
                        <input type="number" class="form-control" name="patient_id" required>
                        <small class="text-muted">Search patient from Patient Management page</small>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Doctor *</label>
                        <select class="form-select" name="doctor_id" required>
                            <option value="">-- Select Doctor --</option>
                            <?php foreach ($doctors as $doctor): ?>
                                <option value="<?php echo $doctor['doctor_id']; ?>">
                                    <?php echo htmlspecialchars($doctor['full_name'] . ' - ' . $doctor['department_name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Date *</label>
                        <input type="date" class="form-control" name="appointment_date" 
                               min="<?php echo date('Y-m-d'); ?>" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Time Slot *</label>
                        <select class="form-select" name="timeslot_id" required>
                            <option value="">-- Select Time --</option>
                            <?php foreach ($timeSlots as $slot): ?>
                                <option value="<?php echo $slot['timeslot_id']; ?>">
                                    <?php echo date('H:i', strtotime($slot['start_time'])); ?> - 
                                    <?php echo date('H:i', strtotime($slot['end_time'])); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Reason for Visit</label>
                        <textarea class="form-control" name="reason" rows="3"></textarea>
                    </div>
                    
                    <button type="submit" class="btn btn-primary w-100">
                        <i class="fas fa-calendar-plus"></i> Book Appointment
                    </button>
                </form>
            </div>
        </div>
    </div>
    
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-list"></i> Today's Appointments
            </div>
            <div class="card-body" style="max-height: 500px; overflow-y: auto;">
                <?php if (empty($todayAppointments)): ?>
                    <p class="text-muted text-center">No appointments today</p>
                <?php else: ?>
                    <div class="list-group">
                        <?php foreach ($todayAppointments as $appt): ?>
                            <div class="list-group-item">
                                <div class="d-flex justify-content-between">
                                    <strong><?php echo htmlspecialchars($appt['patient_name']); ?></strong>
                                    <span class="badge status-<?php echo strtolower($appt['current_status']); ?>">
                                        <?php echo $appt['current_status']; ?>
                                    </span>
                                </div>
                                <small class="text-muted">
                                    <?php echo date('H:i', strtotime($appt['start_time'])); ?> - 
                                    Dr. <?php echo htmlspecialchars($appt['doctor_name']); ?>
                                </small>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>