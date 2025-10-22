<table class="table">
    <thead>
        <tr>
            <th>ID</th>
            <th>Tên</th>
            <th>Email</th>
            <th>SĐT</th>
            <th>Hành động</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($students as $student): ?>
        <tr>
            <td><?= $student['id'] ?></td>
            <td>
                <a href="?action=detail&id=<?= $student['id'] ?>">
                    <?= htmlspecialchars($student['name']) ?>
                </a>
            </td>
            <td><?= $student['email'] ?></td>
            <td><?= $student['phone'] ?></td>
            <td>
                <a href="?action=edit&id=<?= $student['id'] ?>" class="btn btn-sm btn-warning">Sửa</a>
                <a href="?action=delete&id=<?= $student['id'] ?>" class="btn btn-sm btn-danger" onclick="return confirm('Xóa?')">Xóa</a>
            </td>
        </tr>
        <?php endforeach; ?>
    </tbody>
</table>