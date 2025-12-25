<?php
/**
 * VISIT_DETAIL.PHP
 * Refactored version: Focus on Prescription_Item management within the Prescription Tab.
 * All UI comments and logic documentation in English.
 */

require_once '../../config/database.php';
session_start();

$db = new Database();
$conn = $db->getConnection();
$currentUserId = $_SESSION['user_id'];

// --- PHASE 1: INITIAL DATA FETCHING ---

// Fetch doctor and department info
$doctorProfile = $db->queryView(
    "Doctor d JOIN Department dept ON d.department_id = dept.department_id", 
    "d.user_id = ?", 
    [$currentUserId],
    "", "1",
    "d.*, dept.department_name" 
);
$doctor = $doctorProfile[0] ?? null;
$doctorId = $doctor['doctor_id'] ?? 0;

if (!$doctor) {
    die("Error: Doctor profile not found for this user.");
}

$appointmentId = $_GET['appointment_id'] ?? 0;
$appointmentData = $db->queryView("v_appointment_details", "appointment_id = ?", [$appointmentId]);
$appointment = $appointmentData[0] ?? null;

if (!$appointment) {
    $_SESSION['flash_message'] = ['text' => 'Appointment not found', 'type' => 'danger'];
    header("Location: appointments.php");
    exit();
}

// Fetch Visit record
$visitData = $db->queryView("Visit", "appointment_id = ?", [$appointmentId]);
$visit = $visitData[0] ?? null;

// Pre-fetch Prescription Header for Logic and UI
$prescription = null;
if ($visit) {
    $prescData = $db->queryView("Prescription", "visit_id = ?", [$visit['visit_id']]);
    $prescription = $prescData[0] ?? null;
}

// --- PHASE 2: FORM SUBMISSION HANDLING (POST) ---

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    try {
        // 1. Start Visit Logic
        if ($action === 'start_visit' && !$visit) {
            $result = $db->callProcedure('sp_start_visit', 
                [$appointmentId, $doctorId, $currentUserId], 
                ['vid', 'status', 'msg']
            );
            if ($result['status'] != 201) throw new Exception($result['msg']);
        }
        
        // 2. Add Diagnosis Logic
        if ($action === 'add_diagnosis' && $visit) {
            $result = $db->callProcedure('sp_add_diagnosis',
                [$visit['visit_id'], $_POST['diagnosis_id'], $doctorId, $_POST['diagnosis_note'] ?? '', $currentUserId],
                ['status', 'msg']
            );
            if ($result['status'] != 201) throw new Exception($result['msg']);
            header("Location: visit_detail.php?appointment_id=$appointmentId#diagnoses");
            exit();
        }
        
        // 3. Add Medical Service Logic
        if ($action === 'add_service' && $visit) {
            $result = $db->callProcedure('sp_add_visit_service',
                [$visit['visit_id'], $_POST['service_id'], $_POST['quantity'] ?? 1, $currentUserId],
                ['status', 'msg']
            );
            if ($result['status'] != 201) throw new Exception($result['msg']);
            header("Location: visit_detail.php?appointment_id=$appointmentId#services");
            exit();
        }
        
        // 4. Create Prescription Header Logic
        if ($action === 'create_prescription' && $visit) {
            $result = $db->callProcedure('sp_create_prescription',
                [$visit['visit_id'], $doctorId, $_POST['prescription_note'] ?? '', $currentUserId],
                ['prid', 'status', 'msg']
            );
            if ($result['status'] != 201) throw new Exception($result['msg']);
            header("Location: visit_detail.php?appointment_id=$appointmentId#prescription");
            exit();
        }

        // 5. Add Item to Prescription (Logic for Procedure 16)
        if ($action === 'add_prescription_item' && $prescription) {
            $result = $db->callProcedure('sp_add_prescription_item',
                [
                    $prescription['prescription_id'], 
                    $_POST['medication_id'], 
                    $_POST['quantity'], 
                    $_POST['dosage'], 
                    $_POST['instruction'], 
                    $currentUserId
                ],
                ['status', 'msg']
            );
            if ($result['status'] != 201) throw new Exception($result['msg']);
            header("Location: visit_detail.php?appointment_id=$appointmentId#prescription");
            exit();
        }
        
        // 6. Complete Visit Logic
        if ($action === 'end_visit' && $visit) {
            $result = $db->callProcedure('sp_end_visit', [$visit['visit_id'], $currentUserId], ['status', 'msg']);
            if ($result['status'] != 200) throw new Exception($result['msg']);
            header("Location: appointments.php");
            exit();
        }
        
    } catch (Exception $e) {
        $_SESSION['flash_error'] = $e->getMessage();
        header("Location: visit_detail.php?appointment_id=$appointmentId");
        exit();
    }
}

// --- PHASE 3: DATA FETCHING FOR UI DISPLAY (GET) ---

$diagnosesList = $db->getConnection()->query("SELECT * FROM Diagnosis ORDER BY diagnosis_name ASC")->fetchAll(PDO::FETCH_ASSOC);
$servicesList = $db->getConnection()->query("SELECT * FROM MedicalService ORDER BY service_name ASC")->fetchAll(PDO::FETCH_ASSOC);

$visitDiagnoses = [];
$visitServices = [];
$prescriptionItems = [];

if ($visit) {
    // Fetch Diagnoses
    $visitDiagnoses = $db->queryView("v_visit_diagnoses_detail", "visit_id = ?", [$visit['visit_id']]);
    
    // Fetch Ordered Services
    $stmtSrv = $db->getConnection()->prepare("SELECT vs.*, ms.service_name, ms.service_fee FROM Visit_Service vs JOIN MedicalService ms ON vs.service_id = ms.service_id WHERE vs.visit_id = ?");
    $stmtSrv->execute([$visit['visit_id']]);
    $visitServices = $stmtSrv->fetchAll(PDO::FETCH_ASSOC);
    
    // Refresh Prescription Header
    $prescData = $db->queryView("Prescription", "visit_id = ?", [$visit['visit_id']]);
    $prescription = $prescData[0] ?? null;

    if ($prescription) {
        // Fetch specific items from Prescription_Item 
        // Note: Joining with the table where medicine names are stored (usually PharmacyItem or Medication)
        $stmtItem = $db->getConnection()->prepare("
            SELECT pi.*, ph.item_name, ph.unit 
            FROM Prescription_Item pi 
            JOIN PharmacyItem ph ON pi.item_id = ph.item_id 
            WHERE pi.prescription_id = ?
        ");
        $stmtItem->execute([$prescription['prescription_id']]);
        $prescriptionItems = $stmtItem->fetchAll(PDO::FETCH_ASSOC);
    }
}

$pageTitle = "Visit Details";
require_once '../../includes/header.php'; 
?>

<div class="container-fluid px-4">
    <div class="d-flex justify-content-between align-items-center my-4">
        <h2><i class="fas fa-user-md"></i> Clinical Examination</h2>
        <a href="appointments.php" class="btn btn-outline-secondary btn-sm"><i class="fas fa-chevron-left"></i> Return</a>
    </div>

    <div class="card mb-4 border-0 shadow-sm">
        <div class="card-header bg-primary text-white fw-bold">Appointment Summary</div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-4">
                    <label class="text-muted small d-block">Patient Name</label>
                    <span class="h5"><?php echo htmlspecialchars($appointment['patient_name']); ?></span>
                </div>
                <div class="col-md-4">
                    <label class="text-muted small d-block">Schedule</label>
                    <span><?php echo date('M d, Y', strtotime($appointment['appointment_date'])); ?> (<?php echo $appointment['start_time']; ?>)</span>
                </div>
                <div class="col-md-4 text-md-end">
                    <label class="text-muted small d-block">Status</label>
                    <span class="badge bg-info"><?php echo $appointment['current_status']; ?></span>
                </div>
            </div>
            <?php if (!$visit && $appointment['current_status'] === 'CONFIRMED'): ?>
                <div class="mt-3 text-center">
                    <form method="POST"><input type="hidden" name="action" value="start_visit"><button type="submit" class="btn btn-success px-5">Start Medical Visit</button></form>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <?php if ($visit): ?>
    <ul class="nav nav-tabs mb-3" id="visitTabs" role="tablist">
        <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#diagnoses" type="button">Diagnoses</button></li>
        <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#services" type="button">Services</button></li>
        <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#prescription" type="button">Prescription</button></li>
        <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#notes" type="button">Clinical Notes</button></li>
    </ul>

    <div class="tab-content">
        <div class="tab-pane fade show active" id="diagnoses" role="tabpanel">
            <div class="card card-body shadow-sm">
                <h6 class="fw-bold text-primary mb-3">Diagnosis History</h6>
                <div class="list-group mb-4">
                    <?php foreach ($visitDiagnoses as $diag): ?>
                        <div class="list-group-item">
                            <strong><?php echo htmlspecialchars($diag['diagnosis_name']); ?></strong>
                            <p class="mb-0 small text-muted"><?php echo htmlspecialchars($diag['doctor_note']); ?></p>
                        </div>
                    <?php endforeach; ?>
                </div>
                <form method="POST" class="row g-2 border-top pt-3">
                    <input type="hidden" name="action" value="add_diagnosis">
                    <div class="col-md-6">
                        <select class="form-select" name="diagnosis_id" required>
                            <option value="">-- Select Condition --</option>
                            <?php foreach ($diagnosesList as $d): ?><option value="<?php echo $d['diagnosis_id']; ?>"><?php echo $d['diagnosis_name']; ?></option><?php endforeach; ?>
                        </select>
                    </div>
                    <div class="col-md-4"><input type="text" name="diagnosis_note" class="form-control" placeholder="Optional notes"></div>
                    <div class="col-md-2"><button type="submit" class="btn btn-primary w-100">Add</button></div>
                </form>
            </div>
        </div>

        <div class="tab-pane fade" id="services" role="tabpanel">
            <div class="card card-body shadow-sm">
                <h6 class="fw-bold text-primary mb-3">Ordered Services & Procedures</h6>
                <table class="table table-sm mb-4">
                    <thead><tr><th>Service Name</th><th>Qty</th><th class="text-end">Fee</th></tr></thead>
                    <tbody>
                        <?php foreach ($visitServices as $s): ?>
                        <tr><td><?php echo $s['service_name']; ?></td><td><?php echo $s['quantity']; ?></td><td class="text-end"><?php echo number_format($s['service_fee']); ?></td></tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
                <form method="POST" class="row g-2 border-top pt-3">
                    <input type="hidden" name="action" value="add_service">
                    <div class="col-md-7">
                        <select class="form-select" name="service_id" required>
                            <option value="">-- Choose Service --</option>
                            <?php foreach ($servicesList as $sv): ?><option value="<?php echo $sv['service_id']; ?>"><?php echo $sv['service_name']; ?></option><?php endforeach; ?>
                        </select>
                    </div>
                    <div class="col-md-2"><input type="number" name="quantity" class="form-control" value="1"></div>
                    <div class="col-md-3"><button type="submit" class="btn btn-primary w-100">Order Service</button></div>
                </form>
            </div>
        </div>

        <div class="tab-pane fade" id="prescription" role="tabpanel">
            <div class="card border-0 shadow-sm">
                <div class="card-body">
                    <?php if ($prescription): ?>
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <h6 class="fw-bold text-primary mb-0">Current Prescription Details</h6>
                            <span class="badge bg-light text-dark border">ID: #<?php echo $prescription['prescription_id']; ?></span>
                        </div>
                        <div class="table-responsive mb-4">
                            <table class="table table-hover table-bordered align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th>Medication</th>
                                        <th class="text-center">Qty</th>
                                        <th>Dosage / Frequency</th>
                                        <th>Instructions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php if (empty($prescriptionItems)): ?>
                                        <tr><td colspan="4" class="text-center py-4 text-muted">No medications prescribed yet.</td></tr>
                                    <?php else: ?>
                                        <?php foreach ($prescriptionItems as $item): ?>
                                        <tr>
                                            <td class="fw-bold"><?php echo htmlspecialchars($item['item_name']); ?></td>
                                            <td class="text-center"><?php echo $item['quantity']; ?> <?php echo htmlspecialchars($item['unit']); ?></td>
                                            <td><span class="badge bg-light text-dark border px-2"><?php echo htmlspecialchars($item['dosage']); ?></span></td>
                                            <td class="small text-muted"><?php echo htmlspecialchars($item['usage_instruction']); ?></td>
                                        </tr>
                                        <?php endforeach; ?>
                                    <?php endif; ?>
                                </tbody>
                            </table>
                        </div>

                        <hr class="my-4">

                        <h6 class="fw-bold text-success mb-3"><i class="fas fa-plus me-1"></i> Add Medication</h6>
                        <form method="POST" class="row g-3 bg-light p-3 rounded border">
                            <input type="hidden" name="action" value="add_prescription_item">
                            <div class="col-md-6">
                                <label class="form-label small fw-bold">Search Medication</label>
                                <select class="form-select" name="medication_id" required>
                                    <option value="">-- Select from Master List --</option>
                                    <?php 
                                    
                                    $medsMaster = $db->getConnection()->query("SELECT item_id, item_name, unit FROM PharmacyItem ORDER BY item_name")->fetchAll();
                                    foreach ($medsMaster as $m): ?>
                                        <option value="<?php echo $m['item_id']; ?>"><?php echo htmlspecialchars($m['item_name']); ?> (<?php echo $m['unit']; ?>)</option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small fw-bold">Quantity</label>
                                <input type="number" name="quantity" class="form-control" value="1" min="1" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label small fw-bold">Dosage (e.g. 1 tab, twice daily)</label>
                                <input type="text" name="dosage" class="form-control" placeholder="1 tab after meals" required>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label small fw-bold">Usage Instructions</label>
                                <textarea name="instruction" class="form-control" rows="2" placeholder="Specific patient instructions..."></textarea>
                            </div>
                            <div class="col-12 text-end">
                                <button type="submit" class="btn btn-success px-4">Add to Prescription</button>
                            </div>
                        </form>

                    <?php else: ?>
                        <div class="text-center py-5">
                            <i class="fas fa-file-prescription fa-4x text-light-emphasis mb-3"></i>
                            <h5>Prescription Not Created</h5>
                            <p class="text-muted">Initiate the prescription header to start adding medications.</p>
                            <form method="POST" class="mx-auto" style="max-width: 450px;">
                                <input type="hidden" name="action" value="create_prescription">
                                <textarea class="form-control mb-3" name="prescription_note" rows="2" placeholder="General prescription remarks..."></textarea>
                                <button type="submit" class="btn btn-primary px-5">Create Prescription Header</button>
                            </form>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <div class="tab-pane fade" id="notes" role="tabpanel">
            <div class="card card-body shadow-sm">
                <label class="form-label fw-bold">Comprehensive Exam Notes</label>
                <textarea class="form-control" rows="6" placeholder="Observations, symptoms, and plan..."><?php echo htmlspecialchars($visit['clinical_note'] ?? ''); ?></textarea>
            </div>
        </div>
    </div>

    <?php if ($appointment['current_status'] === 'IN_PROGRESS'): ?>
    <div class="card mt-4 border-success bg-light p-4 text-center">
        <h5 class="text-success fw-bold">Complete Examination</h5>
        <p class="small text-muted">Finalizing will close the record and trigger the billing process.</p>
        <form method="POST" onsubmit="return confirm('Complete this clinical visit?');">
            <input type="hidden" name="action" value="end_visit">
            <button type="submit" class="btn btn-success btn-lg px-5 shadow-sm">Complete & Close Visit</button>
        </form>
    </div>
    <?php endif; ?>

    <?php endif; ?>
</div>

<script>
/**
 * Tab Persistence Script
 * Keeps the user on the same tab after page refresh/redirect
 */
document.addEventListener("DOMContentLoaded", function() {
    var hash = window.location.hash;
    if (hash) {
        var triggerEl = document.querySelector('button[data-bs-target="' + hash + '"]');
        if (triggerEl) { (new bootstrap.Tab(triggerEl)).show(); }
    }
    var tabEls = document.querySelectorAll('button[data-bs-toggle="tab"]');
    tabEls.forEach(function(el) {
        el.addEventListener('shown.bs.tab', function(event) {
            window.location.hash = event.target.getAttribute('data-bs-target');
        });
    });
});
</script>

<?php require_once '../../includes/footer.php'; ?>