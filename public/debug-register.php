<?php
// Xóa hết buffer cũ
if (ob_get_level()) {
    ob_end_clean();
}

// Hiển thị tất cả lỗi
ini_set('display_errors', 1);
error_reporting(E_ALL);

echo "<html lang='vi'>";
echo "<head>";
echo "<meta charset='UTF-8'>";
echo "<title>Debug Hệ thống</title>";
echo "<style>";
echo "body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }";
echo ".box { background: white; padding: 20px; margin: 10px 0; border-radius: 5px; }";
echo ".success { border-left: 4px solid #28a745; }";
echo ".error { border-left: 4px solid #dc3545; }";
echo ".info { border-left: 4px solid #17a2b8; }";
echo "h2 { margin-top: 0; }";
echo "code { background: #11acb4ff; padding: 2px 5px; }";
echo "table { border-collapse: collapse; width: 100%; }";
echo "th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }";
echo "th { background: #f8f9fa; }";
echo "</style>";
echo "</head>";
echo "<body>";

echo "<h1>🔍 Debug Hệ thống Quản lý Sinh viên</h1>";

// 1. Kiểm tra PHP
echo "<div class='box info'>";
echo "<h2>1️⃣ Thông tin PHP</h2>";
echo "PHP Version: " . phpversion() . "<br>";
echo "OS: " . php_uname() . "<br>";
echo "Web Server: " . $_SERVER['SERVER_SOFTWARE'] . "<br>";
echo "</div>";

// 2. Kiểm tra thư mục
echo "<div class='box'>";
echo "<h2>2️⃣ Kiểm tra thư mục</h2>";

$base = dirname(__DIR__);
$dirs = [
    'src/common' => $base . '/src/common',
    'src/common/controller' => $base . '/src/common/controller',
    'src/common/model' => $base . '/src/common/model',
    'src/view' => $base . '/src/view',
    'src/view/students' => $base . '/src/view/students',
    'public/uploads' => __DIR__ . '/uploads'
];

foreach ($dirs as $name => $path) {
    if (is_dir($path)) {
        echo "✅ <code>$name</code><br>";
    } else {
        echo "❌ <code>$name</code> - Không tồn tại<br>";
    }
}
echo "</div>";

// 3. Kiểm tra file
echo "<div class='box'>";
echo "<h2>3️⃣ Kiểm tra file</h2>";

$files = [
    'Database.php' => $base . '/src/common/Database.php',
    'User.php' => $base . '/src/common/model/User.php',
    'Student.php' => $base . '/src/common/model/Student.php',
    'AuthController.php' => $base . '/src/common/controller/AuthController.php',
    'StudentController.php' => $base . '/src/common/controller/StudentController.php',
];

foreach ($files as $name => $path) {
    if (file_exists($path)) {
        $size = filesize($path);
        echo "✅ <code>$name</code> ({$size} bytes)<br>";
    } else {
        echo "❌ <code>$name</code> - Không tồn tại<br>";
    }
}
echo "</div>";

// 4. Kiểm tra kết nối CSDL
echo "<div class='box'>";
echo "<h2>4️⃣ Kiểm tra kết nối CSDL</h2>";

$host = 'localhost';
$dbname = 'student_management';
$user = 'root';
$pass = '';

echo "Host: <code>$host</code><br>";
echo "Database: <code>$dbname</code><br>";
echo "Username: <code>$user</code><br>";

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $user,
        $pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );
    
    echo "<div class='box success'>";
    echo "✅ Kết nối CSDL thành công!<br>";
    
    // Kiểm tra bảng users
    try {
        $stmt = $pdo->query("SELECT COUNT(*) as total FROM users");
        $result = $stmt->fetch();
        echo "✅ Bảng 'users' tồn tại (Tổng: {$result['total']} users)<br>";
        
        // Hiển thị danh sách users
        $stmt = $pdo->query("SELECT id, username, email, created_at FROM users ORDER BY id DESC LIMIT 10");
        $users = $stmt->fetchAll();
        
        if (!empty($users)) {
            echo "<h3>Danh sách users (10 gần nhất):</h3>";
            echo "<table>";
            echo "<tr><th>ID</th><th>Username</th><th>Email</th><th>Created At</th></tr>";
            foreach ($users as $u) {
                echo "<tr>";
                echo "<td>{$u['id']}</td>";
                echo "<td>{$u['username']}</td>";
                echo "<td>{$u['email']}</td>";
                echo "<td>{$u['created_at']}</td>";
                echo "</tr>";
            }
            echo "</table>";
        }
    } catch (Exception $e) {
        echo "❌ Bảng 'users' không tồn tại<br>";
        echo "Lỗi: " . $e->getMessage() . "<br>";
    }
    
    // Kiểm tra bảng students
    try {
        $stmt = $pdo->query("SELECT COUNT(*) as total FROM students");
        $result = $stmt->fetch();
        echo "✅ Bảng 'students' tồn tại (Tổng: {$result['total']} students)<br>";
    } catch (Exception $e) {
        echo "❌ Bảng 'students' không tồn tại<br>";
    }
    
    echo "</div>";
    
} catch (PDOException $e) {
    echo "<div class='box error'>";
    echo "❌ Kết nối CSDL thất bại!<br>";
    echo "Lỗi: " . $e->getMessage() . "<br>";
    echo "💡 Gợi ý:<br>";
    echo "- Kiểm tra MySQL server có đang chạy không<br>";
    echo "- Kiểm tra database 'student_management' đã tạo chưa<br>";
    echo "- Kiểm tra username/password có đúng không<br>";
    echo "</div>";
}

// 5. Test Password Hash
echo "<div class='box info'>";
echo "<h2>5️⃣ Test mã hóa mật khẩu</h2>";
echo "<p>Hàm password_hash(): " . (function_exists('password_hash') ? '✅ Có' : '❌ Không') . "</p>";
echo "<p>Hàm password_verify(): " . (function_exists('password_verify') ? '✅ Có' : '❌ Không') . "</p>";

if (function_exists('password_hash')) {
    $testPass = 'test123';
    $hash = password_hash($testPass, PASSWORD_DEFAULT);
    echo "<p>Test hash: <code>" . substr($hash, 0, 30) . "...</code></p>";
    echo "<p>Verify: " . (password_verify($testPass, $hash) ? '✅ OK' : '❌ Fail') . "</p>";
}
echo "</div>";

// 6. Session
echo "<div class='box info'>";
echo "<h2>6️⃣ Session</h2>";
session_start();
echo "Session Status: " . (session_id() ? '✅ Hoạt động' : '❌ Không') . "<br>";
echo "Session ID: <code>" . session_id() . "</code><br>";
echo "</div>";

// 7. Form test
echo "<div class='box'>";
echo "<h2>7️⃣ Test Tạo User</h2>";
echo "<form method='POST'>";
echo "Username: <input type='text' name='test_user' value='" . (isset($_POST['test_user']) ? htmlspecialchars($_POST['test_user']) : '') . "'><br>";
echo "Email: <input type='email' name='test_email' value='" . (isset($_POST['test_email']) ? htmlspecialchars($_POST['test_email']) : '') . "'><br>";
echo "Password: <input type='password' name='test_pass' value='test123'><br>";
echo "<button type='submit' name='do_test' value='1'>🧪 Tạo User Test</button>";
echo "</form>";

if (isset($_POST['do_test'])) {
    $test_user = isset($_POST['test_user']) ? trim($_POST['test_user']) : '';
    $test_email = isset($_POST['test_email']) ? trim($_POST['test_email']) : '';
    $test_pass = isset($_POST['test_pass']) ? $_POST['test_pass'] : '';
    
    if ($test_user && $test_email && $test_pass) {
        try {
            $pdo = new PDO(
                "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
                $user,
                $pass,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
            
            $passHash = password_hash($test_pass, PASSWORD_DEFAULT);
            $stmt = $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
            $result = $stmt->execute([$test_user, $test_email, $passHash]);
            
            if ($result) {
                echo "<div class='box success'>";
                echo "✅ Tạo user thành công!<br>";
                echo "Username: <code>$test_user</code><br>";
                echo "Email: <code>$test_email</code><br>";
                echo "Password: <code>test123</code><br>";
                echo "Thử đăng nhập ngay: <a href='index.php?action=login'>Đến trang login</a>";
                echo "</div>";
            }
        } catch (Exception $e) {
            echo "<div class='box error'>";
            echo "❌ Lỗi: " . $e->getMessage() . "<br>";
            echo "</div>";
        }
    }
}

echo "</div>";

echo "<hr>";
echo "<a href='index.php?action=login'>← Quay lại trang đăng nhập</a>";
echo "</body>";
echo "</html>";
?>