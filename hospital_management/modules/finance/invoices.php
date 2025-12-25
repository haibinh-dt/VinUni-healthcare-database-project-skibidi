<?php
$pageTitle = "Invoice Management";
require_once '../../includes/header.php';
require_once '../../config/database.php';

requireRole('FINANCE');

$db = new Database();
$conn = $db->getConnection();

$filterStatus = $_GET['status'] ?? '';
$searchQuery = $_GET['search'] ?? '';

$whereConditions = [];
$params = [];

if ($filterStatus) {
    $whereConditions[] = "pi.status = ?";
    $params[] = $filterStatus;
}

if ($searchQuery) {
    $whereConditions[] = "p.full_name LIKE ?";
    $params[] = "%$searchQuery%";
}

$whereClause = empty($whereConditions) ? '' : 'WHERE ' . implode(' AND ', $whereConditions);

$sql = "
    SELECT 
        pi.patient_invoice_id,
        pi.invoice_date,
        pi.total_amount,
        pi.status,
        p.full_name as patient_name,
        COALESCE(SUM(pay.amount), 0) as amount_paid
    FROM PatientInvoice pi
    JOIN Visit v ON pi.visit_id = v.visit_id
    JOIN Patient p ON v.patient_id = p.patient_id
    LEFT JOIN Payment pay ON pi.patient_invoice_id = pay.invoice_id
    $whereClause
    GROUP BY pi.patient_invoice_id
    ORDER BY pi.invoice_date DESC
    LIMIT 100
";

$stmt = $conn->prepare($sql);
$stmt->execute($params);
$invoices = $stmt->fetchAll();
?>

<h2><i class="fas fa-file-invoice-dollar"></i> Invoice Management</h2>

<!-- Filters -->
<div class="card my-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-4">
                <input type="text" class="form-control" name="search" 
                       placeholder="Search patient name..." value="<?php echo htmlspecialchars($searchQuery); ?>">
            </div>
            <div class="col-md-3">
                <select class="form-select" name="status">
                    <option value="">All Statuses</option>
                    <option value="PAID" <?php echo $filterStatus === 'PAID' ? 'selected' : ''; ?>>Paid</option>
                    <option value="NOT PAID" <?php echo $filterStatus === 'NOT PAID' ? 'selected' : ''; ?>>Not Paid</option>
                </select>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-primary w-100">Filter</button>
            </div>
            <div class="col-md-3">
                <a href="invoices.php" class="btn btn-secondary w-100">Clear</a>
            </div>
        </form>
    </div>
</div>

<!-- Invoice Table -->
<div class="card">
    <div class="card-header">
        <i class="fas fa-list"></i> Invoices
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Invoice ID</th>
                        <th>Date</th>
                        <th>Patient</th>
                        <th class="text-end">Total Amount</th>
                        <th class="text-end">Paid</th>
                        <th class="text-end">Balance</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($invoices as $inv): ?>
                    <tr>
                        <td><strong>#<?php echo $inv['patient_invoice_id']; ?></strong></td>
                        <td><?php echo date('M d, Y', strtotime($inv['invoice_date'])); ?></td>
                        <td><?php echo htmlspecialchars($inv['patient_name']); ?></td>
                        <td class="text-end"><?php echo number_format($inv['total_amount']); ?> ₫</td>
                        <td class="text-end"><?php echo number_format($inv['amount_paid']); ?> ₫</td>
                        <td class="text-end">
                            <strong><?php echo number_format($inv['total_amount'] - $inv['amount_paid']); ?> ₫</strong>
                        </td>
                        <td>
                            <span class="badge bg-<?php echo $inv['status'] === 'PAID' ? 'success' : 'warning'; ?>">
                                <?php echo $inv['status']; ?>
                            </span>
                        </td>
                        <td>
                            <a href="payments.php?invoice_id=<?php echo $inv['patient_invoice_id']; ?>" 
                               class="btn btn-sm btn-primary">
                                <i class="fas fa-money-bill-wave"></i> Record Payment
                            </a>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php require_once '../../includes/footer.php'; ?>