<?php /** @var array $logs */ ?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nhật ký hoạt động</title>
    <style>
        :root {
            --primary: #007bff;
            --success: #28a745;
            --warning: #ffc107;
            --danger: #dc3545;
            --info: #17a2b8;
            --dark: #343a40;
            --light: #f8f9fa;
            --white: #fff;
            --border: #dee2e6;
            --text: #212529;
            --text-muted: #6c757d;
            --radius: 8px;
            --shadow: 0 2px 4px rgba(0,0,0,.1);
            --shadow-lg: 0 4px 12px rgba(0,0,0,.15);
        }
        
        * { box-sizing: border-box; margin: 0; padding: 0; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: var(--light);
            color: var(--text);
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: var(--white);
            padding: 24px;
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
        }
        
        .header h1 {
            color: var(--dark);
            font-size: 28px;
            font-weight: 600;
            margin: 0;
        }
        
        .stats {
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
        }
        
        .stat-item {
            background: var(--primary);
            color: var(--white);
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 500;
        }
        
        .actions {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: var(--radius);
            text-decoration: none;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: var(--primary);
            color: var(--white);
        }
        
        .btn-primary:hover {
            background: #0056b3;
            transform: translateY(-1px);
        }
        
        .btn-secondary {
            background: var(--text-muted);
            color: var(--white);
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .logs-container {
            background: var(--white);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
        }
        
        .logs-header {
            background: var(--dark);
            color: var(--white);
            padding: 16px 24px;
            font-weight: 600;
            display: grid;
            grid-template-columns: 1fr 100px 120px 80px 2fr;
            gap: 16px;
            align-items: center;
        }
        
        .logs-list {
            max-height: 600px;
            overflow-y: auto;
        }
        
        .log-item {
            padding: 16px 24px;
            border-bottom: 1px solid var(--border);
            display: grid;
            grid-template-columns: 1fr 100px 120px 80px 2fr;
            gap: 16px;
            align-items: center;
            transition: background 0.2s;
        }
        
        .log-item:hover {
            background: #f8f9fa;
        }
        
        .log-item:last-child {
            border-bottom: none;
        }
        
        .log-time {
            font-size: 14px;
            color: var(--text-muted);
            font-family: 'Courier New', monospace;
        }
        
        .log-user {
            font-weight: 500;
            color: var(--primary);
        }
        
        .log-action {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .action-create { background: #d4edda; color: #155724; }
        .action-update { background: #fff3cd; color: #856404; }
        .action-delete { background: #f8d7da; color: #721c24; }
        .action-export { background: #d1ecf1; color: #0c5460; }
        .action-login { background: #e2e3e5; color: #383d41; }
        .action-change_password { background: #fce4ec; color: #880e4f; }
        .action-default { background: #e9ecef; color: #495057; }
        
        .log-target {
            font-weight: 500;
            color: var(--info);
        }
        
        .log-details {
            color: var(--text);
            font-size: 14px;
        }
        
        .no-logs {
            text-align: center;
            padding: 60px 24px;
            color: var(--text-muted);
        }
        
        .no-logs-icon {
            font-size: 48px;
            margin-bottom: 16px;
            opacity: 0.5;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            gap: 8px;
            padding: 20px;
            background: var(--light);
            border-top: 1px solid var(--border);
        }
        
        .pagination a, .pagination span {
            padding: 8px 12px;
            border: 1px solid var(--border);
            text-decoration: none;
            color: var(--text);
            border-radius: 4px;
            transition: all 0.2s;
        }
        
        .pagination a:hover {
            background: var(--primary);
            color: var(--white);
            border-color: var(--primary);
        }
        
        .pagination .active {
            background: var(--primary);
            color: var(--white);
            border-color: var(--primary);
        }
        
        .pagination .disabled {
            color: var(--text-muted);
            cursor: not-allowed;
        }
        
        @media (max-width: 768px) {
            .logs-header, .log-item {
                grid-template-columns: 1fr;
                gap: 8px;
            }
            
            .logs-header {
                display: none;
            }
            
            .log-item {
                border: 1px solid var(--border);
                margin-bottom: 8px;
                border-radius: var(--radius);
            }
            
            .log-time::before { content: "🕒 "; }
            .log-user::before { content: "👤 "; }
            .log-action::before { content: "⚡ "; }
            .log-target::before { content: "🎯 "; }
            .log-details::before { content: "📝 "; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>📊 Nhật ký hoạt động hệ thống</h1>
                <div class="stats">
                    <div class="stat-item">Tổng: <?php echo isset($total) ? (int)$total : 0; ?> hoạt động</div>
                    <div class="stat-item">Trang: <?php echo isset($page) ? (int)$page : 1; ?>/<?php echo isset($totalPages) ? (int)$totalPages : 1; ?></div>
                </div>
            </div>
            <div class="actions">
                <a href="index.php?action=index" class="btn btn-primary">🏠 Trang chủ</a>
                <a href="index.php?action=statistics" class="btn btn-secondary">📈 Thống kê</a>
            </div>
        </div>

        <div class="logs-container">
            <div class="logs-header">
                <div>Thời gian</div>
                <div>Người dùng</div>
                <div>Hành động</div>
                <div>Đối tượng</div>
                <div>Chi tiết</div>
            </div>
            
            <div class="logs-list">
                <?php if (!empty($logs)): ?>
                    <?php foreach ($logs as $log): ?>
                        <div class="log-item">
                            <div class="log-time">
                                <?php 
                                $time = $log['created_at'] ?? '';
                                echo date('d/m/Y H:i:s', strtotime($time));
                                ?>
                            </div>
                            <div class="log-user">
                                User #<?php echo htmlspecialchars($log['user_id'] ?? '0'); ?>
                            </div>
                            <div class="log-action action-<?php echo str_replace('_', '-', $log['action'] ?? 'default'); ?>">
                                <?php 
                                $action = $log['action'] ?? '';
                                $actionLabels = [
                                    'create_student' => 'Tạo SV',
                                    'update_student' => 'Sửa SV',
                                    'delete_student' => 'Xóa SV',
                                    'export_csv' => 'Xuất CSV',
                                    'change_password' => 'Đổi MK',
                                    'login' => 'Đăng nhập',
                                    'register' => 'Đăng ký'
                                ];
                                echo $actionLabels[$action] ?? ucfirst(str_replace('_', ' ', $action));
                                ?>
                            </div>
                            <div class="log-target">
                                <?php if (!empty($log['student_id'])): ?>
                                    SV #<?php echo htmlspecialchars($log['student_id']); ?>
                                <?php else: ?>
                                    -
                                <?php endif; ?>
                            </div>
                            <div class="log-details">
                                <?php echo htmlspecialchars($log['details'] ?? ''); ?>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <div class="no-logs">
                        <div class="no-logs-icon">📋</div>
                        <h3>Chưa có nhật ký hoạt động</h3>
                        <p>Thực hiện một số thao tác để xem nhật ký xuất hiện ở đây.</p>
                    </div>
                <?php endif; ?>
            </div>
            
            <?php if (isset($totalPages) && $totalPages > 1): ?>
                <div class="pagination">
                    <?php if ($page > 1): ?>
                        <a href="index.php?action=logs&page=<?php echo $page - 1; ?>">« Trước</a>
                    <?php else: ?>
                        <span class="disabled">« Trước</span>
                    <?php endif; ?>

                    <?php for ($i = 1; $i <= $totalPages; $i++): ?>
                        <?php if ($i == $page): ?>
                            <span class="active"><?php echo $i; ?></span>
                        <?php else: ?>
                            <a href="index.php?action=logs&page=<?php echo $i; ?>"><?php echo $i; ?></a>
                        <?php endif; ?>
                    <?php endfor; ?>

                    <?php if ($page < $totalPages): ?>
                        <a href="index.php?action=logs&page=<?php echo $page + 1; ?>">Sau »</a>
                    <?php else: ?>
                        <span class="disabled">Sau »</span>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>

