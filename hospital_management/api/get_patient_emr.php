<?php
header('Content-Type: application/json');

// turn off error reporting for production
error_reporting(0); 
ini_set('display_errors', 0);

require_once '../config/database.php';

try {
    $db = new Database();
    
    // make sure the connection is established
    $conn = $db->getConnection(); 
    if (!$conn) {
        throw new Exception("Database connection failed.");
    }

    $patientId = $_GET['patient_id'] ?? 0;
    if (!$patientId) {
        throw new Exception("Invalid Patient ID");
    }

    // query medical history
    $history = $db->queryView(
        "v_patient_medical_history", 
        "patient_id = ?", 
        [$patientId], 
        "visit_start_time DESC"
    );

    $details = $db->queryView(
        "Patient", 
        "patient_id = ?", 
        [$patientId]
    );

    echo json_encode([
        'success' => true,
        'history' => $history,
        'details' => $details[0] ?? null
    ]);

} catch (Exception $e) {
    // return error as JSON
    echo json_encode([
        'success' => false, 
        'message' => $e->getMessage()
    ]);
}