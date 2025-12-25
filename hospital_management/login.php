<?php
session_start();

// If already logged in, redirect to dashboard
if (isset($_SESSION['user_id'])) {
    header("Location: index.php");
    exit();
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_once 'config/database.php';
    
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    if (empty($username) || empty($password)) {
        $error = 'Please enter both username and password';
    } else {
        try {
            $db = new Database();
            $conn = $db->getConnection();
            
            // Prepare input and output parameters
            $inParams = [$username, $password, $_SERVER['REMOTE_ADDR']];
            $outParams = ['p_user_id', 'p_role', 'p_status_code', 'p_message', 'p_must_change'];

            $result = $db->callProcedure('sp_verify_login', $inParams, $outParams);

            if ($result['p_status_code'] == 200) {
                $_SESSION['user_id'] = $result['p_user_id'];
                $_SESSION['username'] = $username;
                $_SESSION['role'] = $result['p_role'];
                $_SESSION['must_change'] = $result['p_must_change'];

                session_regenerate_id(true);
                

                header("Location: index.php");
                exit();
            } else {
                $error = $result['p_message'];
            }
        } catch (Exception $e) {
            $error = 'System error. Please try again later.';
            error_log($e->getMessage());
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Hospital Management System</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <div class="login-container">
        <div class="login-card card">
            <div class="card-header text-white">
                <i class="fas fa-hospital-user"></i>
                <h4 class="mt-3 mb-0">Hospital Management System</h4>
                <p class="mb-0"><small>Please login to continue</small></p>
            </div>
            <div class="card-body p-4">
                <?php if ($error): ?>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="fas fa-exclamation-circle"></i> <?php echo htmlspecialchars($error); ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <?php endif; ?>
                
                <form method="POST" action="">
                    <div class="mb-3">
                        <label for="username" class="form-label">
                            <i class="fas fa-user"></i> Username
                        </label>
                        <input type="text" class="form-control" id="username" name="username" required autofocus>
                    </div>
                    
                    <div class="mb-3">
                        <label for="password" class="form-label">
                            <i class="fas fa-lock"></i> Password
                        </label>
                        <input type="password" class="form-control" id="password" name="password" required>
                    </div>
                    
                    <button type="submit" class="btn btn-primary w-100 py-2">
                        <i class="fas fa-sign-in-alt"></i> Login
                    </button>
                </form>
                
                <hr class="my-4">
                
                <div class="text-center">
                    <h6 class="text-muted mb-3">Demo Accounts</h6>
                    <div class="row g-2">
                        <div class="col-6">
                            <button class="btn btn-outline-primary btn-sm w-100" onclick="fillCredentials('admin', 'Admin123')">
                                <i class="fas fa-user-shield"></i> Admin
                            </button>
                        </div>
                        <div class="col-6">
                            <button class="btn btn-outline-success btn-sm w-100" onclick="fillCredentials('doc_minh', 'Doctor123')">
                                <i class="fas fa-user-md"></i> Doctor
                            </button>
                        </div>
                        <div class="col-6">
                            <button class="btn btn-outline-info btn-sm w-100" onclick="fillCredentials('pharmacist1', 'Pharma123')">
                                <i class="fas fa-pills"></i> Pharmacist
                            </button>
                        </div>
                        <div class="col-6">
                            <button class="btn btn-outline-warning btn-sm w-100" onclick="fillCredentials('finance1', 'Finance123')">
                                <i class="fas fa-dollar-sign"></i> Finance
                            </button>
                        </div>
                        <div class="col-12">
                            <button class="btn btn-outline-secondary btn-sm w-100" onclick="fillCredentials('receptionist1', 'Reception123')">
                                <i class="fas fa-clipboard"></i> Receptionist
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function fillCredentials(username, password) {
            document.getElementById('username').value = username;
            document.getElementById('password').value = password;
        }
    </script>
</body>
</html>