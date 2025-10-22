<?php
/**
 * File: src/common/model/User.php
 * Model xử lý User
 */

class User {
    private $db;
    private $table = 'users';
    
    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }
    
    public function usernameExists($username) {
        $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE username = ?";
        $result = Database::getInstance()->queryOne($sql, [$username]);
        return $result['count'] > 0;
    }
    
    public function emailExists($email) {
        $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE email = ?";
        $result = Database::getInstance()->queryOne($sql, [$email]);
        return $result['count'] > 0;
    }
    
    public function create($username, $email, $password) {
        $passwordHash = password_hash($password, PASSWORD_DEFAULT);
        $sql = "INSERT INTO {$this->table} (username, email, password, created_at, updated_at) 
                VALUES (?, ?, ?, NOW(), NOW())";
        return Database::getInstance()->execute($sql, [$username, $email, $passwordHash]);
    }
    
    public function getUserByUsername($username) {
        $sql = "SELECT * FROM {$this->table} WHERE username = ?";
        return Database::getInstance()->queryOne($sql, [$username]);
    }
    
    public function getUserById($id) {
        $sql = "SELECT * FROM {$this->table} WHERE id = ?";
        return Database::getInstance()->queryOne($sql, [$id]);
    }
    
    public function getUserByEmail($email) {
        $sql = "SELECT * FROM {$this->table} WHERE email = ?";
        return Database::getInstance()->queryOne($sql, [$email]);
    }
    
    public function getConnection() {
        return Database::getInstance()->getConnection();
    }
    
    public function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }

    public function changePassword($userId, $oldPassword, $newPassword) {
        $stmt = $this->db->prepare("SELECT id, password FROM {$this->table} WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        if (!$user) {
            return ['success' => false, 'message' => 'Người dùng không tồn tại'];
        }

        if (!password_verify($oldPassword, $user['password'])) {
            return ['success' => false, 'message' => 'Mật khẩu cũ không chính xác'];
        }

        $newHash = password_hash($newPassword, PASSWORD_DEFAULT);
        $update = $this->db->prepare("UPDATE {$this->table} SET password = ?, updated_at = NOW() WHERE id = ?");
        $update->execute([$newHash, $userId]);

        return ['success' => true, 'message' => 'Đổi mật khẩu thành công'];
    }

    /**
     * Cập nhật mật khẩu mới cho người dùng (dùng cho tính năng quên mật khẩu).
     * Hàm này không cần kiểm tra mật khẩu cũ.
     */
    public function updatePassword($userId, $newPassword) {
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        $sql = "UPDATE {$this->table} SET password = ?, updated_at = NOW() WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute([$hashedPassword, $userId]);
    }
}