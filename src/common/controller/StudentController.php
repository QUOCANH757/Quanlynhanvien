<?php
/**
 * File: src/common/controller/StudentController.php
 * Controller xử lý Student - Hoàn chỉnh cho tất cả 10 bài tập
 */

class StudentController {
    private $studentModel;
    private $logModel;
    
    public function __construct() {
        require_once MODELS_PATH . '/Student.php';
        require_once MODELS_PATH . '/ActivityLog.php';
        
        $this->studentModel = new Student();
        $this->logModel = new ActivityLog();
    }
    
    // ============================================
    // BÀI 1: HIỂN THỊ DANH SÁCH SINH VIÊN
    // ============================================
    
    /**
     * Hiển thị danh sách sinh viên (có phân trang, sắp xếp)
     * Bài 1, 6, 14
     */
    public function index() {
        // Lấy tham số từ URL
        $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
        $sort = isset($_GET['sort']) ? $_GET['sort'] : 'id';
        $order = isset($_GET['order']) ? strtoupper($_GET['order']) : 'ASC';
        $search = isset($_GET['search']) ? trim($_GET['search']) : '';
        
        // Kiểm tra page hợp lệ
        $totalPages = $this->studentModel->getTotalPages($search);
        if ($page < 1 || $page > $totalPages) {
            $page = 1;
        }
        
        // Lấy dữ liệu
        $students = $this->studentModel->getAllPaginated($page, $sort, $order, $search);
        $total = $this->studentModel->getTotal($search);
        $perPage = $this->studentModel->getPerPage();
        
        // Dữ liệu cho view
        $data = [
            'students' => $students,
            'total' => $total,
            'page' => $page,
            'perPage' => $perPage,
            'totalPages' => $totalPages,
            'sort' => $sort,
            'order' => $order,
            'search' => $search
        ];
        
        $this->view('students/index', $data);
    }
    
    // ============================================
    // BÀI 2: THÊM SINH VIÊN MỚI
    // ============================================
    
    /**
     * Hiển thị form thêm sinh viên
     */
    public function showCreate() {
        $this->view('students/create');
    }
    
    /**
     * Xử lý thêm sinh viên
     */
    public function doCreate() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: index.php?action=create');
            exit;
        }
        
        $name = trim($_POST['name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $phone = trim($_POST['phone'] ?? '');
        $avatar = null;
        
        // Validate
        $errors = [];
        if (empty($name)) {
            $errors[] = 'Tên không được để trống';
        }
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'Email không hợp lệ';
        }
        if (empty($phone)) {
            $errors[] = 'Số điện thoại không được để trống';
        }
        
        if (!empty($errors)) {
            $_SESSION['errors'] = $errors;
            header('Location: index.php?action=create');
            exit;
        }
        
        // Xử lý upload file
        if (isset($_FILES['avatar']) && $_FILES['avatar']['size'] > 0) {
            $uploadResult = $this->handleFileUpload($_FILES['avatar']);
            if ($uploadResult['success']) {
                $avatar = $uploadResult['filename'];
            } else {
                $_SESSION['error'] = $uploadResult['message'];
                header('Location: index.php?action=create');
                exit;
            }
        }
        
        // Tạo sinh viên
        $result = $this->studentModel->create($name, $email, $phone, $avatar);
        
        if ($result['success']) {
            // Ghi log (Bài 20)
            $userId = $_SESSION['user_id'] ?? 0;
            $this->logModel->log('create_student', $userId, null, "Tạo sinh viên: $name");
            
            $_SESSION['success'] = $result['message'];
            header('Location: index.php?action=index');
        } else {
            $_SESSION['error'] = $result['message'];
            header('Location: index.php?action=create');
        }
        exit;
    }
    
    // ============================================
    // BÀI 3: HIỂN THỊ VÀ CHỈNH SỬA SINH VIÊN
    // ============================================
    
    /**
     * Hiển thị form chỉnh sửa sinh viên
     */
    public function showEdit() {
        $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        
        if (!$id) {
            $_SESSION['error'] = 'ID không hợp lệ';
            header('Location: index.php?action=index');
            exit;
        }
        
        $student = $this->studentModel->getById($id);
        if (!$student) {
            $_SESSION['error'] = 'Sinh viên không tồn tại';
            header('Location: index.php?action=index');
            exit;
        }
        
        $this->view('students/edit', ['student' => $student]);
    }
    
    /**
     * Xử lý cập nhật sinh viên
     */
    public function doUpdate() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: index.php?action=index');
            exit;
        }
        
        $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
        $name = trim($_POST['name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $phone = trim($_POST['phone'] ?? '');
        $avatar = null;
        
        // Validate
        $errors = [];
        if (!$id) {
            $errors[] = 'ID không hợp lệ';
        }
        if (empty($name)) {
            $errors[] = 'Tên không được để trống';
        }
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'Email không hợp lệ';
        }
        if (empty($phone)) {
            $errors[] = 'Số điện thoại không được để trống';
        }
        
        if (!empty($errors)) {
            $_SESSION['errors'] = $errors;
            header('Location: index.php?action=edit&id=' . $id);
            exit;
        }
        
        // Xử lý upload file nếu có
        if (isset($_FILES['avatar']) && $_FILES['avatar']['size'] > 0) {
            $uploadResult = $this->handleFileUpload($_FILES['avatar']);
            if ($uploadResult['success']) {
                $avatar = $uploadResult['filename'];
            } else {
                $_SESSION['error'] = $uploadResult['message'];
                header('Location: index.php?action=edit&id=' . $id);
                exit;
            }
        }
        
        // Cập nhật sinh viên
        $result = $this->studentModel->update($id, $name, $email, $phone, $avatar);
        
        if ($result['success']) {
            // Ghi log (Bài 20)
            $userId = $_SESSION['user_id'] ?? 0;
            $this->logModel->log('update_student', $userId, $id, "Cập nhật sinh viên: $name");
            
            $_SESSION['success'] = $result['message'];
            header('Location: index.php?action=index');
        } else {
            $_SESSION['error'] = $result['message'];
            header('Location: index.php?action=edit&id=' . $id);
        }
        exit;
    }
    
    // ============================================
    // BÀI 4: XÓA SINH VIÊN
    // ============================================
    
    /**
     * Xóa sinh viên
     */
    public function delete() {
        $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        
        if (!$id) {
            $_SESSION['error'] = 'ID không hợp lệ';
            header('Location: index.php?action=index');
            exit;
        }
        
        // Lấy thông tin trước khi xóa (để ghi log)
        $student = $this->studentModel->getById($id);
        
        $result = $this->studentModel->delete($id);
        
        if ($result['success']) {
            // Ghi log (Bài 20)
            $userId = $_SESSION['user_id'] ?? 0;
            $name = $student['name'] ?? 'N/A';
            $this->logModel->log('delete_student', $userId, $id, "Xóa sinh viên: $name");
            
            $_SESSION['success'] = $result['message'];
        } else {
            $_SESSION['error'] = $result['message'];
        }
        
        header('Location: index.php?action=index');
        exit;
    }
    
    // ============================================
    // BÀI 5: TÌM KIẾM SINH VIÊN
    // ============================================
    
    /**
     * Tìm kiếm sinh viên
     */
    public function search() {
        $keyword = isset($_GET['q']) ? trim($_GET['q']) : '';
        $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
        
        if (empty($keyword)) {
            header('Location: index.php?action=index');
            exit;
        }
        
        $students = $this->studentModel->getAllPaginated($page, 'id', 'ASC', $keyword);
        $total = $this->studentModel->getTotal($keyword);
        $perPage = $this->studentModel->getPerPage();
        $totalPages = ceil($total / $perPage);
        
        $data = [
            'students' => $students,
            'total' => $total,
            'page' => $page,
            'perPage' => $perPage,
            'totalPages' => $totalPages,
            'keyword' => $keyword
        ];
        
        $this->view('students/search', $data);
    }
    
    // ============================================
    // BÀI 11: HIỂN THỊ THỐNG KÊ SỐ LƯỢNG SINH VIÊN
    // ============================================
    
    /**
     * Hiển thị thống kê
     */
    public function statistics() {
        $stats = $this->studentModel->getStatistics();
        
        $this->view('students/statistics', [
            'total' => $stats['total'],
            'gmail' => $stats['gmail'],
            'phone09' => $stats['phone09']
        ]);
    }
    
    // ============================================
    // BÀI 13: HIỂN THỊ CHI TIẾT SINH VIÊN
    // ============================================
    
    /**
     * Hiển thị chi tiết sinh viên
     */
    public function detail() {
        $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        
        // Kiểm tra id hợp lệ
        if (!$id || !is_numeric($id)) {
            $_SESSION['error'] = 'ID không hợp lệ';
            header('Location: index.php?action=index');
            exit;
        }
        
        $student = $this->studentModel->getById($id);
        
        if (!$student) {
            $_SESSION['error'] = 'Sinh viên không tồn tại';
            header('Location: index.php?action=index');
            exit;
        }
        
        $this->view('students/detail', ['student' => $student]);
    }
    
    // ============================================
    // BÀI 18: XUẤT DANH SÁCH SINH VIÊN RA FILE CSV
    // ============================================
    
    /**
     * Xuất danh sách sinh viên ra CSV
     */
    public function exportCsv() {
        // Lấy tất cả sinh viên
        $students = $this->studentModel->getAllForExport();
        
        // Thiết lập header HTTP
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="students_' . date('Y-m-d_H-i-s') . '.csv"');
        
        // BOM cho UTF-8 (để Excel đọc đúng tiếng Việt)
        echo "\xEF\xBB\xBF";
        
        // Mở output stream
        $output = fopen('php://output', 'w');
        
        // Ghi header
        fputcsv($output, ['ID', 'Tên', 'Email', 'Số Điện Thoại', 'Ảnh', 'Ngày Tạo', 'Ngày Cập Nhật'], ',');
        
        // Ghi dữ liệu
        foreach ($students as $student) {
            fputcsv($output, [
                $student['id'],
                $student['name'],
                $student['email'],
                $student['phone'],
                $student['avatar'] ?? 'N/A',
                $student['created_at'],
                $student['updated_at'] ?? 'N/A'
            ], ',');
        }
        
        // Ghi log
        $userId = $_SESSION['user_id'] ?? 0;
        $this->logModel->log('export_csv', $userId, null, "Xuất danh sách sinh viên (CSV)");
        
        fclose($output);
        exit;
    }
    
    // ============================================
    // BÀI 20: GHI LOG HOẠT ĐỘNG NGƯỜI DÙNG
    // ============================================
    
    /**
     * Xem logs hoạt động
     */
    public function viewLogs() {
        $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
        $logs = $this->logModel->getAll($page);
        $total = $this->logModel->getTotal();
        $perPage = $this->logModel->getPerPage();
        $totalPages = ceil($total / $perPage);
        
        $this->view('logs/index', [
            'logs' => $logs,
            'page' => $page,
            'totalPages' => $totalPages,
            'total' => $total
        ]);
    }
    
    // ============================================
    // HELPER METHODS
    // ============================================
    
    /**
     * Render view
     */
    private function view($path, $data = []) {
        extract($data);
        $file = VIEWS_PATH . '/' . str_replace('.', '/', $path) . '.php';
        
        if (!file_exists($file)) {
            die("View không tồn tại: $file");
        }
        
        require $file;
    }
    
    /**
     * Xử lý upload file
     */
    private function handleFileUpload($file) {
        $allowed = ['jpg', 'jpeg', 'png', 'gif'];
        $maxSize = 2 * 1024 * 1024; // 2MB
        
        // Kiểm tra size
        if ($file['size'] > $maxSize) {
            return ['success' => false, 'message' => 'File quá lớn (tối đa 2MB)'];
        }
        
        // Kiểm tra type
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, $allowed)) {
            return ['success' => false, 'message' => 'Định dạng file không hợp lệ'];
        }
        
        // Tạo tên file duy nhất
        $filename = 'avatar_' . time() . '_' . uniqid() . '.' . $ext;
        $uploadPath = UPLOADS_PATH . '/students/' . $filename;
        
        // Tạo thư mục nếu chưa tồn tại
        if (!is_dir(UPLOADS_PATH . '/students')) {
            mkdir(UPLOADS_PATH . '/students', 0755, true);
        }
        
        // Upload file
        if (move_uploaded_file($file['tmp_name'], $uploadPath)) {
            return ['success' => true, 'filename' => 'students/' . $filename];
        } else {
            return ['success' => false, 'message' => 'Lỗi upload file'];
        }
    }
}