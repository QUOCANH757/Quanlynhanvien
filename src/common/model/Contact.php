<?php
class Contact
{
    private $db;
    
    public function __construct()
    {
        // Sử dụng Database service hiện có (PDO connection)
        $this->db = Database::getInstance()->getConnection();
    }
    
    public function create($name, $email, $content)
    {
        // Validate dữ liệu
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['success' => false, 'message' => 'Email không hợp lệ'];
        }
        
        if (empty($name) || empty($content)) {
            return ['success' => false, 'message' => 'Tất cả trường phải được điền'];
        }
        
        // Prepare statement để tránh SQL injection
        $sql = "INSERT INTO contacts (name, email, content, created_at) VALUES (?, ?, ?, NOW())";
        $stmt = $this->db->prepare($sql);

        if ($stmt->execute([$name, $email, $content])) {
            return ['success' => true, 'message' => 'Gửi liên hệ thành công!'];
        } else {
            return ['success' => false, 'message' => 'Lỗi lưu dữ liệu'];
        }
    }
}
?>