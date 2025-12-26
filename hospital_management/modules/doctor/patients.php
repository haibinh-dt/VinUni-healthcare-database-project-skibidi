<?php
$pageTitle = "My Patients";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('DOCTOR');

$db = new Database();
$conn = $db->getConnection();

// Get doctor profile
$doctorProfile = $db->queryView(
    "Doctor d JOIN Department dept ON d.department_id = dept.department_id", 
    "d.user_id = ?", 
    [$_SESSION['user_id']],
    "",
    "1",
    "d.*, dept.department_name" 
);

$doctor = $doctorProfile[0] ?? null;
$doctorId = $doctor['doctor_id'] ?? 0;

if (!$doctor) {
    die("Error: Doctor profile not found for this user.");
}

// Search
$searchQuery = $_GET['search'] ?? '';

// Get patients who have visited this doctor
$where = "doctor_id = ?";
$params = [$doctorId];

if ($searchQuery) {
    $where .= " AND (full_name LIKE ? OR phone LIKE ?)";
    $params[] = "%$searchQuery%";
    $params[] = "%$searchQuery%";
}

$patients = $db->queryView(
    "v_doctor_patient_list",
    $where,
    $params,
    "last_visit DESC",
    "100"
);
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="fas fa-user-injured"></i> My Patients</h2>
    <div>
        <span class="badge bg-primary"><?php echo count($patients); ?> patients</span>
    </div>
</div>

<!-- Search -->
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-10">
                <div class="input-group">
                    <span class="input-group-text"><i class="fas fa-search"></i></span>
                    <input type="text" class="form-control" name="search" 
                           placeholder="Search by patient name or phone..." 
                           value="<?php echo htmlspecialchars($searchQuery); ?>">
                </div>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-primary w-100">Search</button>
            </div>
        </form>
        <?php if ($searchQuery): ?>
            <div class="mt-2">
                <a href="patients.php" class="btn btn-sm btn-secondary">
                    <i class="fas fa-times"></i> Clear Search
                </a>
            </div>
        <?php endif; ?>
    </div>
</div>

<!-- Patient Cards -->
<div class="row">
    <?php if (empty($patients)): ?>
        <div class="col-12">
            <div class="alert alert-info text-center">
                <i class="fas fa-info-circle"></i> No patients found.
            </div>
        </div>
    <?php else: ?>
        <?php foreach ($patients as $patient): ?>
        <div class="col-md-6 mb-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <h5 class="card-title">
                                <i class="fas fa-user-circle"></i>
                                <?php echo htmlspecialchars($patient['full_name']); ?>
                            </h5>
                            <p class="card-text">
                                <small class="text-muted">
                                    <i class="fas fa-hashtag"></i> Patient ID: <?php echo $patient['patient_id']; ?>
                                </small>
                            </p>
                        </div>
                        <span class="badge bg-info">
                            <?php echo $patient['visit_count']; ?> visits
                        </span>
                    </div>
                    
                    <hr>
                    
                    <div class="row g-2">
                        <div class="col-6">
                            <small class="text-muted">Age</small>
                            <div><?php echo $patient['age']; ?> years</div>
                        </div>
                        <div class="col-6">
                            <small class="text-muted">Gender</small>
                            <div>
                                <i class="fas fa-<?php echo $patient['gender'] === 'Male' ? 'mars' : 'venus'; ?>"></i>
                                <?php echo $patient['gender']; ?>
                            </div>
                        </div>
                        <div class="col-12">
                            <small class="text-muted">Phone</small>
                            <div>
                                <i class="fas fa-phone"></i>
                                <?php echo htmlspecialchars($patient['phone']); ?>
                            </div>
                        </div>
                        <div class="col-12">
                            <small class="text-muted">Last Visit</small>
                            <div>
                                <i class="fas fa-calendar"></i>
                                <?php echo date('F j, Y - H:i', strtotime($patient['last_visit'])); ?>
                            </div>
                        </div>
                    </div>
                    
                    <hr>
                    
                    <div class="d-flex gap-2">
                        <button class="btn btn-sm btn-primary" 
                                onclick="viewMedicalHistory(<?php echo $patient['patient_id']; ?>)">
                            <i class="fas fa-history"></i> Medical History
                        </button>
                        <button class="btn btn-sm btn-info" 
                                onclick="viewPatientDetails(<?php echo $patient['patient_id']; ?>)">
                            <i class="fas fa-info-circle"></i> Details
                        </button>
                    </div>
                </div>
            </div>
        </div>
        <?php endforeach; ?>
    <?php endif; ?>
</div>

<!-- Patient Detail Modal -->
<div class="modal fade" id="patientDetailModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-user"></i> Patient Details</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="patientDetailContent">
                <div class="text-center">
                    <div class="spinner-border" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Medical History Modal -->
<div class="modal fade" id="medicalHistoryModal" tabindex="-1">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title"><i class="fas fa-file-medical"></i> Medical History</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="medicalHistoryContent">
                <div class="text-center">
                    <div class="spinner-border" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
$pageScripts = <<<'JS'
<script>
    function viewPatientDetails(patientId) {
        const modal = new bootstrap.Modal(document.getElementById('patientDetailModal'));
        const content = document.getElementById('patientDetailContent');
        
        
        content.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"></div></div>';
        modal.show();
        
        fetch('/hospital_management/api/get_patient_emr.php?patient_id=' + patientId)
            .then(response => response.json())
            .then(data => {
                if (data.success && data.details) {
                    const p = data.details;
                    content.innerHTML = `
                        <div class="row">
                            <div class="col-md-6">
                                <p class="mb-1 text-muted">Full Name</p>
                                <h6>${p.full_name}</h6>
                                <p class="mb-1 text-muted">Gender</p>
                                <h6>${p.gender}</h6>
                                <p class="mb-1 text-muted">Date of Birth</p>
                                <h6>${p.date_of_birth}</h6>
                            </div>
                            <div class="col-md-6">
                                <p class="mb-1 text-muted">Phone</p>
                                <h6>${p.phone}</h6>
                                <p class="mb-1 text-muted">Email</p>
                                <h6>${p.email || 'N/A'}</h6>
                                <p class="mb-1 text-muted">Address</p>
                                <h6>${p.address}</h6>
                            </div>
                        </div>
                    `;
                } else {
                    content.innerHTML = '<div class="alert alert-danger">Cannot load patient details.</div>';
                }
            })
            .catch(err => {
                content.innerHTML = '<div class="alert alert-danger">Connection error.</div>';
            });
    }
    
    function viewMedicalHistory(patientId) {
        const modal = new bootstrap.Modal(document.getElementById('medicalHistoryModal'));
        const content = document.getElementById('medicalHistoryContent');
        
        content.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"></div></div>';
        modal.show();
        
        fetch('/hospital_management/api/get_patient_emr.php?patient_id=' + patientId)
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    let html = '<div class="table-responsive"><table class="table table-hover">';
                    html += '<thead class="table-light"><tr><th>Date</th><th>Doctor</th><th>Dept</th><th>Diagnoses</th><th>Notes</th></tr></thead><tbody>';
                    
                    if (data.history.length === 0) {
                        html += '<tr><td colspan="5" class="text-center text-muted">No medical history found</td></tr>';
                    } else {
                        data.history.forEach(visit => {
                            const visitDate = new Date(visit.visit_start_time).toLocaleDateString('vi-VN');
                            const escapeHtml = (text) => {
                                const div = document.createElement('div');
                                div.textContent = text;
                                return div.innerHTML;
                            };
                            html += '<tr>' +
                                '<td><strong>' + escapeHtml(visitDate) + '</strong></td>' +
                                '<td>' + escapeHtml(visit.consulting_doctor) + '</td>' +
                                '<td><span class="badge bg-light text-dark">' + escapeHtml(visit.department_name) + '</span></td>' +
                                '<td><small>' + (visit.all_diagnoses ? escapeHtml(visit.all_diagnoses) : '<span class="text-muted">N/A</span>') + '</small></td>' +
                                '<td><small>' + escapeHtml(visit.clinical_note || '') + '</small></td>' +
                                '</tr>';
                        });
                    }
                    
                    html += '</tbody></table></div>';
                    content.innerHTML = html;
                } else {
                    content.innerHTML = '<div class="alert alert-danger">' + (data.message || 'Error loading history') + '</div>';
                }
            })
            .catch(error => {
                content.innerHTML = '<div class="alert alert-danger">Failed to fetch data from API.</div>';
            });
    }
</script>
JS;

require_once '../../includes/footer.php';
?>