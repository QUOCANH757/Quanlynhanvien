<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Liên Hệ</title>
    <link href="/styles/form.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="contact-card">
        <h2>Liên Hệ Với Chúng Tôi</h2>
        <?php if (isset($result)): ?>
            <div class="alert alert-<?= $result['success'] ? 'success' : 'danger' ?>">
                <?= htmlspecialchars($result['message']) ?>
            </div>
        <?php endif; ?>
        <form method="POST" action="?action=contact_store">
            <div class="mb-3">
                <label for="name" class="form-label">Họ và Tên:</label>
                <input type="text" id="name" name="name" class="form-control" required>
            </div>
            <div class="mb-3">
                <label for="email" class="form-label">Email:</label>
                <input type="email" id="email" name="email" class="form-control" required>
            </div>
            <div class="mb-3">
                <label for="content" class="form-label">Nội dung tin nhắn:</label>
                <textarea id="content" name="content" class="form-control" rows="5" required></textarea>
            </div>
            <button type="submit" class="btn btn-submit mt-3">Gửi Tin Nhắn</button>
        </form>
    </div>
</body>
</html>