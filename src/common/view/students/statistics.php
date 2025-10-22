<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thống kê sinh viên</title>
    <style>
        :root {
            --primary: #007bff;
            --success: #28a745;
            --warning: #ffc107;
            --text: #343a40;
            --muted: #6c757d;
            --bg: #f8f9fa;
            --white: #fff;
            --radius: 10px;
            --shadow: 0 8px 24px rgba(0,0,0,.08);
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif; background: var(--bg); color: var(--text); }
        .wrap { max-width: 1000px; margin: 32px auto; padding: 24px; background: var(--white); border-radius: var(--radius); box-shadow: var(--shadow); }
        h1 { margin: 0 0 24px; font-weight: 600; }
        .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
        .card { border-radius: var(--radius); padding: 24px; color: #fff; box-shadow: var(--shadow); }
        .card h4 { margin: 0 0 8px; font-weight: 500; opacity: .9; }
        .card .num { font-size: 40px; font-weight: 700; line-height: 1; }
        .primary { background: linear-gradient(135deg, #2b8cff, #0056b3); }
        .success { background: linear-gradient(135deg, #4ad66d, #1e7e34); }
        .warning { background: linear-gradient(135deg, #ffd34d, #cc9a06); color: #212529; }
        .actions { margin-top: 24px; display: flex; gap: 12px; }
        .btn { padding: 10px 16px; border-radius: 8px; text-decoration: none; display: inline-block; border: 1px solid #dee2e6; color: var(--text); background: #fff; }
        .btn:hover { background: #f1f3f5; }
    </style>
    </head>
<body>
    <div class="wrap">
        <h1>Thống kê sinh viên</h1>
        <div class="grid">
            <div class="card primary">
                <h4>Tổng số sinh viên</h4>
                <div class="num"><?= (int)$total ?></div>
            </div>
            <div class="card success">
                <h4>Email @gmail.com</h4>
                <div class="num"><?= (int)$gmail ?></div>
            </div>
            <div class="card warning">
                <h4>SĐT bắt đầu 09</h4>
                <div class="num"><?= (int)$phone09 ?></div>
            </div>
        </div>
        <div class="actions">
            <a class="btn" href="index.php?action=index">← Quay lại danh sách</a>
            <a class="btn" href="index.php?action=export-csv">Xuất CSV</a>
        </div>
    </div>
</body>
</html>