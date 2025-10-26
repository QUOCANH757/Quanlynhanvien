<?php
/**
 * File: src/common/Database.php
 * Quản lý kết nối cơ sở dữ liệu xin chaof
 */

class Database {
    private static $instance = null;
    private $pdo;
    
    private function __construct() {
        // Thông tin kết nối CSDL
        $host = 'localhost';
        $dbname = 'quanlynhansu';
        $username = 'root';
        $password = '';
        
        try {
$this->pdo = new PDO(
    "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
    $username,
    $password,
    [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]
);
        } catch (PDOException $e) {
            die('Lỗi kết nối cơ sở dữ liệu: ' . $e->getMessage());
        }
    }
    
    // Singleton pattern
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }
    
    // Lấy PDO connection
    public function getConnection() {
        return $this->pdo;
    }
    
    // Thực thi truy vấn SELECT
    public function query($sql, $params = []) {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }
    
    // Thực thi truy vấn SELECT một bản ghi
    public function queryOne($sql, $params = []) {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetch();
    }
    
    // Thực thi INSERT/UPDATE/DELETE
    public function execute($sql, $params = []) {
        $stmt = $this->pdo->prepare($sql);
        return $stmt->execute($params);
    }
    
    // Lấy ID vừa insert
    public function lastInsertId() {
        return $this->pdo->lastInsertId();
    }
}
