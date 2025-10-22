<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đặt lại mật khẩu</title>
    <style>
        :root {
            --primary: #007bff;
            --success: #28a745;
            --danger: #dc3545;
            --light: #f8f9fa; /* Giữ nguyên màu nền nhạt */
            --white: #fff;
            --text: #33373d; /* Làm dịu màu văn bản một chút */
            --border: #e4e7eb; /* Màu viền nhạt hơn */
            --radius-lg: 10px; /* Bo góc lớn hơn cho thẻ */
            --radius-sm: 6px; /* Bo góc nhỏ hơn cho các input/button */
            --shadow: 0 5px 15px rgba(0, 0, 0, 0.08); /* Bóng đổ mềm mại hơn */
        }
        
        * { box-sizing: border-box; margin: 0; padding: 0; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: var(--light); /* Sử dụng màu nền nhạt */
            color: var(--text);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            line-height: 1.6;
        }
        
        .container {
            max-width: 420px; /* Tăng nhẹ độ rộng tối đa */
            width: 100%;
            padding: 20px;
        }
        
        .card {
            background: var(--white);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow);
            padding: 40px; /* Tăng padding để thoáng hơn */
            border: 1px solid #fff; /* Thêm viền trắng để nổi bật trên nền xám */
        }
        
        .logo {
            text-align: center;
            margin-bottom: 32px;
        }
        
        .logo h1 {
            color: var(--text); /* Đổi màu tiêu đề thành màu văn bản chính */
            font-size: 26px;
            font-weight: 700; /* Đậm hơn */
        }
        
        .alert {
            padding: 16px; /* Tăng padding */
            margin-bottom: 20px;
            border-radius: var(--radius-sm);
            border: 1px solid transparent;
            font-size: 15px;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border-color: #c3e6cb;
        }
        
        .alert-danger {
            background: #f8d7da;
            color: #721c24;
            border-color: #f5c6cb;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600; /* Đậm hơn một chút */
            font-size: 15px;
            color: #495057;
        }
        
        .form-group input {
            width: 100%;
            padding: 14px 16px; /* Tăng padding cho input cao hơn */
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            font-size: 16px;
            transition: border-color 0.2s, box-shadow 0.2s;
            background-color: #fff;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: var(--primary);
            background-color: var(--white);
            box-shadow: 0 0 0 4px rgba(0, 123, 255, 0.15); /* Hiệu ứng focus rõ ràng hơn */
        }
        
        .btn {
            width: 100%;
            padding: 14px; /* Tăng padding */
            border: none;
            border-radius: var(--radius-sm);
            font-size: 16px;
            font-weight: 600; /* Đậm hơn */
            cursor: pointer;
            transition: all 0.2s ease, transform 0.1s ease;
            text-decoration: none;
            display: inline-block;
            text-align: center;
        }

        .btn:hover {
             transform: translateY(-2px); /* Hiệu ứng nhấc lên khi hover */
             box-shadow: 0 3px 8px rgba(0,0,0,0.1);
        }
        
        .btn-primary {
            background: var(--success); /* Giữ nguyên màu xanh lá theo code gốc */
            color: var(--white);
        }
        
        .btn-primary:hover {
            background: #218838;
            box-shadow: 0 4px 10px rgba(40, 167, 69, 0.2); /* Thêm bóng đổ màu xanh */
        }
        
        .btn-secondary {
            background: #f1f3f5; /* Màu nhạt hơn */
            color: #495057; /* Màu chữ tối hơn */
            margin-top: 12px;
        }
        
        .btn-secondary:hover {
            background: #e9ecef;
            box-shadow: none; /* Không cần bóng đổ cho nút phụ */
            transform: none; /* Không cần nhấc lên */
        }
        
        .help-text {
            font-size: 14px;
            color: #6c757d;
            margin-top: 16px; /* Tăng margin */
            text-align: center; /* Căn giữa */
        }
        
        .user-info {
            background: #f1f3f5; /* Màu nền nhạt */
            padding: 16px;
            border-radius: var(--radius-sm);
            margin-bottom: 24px; /* Tăng khoảng cách */
            text-align: center;
            border: 1px solid var(--border);
        }
        .user-info strong {
            color: #0056b3; /* Làm nổi bật username */
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="logo">
                <h1>🔑 Đặt lại mật khẩu</h1>
            </div>
            
            <?php if (isset($_SESSION['error'])): ?>
                <div class="alert alert-danger">
                    <?php 
                        echo $_SESSION['error']; 
                        unset($_SESSION['error']);
                    ?>
                </div>
            <?php endif; ?>
            
            <?php if (isset($_SESSION['success'])): ?>
                <div class="alert alert-success">
                    <?php 
                        echo $_SESSION['success']; 
                        unset($_SESSION['success']);
                    ?>
                </div>
            <?php endif; ?>
            
            <?php if (isset($user)): ?>
                <div class="user-info">
                    <strong>👤 <?php echo htmlspecialchars($user['username']); ?></strong><br>
                    <small><?php echo htmlspecialchars($user['email']); ?></small>
                </div>
            <?php endif; ?>
            
            <form method="POST" action="index.php?action=doResetPassword">
                <input type="hidden" name="token" value="<?php echo htmlspecialchars($_GET['token'] ?? ''); ?>">
                
                <div class="form-group">
                    <label for="new_password">Mật khẩu mới</label>
                    <input type="password" id="new_password" name="new_password" required 
                           placeholder="Nhập mật khẩu mới (ít nhất 6 ký tự)"
                           minlength="6">
                </div>
                
                <div class="form-group">
                    <label for="confirm_password">Xác nhận mật khẩu</label>
                    <input type="password" id="confirm_password" name="confirm_password" required 
                           placeholder="Nhập lại mật khẩu mới"
                           minlength="6">
                </div>
                
                <button type="submit" class="btn btn-primary">
                    🔒 Đặt lại mật khẩu
                </button>
                
                <div class="help-text">
                    Mật khẩu phải có ít nhất 6 ký tự
                </div>
            </form>
            
            <a href="index.php?action=login" class="btn btn-secondary">
                ← Quay lại đăng nhập
            </a>
        </div>
    </div>
    
    <script>
        // Kiểm tra mật khẩu trùng khớp
        document.getElementById('confirm_password').addEventListener('input', function() {
            const newPassword = document.getElementById('new_password').value;
            const confirmPassword = this.value;
            
            if (newPassword !== confirmPassword) {
                this.setCustomValidity('Mật khẩu không trùng khớp');
            } else {
                this.setCustomValidity('');
            }
        });
    </script>
</body>
</html>