<?php
/**
 * File: src/view/students/edit.php
 * View form chỉnh sửa sinh viên - Bài 3, 10
 */
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chỉnh sửa sinh viên</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        h1 {
            color: #333;
            margin-bottom: 30px;
            text-align: center;
        }
        
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: bold;
            font-size: 14px;
        }
        
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            font-family: Arial, sans-serif;
        }
        
        .form-group input:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #007bff;
            box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 100px;
        }
        
        .form-group input::placeholder {
            color: #999;
        }
        
        .current-avatar {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 15px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 4px;
        }
        
        .current-avatar img {
            width: 80px;
            height: 80px;
            border-radius: 4px;
            object-fit: cover;
        }
        
        .avatar-info h4 {
            color: #333;
            margin-bottom: 5px;
        }
        
        .avatar-info p {
            font-size: 12px;
            color: #999;
        }
        
        .file-input-wrapper {
            position: relative;
            overflow: hidden;
            display: inline-block;
            width: 100%;
        }
        
        .file-input-wrapper input[type=file] {
            position: absolute;
            left: -9999px;
        }
        
        .file-input-label {
            display: block;
            padding: 10px;
            background: #f8f9fa;
            border: 2px dashed #ddd;
            border-radius: 4px;
            text-align: center;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        
        .file-input-label:hover {
            background: #e9ecef;
        }
        
        .file-name {
            display: block;
            margin-top: 10px;
            font-size: 12px;
            color: #666;
        }
        
        .required {
            color: #dc3545;
        }
        
        .form-actions {
            display: flex;
            gap: 10px;
            margin-top: 30px;
        }
        
        .btn {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        
        .btn-primary {
            background: #ffc107;
            color: #212529;
        }
        
        .btn-primary:hover {
            background: #e0a800;
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
            text-decoration: none;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .btn-secondary:hover {
            background: #545b62;
        }
        
        .help-text {
            font-size: 12px;
            color: #999;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Chỉnh sửa thông tin sinh viên</h1>
        
        <!-- Hiển thị thông báo lỗi -->
        <?php if (isset($_SESSION['error'])): ?>
            <div class="alert alert-error">
                <?php 
                    echo $_SESSION['error']; 
                    unset($_SESSION['error']);
                ?>
            </div>
        <?php endif; ?>
        
        <!-- Form chỉnh sửa sinh viên -->
        <form method="POST" action="index.php?action=doUpdate" enctype="multipart/form-data">
            <input type="hidden" name="id" value="<?php echo htmlspecialchars($student['id']); ?>">
            
            <div class="form-group">
                <label for="name">Tên sinh viên <span class="required">*</span></label>
                <input type="text" id="name" name="name" 
                       value="<?php echo htmlspecialchars($student['name']); ?>" required>
            </div>
            
            <div class="form-group">
                <label for="email">Email <span class="required">*</span></label>
                <input type="email" id="email" name="email" 
                       value="<?php echo htmlspecialchars($student['email']); ?>" required>
                <div class="help-text">Ví dụ: student@example.com</div>
            </div>
            
            <div class="form-group">
                <label for="phone">Số điện thoại <span class="required">*</span></label>
                <input type="tel" id="phone" name="phone" 
                       value="<?php echo htmlspecialchars($student['phone']); ?>" 
                       required pattern="[0-9]{10,11}">
                <div class="help-text">Phải là 10 hoặc 11 chữ số</div>
            </div>
            
            <!-- Bài 10: Hiển thị và cập nhật ảnh -->
            <div class="form-group">
                <label>Ảnh đại diện hiện tại</label>
                <?php if (!empty($student['avatar'])): ?>
                    <div class="current-avatar">
                        <img src="uploads/<?php echo htmlspecialchars($student['avatar']); ?>" alt="Avatar">
                        <div class="avatar-info">
                            <h4>Ảnh hiện tại</h4>
                            <p><?php echo htmlspecialchars($student['avatar']); ?></p>
                        </div>
                    </div>
                <?php else: ?>
                    <div class="current-avatar">
                        <img src="https://via.placeholder.com/80" alt="No Avatar">
                        <div class="avatar-info">
                            <h4>Chưa có ảnh</h4>
                            <p>Hãy tải lên ảnh đại diện</p>
                        </div>
                    </div>
                <?php endif; ?>
            </div>
            
            <div class="form-group">
                <label for="avatar">Cập nhật ảnh đại diện</label>
                <div class="file-input-wrapper">
                    <input type="file" id="avatar" name="avatar" accept="image/*">
                    <label for="avatar" class="file-input-label">
                        <div>📷 Chọn ảnh mới (tùy chọn)</div>
                        <span class="file-name" id="file-name">Chưa chọn file</span>
                    </label>
                </div>
                <div class="help-text">Định dạng: JPG, PNG, GIF, WebP. Kích thước tối đa: 5MB</div>
            </div>
            
            <div class="form-actions">
                <button type="submit" class="btn btn-primary">Cập nhật sinh viên</button>
                <a href="index.php?action=index" class="btn btn-secondary">Hủy</a>
            </div>
        </form>
    </div>
    
    <script>
        // Hiển thị tên file khi chọn
        document.getElementById('avatar').addEventListener('change', function(e) {
            const fileName = e.target.files[0]?.name || 'Chưa chọn file';
            document.getElementById('file-name').textContent = fileName;
        });
    </script>
</body>
</html>