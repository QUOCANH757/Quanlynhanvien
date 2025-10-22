<?php
http_response_code(500);
?>
<!DOCTYPE html>
<html lang="vi">
<head>
	<meta charset="UTF-8">
	<title>Lỗi hệ thống</title>
	<style>
		body{font-family:Arial,Helvetica,sans-serif;background:#f8f9fa;color:#333;margin:0;padding:40px}
		.card{max-width:720px;margin:0 auto;background:#fff;border:1px solid #e9ecef;border-radius:8px;padding:24px}
		h1{margin-top:0;color:#c1121f}
		pre{background:#f1f3f5;padding:12px;border-radius:6px;overflow:auto}
		.a{display:inline-block;margin-top:16px;text-decoration:none;color:#0056b3}
	</style>
</head>
<body>
	<div class="card">
		<h1>Đã xảy ra lỗi hệ thống</h1>
		<p>Vui lòng thử lại sau. Nếu lỗi tiếp diễn, liên hệ quản trị viên.</p>
		<?php if (!empty($_SESSION['error'])): ?>
			<pre><?php echo htmlspecialchars($_SESSION['error']); ?></pre>
		<?php endif; ?>
		<a class="a" href="/ThucHanhBuoi1/public/index.php?action=index">Quay lại trang chủ</a>
	</div>
</body>
</html>

