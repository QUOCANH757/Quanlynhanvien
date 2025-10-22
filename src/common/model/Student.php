<?php
/**
 * File: src/common/model/Student.php
 * Model xử lý Student - Hoàn chỉnh cho tất cả 10 bài tập
 */

class Student {
    private $db;
    private $table = 'students';
    private $perPage = 5; // Số sinh viên mỗi trang
    
    public function __construct() {
        // Sử dụng Database service hiện có
        $this->db = Database::getInstance();
    }
    
    // ============================================
    // BÀI 11: HIỂN THỊ THỐNG KÊ SỐ LƯỢNG SINH VIÊN
    // ============================================
    
    /**
     * Lấy tổng số sinh viên
     */
    public function getTotalStudents() {
        $sql = "SELECT COUNT(*) as total FROM {$this->table}";
        $result = $this->db->queryOne($sql);
        return $result['total'] ?? 0;
    }

    /**
     * Lấy số sinh viên có email @gmail.com
     */
    public function getGmailStudents() {
        $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE email LIKE '%@gmail.com'";
        $result = $this->db->queryOne($sql);
        return $result['count'] ?? 0;
    }

    /**
     * Lấy số sinh viên có SĐT bắt đầu bằng 09
     */
    public function getPhoneStartsWith09() {
        $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE phone LIKE '09%'";
        $result = $this->db->queryOne($sql);
        return $result['count'] ?? 0;
    }

    /**
     * Lấy tất cả thống kê
     */
    public function getStatistics() {
        return [
            'total' => $this->getTotalStudents(),
            'gmail' => $this->getGmailStudents(),
            'phone09' => $this->getPhoneStartsWith09()
        ];
    }
    
    // ============================================
    // BÀI 13: HIỂN THỊ CHI TIẾT SINH VIÊN
    // ============================================
    
    /**
     * Lấy sinh viên theo ID (với kiểm tra an toàn)
     */
    public function getById($id) {
        // Kiểm tra xem id có hợp lệ không
        if (!is_numeric($id) || $id <= 0) {
            return null;
        }
        
        $sql = "SELECT * FROM {$this->table} WHERE id = ?";
        $stmt = $this->db->getConnection()->prepare($sql);
        $stmt->execute([$id]);
        
        return $stmt->fetch();
    }
    
    // ============================================
    // BÀI 14: SẮP XẾP DANH SÁCH SINH VIÊN
    // ============================================
    
    /**
     * Lấy tất cả sinh viên (có sắp xếp)
     */
    public function getAll($sort = 'id', $order = 'ASC') {
        // Định danh các cột cho phép sort
        $allowedColumns = ['id', 'name', 'email', 'phone', 'created_at'];
        $allowedOrders = ['ASC', 'DESC'];
        
        // Kiểm tra hợp lệ
        $sort = in_array($sort, $allowedColumns) ? $sort : 'id';
        $order = in_array(strtoupper($order), $allowedOrders) ? strtoupper($order) : 'ASC';
        
        $sql = "SELECT * FROM {$this->table} ORDER BY {$sort} {$order}";
        return $this->db->query($sql);
    }

    /**
     * Lấy sinh viên với phân trang và sắp xếp
     */
    public function getAllPaginated($page = 1, $sort = 'id', $order = 'ASC', $search = '') {
        $allowedColumns = ['id', 'name', 'email', 'phone', 'created_at', 'updated_at'];
        $allowedOrders = ['ASC', 'DESC'];
        
        $sort = in_array($sort, $allowedColumns) ? $sort : 'id';
        $order = in_array(strtoupper($order), $allowedOrders) ? strtoupper($order) : 'ASC';
        
        $page = max(1, (int)$page);
        $offset = ($page - 1) * $this->perPage;
        
        $sql = "SELECT id, name, email, phone, avatar, created_at, updated_at FROM {$this->table}";
        $params = [];
        
        if (!empty($search)) {
            $sql .= " WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?";
            $params = ["%$search%", "%$search%", "%$search%"];
        }
        
        // Tránh lỗi PDO quote số cho LIMIT/OFFSET bằng cách chèn trực tiếp số nguyên
        $limit = (int)$this->perPage;
        $offset = (int)$offset;
        $sql .= " ORDER BY {$sort} {$order} LIMIT {$limit} OFFSET {$offset}";

        $stmt = $this->db->getConnection()->prepare($sql);
        $stmt->execute($params);
        
        return $stmt->fetchAll();
    }
    
    // ============================================
    // BÀI 2: THÊM SINH VIÊN MỚI
    // ============================================
    
    /**
     * Tạo sinh viên mới
     */
    public function create($name, $email, $phone, $avatar = null) {
        // Validate email
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['success' => false, 'message' => 'Email không hợp lệ'];
        }
        
        // Kiểm tra email đã tồn tại
        $existingSql = "SELECT COUNT(*) as count FROM {$this->table} WHERE email = ?";
        $existingStmt = $this->db->getConnection()->prepare($existingSql);
        $existingStmt->execute([$email]);
        if ($existingStmt->fetch()['count'] > 0) {
            return ['success' => false, 'message' => 'Email đã tồn tại'];
        }
        
        $sql = "INSERT INTO {$this->table} (name, email, phone, avatar, created_at, updated_at) 
                VALUES (?, ?, ?, ?, NOW(), NOW())";
        
        try {
            $stmt = $this->db->getConnection()->prepare($sql);
            $stmt->execute([$name, $email, $phone, $avatar]);
            return ['success' => true, 'message' => 'Thêm sinh viên thành công'];
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Lỗi: ' . $e->getMessage()];
        }
    }
    
    // ============================================
    // BÀI 3: CẬP NHẬT SINH VIÊN
    // ============================================
    
    /**
     * Cập nhật sinh viên
     */
    public function update($id, $name, $email, $phone, $avatar = null) {
        // Kiểm tra id hợp lệ
        if (!is_numeric($id) || $id <= 0) {
            return ['success' => false, 'message' => 'ID không hợp lệ'];
        }
        
        // Validate email
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['success' => false, 'message' => 'Email không hợp lệ'];
        }
        
        try {
            if ($avatar !== null) {
                $sql = "UPDATE {$this->table} 
                        SET name = ?, email = ?, phone = ?, avatar = ?, updated_at = NOW()
                        WHERE id = ?";
                $stmt = $this->db->getConnection()->prepare($sql);
                $stmt->execute([$name, $email, $phone, $avatar, $id]);
            } else {
                $sql = "UPDATE {$this->table} 
                        SET name = ?, email = ?, phone = ?, updated_at = NOW()
                        WHERE id = ?";
                $stmt = $this->db->getConnection()->prepare($sql);
                $stmt->execute([$name, $email, $phone, $id]);
            }
            return ['success' => true, 'message' => 'Cập nhật sinh viên thành công'];
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Lỗi: ' . $e->getMessage()];
        }
    }
    
    // ============================================
    // BÀI 4: XÓA SINH VIÊN
    // ============================================
    
    /**
     * Xóa sinh viên
     */
    public function delete($id) {
        // Kiểm tra id hợp lệ
        if (!is_numeric($id) || $id <= 0) {
            return ['success' => false, 'message' => 'ID không hợp lệ'];
        }
        
        try {
            $sql = "DELETE FROM {$this->table} WHERE id = ?";
            $stmt = $this->db->getConnection()->prepare($sql);
            $stmt->execute([$id]);
            return ['success' => true, 'message' => 'Xóa sinh viên thành công'];
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Lỗi: ' . $e->getMessage()];
        }
    }
    
    // ============================================
    // BÀI 5: TÌM KIẾM SINH VIÊN
    // ============================================
    
    /**
     * Tìm kiếm sinh viên
     */
    public function search($keyword, $page = 1) {
        if (empty($keyword)) {
            return $this->getAllPaginated($page);
        }
        
        return $this->getAllPaginated($page, 'id', 'ASC', $keyword);
    }
    
    // ============================================
    // BÀI 6: TÍNH TỔNG SỐ SINH VIÊN (CHO PHÂN TRANG)
    // ============================================
    
    /**
     * Tính tổng số sinh viên (có tìm kiếm)
     */
    public function getTotal($search = '') {
        $sql = "SELECT COUNT(*) as total FROM {$this->table}";
        $params = [];
        
        if (!empty($search)) {
            $sql .= " WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?";
            $params = ["%$search%", "%$search%", "%$search%"];
        }
        
        $stmt = $this->db->getConnection()->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetch();
        
        return $result['total'] ?? 0;
    }
    
    /**
     * Lấy số trang tối đa
     */
    public function getTotalPages($search = '') {
        $total = $this->getTotal($search);
        return ceil($total / $this->perPage);
    }
    
    /**
     * Lấy số sinh viên mỗi trang
     */
    public function getPerPage() {
        return $this->perPage;
    }
    
    // ============================================
    // BÀI 18: XUẤT DANH SÁCH SINH VIÊN RA FILE CSV
    // ============================================
    
    /**
     * Lấy tất cả sinh viên (không phân trang) cho xuất CSV
     */
    public function getAllForExport() {
        $sql = "SELECT id, name, email, phone, avatar, created_at, updated_at FROM {$this->table} ORDER BY id ASC";
        return $this->db->query($sql);
    }
    
    // ============================================
    // BÀI 20: GHI LOG HOẠT ĐỘNG NGƯỜI DÙNG
    // ============================================
    
    /**
     * Ghi log hoạt động (sẽ sử dụng trong Controller)
     * Phương thức này giữ ở đây để reference
     */
    public function logActivity($action, $userId, $studentId = null, $details = '') {
        // Chi tiết sẽ được xử lý bởi ActivityLog model
        // Ở đây chỉ để reference
        return true;
    }
    
    // ============================================
    // HELPER METHODS
    // ============================================
    
    /**
     * Kiểm tra email đã tồn tại
     */
    public function emailExists($email, $excludeId = null) {
        $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE email = ?";
        $params = [$email];
        
        if ($excludeId !== null) {
            $sql .= " AND id != ?";
            $params[] = $excludeId;
        }
        
        $stmt = $this->db->getConnection()->prepare($sql);
        $stmt->execute($params);
        
        return $stmt->fetch()['count'] > 0;
    }
    
    /**
     * Lấy số dòng bị ảnh hưởng từ câu lệnh cuối cùng
     */
    public function getRowCount() {
        return 0;
    }
}