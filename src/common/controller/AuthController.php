<?php
/**
 * File: src/common/controller/AuthController.php
 * Controller xử lý xác thực: Đăng nhập, Đăng ký, Quên mật khẩu.
 */

// Import các lớp của PHPMailer để gửi mail
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

// ========================================
// KHÔNG CẦN REQUIRE AUTOLOAD Ở ĐÂY NỮA!
// Vì autoload đã được load trong index.php rồi
// ========================================

class AuthController {
    private $userModel;
    private $passwordResetModel;
    
    public function __construct() {
        require_once MODELS_PATH . '/User.php';
        require_once MODELS_PATH . '/PasswordReset.php';
        $this->userModel = new User();
        $this->passwordResetModel = new PasswordReset();
    }
    
    /**
     * Hiển thị form đăng nhập
     */
    public function showLogin() {
        $this->view('/auth/login');
    }
    
    /**
     * Xử lý đăng nhập
     */
    public function doLogin() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: index.php?action=login');
            exit;
        }
        
        $username = trim($_POST['username'] ?? '');
        $password = $_POST['password'] ?? '';
        
        $user = $this->userModel->getUserByUsername($username);
        
        if ($user && password_verify($password, $user['password'])) {
            // Đăng nhập thành công, lưu session
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['username'] = $user['username'];
            header('Location: index.php?action=index');
        } else {
            $_SESSION['error'] = 'Tên đăng nhập hoặc mật khẩu không chính xác.';
            header('Location: index.php?action=login');
        }
        exit;
    }
    
    /**
     * Hiển thị form đăng ký
     */
    public function showRegister() {
        $this->view('/auth/register');
    }

    /**
     * Xử lý đăng ký
     */
   // Thêm phương thức này vào trong class AuthController
// File: src/common/controller/AuthController.php

/**
 * Xử lý dữ liệu từ form đăng ký
 */
public function doRegister() {
    // Chỉ cho phép phương thức POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        header('Location: index.php?action=register');
        exit;
    }

    // 1. Lấy và làm sạch dữ liệu
    $username = trim($_POST['username'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $confirm_password = $_POST['confirm_password'] ?? '';

    // 2. Validate dữ liệu
    if (strlen($username) < 3) {
        $_SESSION['error'] = 'Tên đăng nhập phải có ít nhất 3 ký tự.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $_SESSION['error'] = 'Email không hợp lệ.';
    } elseif (strlen($password) < 6) {
        $_SESSION['error'] = 'Mật khẩu phải có ít nhất 6 ký tự.';
    } elseif ($password !== $confirm_password) {
        $_SESSION['error'] = 'Mật khẩu xác nhận không khớp.';
    } elseif ($this->userModel->usernameExists($username)) {
        $_SESSION['error'] = 'Tên đăng nhập này đã tồn tại.';
    } elseif ($this->userModel->emailExists($email)) {
        $_SESSION['error'] = 'Email này đã được sử dụng.';
    }

    // Nếu có lỗi, quay lại trang đăng ký
    if (isset($_SESSION['error'])) {
        header('Location: index.php?action=register');
        exit;
    }

    // 3. Tạo người dùng mới
    if ($this->userModel->create($username, $email, $password)) {
        // Đăng ký thành công, chuyển hướng đến trang đăng nhập với thông báo
        $_SESSION['success'] = 'Đăng ký tài khoản thành công! Vui lòng đăng nhập.';
        header('Location: index.php?action=login');
    } else {
        // Nếu có lỗi từ CSDL
        $_SESSION['error'] = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
        header('Location: index.php?action=register');
    }
    exit;
}

    /**
     * Xử lý đăng xuất
     */
    public function logout() {
        session_unset();
        session_destroy();
        header('Location: index.php?action=login');
        exit;
    }

    // ============================================
    // QUÊN MẬT KHẨU / ĐẶT LẠI MẬT KHẨU
    // ============================================

    /**
     * Hiển thị form yêu cầu reset mật khẩu
     */
    public function showForgotPassword() {
        $this->view('/auth/forgot_password');
    }

    /**
     * Xử lý gửi email reset mật khẩu
     */
public function sendResetEmail() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        header('Location: index.php?action=forgot-password');
        exit;
    }

    $email = trim($_POST['email'] ?? '');
    $user = $this->userModel->getUserByEmail($email);

    if (!$user) {
        $_SESSION['error'] = 'Không tìm thấy người dùng nào với địa chỉ email này.';
        header('Location: index.php?action=forgot-password');
        exit;
    }

    $token = $this->passwordResetModel->createToken($user['id']);
    if (!$token) {
        $_SESSION['error'] = 'Không thể tạo token. Vui lòng thử lại.';
        header('Location: index.php?action=forgot-password');
        exit;
    }

    // ===========================================
    // BẮT ĐẦU CẤU HÌNH GỬI EMAIL
    // ===========================================
    $mail = new PHPMailer(true); // true để bật Exception

    try {
        // --- Cấu hình Server ---
        // Bật chế độ debug chi tiết. Tắt đi khi deploy sản phẩm thật
        // 0 = off, 1 = client messages, 2 = client and server messages
        $mail->SMTPDebug = SMTP::DEBUG_OFF; // Đổi thành DEBUG_SERVER để xem lỗi chi tiết
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com'; // Sử dụng SMTP của Gmail
        $mail->SMTPAuth   = true;
        $mail->Username   = 'dlqanh-cntt17@tdu.edu.vn'; // <-- THAY BẰNG EMAIL CỦA BẠN
        $mail->Password   = 'dhbg jssb ouwx psvg';    // <-- THAY BẰNG MẬT KHẨU ỨNG DỤNG
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS; // Giao thức bảo mật
        $mail->Port       = 587; // Port cho TLS

        // --- Cấu hình người gửi, người nhận ---
        $mail->setFrom('dlqanh-cntt17@tdu.edu.vn', 'WEBSIRE Quản Lý Sinh Viên'); // Email và Tên người gửi
        $mail->addAddress($user['email'], $user['username']); // Email và Tên người nhận

        // --- Nội dung Email ---
        $mail->isHTML(true); // Set định dạng email là HTML
        $mail->CharSet = 'UTF-8';
        $mail->Subject = 'Yêu cầu đặt lại mật khẩu';
        
        // Tạo link reset
        $resetLink = BASE_URL . '/index.php?action=reset-password&token=' . $token;

        $mail->Body    = "
            <h2>Yêu cầu đặt lại mật khẩu</h2>
            <p>Xin chào {$user['username']},</p>
            <p>Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Vui lòng nhấp vào liên kết bên dưới để tiếp tục:</p>
            <p><a href='{$resetLink}' style='padding:10px 15px; background-color:#007bff; color:white; text-decoration:none; border-radius:5px;'>Đặt lại mật khẩu</a></p>
            <p>Nếu bạn không yêu cầu việc này, vui lòng bỏ qua email này.</p>
            <p>Liên kết này sẽ hết hạn sau 1 giờ.</p>
        ";
        $mail->AltBody = "Để đặt lại mật khẩu, vui lòng truy cập link sau: {$resetLink}";

        $mail->send();
        
        $_SESSION['success'] = 'Link đặt lại mật khẩu đã được gửi đến email của bạn!';
    } catch (Exception $e) {
        // Ghi lại lỗi để debug, không hiển thị chi tiết cho người dùng
        error_log("Lỗi gửi mail: {$mail->ErrorInfo}"); 
        $_SESSION['error'] = 'Không thể gửi mail. Vui lòng thử lại sau.';
    }
    
    header('Location: index.php?action=forgot-password');
    exit;
}

    /**
     * Hiển thị form nhập mật khẩu mới
     */
    public function showResetPasswordForm() {
    // 1. Lấy token từ URL
    $token = $_GET['token'] ?? '';
    if (empty($token)) {
        header('HTTP/1.0 400 Bad Request');
        echo 'Token không được cung cấp.';
        exit;
    }

    // 2. Kiểm tra xem token có hợp lệ trong CSDL không
    $isValid = $this->passwordResetModel->validateToken($token);

    if (!$isValid) {
        // Nếu token không hợp lệ hoặc hết hạn, báo lỗi và chuyển về trang đăng nhập
        $_SESSION['error'] = 'Link đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.';
        header('Location: index.php?action=login');
        exit;
    }

    // 3. Nếu token hợp lệ, hiển thị view và truyền token vào để form có thể sử dụng
    $this->view('auth/reset-password', ['token' => $token]);
}
    /**
     * Xử lý cập nhật mật khẩu mới
     */
    public function doResetPassword() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: index.php?action=login');
            exit;
        }

        $token = $_POST['token'] ?? '';
        $newPassword = $_POST['password'] ?? '';
        $confirmPassword = $_POST['password_confirm'] ?? '';

        if (empty($newPassword) || $newPassword !== $confirmPassword) {
            $_SESSION['error'] = 'Mật khẩu không hợp lệ hoặc không trùng khớp.';
            header('Location: index.php?action=reset-password&token=' . $token);
            exit;
        }

        $user = $this->passwordResetModel->getUserFromToken($token);

        if (!$user) {
            $_SESSION['error'] = 'Token không hợp lệ hoặc đã hết hạn.';
            header('Location: index.php?action=login');
            exit;
        }

        // Cập nhật mật khẩu trong CSDL
        if ($this->userModel->updatePassword($user['id'], $newPassword)) {
            $this->passwordResetModel->markTokenUsed($token);
            $_SESSION['success'] = 'Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập.';
            header('Location: index.php?action=login');
        } else {
            $_SESSION['error'] = 'Lỗi khi cập nhật mật khẩu. Vui lòng thử lại.';
            header('Location: index.php?action=reset-password&token=' . $token);
        }
        exit;
    }

    /**
     * Hàm hỗ trợ để render view
     */
    private function view($path, $data = []) {
        extract($data);
        $file = VIEWS_PATH . '/' . $path . '.php';
        if (file_exists($file)) {
            require $file;
        } else {
            die("View không tồn tại: $file");
        }
    }
}