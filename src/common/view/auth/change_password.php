<!DOCTYPE html>
<html lang="vi">
<head>
	<meta charset="UTF-8">
	<title>Đổi mật khẩu</title>
</head>
<body>
	<h1>Đổi mật khẩu</h1>
	<?php if (!empty($_SESSION['errors'])): ?>
		<ul style="color:red;">
			<?php foreach ($_SESSION['errors'] as $err): ?>
				<li><?php echo htmlspecialchars($err); ?></li>
			<?php endforeach; unset($_SESSION['errors']); ?>
		</ul>
	<?php endif; ?>
	<form method="post" action="index.php?action=doChangePassword">
		<div>
			<label>Mật khẩu cũ</label>
			<input type="password" name="old_password" required>
		</div>
		<div>
			<label>Mật khẩu mới</label>
			<input type="password" name="new_password" required>
		</div>
		<div>
			<label>Nhập lại mật khẩu mới</label>
			<input type="password" name="confirm_password" required>
		</div>
		<button type="submit">Cập nhật</button>
		<a href="index.php?action=index">Hủy</a>
	</form>
</body>
</html>

