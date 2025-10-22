<?php
/**
 * File: src/common/model/PasswordReset.php
 * Model xử lý đổi mật khẩu qua email
 */

class PasswordReset {
    private $db;
    private $table = 'password_reset_tokens';
    
    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }
    
    /**
     * Tạo token reset password
     */
    public function createToken($userId) {
        // Xóa token cũ nếu có
        $this->deleteExpiredTokens($userId);
        
        // Tạo token mới
        $token = bin2hex(random_bytes(32));
        $expiresAt = date('Y-m-d H:i:s', strtotime('+1 hour')); // Token hết hạn sau 1 giờ
        
        $sql = "INSERT INTO {$this->table} (user_id, token, expires_at) VALUES (?, ?, ?)";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$userId, $token, $expiresAt])) {
            return $token;
        }
        
        return false;
    }
    
    /**
     * Kiểm tra token có hợp lệ không
     */
    public function validateToken($token) {
        $sql = "SELECT * FROM {$this->table} WHERE token = ? AND expires_at > NOW() AND used_at IS NULL";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$token]);
        
        return $stmt->fetch();
    }
    
    /**
     * Đánh dấu token đã sử dụng
     */
    public function markTokenUsed($token) {
        $sql = "UPDATE {$this->table} SET used_at = NOW() WHERE token = ?";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute([$token]);
    }
    
    /**
     * Xóa token hết hạn
     */
    private function deleteExpiredTokens($userId) {
        $sql = "DELETE FROM {$this->table} WHERE user_id = ? AND (expires_at <= NOW() OR used_at IS NOT NULL)";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$userId]);
    }
    
    /**
     * Lấy user từ token
     */
    public function getUserFromToken($token) {
        $sql = "SELECT u.* FROM {$this->table} pr 
                JOIN users u ON pr.user_id = u.id 
                WHERE pr.token = ? AND pr.expires_at > NOW() AND pr.used_at IS NULL";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$token]);
        
        return $stmt->fetch();
    }
}
