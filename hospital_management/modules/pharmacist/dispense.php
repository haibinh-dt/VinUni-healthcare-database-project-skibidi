<?php
// 1. Database and Session must come first
require_once '../../config/database.php';
session_start(); // Ensure session is started for Flash Messages

$db = new Database();
$conn = $db->getConnection();

// Handle dispensing
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];
    
    if ($action === 'dispense') {
        $prescriptionId = $_POST['prescription_id'];
        $itemId = $_POST['item_id'];
        $quantity = $_POST['quantity'];
        
        try {
            $stmt = $conn->prepare("CALL sp_dispense_medication(?, ?, ?, ?, @status, @msg)");
            $stmt->execute([$prescriptionId, $itemId, $quantity, $_SESSION['user_id']]);
            
            $result = $conn->query("SELECT @status as status, @msg as message")->fetch();
            
            if ($result['status'] == 200) {
                $_SESSION['flash_message'] = 'Medication dispensed successfully'; // Store as string
            } else {
                $_SESSION['flash_message'] = $result['message']; // Store as string
            }
        } catch (Exception $e) {
            setFlashMessage('Error: ' . $e->getMessage(), 'danger');
        }
        
        header("Location: dispense.php");
        exit();
    }
}
$pageTitle = "Dispense Medication";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('PHARMACIST');

// Get pending prescriptions
$stmt = $conn->query("
    SELECT DISTINCT 
        p.prescription_id,
        p.prescribed_at,
        pt.patient_id,
        pt.full_name as patient_name,
        d.full_name as doctor_name,
        p.note
    FROM Prescription p
    JOIN Visit v ON p.visit_id = v.visit_id
    JOIN Patient pt ON v.patient_id = pt.patient_id
    JOIN Doctor d ON p.doctor_id = d.doctor_id
    WHERE DATE(p.prescribed_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ORDER BY p.prescribed_at DESC
");
$prescriptions = $stmt->fetchAll();

// Get prescription details if selected
$selectedPrescription = null;
$prescriptionItems = [];
if (isset($_GET['prescription_id'])) {
    $prescriptionId = $_GET['prescription_id'];
    
    $stmt = $conn->prepare("
        SELECT * FROM v_prescription_for_pharmacy 
        WHERE prescription_id = ?
    ");
    $stmt->execute([$prescriptionId]);
    $prescriptionItems = $stmt->fetchAll();
    
    if (!empty($prescriptionItems)) {
        $selectedPrescription = [
            'prescription_id' => $prescriptionId,
            'patient_name' => $prescriptionItems[0]['patient_name'],
            'doctor_name' => $prescriptionItems[0]['doctor_name'],
            'prescribed_at' => $prescriptionItems[0]['prescribed_at'],
            'doctor_note' => $prescriptionItems[0]['doctor_note']
        ];
    }
}
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="fas fa-prescription-bottle"></i> Medication Dispensing</h2>
</div>

<div class="row">
    <!-- Prescription List -->
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <i class="fas fa-list"></i> Recent Prescriptions
            </div>
            <div class="card-body" style="max-height: 600px; overflow-y: auto;">
                <div class="list-group">
                    <?php foreach ($prescriptions as $rx): ?>
                    <a href="?prescription_id=<?php echo $rx['prescription_id']; ?>" 
                       class="list-group-item list-group-item-action <?php echo (isset($_GET['prescription_id']) && $_GET['prescription_id'] == $rx['prescription_id']) ? 'active' : ''; ?>">
                        <div class="d-flex w-100 justify-content-between">
                            <h6 class="mb-1">#<?php echo $rx['prescription_id']; ?></h6>
                            <small><?php echo date('M d, H:i', strtotime($rx['prescribed_at'])); ?></small>
                        </div>
                        <p class="mb-1">
                            <i class="fas fa-user"></i> <?php echo htmlspecialchars($rx['patient_name']); ?>
                        </p>
                        <small>Dr. <?php echo htmlspecialchars($rx['doctor_name']); ?></small>
                    </a>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Dispensing Area -->
    <div class="col-md-8">
        <?php if (!$selectedPrescription): ?>
        <div class="card">
            <div class="card-body text-center py-5">
                <i class="fas fa-hand-pointer fa-3x text-muted mb-3"></i>
                <h5 class="text-muted">Select a prescription from the list to begin dispensing</h5>
            </div>
        </div>
        <?php else: ?>
        
        <!-- Prescription Details -->
        <div class="card mb-3">
            <div class="card-header bg-primary text-white">
                <i class="fas fa-file-prescription"></i> Prescription #<?php echo $selectedPrescription['prescription_id']; ?>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <p class="mb-1">
                            <strong>Patient:</strong> <?php echo htmlspecialchars($selectedPrescription['patient_name']); ?><br>
                            <strong>Prescribed by:</strong> Dr. <?php echo htmlspecialchars($selectedPrescription['doctor_name']); ?>
                        </p>
                    </div>
                    <div class="col-md-6 text-end">
                        <p class="mb-1">
                            <strong>Date:</strong> <?php echo date('F j, Y - H:i', strtotime($selectedPrescription['prescribed_at'])); ?>
                        </p>
                    </div>
                </div>
                <?php if ($selectedPrescription['doctor_note']): ?>
                <hr>
                <div class="alert alert-info mb-0">
                    <strong>Doctor's Note:</strong> <?php echo htmlspecialchars($selectedPrescription['doctor_note']); ?>
                </div>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Medication Items -->
        <div class="card">
            <div class="card-header">
                <i class="fas fa-pills"></i> Medications to Dispense
            </div>
            <div class="card-body">
                <?php foreach ($prescriptionItems as $item): ?>
                <div class="card mb-3">
                    <div class="card-body">
                        <h5 class="card-title"><?php echo htmlspecialchars($item['item_name']); ?></h5>
                        
                        <div class="row mb-3">
                            <div class="col-md-4">
                                <small class="text-muted">Quantity Prescribed</small>
                                <h4><?php echo $item['quantity']; ?></h4>
                            </div>
                            <div class="col-md-4">
                                <small class="text-muted">Dosage</small>
                                <p class="mb-0"><?php echo htmlspecialchars($item['dosage'] ?? 'As directed'); ?></p>
                            </div>
                            <div class="col-md-4">
                                <small class="text-muted">Status</small>
                                <p class="mb-0">
                                    <?php
                                    // Check if already dispensed
                                    $stmt = $conn->prepare("
                                        SELECT COUNT(*) as count FROM StockMovement 
                                        WHERE reference_type = 'PRESCRIPTION' 
                                        AND reference_id = ? 
                                        AND movement_type = 'OUT'
                                    ");
                                    $stmt->execute([$selectedPrescription['prescription_id']]);
                                    $dispensed = $stmt->fetch()['count'] > 0;
                                    ?>
                                    <?php if ($dispensed): ?>
                                        <span class="badge bg-success">Dispensed</span>
                                    <?php else: ?>
                                        <span class="badge bg-warning">Pending</span>
                                    <?php endif; ?>
                                </p>
                            </div>
                        </div>
                        
                        <?php if ($item['usage_instruction']): ?>
                        <div class="alert alert-secondary mb-3">
                            <strong>Usage Instructions:</strong><br>
                            <?php echo nl2br(htmlspecialchars($item['usage_instruction'])); ?>
                        </div>
                        <?php endif; ?>
                        
                        <!-- Check stock availability -->
                        <?php
                        $stmt = $conn->prepare("
                            SELECT SUM(quantity) as available 
                            FROM PharmacyBatch 
                            WHERE item_id = ? 
                            AND expiry_date > CURDATE()
                        ");
                        $stmt->execute([$item['item_id']]);
                        $available = $stmt->fetch()['available'] ?? 0;
                        ?>
                        
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <?php if ($available >= $item['quantity']): ?>
                                    <span class="badge bg-success">
                                        <i class="fas fa-check"></i> In Stock: <?php echo $available; ?> units
                                    </span>
                                <?php else: ?>
                                    <span class="badge bg-danger">
                                        <i class="fas fa-times"></i> Insufficient Stock: <?php echo $available; ?> units available
                                    </span>
                                <?php endif; ?>
                            </div>
                            
                            <?php if (!$dispensed && $available >= $item['quantity']): ?>
                            <form method="POST" style="display: inline;">
                                <input type="hidden" name="action" value="dispense">
                                <input type="hidden" name="prescription_id" value="<?php echo $selectedPrescription['prescription_id']; ?>">
                                <input type="hidden" name="item_id" value="<?php echo $item['item_id']; ?>">
                                <input type="hidden" name="quantity" value="<?php echo $item['quantity']; ?>">
                                <button type="submit" class="btn btn-primary" 
                                        onclick="return confirm('Dispense <?php echo $item['quantity']; ?> units of <?php echo htmlspecialchars($item['item_name']); ?>?')">
                                    <i class="fas fa-check-circle"></i> Dispense
                                </button>
                            </form>
                            <?php elseif ($dispensed): ?>
                            <button class="btn btn-success" disabled>
                                <i class="fas fa-check"></i> Already Dispensed
                            </button>
                            <?php else: ?>
                            <button class="btn btn-secondary" disabled>
                                <i class="fas fa-ban"></i> Cannot Dispense
                            </button>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
        
        <?php endif; ?>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>