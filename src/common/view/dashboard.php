<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        
        .navbar { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            padding: 15px 30px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            color: white;
        }
        .navbar h2 { font-size: 24px; }
        .navbar .user-info { display: flex; align-items: center; gap: 20px; }
        .navbar a { color: white; text-decoration: none; padding: 8px 16px; background: rgba(255,255,255,0.2); border-radius: 5px; }
        .navbar a:hover { background: rgba(255,255,255,0.3); }
        
        .container { max-width: 1200px; margin: 40px auto; padding: 0 20px; }
        
        .alert { padding: 15px; margin-bottom: 20px; border-radius: 5px; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        
        .dashboard-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; }
        .card { 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .card h3 { color: #333; margin-bottom: 15px; }
        .card a { 
            display: inline-block; 
            margin-top: 15px; 
            padding: 10px 20px; 
            background: #667eea; 
            color: white; 
            text-decoration: none; 
            border-radius: 5px; 
        }
        .card a:hover { opacity: 0.9; }
    </style>
</head>
<body>
    <div class="navbar">
        <h2>🎓 Hệ thống quản lý sinh viên</h2>
        <div class="user-info">
            <span>Xin chào, <strong><?= htmlspecialchars($_SESSION['username']) ?></strong></span>
            <a href="index.php?action=logout">Đăng xuất</a>
        </div>
    </div>
    
    <div class="container">
        <?php if ($message): ?>
            <div class="alert alert-<?= $messageType ?>">
                <?= htmlspecialchars($message) ?>
            </div>
        <?php endif; ?>
        
        <h1 style="margin-bottom: 30px;">Trang chủ Dashboard</h1>
        
        <div class="dashboard-cards">
            <div class="card">
                <h3>📋 Quản lý sinh viên</h3>
                <p>Xem, thêm, sửa, xóa thông tin sinh viên</p>
                <a href="index.php?action=list">Truy cập</a>
            </div>
            
            <div class="card">
                <h3>🔍 Tìm kiếm</h3>
                <p>Tìm kiếm sinh viên theo tên</p>
                <a href="index.php?action=list">Truy cập</a>
            </div>
            
            <div class="card">
                <h3>📊 Thống kê</h3>
                <p>Xem báo cáo và thống kê</p>
                <a href="#">Sắp có</a>
            </div>
        </div>
    </div>
</body>
</html>