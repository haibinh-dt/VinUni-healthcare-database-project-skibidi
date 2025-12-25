<?php
require_once '../../includes/session.php';
requireRole('ADMIN');
require_once '../../config/database.php';

$db = new Database();
$conn = $db->getConnection();

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'create_user') {
        $username = $_POST['username'];
        $password = $_POST['password'];
        $role = $_POST['role'];
        $passwordHash = hash('sha256', $password);
        
        try {
            $result = $db->callProcedure(
                'sp_create_user_with_default_password',
                [$username, $passwordHash, $role, $_SESSION['user_id']],
                ['new_id', 'status', 'msg']
            );

            if ($result['status'] == 201) {
                setFlashMessage('User created successfully', 'success');
            } else {
                setFlashMessage($result['msg'], 'danger');
            }

        } catch (Exception $e) {
            setFlashMessage('Error creating user: ' . $e->getMessage(), 'danger');
        }
        
        header("Location: users.php");
        exit();
    }
    
    if ($action === 'deactivate_user') {
        $userId = $_POST['user_id'];
        
        try {
            $result = $db->callProcedure("sp_deactivate_user", [$userId, $_SESSION['user_id']], ['status', 'msg']);
            
            if (isset($result['status']) && $result['status'] == 200) {
                setFlashMessage($result['msg'] ?? 'User deactivated successfully', 'success');
            } else {
                setFlashMessage($result['msg'] ?? 'Operation failed', 'danger');
            }
        } catch (Exception $e) {
            setFlashMessage('Error deactivating user', 'danger');
        }
        
        header("Location: users.php");
        exit();
    }
}

$pageTitle = "User Management";
require_once '../../includes/header.php';
require_once '../../config/database.php';

// Get all roles for dropdown
$stmt = $conn->query("SELECT role_name FROM Role ORDER BY role_name");
$roles = $stmt->fetchAll();

// Get users grouped by roles
$rows = $db->queryView('v_user_role_directory');

$users = [];
foreach ($rows as $row) {
    $uid = $row['user_id'];
    if (!isset($users[$uid])) {
        $users[$uid] = [
            'user_id' => $uid,
            'username' => $row['username'],
            'account_status' => $row['account_status'],
            'roles' => []
        ];
    }
    $users[$uid]['roles'][] = $row['role_name'];
}

$usersByRole = [];
foreach ($users as $user) {
    foreach ($user['roles'] as $role) {
        $usersByRole[$role][] = $user;
    }
}

?>

<!-- Page Header -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="fas fa-users-cog"></i> User Management</h2>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createUserModal">
        <i class="fas fa-user-plus"></i> Create New User
    </button>
</div>

<!-- Statistics Cards -->
<div class="row mb-4">
    <?php
    $totalUsers = count($users);
    $activeUsers = count(array_filter($users, fn($u) => $u['account_status'] === 'ACTIVE'));
    $lockedUsers = $totalUsers - $activeUsers;
    ?>
    <div class="col-md-4">
        <div class="kpi-card bg-primary text-white">
            <h3><?php echo $totalUsers; ?></h3>
            <p>Total Users</p>
        </div>
    </div>
    <div class="col-md-4">
        <div class="kpi-card bg-success text-white">
            <h3><?php echo $activeUsers; ?></h3>
            <p>Active Users</p>
        </div>
    </div>
    <div class="col-md-4">
        <div class="kpi-card bg-danger text-white">
            <h3><?php echo $lockedUsers; ?></h3>
            <p>Locked Accounts</p>
        </div>
    </div>
</div>

<!-- Users by Role -->
<?php foreach ($usersByRole as $roleName => $roleUsers): ?>
<div class="card mb-4">
    <div class="card-header">
        <i class="fas fa-user-tag"></i> <?php echo htmlspecialchars($roleName); ?> 
        <span class="badge bg-secondary"><?php echo count($roleUsers); ?></span>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>User ID</th>
                        <th>Username</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($roleUsers as $user): ?>
                    <tr>
                        <td>#<?php echo $user['user_id']; ?></td>
                        <td>
                            <i class="fas fa-user"></i> 
                            <strong><?php echo htmlspecialchars($user['username']); ?></strong>
                        </td>
                        <td>
                            <span class="badge bg-<?php echo $user['account_status'] === 'ACTIVE' ? 'success' : 'danger'; ?>">
                                <?php echo $user['account_status']; ?>
                            </span>
                        </td>
                        <td>
                            <?php if ($user['account_status'] === 'ACTIVE' && $user['user_id'] != $_SESSION['user_id']): ?>
                                <form method="POST" style="display: inline;" onsubmit="return confirm('Deactivate this user?');">
                                    <input type="hidden" name="action" value="deactivate_user">
                                    <input type="hidden" name="user_id" value="<?php echo $user['user_id']; ?>">
                                    <button type="submit" class="btn btn-sm btn-warning">
                                        <i class="fas fa-ban"></i> Deactivate
                                    </button>
                                </form>
                            <?php endif; ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<?php endforeach; ?>

<!-- Create User Modal -->
<div class="modal fade" id="createUserModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title"><i class="fas fa-user-plus"></i> Create New User</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" class="needs-validation" novalidate>
                <input type="hidden" name="action" value="create_user">
                <div class="modal-body">
                    <div class="mb-3">
                        <label for="username" class="form-label">Username *</label>
                        <input type="text" class="form-control" id="username" name="username" required 
                               pattern="[a-zA-Z0-9_]{3,50}" title="3-50 characters, letters, numbers, underscore only">
                        <div class="invalid-feedback">Please provide a valid username</div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="password" class="form-label">Password *</label>
                        <input type="password" class="form-control" id="password" name="password" required 
                               minlength="6" title="Minimum 6 characters">
                        <div class="invalid-feedback">Password must be at least 6 characters</div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="role" class="form-label">Role *</label>
                        <select class="form-select" id="role" name="role" required>
                            <option value="">-- Select Role --</option>
                            <?php foreach ($roles as $role): ?>
                                <option value="<?php echo htmlspecialchars($role['role_name']); ?>">
                                    <?php echo htmlspecialchars($role['role_name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                        <div class="invalid-feedback">Please select a role</div>
                    </div>
                    
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle"></i> User will be able to login immediately with the provided credentials.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Create User
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>