<?php
require_once '../../config/database.php';
session_start(); // Ensure session is started for Flash Messages

$db = new Database();
$conn = $db->getConnection();

// Handle patient registration
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'register') {
    $fullName = $_POST['full_name'];
    $dob = $_POST['date_of_birth'];
    $gender = $_POST['gender'];
    $phone = $_POST['phone'];
    $email = $_POST['email'];
    $address = $_POST['address'];
    
    try {
        $stmt = $conn->prepare("CALL sp_register_patient(?, ?, ?, ?, ?, ?, ?, @pid, @status, @msg)");
        $stmt->execute([$fullName, $dob, $gender, $phone, $email, $address, $_SESSION['user_id']]);
        
        $result = $conn->query("SELECT @pid as patient_id, @status as status, @msg as message")->fetch();
        
        if ($result['status'] == 201) {
            // Directly setting the session array
            $_SESSION['flash_message'] = [
                'text' => 'Patient registered successfully! Patient ID: ' . $result['patient_id'],
                'type' => 'success'
            ];
        } else {
            $_SESSION['flash_message'] = [
                'text' => 'Error: ' . $result['message'],
                'type' => 'danger'
            ];
        }
    } catch (Exception $e) {
        setFlashMessage('Error registering patient: ' . $e->getMessage(), 'danger');
    }
    
    header("Location: patients.php");
    exit();
}

// Search functionality
$searchQuery = $_GET['search'] ?? '';
$whereClause = '';
$params = [];

if ($searchQuery) {
    $whereClause = "full_name LIKE ? OR phone LIKE ?";
    $params = ["%$searchQuery%", "%$searchQuery%"];
}

// Get patients
$sql = "SELECT * FROM v_patient_master_record";
if ($whereClause) {
    $sql .= " WHERE $whereClause";
}
$sql .= " ORDER BY patient_id DESC LIMIT 100";

$stmt = $conn->prepare($sql);
$stmt->execute($params);
$patients = $stmt->fetchAll();

$pageTitle = "Patient Management";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('RECEPTIONIST');
?>

<!-- Page Header -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="fas fa-users"></i> Patient Management</h2>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#registerPatientModal">
        <i class="fas fa-user-plus"></i> Register New Patient
    </button>
</div>

<!-- Search Bar -->
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-10">
                <div class="input-group">
                    <span class="input-group-text"><i class="fas fa-search"></i></span>
                    <input type="text" class="form-control" name="search" 
                           placeholder="Search by name or phone number..." 
                           value="<?php echo htmlspecialchars($searchQuery); ?>">
                </div>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-primary w-100">Search</button>
            </div>
        </form>
    </div>
</div>

<!-- Patient List -->
<div class="card">
    <div class="card-header">
        <i class="fas fa-list"></i> Patient Directory
        <?php if ($searchQuery): ?>
            <span class="badge bg-info">Search: "<?php echo htmlspecialchars($searchQuery); ?>"</span>
            <a href="patients.php" class="btn btn-sm btn-secondary float-end">Clear Search</a>
        <?php endif; ?>
    </div>
    <div class="card-body">
        <?php if (empty($patients)): ?>
            <div class="alert alert-info text-center">
                <i class="fas fa-info-circle"></i> No patients found. Register a new patient to get started.
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Full Name</th>
                            <th>Age</th>
                            <th>Gender</th>
                            <th>Phone</th>
                            <th>Last Visit</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($patients as $patient): ?>
                        <tr>
                            <td><strong>#<?php echo $patient['patient_id']; ?></strong></td>
                            <td>
                                <i class="fas fa-user-circle"></i> 
                                <?php echo htmlspecialchars($patient['full_name']); ?>
                            </td>
                            <td><?php echo $patient['age']; ?> years</td>
                            <td>
                                <i class="fas fa-<?php echo $patient['gender'] === 'Male' ? 'mars' : 'venus'; ?>"></i>
                                <?php echo $patient['gender']; ?>
                            </td>
                            <td>
                                <i class="fas fa-phone"></i> 
                                <?php echo htmlspecialchars($patient['phone']); ?>
                            </td>
                            <td>
                                <?php if ($patient['last_visit']): ?>
                                    <span class="text-muted">
                                        <?php echo date('M d, Y', strtotime($patient['last_visit'])); ?>
                                    </span>
                                <?php else: ?>
                                    <span class="badge bg-secondary">No visits</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <a href="appointments.php?patient_id=<?php echo $patient['patient_id']; ?>" 
                                   class="btn btn-sm btn-primary" title="Book Appointment">
                                    <i class="fas fa-calendar-plus"></i>
                                </a>
                                <button class="btn btn-sm btn-info" 
                                        onclick="viewPatientDetails(<?php echo $patient['patient_id']; ?>)"
                                        title="View Details">
                                    <i class="fas fa-info-circle"></i>
                                </button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            
            <div class="mt-3">
                <p class="text-muted">
                    <i class="fas fa-users"></i> Showing <?php echo count($patients); ?> patient(s)
                </p>
            </div>
        <?php endif; ?>
    </div>
</div>

<!-- Register Patient Modal -->
<div class="modal fade" id="registerPatientModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title"><i class="fas fa-user-plus"></i> Register New Patient</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" class="needs-validation" novalidate>
                <input type="hidden" name="action" value="register">
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="full_name" class="form-label">Full Name *</label>
                            <input type="text" class="form-control" id="full_name" name="full_name" required>
                            <div class="invalid-feedback">Please provide patient's full name</div>
                        </div>
                        
                        <div class="col-md-6 mb-3">
                            <label for="date_of_birth" class="form-label">Date of Birth *</label>
                            <input type="date" class="form-control" id="date_of_birth" name="date_of_birth" 
                                   max="<?php echo date('Y-m-d'); ?>" required>
                            <div class="invalid-feedback">Please provide date of birth</div>
                        </div>
                        
                        <div class="col-md-6 mb-3">
                            <label for="gender" class="form-label">Gender *</label>
                            <select class="form-select" id="gender" name="gender" required>
                                <option value="">-- Select --</option>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                            </select>
                            <div class="invalid-feedback">Please select gender</div>
                        </div>
                        
                        <div class="col-md-6 mb-3">
                            <label for="phone" class="form-label">Phone Number *</label>
                            <input type="tel" class="form-control" id="phone" name="phone" 
                                   pattern="[0-9\-\+\s\(\)]+" required>
                            <div class="invalid-feedback">Please provide phone number</div>
                        </div>
                        
                        <div class="col-md-12 mb-3">
                            <label for="email" class="form-label">Email (Optional)</label>
                            <input type="email" class="form-control" id="email" name="email">
                        </div>
                        
                        <div class="col-md-12 mb-3">
                            <label for="address" class="form-label">Address</label>
                            <textarea class="form-control" id="address" name="address" rows="2"></textarea>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Register Patient
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Patient Detail Modal -->
<div class="modal fade" id="patientDetailModal" tabindex="-1" aria-labelledby="patientDetailModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-info text-white">
                <h5 class="modal-title" id="patientDetailModalLabel">
                    <i class="fas fa-user-medical"></i> Patient Medical Record
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="patientDetailContent">
                </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<?php
$pageScripts = <<<'JS'
<script>
    function viewPatientDetails(patientId) {
        // Initialize the Bootstrap Modal
        const modalElement = document.getElementById('patientDetailModal');
        const modal = new bootstrap.Modal(modalElement);
        const content = document.getElementById('patientDetailContent');
        
        // Show loading spinner immediately
        content.innerHTML = '<div class="text-center my-5"><div class="spinner-border text-info" role="status"></div><p class="mt-2">Fetching medical records...</p></div>';
        modal.show();
        
        // Fetch data from your API
        fetch('/hospital_management/api/get_patient_emr.php?patient_id=' + patientId)
            .then(response => response.json())
            .then(data => {
                if (data.success && data.details) {
                    const p = data.details;
                    content.innerHTML = `
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="small text-muted">Full Name</label>
                                <h6 class="border-bottom pb-2">${p.full_name}</h6>
                                <label class="small text-muted">Gender</label>
                                <h6 class="border-bottom pb-2">${p.gender}</h6>
                                <label class="small text-muted">Date of Birth</label>
                                <h6 class="border-bottom pb-2">${p.date_of_birth}</h6>
                            </div>
                            <div class="col-md-6">
                                <label class="small text-muted">Phone Number</label>
                                <h6 class="border-bottom pb-2">${p.phone}</h6>
                                <label class="small text-muted">Email Address</label>
                                <h6 class="border-bottom pb-2">${p.email || 'No email provided'}</h6>
                                <label class="small text-muted">Residential Address</label>
                                <h6 class="border-bottom pb-2">${p.address}</h6>
                            </div>
                        </div>
                    `;
                } else {
                    content.innerHTML = '<div class="alert alert-warning">No details found for this patient.</div>';
                }
            })
            .catch(err => {
                content.innerHTML = '<div class="alert alert-danger">Error connecting to server. Please try again.</div>';
            });
    }
</script>
JS;

echo $pageScripts; // This sends the JS to the browser
require_once '../../includes/footer.php';
?>