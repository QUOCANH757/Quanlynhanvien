<?php
/**
 * File: public/index.php
 * Front Controller - Điểm vào chính của ứng dụng
 */

// Khởi động session
session_start();
date_default_timezone_set('Asia/Ho_Chi_Minh');
// Bật hiển thị lỗi (tạm thời để debug)
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Định nghĩa các đường dẫn cơ bản
define('BASE_PATH', dirname(__DIR__)); // Thư mục gốc dự án
define('SRC_PATH', BASE_PATH . '/src');
define('CONTROLLERS_PATH', SRC_PATH . '/common/controller');
define('MODELS_PATH', SRC_PATH . '/common/model');
define('VIEWS_PATH', SRC_PATH . '/common/view');
define('UPLOADS_PATH', __DIR__ . '/uploads');
define('STYLES_PATH', __DIR__ . '/styles');
define('LOGS_PATH', BASE_PATH . '/logs');
define('CONFIG_PATH', BASE_PATH . '/system/config');
define('BASE_URL', 'http://localhost:8080');

// ========================================
// COMPOSER AUTOLOAD - QUAN TRỌNG!
// ========================================
$autoloadPath = BASE_PATH . '/vendor/autoload.php';

if (file_exists($autoloadPath)) {
    require_once $autoloadPath;
    error_log("✓ Composer autoload loaded successfully from: $autoloadPath");
} else {
    die("
        <h1>❌ LỖI: Không tìm thấy Composer autoload</h1>
        <p><strong>Đường dẫn tìm kiếm:</strong> <code>$autoloadPath</code></p>
        <p><strong>Giải pháp:</strong></p>
        <ol>
            <li>Mở Terminal/CMD tại thư mục: <code>" . BASE_PATH . "</code></li>
            <li>Chạy lệnh: <code>composer install</code></li>
            <li>Chờ cài đặt hoàn tất</li>
            <li>Tải lại trang này</li>
        </ol>
        <hr>
        <p><strong>Đường dẫn hiện tại:</strong></p>
        <ul>
            <li>BASE_PATH: " . BASE_PATH . "</li>
            <li>__DIR__: " . __DIR__ . "</li>
            <li>File hiện tại: " . __FILE__ . "</li>
        </ul>
    ");
}

// Ensure logs directory exists
if (!is_dir(LOGS_PATH)) {
    mkdir(LOGS_PATH, 0755, true);
}

// Autoload - require các file cần thiết
if (file_exists(BASE_PATH . '/system/services/Database.php')) {
    require_once BASE_PATH . '/system/services/Database.php';
}

// Helper Functions
if (file_exists(SRC_PATH . '/common/helper/Functions.php')) {
    require_once SRC_PATH . '/common/helper/Functions.php';
}

// ========================================
// LẤY ACTION TỪ URL
// ========================================
$action = isset($_GET['action']) ? $_GET['action'] : 'index';
$handled = false;

// Debug log
error_log("=== REQUEST === Action: $action | Method: {$_SERVER['REQUEST_METHOD']} | Time: " . date('Y-m-d H:i:s'));

// ========================================
// TEST DB ACTION
// ========================================
if ($action === 'testdb') {
    echo "<!DOCTYPE html>";
    echo "<html><head><meta charset='UTF-8'><title>Kiểm tra hệ thống</title>";
    echo "<style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        .warning { color: #ffc107; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        td:first-child { font-weight: bold; width: 200px; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 4px; overflow: auto; }
        .alert { padding: 15px; margin: 20px 0; border-radius: 4px; }
        .alert-success { background: #d4edda; border-left: 4px solid #28a745; }
        .alert-warning { background: #fff3cd; border-left: 4px solid #ffc107; }
    </style>";
    echo "</head><body><div class='container'>";
    
    echo "<h1>🔍 Kiểm tra hệ thống</h1>";
    
    // Kiểm tra PHP
    echo "<h2>📌 Thông tin PHP</h2>";
    echo "<table>";
    echo "<tr><td>PHP Version</td><td class='success'>✓ " . PHP_VERSION . "</td></tr>";
    echo "<tr><td>Server</td><td>" . $_SERVER['SERVER_SOFTWARE'] . "</td></tr>";
    echo "</table>";
    
    // Kiểm tra đường dẫn
    echo "<h2>📁 Đường dẫn</h2>";
    echo "<table>";
    echo "<tr><td>BASE_PATH</td><td>" . BASE_PATH . "</td></tr>";
    echo "<tr><td>Document Root</td><td>" . $_SERVER['DOCUMENT_ROOT'] . "</td></tr>";
    echo "<tr><td>Script Filename</td><td>" . __FILE__ . "</td></tr>";
    echo "</table>";
    
    // Kiểm tra file quan trọng
    echo "<h2>📂 Kiểm tra file/folder</h2>";
    echo "<table>";
    
    $checks = [
        'composer.json' => BASE_PATH . '/composer.json',
        'vendor/autoload.php' => BASE_PATH . '/vendor/autoload.php',
        'AuthController.php' => CONTROLLERS_PATH . '/AuthController.php',
        'Database.php' => BASE_PATH . '/system/services/Database.php',
        'Thư mục vendor' => BASE_PATH . '/vendor',
        'Thư mục src' => SRC_PATH,
        'Thư mục public' => BASE_PATH . '/public',
    ];
    
    foreach ($checks as $name => $path) {
        $exists = (strpos($name, 'Thư mục') !== false) ? is_dir($path) : file_exists($path);
        $status = $exists ? "<span class='success'>✓ Có</span>" : "<span class='error'>❌ Không có</span>";
        echo "<tr><td>$name</td><td>$status</td></tr>";
    }
    echo "</table>";
    
    // Kiểm tra Composer
    echo "<h2>📦 Composer & Dependencies</h2>";
    if (file_exists(BASE_PATH . '/vendor/autoload.php')) {
        echo "<div class='alert alert-success'>";
        echo "✅ <strong>Composer đã được cài đặt thành công!</strong><br>";
        
        // Kiểm tra PHPMailer
        if (class_exists('PHPMailer\PHPMailer\PHPMailer')) {
            echo "✅ PHPMailer: Đã cài đặt<br>";
        } else {
            echo "⚠️ PHPMailer: Chưa load được class<br>";
        }
        
        // Đọc composer.json
        if (file_exists(BASE_PATH . '/composer.json')) {
            $composerData = json_decode(file_get_contents(BASE_PATH . '/composer.json'), true);
            echo "<br><strong>Dependencies:</strong><br>";
            echo "<pre>" . json_encode($composerData['require'] ?? [], JSON_PRETTY_PRINT) . "</pre>";
        }
        echo "</div>";
    } else {
        echo "<div class='alert alert-warning'>";
        echo "⚠️ <strong>Composer chưa được cài đặt!</strong><br><br>";
        echo "<strong>Hướng dẫn cài đặt:</strong><br>";
        echo "1. Mở Terminal/CMD tại: <code>" . BASE_PATH . "</code><br>";
        echo "2. Chạy lệnh: <code>composer install</code><br>";
        echo "3. Đợi cài đặt hoàn tất<br>";
        echo "4. Tải lại trang này<br>";
        echo "</div>";
    }
    
    // Kiểm tra Database
    echo "<h2>🗄️ Kết nối Database</h2>";
    if (class_exists('Database')) {
        try {
            $db = Database::getInstance()->getConnection();
            echo "<div class='alert alert-success'>✅ Kết nối database: <strong>THÀNH CÔNG</strong></div>";
        } catch (Exception $e) {
            echo "<div class='alert alert-warning'>";
            echo "❌ Kết nối database: <strong>THẤT BẠI</strong><br>";
            echo "Lỗi: " . htmlspecialchars($e->getMessage());
            echo "</div>";
        }
    } else {
        echo "<div class='alert alert-warning'>⚠️ Class Database không tồn tại</div>";
    }
    
    // Cấu trúc thư mục
    echo "<h2>🌳 Cấu trúc thư mục</h2>";
    echo "<pre>";
    echo "ThucHanhBuoi1/\n";
    echo "├── composer.json       " . (file_exists(BASE_PATH . '/composer.json') ? '✓' : '❌') . "\n";
    echo "├── vendor/             " . (is_dir(BASE_PATH . '/vendor') ? '✓' : '❌') . "\n";
    echo "│   └── autoload.php    " . (file_exists(BASE_PATH . '/vendor/autoload.php') ? '✓' : '❌') . "\n";
    echo "├── public/             " . (is_dir(BASE_PATH . '/public') ? '✓' : '❌') . "\n";
    echo "│   └── index.php       " . (file_exists(__FILE__) ? '✓' : '❌') . "\n";
    echo "├── src/                " . (is_dir(SRC_PATH) ? '✓' : '❌') . "\n";
    echo "│   └── common/         " . (is_dir(SRC_PATH . '/common') ? '✓' : '❌') . "\n";
    echo "│       ├── controller/ " . (is_dir(CONTROLLERS_PATH) ? '✓' : '❌') . "\n";
    echo "│       ├── model/      " . (is_dir(MODELS_PATH) ? '✓' : '❌') . "\n";
    echo "│       └── view/       " . (is_dir(VIEWS_PATH) ? '✓' : '❌') . "\n";
    echo "└── system/             " . (is_dir(BASE_PATH . '/system') ? '✓' : '❌') . "\n";
    echo "</pre>";
    
    echo "<hr>";
    echo "<p><a href='index.php?action=login'>→ Đi đến trang đăng nhập</a></p>";
    
    echo "</div></body></html>";
    exit;
}

// ========================================
// MIDDLEWARE: KIỂM TRA PHIÊN ĐĂNG NHẬP
// ========================================
$publicActions = [
    'login', 'doLogin', 'register', 'doRegister', 'logout',
    'contact', 'doContact',
    'forgot-password', 'sendResetEmail', 'reset-password', 'doResetPassword',
    'testdb'
];

$isLoggedIn = isset($_SESSION['user_id']);

if (!$isLoggedIn && !in_array($action, $publicActions)) {
    $_SESSION['error'] = 'Vui lòng đăng nhập để tiếp tục';
    header('Location: index.php?action=login');
    exit;
}

// ========================================
// ROUTE HANDLER
// ========================================
try {
    
    // AUTHENTICATION ROUTES
    $authActions = ['login', 'register', 'logout', 'doLogin', 'doRegister', 
                    'forgot-password', 'sendResetEmail', 'reset-password', 'doResetPassword'];
    
    if (in_array($action, $authActions)) {
        require_once CONTROLLERS_PATH . '/AuthController.php';
        $controller = new AuthController();
        
        switch ($action) {
            case 'login':
                $controller->showLogin();
                $handled = true; break;
            case 'doLogin':
                $controller->doLogin();
                $handled = true; break;
            case 'register':
                $controller->showRegister();
                $handled = true; break;
            case 'doRegister':
                $controller->doRegister();
                $handled = true; break;
            case 'logout':
                $controller->logout();
                $handled = true; break;
            case 'forgot-password':
                $controller->showForgotPassword();
                $handled = true; break;
            case 'sendResetEmail':
                $controller->sendResetEmail();
                $handled = true; break;
            case 'reset-password':
                $controller->showResetPasswordForm();
                $handled = true; break;
            case 'doResetPassword':
                $controller->doResetPassword();
                $handled = true; break;
        }
    }
    
    // CONTACT ROUTES
    elseif (in_array($action, ['contact', 'doContact'])) {
        if (file_exists(CONTROLLERS_PATH . '/ContactController.php')) {
            require_once CONTROLLERS_PATH . '/ContactController.php';
            $controller = new ContactController();
            
            switch ($action) {
                case 'contact':
                    $controller->index();
                    $handled = true; break;
                case 'doContact':
                    $controller->store();
                    $handled = true; break;
            }
        }
    }
    
    // STUDENT ROUTES
    else {
        if (file_exists(CONTROLLERS_PATH . '/StudentController.php')) {
            require_once CONTROLLERS_PATH . '/StudentController.php';
            $controller = new StudentController();
            
            switch ($action) {
                case 'index':
                case 'list':
                    $controller->index(); $handled = true; break;
                case 'create':
                    $controller->showCreate(); $handled = true; break;
                case 'doCreate':
                    $controller->doCreate(); $handled = true; break;
                case 'edit':
                    $controller->showEdit(); $handled = true; break;
                case 'doUpdate':
                    $controller->doUpdate(); $handled = true; break;
                case 'delete':
                    $controller->delete(); $handled = true; break;
                case 'search':
                    $controller->search(); $handled = true; break;
                case 'statistics':
                    $controller->statistics(); $handled = true; break;
                case 'detail':
                    $controller->detail(); $handled = true; break;
                case 'sort':
                    $controller->index(); $handled = true; break;
                case 'export-csv':
                    $controller->exportCsv(); $handled = true; break;
                case 'logs':
                    $controller->viewLogs(); $handled = true; break;
                default:
                    $controller->index(); $handled = true; break;
            }
        }
    }
    
} catch (Exception $e) {
    error_log("❌ EXCEPTION: " . $e->getMessage() . "\n" . $e->getTraceAsString());
    $_SESSION['error'] = 'Lỗi hệ thống: ' . $e->getMessage();
    
    echo "<!DOCTYPE html>";
    echo "<html><head><meta charset='UTF-8'><title>Lỗi</title>";
    echo "<style>body{font-family:Arial;padding:20px;background:#f5f5f5;} .error{background:#fff;border-left:4px solid #dc3545;padding:20px;margin:20px 0;border-radius:4px;} pre{background:#f8f9fa;padding:15px;overflow:auto;border-radius:4px;}</style>";
    echo "</head><body>";
    echo "<div class='error'>";
    echo "<h1>❌ Lỗi hệ thống!</h1>";
    echo "<p><strong>Thông báo:</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p><strong>File:</strong> " . htmlspecialchars($e->getFile()) . ":" . $e->getLine() . "</p>";
    echo "<details><summary><strong>Stack Trace (click để xem chi tiết)</strong></summary><pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre></details>";
    echo "</div>";
    echo "<p><a href='index.php?action=testdb'>← Kiểm tra hệ thống</a></p>";
    echo "</body></html>";
    exit;
}

// ========================================
// 404 NOT FOUND
// ========================================
if (!$handled) {
    http_response_code(404);
    echo "<!DOCTYPE html>";
    echo "<html><head><meta charset='UTF-8'><title>404</title>";
    echo "<style>body{font-family:Arial;padding:20px;text-align:center;background:#f5f5f5;} .container{max-width:600px;margin:50px auto;background:white;padding:40px;border-radius:8px;}</style>";
    echo "</head><body><div class='container'>";
    echo "<h1>404 - Không tìm thấy trang</h1>";
    echo "<p>Action không tồn tại: <code>" . htmlspecialchars($action) . "</code></p>";
    echo "<p><a href='index.php?action=index'>← Về trang chủ</a> | <a href='index.php?action=testdb'>Kiểm tra hệ thống</a></p>";
    echo "</div></body></html>";
    exit;
}