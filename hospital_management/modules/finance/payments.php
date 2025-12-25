<?php
require_once '../../config/database.php';
session_start(); // Ensure session is started for Flash Messages

$db = new Database();
$conn = $db->getConnection();

// Handle payment recording
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $invoiceId = $_POST['invoice_id'];
    $amount = $_POST['amount'];
    $paymentMethod = $_POST['payment_method'];
    
    try {
        $stmt = $conn->prepare("CALL sp_record_payment(?, ?, ?, ?, @pay_id, @status, @msg)");
        $stmt->execute([$invoiceId, $amount, $paymentMethod, $_SESSION['user_id']]);
        
        // Use standard Session instead of function
        $_SESSION['flash_message'] = ['text' => 'Payment recorded successfully', 'type' => 'success'];
        
        header("Location: payments.php?invoice_id=$invoiceId");
        exit();
    } catch (Exception $e) {
        $_SESSION['flash_message'] = ['text' => 'Error: ' . $e->getMessage(), 'type' => 'danger'];
    }
}

// Get invoice details
$invoiceId = $_GET['invoice_id'] ?? 0;
$invoice = null;
$payments = [];

if ($invoiceId) {
    $stmt = $conn->prepare("SELECT * FROM v_invoice_payment_tracker WHERE patient_invoice_id = ?");
    $stmt->execute([$invoiceId]);
    $invoice = $stmt->fetch();
    
    $stmt = $conn->prepare("SELECT * FROM Payment WHERE invoice_id = ? ORDER BY created_at DESC");
    $stmt->execute([$invoiceId]);
    $payments = $stmt->fetchAll();
}

$pageTitle = "Payment Recording";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('FINANCE');
?>

<h2><i class="fas fa-money-bill-wave"></i> Payment Recording</h2>

<?php if (!$invoice): ?>
<div class="card mt-4">
    <div class="card-body text-center py-5">
        <i class="fas fa-info-circle fa-3x text-muted mb-3"></i>
        <h5>Select an invoice from the Invoice Management page to record payment</h5>
        <a href="invoices.php" class="btn btn-primary mt-3">
            <i class="fas fa-file-invoice-dollar"></i> Go to Invoices
        </a>
    </div>
</div>
<?php else: ?>

<!-- Invoice Info -->
<div class="card mt-4">
    <div class="card-header bg-primary text-white">
        <i class="fas fa-file-invoice"></i> Invoice #<?php echo $invoice['patient_invoice_id']; ?>
    </div>
    <div class="card-body">
        <div class="row">
            <div class="col-md-6">
                <p>
                    <strong>Patient:</strong> <?php echo htmlspecialchars($invoice['patient_name']); ?><br>
                    <strong>Total Amount:</strong> <?php echo number_format($invoice['total_amount']); ?> ₫
                </p>
            </div>
            <div class="col-md-6 text-end">
                <p>
                    <strong>Status:</strong> 
                    <span class="badge bg-<?php echo $invoice['payment_status'] === 'PAID' ? 'success' : 'warning'; ?>">
                        <?php echo $invoice['payment_status']; ?>
                    </span><br>
                    <strong>Balance Due:</strong> 
                    <span class="text-danger fs-4"><?php echo number_format($invoice['balance_due']); ?> ₫</span>
                </p>
            </div>
        </div>
    </div>
</div>

<!-- Payment History -->
<div class="card mt-3">
    <div class="card-header">
        <i class="fas fa-history"></i> Payment History
    </div>
    <div class="card-body">
        <?php if (empty($payments)): ?>
            <p class="text-muted text-center">No payments recorded yet</p>
        <?php else: ?>
            <table class="table">
                <thead>
                    <tr>
                        <th>Date & Time</th>
                        <th>Amount</th>
                        <th>Method</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($payments as $pay): ?>
                    <tr>
                        <td><?php echo date('M d, Y - H:i', strtotime($pay['created_at'])); ?></td>
                        <td><strong><?php echo number_format($pay['amount']); ?> ₫</strong></td>
                        <td><?php echo htmlspecialchars($pay['payment_method']); ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        <?php endif; ?>
    </div>
</div>

<!-- Record Payment Form -->
<?php if ($invoice['balance_due'] > 0): ?>
<div class="card mt-3">
    <div class="card-header bg-success text-white">
        <i class="fas fa-plus"></i> Record New Payment
    </div>
    <div class="card-body">
        <form method="POST" class="row g-3">
            <input type="hidden" name="action" value="record_payment">
            <input type="hidden" name="invoice_id" value="<?php echo $invoiceId; ?>">
            
            <div class="col-md-4">
                <label class="form-label">Amount *</label>
                <input type="number" class="form-control" name="amount" 
                       max="<?php echo $invoice['balance_due']; ?>" 
                       value="<?php echo $invoice['balance_due']; ?>" 
                       step="0.01" required>
                <small class="text-muted">Maximum: <?php echo number_format($invoice['balance_due']); ?> ₫</small>
            </div>
            
            <div class="col-md-4">
                <label class="form-label">Payment Method *</label>
                <select class="form-select" name="payment_method" required>
                    <option value="">-- Select --</option>
                    <option value="CASH">Cash</option>
                    <option value="CREDIT_CARD">Credit Card</option>
                    <option value="DEBIT_CARD">Debit Card</option>
                    <option value="BANK_TRANSFER">Bank Transfer</option>
                    <option value="INSURANCE">Insurance</option>
                </select>
            </div>
            
            <div class="col-md-4 d-flex align-items-end">
                <button type="submit" class="btn btn-success w-100">
                    <i class="fas fa-check"></i> Record Payment
                </button>
            </div>
        </form>
    </div>
</div>
<?php endif; ?>

<?php endif; ?>

<?php require_once '../../includes/footer.php'; ?>