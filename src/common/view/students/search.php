<?php /** @var array $students */ ?>
<!DOCTYPE html>
<html lang="vi">
<head>
	<meta charset="UTF-8">
	<title>Kết quả tìm kiếm</title>
</head>
<body>
	<h1>Kết quả tìm kiếm</h1>
	<p>Tổng: <?php echo isset($total) ? (int)$total : count($students); ?></p>
	<p><a href="index.php?action=index">← Quay lại danh sách</a></p>
	<?php if (!empty($students)): ?>
		<table border="1" cellpadding="8">
			<thead>
				<tr>
					<th>ID</th>
					<th>Tên</th>
					<th>Email</th>
					<th>SĐT</th>
				</tr>
			</thead>
			<tbody>
			<?php foreach ($students as $s): ?>
				<tr>
					<td><?php echo (int)$s['id']; ?></td>
					<td><?php echo htmlspecialchars($s['name']); ?></td>
					<td><?php echo htmlspecialchars($s['email']); ?></td>
					<td><?php echo htmlspecialchars($s['phone']); ?></td>
				</tr>
			<?php endforeach; ?>
			</tbody>
		</table>
	<?php else: ?>
		<p>Không có kết quả phù hợp.</p>
	<?php endif; ?>
</body>
</html>

