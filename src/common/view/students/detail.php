<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Profile</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;700&display=swap" rel="stylesheet">
    
    <style>
        /* CSS của bạn giữ nguyên, không cần thay đổi */
        body {
            background-color: #2875c2ff;
            font-family: 'Be Vietnam Pro', sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .profile-card {
            width: 100%;
            max-width: 650px;
            background-color: #ffffffff;
            border-radius: 15px;
            border: none;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.07);
            padding: 2.5rem;
            text-align: center;
        }
        .profile-header {
            margin-bottom: 2rem;
        }
        .profile-avatar {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            object-fit: cover;
            margin: 0 auto 1.5rem auto;
            border: 4px solid #041d36ff;
        }
        .profile-name {
            font-size: 1.75rem;
            font-weight: 700;
            color: #212529;
            margin-bottom: 0.25rem;
        }
        .profile-id {
            font-size: 1rem;
            font-weight: 500;
            color: #0d6efd;
            margin-bottom: 2rem;
        }
        .profile-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: #343a40;
            margin-bottom: 2rem;
        }
        .profile-details {
            text-align: left;
            margin-bottom: 2rem;
        }
        .detail-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 0;
            border-bottom: 1px solid #e9ecef;
        }
        .detail-item:last-child {
            border-bottom: none;
        }
        .detail-label {
            color: #6c757d;
            font-weight: 500;
        }
        .detail-value {
            color: #212529;
            font-weight: 500;
        }
        .profile-actions {
            display: flex;
            justify-content: center;
            gap: 1rem;
        }
        .profile-actions .btn {
            padding: 0.75rem 1.5rem;
            border-radius: 8px;
            font-weight: 500;
        }
    </style>
</head>
<body>

<div class="profile-card">
    <h2 class="profile-title">Student Profile</h2>
    
    <?php
        // =======================================================
        // BẮT ĐẦU PHẦN ĐIỀU CHỈNH
        // =======================================================

        // 1. Đặt đường dẫn mặc định cho ảnh avatar
        $avatarUrl = '/uploads/default-avatar.png'; // Ảnh này nên nằm trong thư mục public/images/

        // 2. Kiểm tra xem sinh viên có avatar không và file có thực sự tồn tại không
        if (!empty($student['avatar'])) {
            $studentAvatarPath = 'uploads/' . $student['avatar'];

            // Kiểm tra file tồn tại trên server để tránh lỗi ảnh hỏng
            // (Giả định rằng file view này được include từ public/index.php)
            if (file_exists($studentAvatarPath)) {
                $avatarUrl = $studentAvatarPath;
            }
        }
        // =======================================================
        // KẾT THÚC PHẦN ĐIỀU CHỈNH
        // =======================================================
    ?>

    <div class="profile-header">
        <img src="<?= htmlspecialchars($avatarUrl) ?>" alt="Student Avatar" class="profile-avatar">
        <h3 class="profile-name"><?= htmlspecialchars($student['name']) ?></h3>
        <p class="profile-id">ID: <?= htmlspecialchars($student['id']) ?></p>
    </div>

    <div class="profile-details">
        <div class="detail-item">
            <span class="detail-label">Class</span>
            <span class="detail-value"><?= htmlspecialchars($student['class'] ?? 'N/A') ?></span>
        </div>
        <div class="detail-item">
            <span class="detail-label">Major</span>
            <span class="detail-value"><?= htmlspecialchars($student['major'] ?? 'N/A') ?></span>
        </div>
        <div class="detail-item">
            <span class="detail-label">Email</span>
            <span class="detail-value"><?= htmlspecialchars($student['email']) ?></span>
        </div>
        <div class="detail-item">
            <span class="detail-label">Phone Number</span>
            <span class="detail-value"><?= htmlspecialchars($student['phone']) ?></span>
        </div>
        <div class="detail-item">
            <span class="detail-label">Date of Birth</span>
            <span class="detail-value"><?= isset($student['dob']) ? date('d/m/Y', strtotime($student['dob'])) : 'N/A' ?></span>
        </div>
        <div class="detail-item">
            <span class="detail-label">GPA</span>
            <span class="detail-value"><?= htmlspecialchars($student['gpa'] ?? 'N/A') ?></span>
        </div>
    </div>

    <div class="profile-actions">
        <a href="?action=edit&id=<?= $student['id'] ?>" class="btn btn-primary">Sửa</a>
        <a href="?action=students" class="btn btn-light border">Quay lại trang chủ</a>
    </div>
</div>

</body>
</html>