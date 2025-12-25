<?php
/**
 * Database Configuration
 * Central connection management using PDO
 */

class Database {
    private $host = "localhost";
    private $db_name = "hospital_management_system";
    private $username = "root";  // Change if different
    private $password = "";      // Change if you have a password
    private $conn;

    /**
     * Get database connection
     */
    public function getConnection() {
        $this->conn = null;

        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4",
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        } catch(PDOException $exception) {
            die("Connection error: " . $exception->getMessage());
        }

        return $this->conn;
    }

    /**
     * Call a stored procedure with parameters
     */
    public function callProcedure($procedureName, $inParams, $outParams) {
        if (!$this->conn) {
            $this->getConnection();
        }

        $inPlaceholders = implode(',', array_fill(0, count($inParams), '?'));
        $outPlaceholders = implode(',', array_map(fn($p) => "@$p", $outParams));

        $sql = "CALL $procedureName($inPlaceholders" .
            ($outPlaceholders ? ",$outPlaceholders" : "") . ")";

        $stmt = $this->conn->prepare($sql);
        $stmt->execute($inParams);

        while ($stmt->nextRowset()) {}

        $selectOut = "SELECT " . implode(',', array_map(
            fn($p) => "@$p AS $p", $outParams
        ));

        return $this->conn->query($selectOut)->fetch(PDO::FETCH_ASSOC);
    }


    /**
     * Call a stored procedure and fetch results
     */
    public function callProcedureAndFetch($procedureName, $params = []) {
        $placeholders = implode(',', array_fill(0, count($params), '?'));
        $sql = "CALL $procedureName($placeholders)";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute($params);
        $data = $stmt->fetchAll();
        while ($stmt->nextRowset()) {}
        return $data;
    }

    /**
     * Execute a view query
     */
    public function queryView($viewName, $whereClause = "", $params = [], $orderBy = "", $limit = "") {
        try {
            $sql = "SELECT * FROM $viewName";
            if ($whereClause) {
                $sql .= " WHERE $whereClause";
            }
            if ($orderBy)     $sql .= " ORDER BY $orderBy";
            if ($limit)       $sql .= " LIMIT $limit";
            
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            
            return $stmt->fetchAll();
        } catch(PDOException $e) {
            throw new Exception("Query error: " . $e->getMessage());
        }
    }
}
?>