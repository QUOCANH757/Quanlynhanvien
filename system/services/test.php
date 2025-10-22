<?php
require_once "Database.php";

use Service\Database;

// Tạo đối tượng và khởi tạo kết nối
$db = new Database();
$db->initialize();

// Thử truy vấn dữ liệu
$result = $db->query("SELECT * FROM your_table_name"); // thay your_table_name = tên bảng thực tế

if ($result) {
    print_r($result);
} else {
    echo "Không có dữ liệu!";
}

// Đóng kết nối
$db->destruct();
?>
