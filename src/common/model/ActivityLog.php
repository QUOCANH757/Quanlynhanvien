<?php
/**
 * File: src/common/model/ActivityLog.php
 * Ghi và đọc nhật ký hoạt động người dùng
 */

class ActivityLog
{
	private $db;
	private $table = 'activity_logs';
	private $perPage = 10;

	public function __construct()
	{
		$this->db = Database::getInstance()->getConnection();
	}

	public function log($action, $userId = 0, $studentId = null, $details = '')
	{
		try {
			// Kiểm tra bảng có tồn tại không
			$checkTable = $this->db->query("SHOW TABLES LIKE '{$this->table}'");
			if ($checkTable->rowCount() == 0) {
				// Tạo bảng nếu chưa tồn tại
				$this->createTable();
			}
			
			$sql = "INSERT INTO {$this->table} (action, user_id, student_id, details, created_at) VALUES (?, ?, ?, ?, NOW())";
			$stmt = $this->db->prepare($sql);
			return $stmt->execute([$action, (int)$userId, $studentId, $details]);
		} catch (Exception $e) {
			// Nếu lỗi, chỉ log ra error log thay vì crash
			error_log("ActivityLog error: " . $e->getMessage());
			return false;
		}
	}
	
	private function createTable()
	{
		$sql = "CREATE TABLE IF NOT EXISTS {$this->table} (
			id INT AUTO_INCREMENT PRIMARY KEY,
			action VARCHAR(100) NOT NULL,
			user_id INT DEFAULT 0,
			student_id INT NULL,
			details TEXT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
		
		$this->db->exec($sql);
	}

	public function getAll($page = 1)
	{
		try {
			// Kiểm tra bảng có tồn tại không
			$checkTable = $this->db->query("SHOW TABLES LIKE '{$this->table}'");
			if ($checkTable->rowCount() == 0) {
				$this->createTable();
			}
			
			$page = max(1, (int)$page);
			$offset = ($page - 1) * $this->perPage;
			$sql = "SELECT * FROM {$this->table} ORDER BY id DESC LIMIT ? OFFSET ?";
			$stmt = $this->db->prepare($sql);
			$stmt->bindValue(1, $this->perPage, PDO::PARAM_INT);
			$stmt->bindValue(2, $offset, PDO::PARAM_INT);
			$stmt->execute();
			return $stmt->fetchAll();
		} catch (Exception $e) {
			error_log("ActivityLog getAll error: " . $e->getMessage());
			return [];
		}
	}

	public function getTotal()
	{
		try {
			// Kiểm tra bảng có tồn tại không
			$checkTable = $this->db->query("SHOW TABLES LIKE '{$this->table}'");
			if ($checkTable->rowCount() == 0) {
				$this->createTable();
				return 0;
			}
			
			$sql = "SELECT COUNT(*) AS total FROM {$this->table}";
			$stmt = $this->db->query($sql);
			$row = $stmt->fetch();
			return (int)($row['total'] ?? 0);
		} catch (Exception $e) {
			error_log("ActivityLog getTotal error: " . $e->getMessage());
			return 0;
		}
	}

	public function getPerPage()
	{
		return $this->perPage;
	}
}


