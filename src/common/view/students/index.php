<?php
/**
 * File: src/view/students/index.php
 * View hiển thị danh sách sinh viên (Bài 1, 4, 5, 6, 9, 10)
 */
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="/styles/index.css" rel="stylesheet">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Danh sách sinh viên</title>
</head>
<body>
    <div class="container">
        <!-- Thông tin user đã đăng nhập -->
        <?php if (isset($_SESSION['username'])): ?>
        <div class="user-info">
            <span>Xin chào, <strong><?php echo htmlspecialchars($_SESSION['username']); ?></strong></span>
            <a href="index.php?action=logout" class="btn btn-secondary">Đăng xuất</a>
        </div>
        <?php endif; ?>
        
        <h1>Danh sách sinh viên</h1>

        <!-- Bài 9: Hiển thị thông báo -->
        <?php if (isset($_SESSION['success'])): ?>
            <div class="alert alert-success">
                <?php 
                    echo $_SESSION['success']; 
                    unset($_SESSION['success']);
                ?>
            </div>
        <?php endif; ?>

        <?php if (isset($_SESSION['error'])): ?>
            <div class="alert alert-error">
                <?php 
                    echo $_SESSION['error']; 
                    unset($_SESSION['error']);
                ?>
            </div>
        <?php endif; ?>

        <!-- Bài 5: Form tìm kiếm -->
        <form method="GET" action="index.php" class="search-bar">
            <input type="hidden" name="action" value="index">
            <input type="text" name="search" placeholder="Tìm kiếm theo tên sinh viên..." 
                   value="<?php echo isset($_GET['search']) ? htmlspecialchars($_GET['search']) : ''; ?>">
            <button type="submit">Tìm kiếm</button>
            <?php if (isset($_GET['search']) && !empty($_GET['search'])): ?>
                <a href="index.php?action=index" class="btn btn-secondary">Xóa tìm kiếm</a>
            <?php endif; ?>
        </form>

        <div class="actions">
            <a href="index.php?action=create" class="btn btn-primary">+ Thêm sinh viên mới</a>
            <a href="index.php?action=statistics" class="btn btn-secondary">Thống kê</a>
            <a href="index.php?action=export-csv" class="btn btn-secondary">Xuất CSV</a>
            <a href="index.php?action=logs" class="btn btn-secondary">Xem log</a>
            <a href="index.php?action=contact" class="btn btn-secondary">Liên hệ</a>
        </div>
        <?php if (count($students) > 0): ?>
        <table>
            <thead>
                <tr>
                    <th><a href="index.php?action=index&sort=id&order=<?php echo ($order==='ASC'?'DESC':'ASC'); ?>">ID</a></th>
                    <th>Ảnh đại diện</th>
                    <th><a href="index.php?action=index&sort=name&order=<?php echo ($order==='ASC'?'DESC':'ASC'); ?>">Tên</a></th>
                    <th><a href="index.php?action=index&sort=email&order=<?php echo ($order==='ASC'?'DESC':'ASC'); ?>">Email</a></th>
                    <th><a href="index.php?action=index&sort=phone&order=<?php echo ($order==='ASC'?'DESC':'ASC'); ?>">Số điện thoại</a></th>
                    <th>Thao tác</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($students as $student): ?>
                <tr>
                    <td><?php echo htmlspecialchars($student['id']); ?></td>
                    <td>
                        <?php if (!empty($student['avatar'])): ?>
                            <img src="uploads/<?php echo htmlspecialchars($student['avatar']); ?>" 
                                 alt="Avatar" class="avatar">
                        <?php else: ?>
                            <img src="../uploads/" alt="No Avatar" class="avatar">
                        <?php endif; ?>
                    </td>
                    <td><?php echo htmlspecialchars($student['name']); ?></td>
                    <td><?php echo htmlspecialchars($student['email']); ?></td>
                    <td><?php echo htmlspecialchars($student['phone']); ?></td>
                    <td>
                        <div class="action-buttons">
                            <a href="index.php?action=edit&id=<?php echo htmlspecialchars($student['id']); ?>" 
                               class="btn btn-warning">Sửa</a>
                            <a href="index.php?action=delete&id=<?php echo htmlspecialchars($student['id']); ?>" 
                               class="btn btn-danger"
                               onclick="return confirm('Bạn có chắc chắn muốn xóa sinh viên này?')">Xóa</a>
                            <a href="index.php?action=detail&id=<?php echo htmlspecialchars($student['id']); ?>" 
                               class="btn btn-detail">xem chi tiết </a>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>

        <!-- Bài 6: Phân trang -->
        <?php if ($totalPages > 1): ?>
        <div class="pagination">
            <?php if ($page > 1): ?>
                <a href="index.php?action=index&page=<?php echo ($page - 1); ?><?php echo isset($_GET['search']) ? '&search=' . urlencode($_GET['search']) : ''; ?>">« Trước</a>
            <?php else: ?>
                <span class="disabled">« Trước</span>
            <?php endif; ?>

            <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                <?php if ($i == $page): ?>
                    <span class="active"><?php echo $i; ?></span>
                <?php else: ?>
                    <a href="index.php?action=index&page=<?php echo $i; ?><?php echo isset($_GET['search']) ? '&search=' . urlencode($_GET['search']) : ''; ?>">
                        <?php echo $i; ?>
                    </a>
                <?php endif; ?>
            <?php endfor; ?>

            <?php if ($page < $totalPages): ?>
                <a href="index.php?action=index&page=<?php echo ($page + 1); ?><?php echo isset($_GET['search']) ? '&search=' . urlencode($_GET['search']) : ''; ?>">Sau »</a>
            <?php else: ?>
                <span class="disabled">Sau »</span>
            <?php endif; ?>
        </div>
        <?php endif; ?>

        <?php else: ?>
        <div class="no-data">
            <p>Không tìm thấy sinh viên nào.</p>
        </div>
        <?php endif; ?>
    </div>
</body>
</html>