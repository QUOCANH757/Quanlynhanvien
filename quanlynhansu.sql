-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 26, 2025 at 02:50 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `quanlynhansu`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_KhoiTaoHanMucPhep` (IN `p_year` YEAR)   BEGIN
    INSERT INTO HanMucPhep (employee_id, year, leave_type_id, total_days)
    SELECT 
        nv.employee_id,
        p_year,
        lnp.leave_type_id,
        lnp.default_days_per_year
    FROM NhanVien nv
    CROSS JOIN LoaiNghiPhep lnp
    WHERE nv.employment_status IN ('PROBATION', 'OFFICIAL')
    AND lnp.is_active = TRUE
    AND lnp.default_days_per_year > 0
    AND NOT EXISTS (
        SELECT 1 FROM HanMucPhep
        WHERE employee_id = nv.employee_id
        AND year = p_year
        AND leave_type_id = lnp.leave_type_id
    );
    
    SELECT CONCAT('Đã khởi tạo hạn mức phép năm ', p_year) AS message;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_NhacNhoHopDongHetHan` (IN `p_days_before` INT)   BEGIN
    SELECT 
        nv.employee_code,
        nv.full_name,
        nv.work_email,
        hdld.contract_number,
        hdld.end_date,
        DATEDIFF(hdld.end_date, CURDATE()) AS days_remaining
    FROM HopDongLaoDong hdld
    JOIN NhanVien nv ON hdld.employee_id = nv.employee_id
    WHERE hdld.contract_status = 'ACTIVE'
    AND hdld.end_date IS NOT NULL
    AND DATEDIFF(hdld.end_date, CURDATE()) BETWEEN 0 AND p_days_before
    ORDER BY hdld.end_date;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_PheDuyetNghiPhep` (IN `p_leave_request_id` INT, IN `p_approver_id` INT, IN `p_status` VARCHAR(20), IN `p_note` TEXT)   BEGIN
    DECLARE v_employee_id INT;
    DECLARE v_leave_type_id INT;
    DECLARE v_year YEAR;
    DECLARE v_total_days DECIMAL(5,2);
    
    -- Lấy thông tin đơn nghỉ phép
    SELECT employee_id, leave_type_id, YEAR(start_date), total_days
    INTO v_employee_id, v_leave_type_id, v_year, v_total_days
    FROM DonNghiPhep
    WHERE leave_request_id = p_leave_request_id;
    
    -- Cập nhật trạng thái đơn
    UPDATE DonNghiPhep
    SET request_status = p_status,
        approver_id = p_approver_id,
        approved_at = CURRENT_TIMESTAMP,
        approval_note = p_note
    WHERE leave_request_id = p_leave_request_id;
    
    -- Nếu phê duyệt, cập nhật hạn mức phép
    IF p_status = 'APPROVED' THEN
        UPDATE HanMucPhep
        SET used_days = used_days + v_total_days
        WHERE employee_id = v_employee_id
        AND year = v_year
        AND leave_type_id = v_leave_type_id;
    END IF;
    
    SELECT CONCAT('Đã ', p_status, ' đơn nghỉ phép #', p_leave_request_id) AS message;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_TaoBangChamCongThang` (IN `p_year` YEAR, IN `p_month` TINYINT)   BEGIN
    -- Tạo bảng chấm công cho tất cả nhân viên đang làm việc
    INSERT INTO BangChamCong (employee_id, year, month, total_working_days)
    SELECT 
        employee_id,
        p_year,
        p_month,
        (SELECT standard_working_days FROM CauHinhCongTy LIMIT 1)
    FROM NhanVien
    WHERE employment_status IN ('PROBATION', 'OFFICIAL')
    AND NOT EXISTS (
        SELECT 1 FROM BangChamCong 
        WHERE employee_id = NhanVien.employee_id 
        AND year = p_year 
        AND month = p_month
    );
    
    SELECT CONCAT('Đã tạo bảng chấm công tháng ', p_month, '/', p_year) AS message;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_TinhLuongThang` (IN `p_employee_id` INT, IN `p_year` YEAR, IN `p_month` TINYINT)   BEGIN
    DECLARE v_basic_salary DECIMAL(15,2);
    DECLARE v_working_days INT;
    DECLARE v_actual_days DECIMAL(5,2);
    DECLARE v_overtime_hours DECIMAL(6,2);
    DECLARE v_overtime_rate DECIMAL(5,2);
    DECLARE v_hourly_rate DECIMAL(15,2);
    
    -- Lấy thông tin lương cơ bản
    SELECT basic_salary INTO v_basic_salary
    FROM HopDongLaoDong
    WHERE employee_id = p_employee_id 
    AND contract_status = 'ACTIVE'
    ORDER BY start_date DESC
    LIMIT 1;
    
    -- Lấy cấu hình
    SELECT standard_working_days, overtime_rate 
    INTO v_working_days, v_overtime_rate
    FROM CauHinhCongTy LIMIT 1;
    
    -- Lấy dữ liệu chấm công
    SELECT total_present_days, total_overtime_hours
    INTO v_actual_days, v_overtime_hours
    FROM BangChamCong
    WHERE employee_id = p_employee_id 
    AND year = p_year 
    AND month = p_month;
    
    -- Tính lương giờ
    SET v_hourly_rate = v_basic_salary / v_working_days / 8;
    
    -- Insert hoặc update bảng lương
    INSERT INTO BangLuong (
        employee_id, year, month, 
        basic_salary, working_days, actual_working_days,
        overtime_amount, payroll_status
    ) VALUES (
        p_employee_id, p_year, p_month,
        v_basic_salary, v_working_days, v_actual_days,
        v_hourly_rate * v_overtime_hours * v_overtime_rate,
        'DRAFT'
    )
    ON DUPLICATE KEY UPDATE
        actual_working_days = v_actual_days,
        overtime_amount = v_hourly_rate * v_overtime_hours * v_overtime_rate,
        updated_at = CURRENT_TIMESTAMP;
    
    SELECT CONCAT('Đã tính lương tháng ', p_month, '/', p_year) AS message;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bangchamcong`
--

CREATE TABLE `bangchamcong` (
  `timesheet_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `year` year(4) NOT NULL,
  `month` tinyint(4) NOT NULL COMMENT 'Tháng 1-12',
  `total_working_days` int(11) DEFAULT 0,
  `total_present_days` decimal(5,2) DEFAULT 0.00,
  `total_absent_days` decimal(5,2) DEFAULT 0.00,
  `total_late_times` int(11) DEFAULT 0,
  `total_early_leave_times` int(11) DEFAULT 0,
  `total_overtime_hours` decimal(6,2) DEFAULT 0.00,
  `status` enum('DRAFT','CONFIRMED','APPROVED') DEFAULT 'DRAFT',
  `confirmed_by` int(11) DEFAULT NULL,
  `confirmed_at` timestamp NULL DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bảng chấm công tháng';

-- --------------------------------------------------------

--
-- Table structure for table `bangluong`
--

CREATE TABLE `bangluong` (
  `payroll_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `year` year(4) NOT NULL,
  `month` tinyint(4) NOT NULL,
  `basic_salary` decimal(15,2) NOT NULL COMMENT 'Lương cơ bản',
  `working_days` int(11) DEFAULT 0 COMMENT 'Số ngày làm việc chuẩn',
  `actual_working_days` decimal(5,2) DEFAULT 0.00 COMMENT 'Số ngày thực tế',
  `total_allowance` decimal(15,2) DEFAULT 0.00 COMMENT 'Tổng phụ cấp',
  `overtime_amount` decimal(15,2) DEFAULT 0.00 COMMENT 'Tiền làm thêm',
  `bonus_amount` decimal(15,2) DEFAULT 0.00 COMMENT 'Tiền thưởng',
  `other_income` decimal(15,2) DEFAULT 0.00 COMMENT 'Thu nhập khác',
  `gross_salary` decimal(15,2) GENERATED ALWAYS AS (`basic_salary` / `working_days` * `actual_working_days` + `total_allowance` + `overtime_amount` + `bonus_amount` + `other_income`) STORED COMMENT 'Tổng thu nhập',
  `social_insurance` decimal(15,2) DEFAULT 0.00 COMMENT 'BHXH (8%)',
  `health_insurance` decimal(15,2) DEFAULT 0.00 COMMENT 'BHYT (1.5%)',
  `unemployment_insurance` decimal(15,2) DEFAULT 0.00 COMMENT 'BHTN (1%)',
  `union_fee` decimal(15,2) DEFAULT 0.00 COMMENT 'Phí công đoàn (1%)',
  `personal_income_tax` decimal(15,2) DEFAULT 0.00 COMMENT 'Thuế TNCN',
  `advance_payment` decimal(15,2) DEFAULT 0.00 COMMENT 'Tạm ứng',
  `discipline_deduction` decimal(15,2) DEFAULT 0.00 COMMENT 'Khấu trừ kỷ luật',
  `other_deduction` decimal(15,2) DEFAULT 0.00 COMMENT 'Khấu trừ khác',
  `total_deduction` decimal(15,2) GENERATED ALWAYS AS (`social_insurance` + `health_insurance` + `unemployment_insurance` + `union_fee` + `personal_income_tax` + `advance_payment` + `discipline_deduction` + `other_deduction`) STORED COMMENT 'Tổng khấu trừ',
  `net_salary` decimal(15,2) GENERATED ALWAYS AS (`gross_salary` - `total_deduction`) STORED COMMENT 'Thực lãnh',
  `payroll_status` enum('DRAFT','CONFIRMED','PAID') DEFAULT 'DRAFT',
  `payment_date` date DEFAULT NULL COMMENT 'Ngày thanh toán',
  `payment_method` varchar(50) DEFAULT NULL COMMENT 'Chuyển khoản/Tiền mặt',
  `notes` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bảng lương nhân viên';

-- --------------------------------------------------------

--
-- Table structure for table `calamviec`
--

CREATE TABLE `calamviec` (
  `shift_id` int(11) NOT NULL,
  `shift_code` varchar(50) NOT NULL,
  `shift_name` varchar(200) NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `break_duration` int(11) DEFAULT 60 COMMENT 'Thời gian nghỉ (phút)',
  `working_hours` decimal(4,2) DEFAULT NULL COMMENT 'Số giờ làm việc',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh mục ca làm việc';

--
-- Dumping data for table `calamviec`
--

INSERT INTO `calamviec` (`shift_id`, `shift_code`, `shift_name`, `start_time`, `end_time`, `break_duration`, `working_hours`, `is_active`, `created_at`) VALUES
(1, 'MORNING', 'Ca sáng', '08:00:00', '17:00:00', 60, 8.00, 1, '2025-10-26 01:47:38'),
(2, 'AFTERNOON', 'Ca chiều', '13:00:00', '22:00:00', 60, 8.00, 1, '2025-10-26 01:47:38'),
(3, 'NIGHT', 'Ca đêm', '22:00:00', '06:00:00', 60, 8.00, 1, '2025-10-26 01:47:38'),
(4, 'ADMIN', 'Ca hành chính', '08:30:00', '17:30:00', 60, 8.00, 1, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `cauhinhcongty`
--

CREATE TABLE `cauhinhcongty` (
  `config_id` int(11) NOT NULL,
  `company_name` varchar(300) NOT NULL,
  `tax_code` varchar(50) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `website` varchar(200) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `logo_url` varchar(500) DEFAULT NULL,
  `standard_working_days` int(11) DEFAULT 26 COMMENT 'Số ngày làm việc chuẩn/tháng',
  `standard_working_hours` decimal(4,2) DEFAULT 8.00 COMMENT 'Số giờ làm việc/ngày',
  `overtime_rate` decimal(5,2) DEFAULT 1.50 COMMENT 'Hệ số làm thêm',
  `social_insurance_rate` decimal(5,2) DEFAULT 8.00 COMMENT 'Tỷ lệ BHXH (%)',
  `health_insurance_rate` decimal(5,2) DEFAULT 1.50 COMMENT 'Tỷ lệ BHYT (%)',
  `unemployment_insurance_rate` decimal(5,2) DEFAULT 1.00 COMMENT 'Tỷ lệ BHTN (%)',
  `personal_deduction` decimal(15,2) DEFAULT 11000000.00 COMMENT 'Giảm trừ gia cảnh',
  `dependent_deduction` decimal(15,2) DEFAULT 4400000.00 COMMENT 'Giảm trừ người phụ thuộc',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cấu hình thông tin công ty';

--
-- Dumping data for table `cauhinhcongty`
--

INSERT INTO `cauhinhcongty` (`config_id`, `company_name`, `tax_code`, `phone`, `email`, `website`, `address`, `logo_url`, `standard_working_days`, `standard_working_hours`, `overtime_rate`, `social_insurance_rate`, `health_insurance_rate`, `unemployment_insurance_rate`, `personal_deduction`, `dependent_deduction`, `updated_at`) VALUES
(1, 'Công ty TNHH ABC', '0123456789', '024-1234-5678', 'info@abc.com.vn', NULL, '123 Đường ABC, Quận 1, TP.HCM', NULL, 26, 8.00, 1.50, 8.00, 1.50, 1.00, 11000000.00, 4400000.00, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `chitietchamcong`
--

CREATE TABLE `chitietchamcong` (
  `attendance_id` bigint(20) NOT NULL,
  `timesheet_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `attendance_date` date NOT NULL,
  `shift_id` int(11) DEFAULT NULL,
  `check_in_time` datetime DEFAULT NULL COMMENT 'Giờ vào',
  `check_out_time` datetime DEFAULT NULL COMMENT 'Giờ ra',
  `is_late` tinyint(1) DEFAULT 0,
  `late_minutes` int(11) DEFAULT 0,
  `is_early_leave` tinyint(1) DEFAULT 0,
  `early_leave_minutes` int(11) DEFAULT 0,
  `overtime_hours` decimal(5,2) DEFAULT 0.00,
  `attendance_status` enum('PRESENT','ABSENT','LATE','LEAVE','BUSINESS_TRIP','REMOTE') DEFAULT 'PRESENT',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chi tiết chấm công theo ngày';

-- --------------------------------------------------------

--
-- Table structure for table `chitietdanhgia`
--

CREATE TABLE `chitietdanhgia` (
  `review_detail_id` int(11) NOT NULL,
  `review_id` int(11) NOT NULL,
  `criteria_id` int(11) NOT NULL,
  `score` decimal(5,2) NOT NULL,
  `comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chi tiết điểm theo tiêu chí';

--
-- Triggers `chitietdanhgia`
--
DELIMITER $$
CREATE TRIGGER `trg_CapNhatDiemDanhGia_AfterInsertChiTiet` AFTER INSERT ON `chitietdanhgia` FOR EACH ROW BEGIN
    UPDATE DanhGiaNhanVien
    SET total_score = (
        SELECT SUM(ctdg.score * tcdg.weight) / SUM(tcdg.weight)
        FROM ChiTietDanhGia ctdg
        JOIN TieuChiDanhGia tcdg ON ctdg.criteria_id = tcdg.criteria_id
        WHERE ctdg.review_id = NEW.review_id
    )
    WHERE review_id = NEW.review_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `chitietphucap`
--

CREATE TABLE `chitietphucap` (
  `payroll_allowance_id` int(11) NOT NULL,
  `payroll_id` int(11) NOT NULL,
  `allowance_type_id` int(11) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chi tiết các khoản phụ cấp';

-- --------------------------------------------------------

--
-- Table structure for table `chucvu`
--

CREATE TABLE `chucvu` (
  `position_id` int(11) NOT NULL,
  `position_code` varchar(50) NOT NULL,
  `position_name` varchar(200) NOT NULL,
  `level` int(11) DEFAULT 1 COMMENT 'Cấp bậc: 1=Staff, 2=Leader, 3=Manager, 4=Director',
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh mục chức vụ';

--
-- Dumping data for table `chucvu`
--

INSERT INTO `chucvu` (`position_id`, `position_code`, `position_name`, `level`, `description`, `is_active`, `created_at`) VALUES
(1, 'CEO', 'Giám Đốc Điều Hành', 4, NULL, 1, '2025-10-26 01:47:38'),
(2, 'DIRECTOR', 'Giám Đốc', 4, NULL, 1, '2025-10-26 01:47:38'),
(3, 'MANAGER', 'Trưởng Phòng', 3, NULL, 1, '2025-10-26 01:47:38'),
(4, 'TEAM_LEAD', 'Trưởng Nhóm', 2, NULL, 1, '2025-10-26 01:47:38'),
(5, 'SENIOR', 'Nhân Viên Chính', 2, NULL, 1, '2025-10-26 01:47:38'),
(6, 'STAFF', 'Nhân Viên', 1, NULL, 1, '2025-10-26 01:47:38'),
(7, 'INTERN', 'Thực Tập Sinh', 1, NULL, 1, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `chukydanhgia`
--

CREATE TABLE `chukydanhgia` (
  `review_cycle_id` int(11) NOT NULL,
  `cycle_name` varchar(200) NOT NULL COMMENT 'Tên chu kỳ: Q1-2025, 2025...',
  `cycle_type` enum('MONTHLY','QUARTERLY','YEARLY','PROJECT') DEFAULT 'QUARTERLY',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `status` enum('PLANNING','ONGOING','COMPLETED') DEFAULT 'PLANNING',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chu kỳ đánh giá';

-- --------------------------------------------------------

--
-- Table structure for table `chungchi`
--

CREATE TABLE `chungchi` (
  `certificate_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `certificate_name` varchar(300) NOT NULL,
  `issuing_organization` varchar(300) DEFAULT NULL COMMENT 'Tổ chức cấp',
  `issue_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL COMMENT 'Ngày hết hạn',
  `certificate_url` varchar(500) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chứng chỉ nghề nghiệp';

-- --------------------------------------------------------

--
-- Table structure for table `danhgianhanvien`
--

CREATE TABLE `danhgianhanvien` (
  `review_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `review_cycle_id` int(11) NOT NULL,
  `reviewer_id` int(11) DEFAULT NULL COMMENT 'Người đánh giá',
  `review_date` date NOT NULL,
  `total_score` decimal(5,2) DEFAULT 0.00,
  `rating` varchar(50) DEFAULT NULL COMMENT 'Xếp loại: Xuất sắc, Tốt, Khá, TB, Yếu',
  `strengths` text DEFAULT NULL COMMENT 'Điểm mạnh',
  `weaknesses` text DEFAULT NULL COMMENT 'Điểm cần cải thiện',
  `development_plan` text DEFAULT NULL COMMENT 'Kế hoạch phát triển',
  `employee_comment` text DEFAULT NULL COMMENT 'Nhận xét của nhân viên',
  `manager_comment` text DEFAULT NULL COMMENT 'Nhận xét của quản lý',
  `status` enum('DRAFT','SUBMITTED','APPROVED') DEFAULT 'DRAFT',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Đánh giá nhân viên';

-- --------------------------------------------------------

--
-- Table structure for table `danhmuchethong`
--

CREATE TABLE `danhmuchethong` (
  `catalog_id` int(11) NOT NULL,
  `catalog_type` varchar(50) NOT NULL COMMENT 'Loại danh mục: BANK, NATION, CITY...',
  `catalog_code` varchar(100) NOT NULL,
  `catalog_name` varchar(300) NOT NULL,
  `parent_code` varchar(100) DEFAULT NULL COMMENT 'Mã cha (cho danh mục phân cấp)',
  `display_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh mục dùng chung: Ngân hàng, Tỉnh/thành, Quốc gia...';

-- --------------------------------------------------------

--
-- Table structure for table `danhmuctaisan`
--

CREATE TABLE `danhmuctaisan` (
  `asset_id` int(11) NOT NULL,
  `asset_code` varchar(50) NOT NULL COMMENT 'Mã tài sản',
  `asset_name` varchar(300) NOT NULL,
  `asset_category` varchar(100) DEFAULT NULL COMMENT 'Loại: Laptop, Điện thoại, Xe, Thẻ...',
  `brand` varchar(100) DEFAULT NULL COMMENT 'Hãng',
  `model` varchar(100) DEFAULT NULL COMMENT 'Model',
  `serial_number` varchar(100) DEFAULT NULL COMMENT 'Serial number',
  `purchase_date` date DEFAULT NULL COMMENT 'Ngày mua',
  `purchase_price` decimal(15,2) DEFAULT NULL COMMENT 'Giá mua',
  `warranty_period` int(11) DEFAULT NULL COMMENT 'Bảo hành (tháng)',
  `asset_status` enum('AVAILABLE','ASSIGNED','MAINTENANCE','DAMAGED','DISPOSED') DEFAULT 'AVAILABLE',
  `current_holder_id` int(11) DEFAULT NULL COMMENT 'Người đang giữ',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh mục tài sản công ty';

-- --------------------------------------------------------

--
-- Table structure for table `donnghiphep`
--

CREATE TABLE `donnghiphep` (
  `leave_request_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `leave_type_id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `total_days` decimal(5,2) NOT NULL,
  `reason` text DEFAULT NULL,
  `attachment_url` varchar(500) DEFAULT NULL,
  `request_status` enum('PENDING','APPROVED','REJECTED','CANCELLED') DEFAULT 'PENDING',
  `approver_id` int(11) DEFAULT NULL COMMENT 'Người phê duyệt',
  `approved_at` timestamp NULL DEFAULT NULL,
  `approval_note` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Đơn xin nghỉ phép';

-- --------------------------------------------------------

--
-- Table structure for table `hanmucphep`
--

CREATE TABLE `hanmucphep` (
  `leave_quota_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `year` year(4) NOT NULL,
  `leave_type_id` int(11) NOT NULL,
  `total_days` decimal(5,2) DEFAULT 0.00 COMMENT 'Tổng số ngày',
  `used_days` decimal(5,2) DEFAULT 0.00 COMMENT 'Đã sử dụng',
  `remaining_days` decimal(5,2) GENERATED ALWAYS AS (`total_days` - `used_days`) STORED COMMENT 'Còn lại',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hạn mức nghỉ phép';

--
-- Dumping data for table `hanmucphep`
--

INSERT INTO `hanmucphep` (`leave_quota_id`, `employee_id`, `year`, `leave_type_id`, `total_days`, `used_days`, `created_at`, `updated_at`) VALUES
(1, 5, '2025', 1, 12.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(2, 1, '2025', 1, 12.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(3, 2, '2025', 1, 12.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(4, 3, '2025', 1, 12.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(5, 4, '2025', 1, 12.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(6, 5, '2025', 2, 30.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(7, 1, '2025', 2, 30.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(8, 2, '2025', 2, 30.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(9, 3, '2025', 2, 30.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(10, 4, '2025', 2, 30.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(11, 5, '2025', 3, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(12, 1, '2025', 3, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(13, 2, '2025', 3, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(14, 3, '2025', 3, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(15, 4, '2025', 3, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(16, 5, '2025', 4, 180.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(17, 1, '2025', 4, 180.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(18, 2, '2025', 4, 180.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(19, 3, '2025', 4, 180.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(20, 4, '2025', 4, 180.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(21, 5, '2025', 6, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(22, 1, '2025', 6, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(23, 2, '2025', 6, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(24, 3, '2025', 6, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(25, 4, '2025', 6, 3.00, 0.00, '2025-10-26 01:47:38', '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `hocvan`
--

CREATE TABLE `hocvan` (
  `education_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `degree_level` enum('HIGH_SCHOOL','COLLEGE','BACHELOR','MASTER','DOCTOR') DEFAULT NULL COMMENT 'Trình độ',
  `major` varchar(200) DEFAULT NULL COMMENT 'Chuyên ngành',
  `school_name` varchar(300) DEFAULT NULL COMMENT 'Trường học',
  `graduation_year` year(4) DEFAULT NULL COMMENT 'Năm tốt nghiệp',
  `grade` varchar(50) DEFAULT NULL COMMENT 'Xếp loại: Xuất sắc, Giỏi, Khá...',
  `certificate_url` varchar(500) DEFAULT NULL COMMENT 'File bằng cấp',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Học vấn nhân viên';

-- --------------------------------------------------------

--
-- Table structure for table `hopdonglaodong`
--

CREATE TABLE `hopdonglaodong` (
  `contract_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `contract_number` varchar(100) NOT NULL COMMENT 'Số hợp đồng',
  `contract_type_id` int(11) NOT NULL,
  `sign_date` date NOT NULL COMMENT 'Ngày ký',
  `start_date` date NOT NULL COMMENT 'Ngày bắt đầu',
  `end_date` date DEFAULT NULL COMMENT 'Ngày kết thúc',
  `basic_salary` decimal(15,2) NOT NULL COMMENT 'Lương cơ bản',
  `probation_salary` decimal(15,2) DEFAULT NULL COMMENT 'Lương thử việc',
  `contract_status` enum('ACTIVE','EXPIRED','TERMINATED','RENEWED') DEFAULT 'ACTIVE',
  `termination_date` date DEFAULT NULL COMMENT 'Ngày chấm dứt',
  `termination_reason` text DEFAULT NULL,
  `file_url` varchar(500) DEFAULT NULL COMMENT 'File hợp đồng scan',
  `notes` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hợp đồng lao động';

--
-- Dumping data for table `hopdonglaodong`
--

INSERT INTO `hopdonglaodong` (`contract_id`, `employee_id`, `contract_number`, `contract_type_id`, `sign_date`, `start_date`, `end_date`, `basic_salary`, `probation_salary`, `contract_status`, `termination_date`, `termination_reason`, `file_url`, `notes`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 'HD2020-001', 4, '2020-01-10', '2020-01-15', NULL, 25000000.00, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(2, 2, 'HD2021-002', 4, '2021-02-25', '2021-03-01', NULL, 20000000.00, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(3, 3, 'HD2022-003', 3, '2022-06-10', '2022-06-15', '2024-06-14', 15000000.00, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(4, 4, 'HD2023-004', 2, '2023-01-05', '2023-01-10', '2024-01-09', 12000000.00, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(5, 5, 'HD2024-005', 1, '2024-08-28', '2024-09-01', '2024-10-31', 8000000.00, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `khenthuong`
--

CREATE TABLE `khenthuong` (
  `award_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `award_type` varchar(100) DEFAULT NULL COMMENT 'Loại: Nhân viên xuất sắc, Sáng kiến, Cống hiến...',
  `award_date` date NOT NULL,
  `achievement` text NOT NULL COMMENT 'Thành tích',
  `reward_amount` decimal(15,2) DEFAULT 0.00,
  `certificate_url` varchar(500) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Khen thưởng thành tích';

-- --------------------------------------------------------

--
-- Table structure for table `kinhnghiemlamviec`
--

CREATE TABLE `kinhnghiemlamviec` (
  `experience_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `company_name` varchar(300) NOT NULL,
  `position` varchar(200) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `is_current` tinyint(1) DEFAULT 0,
  `responsibilities` text DEFAULT NULL COMMENT 'Trách nhiệm công việc',
  `achievements` text DEFAULT NULL COMMENT 'Thành tích đạt được',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Kinh nghiệm làm việc';

-- --------------------------------------------------------

--
-- Table structure for table `kyluat`
--

CREATE TABLE `kyluat` (
  `discipline_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `discipline_type` enum('WARNING','REPRIMAND','SALARY_DEDUCTION','SUSPENSION','TERMINATION') DEFAULT NULL COMMENT 'Loại kỷ luật',
  `discipline_date` date NOT NULL,
  `violation` text NOT NULL COMMENT 'Vi phạm',
  `deduction_amount` decimal(15,2) DEFAULT 0.00 COMMENT 'Số tiền phạt',
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `payroll_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Kỷ luật và xử phạt';

-- --------------------------------------------------------

--
-- Table structure for table `lichsuphongban`
--

CREATE TABLE `lichsuphongban` (
  `history_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `department_id` int(11) NOT NULL,
  `position_id` int(11) DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `is_current` tinyint(1) DEFAULT 1,
  `transfer_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Lịch sử thay đổi phòng ban';

-- --------------------------------------------------------

--
-- Table structure for table `loaihopdong`
--

CREATE TABLE `loaihopdong` (
  `contract_type_id` int(11) NOT NULL,
  `type_code` varchar(50) NOT NULL,
  `type_name` varchar(200) NOT NULL,
  `duration_months` int(11) DEFAULT NULL COMMENT 'Thời hạn (tháng), NULL = vô thời hạn',
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Loại hợp đồng: Thử việc, Xác định thời hạn, Không xác định thời hạn';

--
-- Dumping data for table `loaihopdong`
--

INSERT INTO `loaihopdong` (`contract_type_id`, `type_code`, `type_name`, `duration_months`, `description`, `is_active`, `created_at`) VALUES
(1, 'PROBATION', 'Hợp đồng thử việc', 2, NULL, 1, '2025-10-26 01:47:38'),
(2, 'FIXED_1Y', 'Hợp đồng xác định thời hạn 1 năm', 12, NULL, 1, '2025-10-26 01:47:38'),
(3, 'FIXED_2Y', 'Hợp đồng xác định thời hạn 2 năm', 24, NULL, 1, '2025-10-26 01:47:38'),
(4, 'INDEFINITE', 'Hợp đồng không xác định thời hạn', NULL, NULL, 1, '2025-10-26 01:47:38'),
(5, 'SEASONAL', 'Hợp đồng thời vụ', 3, NULL, 1, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `loainghiphep`
--

CREATE TABLE `loainghiphep` (
  `leave_type_id` int(11) NOT NULL,
  `type_code` varchar(50) NOT NULL,
  `type_name` varchar(200) NOT NULL,
  `is_paid` tinyint(1) DEFAULT 1 COMMENT 'Có hưởng lương không',
  `default_days_per_year` int(11) DEFAULT NULL COMMENT 'Số ngày mặc định/năm',
  `requires_approval` tinyint(1) DEFAULT 1,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Loại nghỉ phép: Phép năm, ốm đau, thai sản...';

--
-- Dumping data for table `loainghiphep`
--

INSERT INTO `loainghiphep` (`leave_type_id`, `type_code`, `type_name`, `is_paid`, `default_days_per_year`, `requires_approval`, `description`, `is_active`, `created_at`) VALUES
(1, 'ANNUAL', 'Phép năm', 1, 12, 1, NULL, 1, '2025-10-26 01:47:38'),
(2, 'SICK', 'Ốm đau', 1, 30, 1, NULL, 1, '2025-10-26 01:47:38'),
(3, 'MARRIAGE', 'Nghỉ kết hôn', 1, 3, 1, NULL, 1, '2025-10-26 01:47:38'),
(4, 'MATERNITY', 'Nghỉ thai sản', 1, 180, 1, NULL, 1, '2025-10-26 01:47:38'),
(5, 'UNPAID', 'Nghỉ không lương', 0, 0, 1, NULL, 1, '2025-10-26 01:47:38'),
(6, 'BEREAVEMENT', 'Nghỉ tang', 1, 3, 1, NULL, 1, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `loaiphucap`
--

CREATE TABLE `loaiphucap` (
  `allowance_type_id` int(11) NOT NULL,
  `type_code` varchar(50) NOT NULL,
  `type_name` varchar(200) NOT NULL,
  `is_taxable` tinyint(1) DEFAULT 1 COMMENT 'Tính thuế',
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Loại phụ cấp: Xăng xe, điện thoại, ăn trưa...';

--
-- Dumping data for table `loaiphucap`
--

INSERT INTO `loaiphucap` (`allowance_type_id`, `type_code`, `type_name`, `is_taxable`, `description`, `is_active`, `created_at`) VALUES
(1, 'TRANSPORT', 'Phụ cấp xăng xe', 1, NULL, 1, '2025-10-26 01:47:38'),
(2, 'PHONE', 'Phụ cấp điện thoại', 1, NULL, 1, '2025-10-26 01:47:38'),
(3, 'LUNCH', 'Phụ cấp ăn trưa', 0, NULL, 1, '2025-10-26 01:47:38'),
(4, 'HOUSING', 'Phụ cấp nhà ở', 1, NULL, 1, '2025-10-26 01:47:38'),
(5, 'POSITION', 'Phụ cấp chức vụ', 1, NULL, 1, '2025-10-26 01:47:38'),
(6, 'RESPONSIBILITY', 'Phụ cấp trách nhiệm', 1, NULL, 1, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `ngaynghile`
--

CREATE TABLE `ngaynghile` (
  `holiday_id` int(11) NOT NULL,
  `holiday_name` varchar(200) NOT NULL,
  `holiday_date` date NOT NULL,
  `is_paid` tinyint(1) DEFAULT 1 COMMENT 'Có tính lương không',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh sách ngày nghỉ lễ';

--
-- Dumping data for table `ngaynghile`
--

INSERT INTO `ngaynghile` (`holiday_id`, `holiday_name`, `holiday_date`, `is_paid`, `description`, `created_at`) VALUES
(1, 'Tết Dương lịch', '2025-01-01', 1, NULL, '2025-10-26 01:47:38'),
(2, 'Tết Nguyên Đán', '2025-01-28', 1, NULL, '2025-10-26 01:47:38'),
(3, 'Tết Nguyên Đán', '2025-01-29', 1, NULL, '2025-10-26 01:47:38'),
(4, 'Tết Nguyên Đán', '2025-01-30', 1, NULL, '2025-10-26 01:47:38'),
(5, 'Tết Nguyên Đán', '2025-01-31', 1, NULL, '2025-10-26 01:47:38'),
(6, 'Tết Nguyên Đán', '2025-02-01', 1, NULL, '2025-10-26 01:47:38'),
(7, 'Giỗ Tổ Hùng Vương', '2025-04-18', 1, NULL, '2025-10-26 01:47:38'),
(8, 'Giải phóng miền Nam', '2025-04-30', 1, NULL, '2025-10-26 01:47:38'),
(9, 'Quốc tế Lao động', '2025-05-01', 1, NULL, '2025-10-26 01:47:38'),
(10, 'Quốc Khánh', '2025-09-02', 1, NULL, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `nguoinhanthongbao`
--

CREATE TABLE `nguoinhanthongbao` (
  `recipient_id` int(11) NOT NULL,
  `notification_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh sách người nhận thông báo';

-- --------------------------------------------------------

--
-- Table structure for table `nhanvien`
--

CREATE TABLE `nhanvien` (
  `employee_id` int(11) NOT NULL,
  `employee_code` varchar(50) NOT NULL COMMENT 'Mã nhân viên',
  `full_name` varchar(200) NOT NULL COMMENT 'Họ và tên',
  `date_of_birth` date DEFAULT NULL COMMENT 'Ngày sinh',
  `gender` enum('M','F','O') DEFAULT NULL COMMENT 'Giới tính: M=Nam, F=Nữ, O=Khác',
  `national_id` varchar(20) DEFAULT NULL COMMENT 'CMND/CCCD',
  `national_id_date` date DEFAULT NULL COMMENT 'Ngày cấp',
  `national_id_place` varchar(200) DEFAULT NULL COMMENT 'Nơi cấp',
  `phone` varchar(20) DEFAULT NULL,
  `personal_email` varchar(100) DEFAULT NULL,
  `work_email` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL COMMENT 'Địa chỉ thường trú',
  `current_address` text DEFAULT NULL COMMENT 'Địa chỉ tạm trú',
  `department_id` int(11) DEFAULT NULL COMMENT 'Phòng ban',
  `position_id` int(11) DEFAULT NULL COMMENT 'Chức vụ',
  `direct_manager_id` int(11) DEFAULT NULL COMMENT 'Người quản lý trực tiếp',
  `join_date` date NOT NULL COMMENT 'Ngày vào làm',
  `probation_end_date` date DEFAULT NULL COMMENT 'Ngày kết thúc thử việc',
  `official_date` date DEFAULT NULL COMMENT 'Ngày chính thức',
  `employment_status` enum('PROBATION','OFFICIAL','RESIGNED','TERMINATED') DEFAULT 'PROBATION' COMMENT 'Trạng thái làm việc',
  `resignation_date` date DEFAULT NULL COMMENT 'Ngày nghỉ việc',
  `resignation_reason` text DEFAULT NULL COMMENT 'Lý do nghỉ việc',
  `avatar_url` varchar(500) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hồ sơ nhân viên';

--
-- Dumping data for table `nhanvien`
--

INSERT INTO `nhanvien` (`employee_id`, `employee_code`, `full_name`, `date_of_birth`, `gender`, `national_id`, `national_id_date`, `national_id_place`, `phone`, `personal_email`, `work_email`, `address`, `current_address`, `department_id`, `position_id`, `direct_manager_id`, `join_date`, `probation_end_date`, `official_date`, `employment_status`, `resignation_date`, `resignation_reason`, `avatar_url`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'NV001', 'Nguyễn Văn An', '1985-05-15', 'M', '001085012345', NULL, NULL, '0901234567', 'an.nv@gmail.com', 'an.nguyen@abc.com', '123 Lê Lợi, Q1, TP.HCM', NULL, 1, 1, NULL, '2020-01-15', NULL, NULL, 'OFFICIAL', NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(2, 'NV002', 'Trần Thị Bình', '1990-08-20', 'F', '001090054321', NULL, NULL, '0912345678', 'binh.tt@gmail.com', 'binh.tran@abc.com', '456 Nguyễn Huệ, Q1, TP.HCM', NULL, 2, 3, NULL, '2021-03-01', NULL, NULL, 'OFFICIAL', NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(3, 'NV003', 'Lê Văn Cường', '1992-12-10', 'M', '001092098765', NULL, NULL, '0923456789', 'cuong.lv@gmail.com', 'cuong.le@abc.com', '789 Trần Hưng Đạo, Q5, TP.HCM', NULL, 3, 6, NULL, '2022-06-15', NULL, NULL, 'OFFICIAL', NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(4, 'NV004', 'Phạm Thị Dung', '1995-03-25', 'F', '001095067890', NULL, NULL, '0934567890', 'dung.pt@gmail.com', 'dung.pham@abc.com', '321 Hai Bà Trưng, Q3, TP.HCM', NULL, 4, 6, NULL, '2023-01-10', NULL, NULL, 'OFFICIAL', NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(5, 'NV005', 'Hoàng Văn Em', '1998-07-08', 'M', '001098045678', NULL, NULL, '0945678901', 'em.hv@gmail.com', 'em.hoang@abc.com', '654 Võ Văn Tần, Q3, TP.HCM', NULL, 3, 7, NULL, '2024-09-01', NULL, NULL, 'PROBATION', NULL, NULL, NULL, NULL, '2025-10-26 01:47:38', '2025-10-26 01:47:38');

--
-- Triggers `nhanvien`
--
DELIMITER $$
CREATE TRIGGER `trg_TaoTaiKhoan_AfterInsertNhanVien` AFTER INSERT ON `nhanvien` FOR EACH ROW BEGIN
    -- Tạo username từ email hoặc mã nhân viên
    DECLARE v_username VARCHAR(50);
    
    IF NEW.work_email IS NOT NULL THEN
        SET v_username = SUBSTRING_INDEX(NEW.work_email, '@', 1);
    ELSE
        SET v_username = NEW.employee_code;
    END IF;
    
    -- Tạo tài khoản với mật khẩu mặc định (cần thay đổi sau)
    INSERT INTO TaiKhoan (employee_id, username, password_hash, must_change_password)
    VALUES (NEW.employee_id, v_username, SHA2('123456', 256), TRUE);
    
    -- Gán vai trò mặc định là EMPLOYEE
    INSERT INTO TaiKhoan_VaiTro (account_id, role_id)
    SELECT LAST_INSERT_ID(), role_id
    FROM VaiTro
    WHERE role_code = 'EMPLOYEE';
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `nhatkyhoatdong`
--

CREATE TABLE `nhatkyhoatdong` (
  `log_id` bigint(20) NOT NULL,
  `account_id` int(11) DEFAULT NULL,
  `action_type` varchar(50) NOT NULL COMMENT 'LOGIN, LOGOUT, CREATE, UPDATE, DELETE, VIEW',
  `module` varchar(50) DEFAULT NULL COMMENT 'Module thực hiện',
  `description` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Lịch sử hoạt động người dùng';

-- --------------------------------------------------------

--
-- Table structure for table `phieucapphattaisan`
--

CREATE TABLE `phieucapphattaisan` (
  `assignment_id` int(11) NOT NULL,
  `asset_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `assign_date` date NOT NULL COMMENT 'Ngày cấp phát',
  `expected_return_date` date DEFAULT NULL COMMENT 'Ngày dự kiến trả',
  `actual_return_date` date DEFAULT NULL COMMENT 'Ngày trả thực tế',
  `asset_condition_before` text DEFAULT NULL COMMENT 'Tình trạng khi nhận',
  `asset_condition_after` text DEFAULT NULL COMMENT 'Tình trạng khi trả',
  `assignment_status` enum('ACTIVE','RETURNED','DAMAGED','LOST') DEFAULT 'ACTIVE',
  `assigned_by` int(11) DEFAULT NULL COMMENT 'Người giao',
  `received_by` int(11) DEFAULT NULL COMMENT 'Người nhận xác nhận',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Phiếu cấp phát và bàn giao tài sản';

--
-- Triggers `phieucapphattaisan`
--
DELIMITER $$
CREATE TRIGGER `trg_CapNhatTaiSan_AfterInsertCapPhat` AFTER INSERT ON `phieucapphattaisan` FOR EACH ROW BEGIN
    UPDATE DanhMucTaiSan
    SET asset_status = 'ASSIGNED',
        current_holder_id = NEW.employee_id
    WHERE asset_id = NEW.asset_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_CapNhatTaiSan_AfterUpdateCapPhat` AFTER UPDATE ON `phieucapphattaisan` FOR EACH ROW BEGIN
    IF NEW.assignment_status = 'RETURNED' AND OLD.assignment_status != 'RETURNED' THEN
        UPDATE DanhMucTaiSan
        SET asset_status = 'AVAILABLE',
            current_holder_id = NULL
        WHERE asset_id = NEW.asset_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phongban`
--

CREATE TABLE `phongban` (
  `department_id` int(11) NOT NULL,
  `department_code` varchar(50) NOT NULL COMMENT 'Mã phòng ban',
  `department_name` varchar(200) NOT NULL COMMENT 'Tên phòng ban',
  `parent_department_id` int(11) DEFAULT NULL COMMENT 'Phòng ban cấp trên',
  `manager_id` int(11) DEFAULT NULL COMMENT 'Trưởng phòng',
  `description` text DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cấu trúc phòng ban';

--
-- Dumping data for table `phongban`
--

INSERT INTO `phongban` (`department_id`, `department_code`, `department_name`, `parent_department_id`, `manager_id`, `description`, `phone`, `email`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'BOD', 'Ban Giám Đốc', NULL, 1, 'Ban lãnh đạo công ty', NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(2, 'HR', 'Phòng Nhân Sự', NULL, 2, 'Quản lý nguồn nhân lực', NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(3, 'IT', 'Phòng Công Nghệ Thông Tin', NULL, 3, 'Phát triển và vận hành hệ thống', NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(4, 'SALES', 'Phòng Kinh Doanh', NULL, NULL, 'Kinh doanh và chăm sóc khách hàng', NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(5, 'MKT', 'Phòng Marketing', NULL, NULL, 'Marketing và truyền thông', NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(6, 'ACC', 'Phòng Kế Toán', NULL, NULL, 'Kế toán và tài chính', NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `quyenhan`
--

CREATE TABLE `quyenhan` (
  `permission_id` int(11) NOT NULL,
  `permission_code` varchar(100) NOT NULL COMMENT 'Mã quyền: VIEW_EMPLOYEE, EDIT_SALARY...',
  `permission_name` varchar(200) NOT NULL COMMENT 'Tên quyền',
  `module` varchar(50) NOT NULL COMMENT 'Module: EMPLOYEE, SALARY, ATTENDANCE...',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh sách quyền hạn';

--
-- Dumping data for table `quyenhan`
--

INSERT INTO `quyenhan` (`permission_id`, `permission_code`, `permission_name`, `module`, `description`, `created_at`) VALUES
(1, 'VIEW_EMPLOYEE', 'Xem danh sách nhân viên', 'EMPLOYEE', NULL, '2025-10-26 01:47:38'),
(2, 'CREATE_EMPLOYEE', 'Thêm nhân viên', 'EMPLOYEE', NULL, '2025-10-26 01:47:38'),
(3, 'EDIT_EMPLOYEE', 'Sửa thông tin nhân viên', 'EMPLOYEE', NULL, '2025-10-26 01:47:38'),
(4, 'DELETE_EMPLOYEE', 'Xóa nhân viên', 'EMPLOYEE', NULL, '2025-10-26 01:47:38'),
(5, 'VIEW_SALARY', 'Xem bảng lương', 'SALARY', NULL, '2025-10-26 01:47:38'),
(6, 'EDIT_SALARY', 'Chỉnh sửa lương', 'SALARY', NULL, '2025-10-26 01:47:38'),
(7, 'APPROVE_SALARY', 'Phê duyệt lương', 'SALARY', NULL, '2025-10-26 01:47:38'),
(8, 'VIEW_ATTENDANCE', 'Xem chấm công', 'ATTENDANCE', NULL, '2025-10-26 01:47:38'),
(9, 'EDIT_ATTENDANCE', 'Sửa chấm công', 'ATTENDANCE', NULL, '2025-10-26 01:47:38'),
(10, 'VIEW_LEAVE', 'Xem đơn nghỉ phép', 'LEAVE', NULL, '2025-10-26 01:47:38'),
(11, 'APPROVE_LEAVE', 'Phê duyệt nghỉ phép', 'LEAVE', NULL, '2025-10-26 01:47:38'),
(12, 'VIEW_CONTRACT', 'Xem hợp đồng', 'CONTRACT', NULL, '2025-10-26 01:47:38'),
(13, 'MANAGE_CONTRACT', 'Quản lý hợp đồng', 'CONTRACT', NULL, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `taikhoan`
--

CREATE TABLE `taikhoan` (
  `account_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL COMMENT 'Liên kết nhân viên',
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL COMMENT 'Mật khẩu đã mã hóa',
  `is_active` tinyint(1) DEFAULT 1,
  `is_locked` tinyint(1) DEFAULT 0,
  `failed_login_attempts` int(11) DEFAULT 0,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `password_changed_at` timestamp NULL DEFAULT NULL,
  `must_change_password` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tài khoản đăng nhập';

--
-- Dumping data for table `taikhoan`
--

INSERT INTO `taikhoan` (`account_id`, `employee_id`, `username`, `password_hash`, `is_active`, `is_locked`, `failed_login_attempts`, `last_login_at`, `password_changed_at`, `must_change_password`, `created_at`, `updated_at`) VALUES
(1, 1, 'an.nguyen', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 1, 0, 0, NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(2, 2, 'binh.tran', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 1, 0, 0, NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(3, 3, 'cuong.le', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 1, 0, 0, NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(4, 4, 'dung.pham', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 1, 0, 0, NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(5, 5, 'em.hoang', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 1, 0, 0, NULL, NULL, 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38');

--
-- Triggers `taikhoan`
--
DELIMITER $$
CREATE TRIGGER `trg_GhiNhatKy_AfterUpdateTaiKhoan` AFTER UPDATE ON `taikhoan` FOR EACH ROW BEGIN
    IF NEW.last_login_at != OLD.last_login_at THEN
        INSERT INTO NhatKyHoatDong (account_id, action_type, description)
        VALUES (NEW.account_id, 'LOGIN', 'Đăng nhập hệ thống');
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `taikhoan_vaitro`
--

CREATE TABLE `taikhoan_vaitro` (
  `account_role_id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `assigned_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Phân vai trò cho tài khoản';

--
-- Dumping data for table `taikhoan_vaitro`
--

INSERT INTO `taikhoan_vaitro` (`account_role_id`, `account_id`, `role_id`, `assigned_at`, `assigned_by`) VALUES
(1, 1, 5, '2025-10-26 01:47:38', NULL),
(2, 2, 5, '2025-10-26 01:47:38', NULL),
(3, 3, 5, '2025-10-26 01:47:38', NULL),
(4, 4, 5, '2025-10-26 01:47:38', NULL),
(5, 5, 5, '2025-10-26 01:47:38', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tailieudinhkem`
--

CREATE TABLE `tailieudinhkem` (
  `document_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `document_type` varchar(100) DEFAULT NULL COMMENT 'Loại: HỢP ĐỒNG, HỒ SƠ, CMND, BẰNG CẤP...',
  `document_name` varchar(300) NOT NULL,
  `file_url` varchar(500) NOT NULL,
  `file_size` int(11) DEFAULT NULL COMMENT 'Kích thước (bytes)',
  `uploaded_by` int(11) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tài liệu hồ sơ nhân viên';

-- --------------------------------------------------------

--
-- Table structure for table `thongbao`
--

CREATE TABLE `thongbao` (
  `notification_id` int(11) NOT NULL,
  `title` varchar(500) NOT NULL,
  `content` text NOT NULL,
  `notification_type` varchar(50) DEFAULT NULL COMMENT 'Loại: ANNOUNCEMENT, POLICY, EVENT, REMINDER...',
  `priority` enum('LOW','MEDIUM','HIGH','URGENT') DEFAULT 'MEDIUM',
  `start_date` date DEFAULT NULL COMMENT 'Ngày bắt đầu hiển thị',
  `end_date` date DEFAULT NULL COMMENT 'Ngày hết hạn',
  `target_audience` enum('ALL','DEPARTMENT','POSITION','SPECIFIC') DEFAULT 'ALL',
  `target_department_id` int(11) DEFAULT NULL COMMENT 'Gửi cho phòng ban',
  `target_position_id` int(11) DEFAULT NULL COMMENT 'Gửi cho chức vụ',
  `attachment_url` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thông báo nội bộ';

-- --------------------------------------------------------

--
-- Table structure for table `thuong`
--

CREATE TABLE `thuong` (
  `bonus_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `bonus_type` varchar(100) DEFAULT NULL COMMENT 'Loại thưởng: Tháng, Quý, Năm, Dự án, Đột xuất',
  `bonus_date` date NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `reason` text DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `payroll_id` int(11) DEFAULT NULL COMMENT 'Liên kết bảng lương',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Quản lý thưởng';

-- --------------------------------------------------------

--
-- Table structure for table `tieuchidanhgia`
--

CREATE TABLE `tieuchidanhgia` (
  `criteria_id` int(11) NOT NULL,
  `criteria_code` varchar(50) NOT NULL,
  `criteria_name` varchar(300) NOT NULL,
  `category` varchar(100) DEFAULT NULL COMMENT 'Nhóm: KPI, Năng lực, Thái độ...',
  `max_score` int(11) DEFAULT 10,
  `weight` decimal(5,2) DEFAULT 1.00 COMMENT 'Trọng số',
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tiêu chí đánh giá';

--
-- Dumping data for table `tieuchidanhgia`
--

INSERT INTO `tieuchidanhgia` (`criteria_id`, `criteria_code`, `criteria_name`, `category`, `max_score`, `weight`, `description`, `is_active`, `created_at`) VALUES
(1, 'KPI_01', 'Hoàn thành công việc đúng hạn', 'KPI', 10, 0.30, NULL, 1, '2025-10-26 01:47:38'),
(2, 'KPI_02', 'Chất lượng công việc', 'KPI', 10, 0.30, NULL, 1, '2025-10-26 01:47:38'),
(3, 'SKILL_01', 'Kỹ năng chuyên môn', 'Năng lực', 10, 0.20, NULL, 1, '2025-10-26 01:47:38'),
(4, 'SKILL_02', 'Kỹ năng làm việc nhóm', 'Năng lực', 10, 0.10, NULL, 1, '2025-10-26 01:47:38'),
(5, 'ATTITUDE_01', 'Tinh thần trách nhiệm', 'Thái độ', 10, 0.10, NULL, 1, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `vaitro`
--

CREATE TABLE `vaitro` (
  `role_id` int(11) NOT NULL,
  `role_code` varchar(50) NOT NULL COMMENT 'Mã vai trò: ADMIN, HR, EMPLOYEE, DIRECTOR',
  `role_name` varchar(100) NOT NULL COMMENT 'Tên vai trò',
  `description` text DEFAULT NULL COMMENT 'Mô tả vai trò',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Quản lý vai trò người dùng';

--
-- Dumping data for table `vaitro`
--

INSERT INTO `vaitro` (`role_id`, `role_code`, `role_name`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'ADMIN', 'Quản trị hệ thống', 'Toàn quyền trên hệ thống', 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(2, 'HR', 'Nhân sự', 'Quản lý nhân sự, lương thưởng, hợp đồng', 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(3, 'DIRECTOR', 'Giám đốc', 'Xem báo cáo, phê duyệt chiến lược', 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(4, 'MANAGER', 'Quản lý', 'Quản lý nhân viên trong phòng ban', 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38'),
(5, 'EMPLOYEE', 'Nhân viên', 'Xem thông tin cá nhân, chấm công, lương', 1, '2025-10-26 01:47:38', '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Table structure for table `vaitro_quyenhan`
--

CREATE TABLE `vaitro_quyenhan` (
  `role_permission_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  `granted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Phân quyền cho vai trò';

--
-- Dumping data for table `vaitro_quyenhan`
--

INSERT INTO `vaitro_quyenhan` (`role_permission_id`, `role_id`, `permission_id`, `granted_at`) VALUES
(1, 1, 8, '2025-10-26 01:47:38'),
(2, 1, 9, '2025-10-26 01:47:38'),
(3, 1, 12, '2025-10-26 01:47:38'),
(4, 1, 13, '2025-10-26 01:47:38'),
(5, 1, 1, '2025-10-26 01:47:38'),
(6, 1, 2, '2025-10-26 01:47:38'),
(7, 1, 3, '2025-10-26 01:47:38'),
(8, 1, 4, '2025-10-26 01:47:38'),
(9, 1, 10, '2025-10-26 01:47:38'),
(10, 1, 11, '2025-10-26 01:47:38'),
(11, 1, 5, '2025-10-26 01:47:38'),
(12, 1, 6, '2025-10-26 01:47:38'),
(13, 1, 7, '2025-10-26 01:47:38');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_bangluongchitiet`
-- (See below for the actual view)
--
CREATE TABLE `v_bangluongchitiet` (
`payroll_id` int(11)
,`employee_code` varchar(50)
,`full_name` varchar(200)
,`department_name` varchar(200)
,`position_name` varchar(200)
,`year` year(4)
,`month` tinyint(4)
,`basic_salary` decimal(15,2)
,`actual_working_days` decimal(5,2)
,`total_allowance` decimal(15,2)
,`overtime_amount` decimal(15,2)
,`bonus_amount` decimal(15,2)
,`gross_salary` decimal(15,2)
,`social_insurance` decimal(15,2)
,`health_insurance` decimal(15,2)
,`unemployment_insurance` decimal(15,2)
,`personal_income_tax` decimal(15,2)
,`total_deduction` decimal(15,2)
,`net_salary` decimal(15,2)
,`payroll_status` enum('DRAFT','CONFIRMED','PAID')
,`payment_date` date
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_danhgianhanvien`
-- (See below for the actual view)
--
CREATE TABLE `v_danhgianhanvien` (
`review_id` int(11)
,`employee_code` varchar(50)
,`full_name` varchar(200)
,`department_name` varchar(200)
,`position_name` varchar(200)
,`cycle_name` varchar(200)
,`review_date` date
,`total_score` decimal(5,2)
,`rating` varchar(50)
,`reviewer_name` varchar(200)
,`status` enum('DRAFT','SUBMITTED','APPROVED')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_donnghiphep`
-- (See below for the actual view)
--
CREATE TABLE `v_donnghiphep` (
`leave_request_id` int(11)
,`employee_code` varchar(50)
,`full_name` varchar(200)
,`department_name` varchar(200)
,`leave_type` varchar(200)
,`start_date` date
,`end_date` date
,`total_days` decimal(5,2)
,`reason` text
,`request_status` enum('PENDING','APPROVED','REJECTED','CANCELLED')
,`approver_name` varchar(200)
,`approved_at` timestamp
,`created_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_hopdonghientai`
-- (See below for the actual view)
--
CREATE TABLE `v_hopdonghientai` (
`employee_code` varchar(50)
,`full_name` varchar(200)
,`department_name` varchar(200)
,`contract_number` varchar(100)
,`contract_type` varchar(200)
,`sign_date` date
,`start_date` date
,`end_date` date
,`basic_salary` decimal(15,2)
,`contract_status` enum('ACTIVE','EXPIRED','TERMINATED','RENEWED')
,`days_until_expiry` int(7)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_taisandangcapphat`
-- (See below for the actual view)
--
CREATE TABLE `v_taisandangcapphat` (
`asset_code` varchar(50)
,`asset_name` varchar(300)
,`asset_category` varchar(100)
,`brand` varchar(100)
,`model` varchar(100)
,`employee_code` varchar(50)
,`full_name` varchar(200)
,`department_name` varchar(200)
,`assign_date` date
,`expected_return_date` date
,`assignment_status` enum('ACTIVE','RETURNED','DAMAGED','LOST')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_thongtinnhanvien`
-- (See below for the actual view)
--
CREATE TABLE `v_thongtinnhanvien` (
`employee_id` int(11)
,`employee_code` varchar(50)
,`full_name` varchar(200)
,`date_of_birth` date
,`age` int(5)
,`gender` enum('M','F','O')
,`phone` varchar(20)
,`work_email` varchar(100)
,`department_name` varchar(200)
,`position_name` varchar(200)
,`join_date` date
,`years_of_service` decimal(10,4)
,`employment_status` enum('PROBATION','OFFICIAL','RESIGNED','TERMINATED')
,`manager_name` varchar(200)
,`created_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_tonghopchamcong`
-- (See below for the actual view)
--
CREATE TABLE `v_tonghopchamcong` (
`timesheet_id` int(11)
,`employee_code` varchar(50)
,`full_name` varchar(200)
,`department_name` varchar(200)
,`year` year(4)
,`month` tinyint(4)
,`total_working_days` int(11)
,`total_present_days` decimal(5,2)
,`total_absent_days` decimal(5,2)
,`total_late_times` int(11)
,`total_early_leave_times` int(11)
,`total_overtime_hours` decimal(6,2)
,`status` enum('DRAFT','CONFIRMED','APPROVED')
,`approved_at` timestamp
);

-- --------------------------------------------------------

--
-- Structure for view `v_bangluongchitiet`
--
DROP TABLE IF EXISTS `v_bangluongchitiet`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_bangluongchitiet`  AS SELECT `bl`.`payroll_id` AS `payroll_id`, `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `pb`.`department_name` AS `department_name`, `cv`.`position_name` AS `position_name`, `bl`.`year` AS `year`, `bl`.`month` AS `month`, `bl`.`basic_salary` AS `basic_salary`, `bl`.`actual_working_days` AS `actual_working_days`, `bl`.`total_allowance` AS `total_allowance`, `bl`.`overtime_amount` AS `overtime_amount`, `bl`.`bonus_amount` AS `bonus_amount`, `bl`.`gross_salary` AS `gross_salary`, `bl`.`social_insurance` AS `social_insurance`, `bl`.`health_insurance` AS `health_insurance`, `bl`.`unemployment_insurance` AS `unemployment_insurance`, `bl`.`personal_income_tax` AS `personal_income_tax`, `bl`.`total_deduction` AS `total_deduction`, `bl`.`net_salary` AS `net_salary`, `bl`.`payroll_status` AS `payroll_status`, `bl`.`payment_date` AS `payment_date` FROM (((`bangluong` `bl` join `nhanvien` `nv` on(`bl`.`employee_id` = `nv`.`employee_id`)) left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) left join `chucvu` `cv` on(`nv`.`position_id` = `cv`.`position_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_danhgianhanvien`
--
DROP TABLE IF EXISTS `v_danhgianhanvien`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_danhgianhanvien`  AS SELECT `dg`.`review_id` AS `review_id`, `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `pb`.`department_name` AS `department_name`, `cv`.`position_name` AS `position_name`, `ck`.`cycle_name` AS `cycle_name`, `dg`.`review_date` AS `review_date`, `dg`.`total_score` AS `total_score`, `dg`.`rating` AS `rating`, `nd`.`full_name` AS `reviewer_name`, `dg`.`status` AS `status` FROM (((((`danhgianhanvien` `dg` join `nhanvien` `nv` on(`dg`.`employee_id` = `nv`.`employee_id`)) left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) left join `chucvu` `cv` on(`nv`.`position_id` = `cv`.`position_id`)) join `chukydanhgia` `ck` on(`dg`.`review_cycle_id` = `ck`.`review_cycle_id`)) left join `nhanvien` `nd` on(`dg`.`reviewer_id` = `nd`.`employee_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_donnghiphep`
--
DROP TABLE IF EXISTS `v_donnghiphep`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_donnghiphep`  AS SELECT `dnp`.`leave_request_id` AS `leave_request_id`, `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `pb`.`department_name` AS `department_name`, `lnp`.`type_name` AS `leave_type`, `dnp`.`start_date` AS `start_date`, `dnp`.`end_date` AS `end_date`, `dnp`.`total_days` AS `total_days`, `dnp`.`reason` AS `reason`, `dnp`.`request_status` AS `request_status`, `nd`.`full_name` AS `approver_name`, `dnp`.`approved_at` AS `approved_at`, `dnp`.`created_at` AS `created_at` FROM ((((`donnghiphep` `dnp` join `nhanvien` `nv` on(`dnp`.`employee_id` = `nv`.`employee_id`)) left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) join `loainghiphep` `lnp` on(`dnp`.`leave_type_id` = `lnp`.`leave_type_id`)) left join `nhanvien` `nd` on(`dnp`.`approver_id` = `nd`.`employee_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_hopdonghientai`
--
DROP TABLE IF EXISTS `v_hopdonghientai`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_hopdonghientai`  AS SELECT `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `pb`.`department_name` AS `department_name`, `hdld`.`contract_number` AS `contract_number`, `lhd`.`type_name` AS `contract_type`, `hdld`.`sign_date` AS `sign_date`, `hdld`.`start_date` AS `start_date`, `hdld`.`end_date` AS `end_date`, `hdld`.`basic_salary` AS `basic_salary`, `hdld`.`contract_status` AS `contract_status`, to_days(`hdld`.`end_date`) - to_days(curdate()) AS `days_until_expiry` FROM (((`hopdonglaodong` `hdld` join `nhanvien` `nv` on(`hdld`.`employee_id` = `nv`.`employee_id`)) left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) join `loaihopdong` `lhd` on(`hdld`.`contract_type_id` = `lhd`.`contract_type_id`)) WHERE `hdld`.`contract_status` = 'ACTIVE' ;

-- --------------------------------------------------------

--
-- Structure for view `v_taisandangcapphat`
--
DROP TABLE IF EXISTS `v_taisandangcapphat`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_taisandangcapphat`  AS SELECT `ts`.`asset_code` AS `asset_code`, `ts`.`asset_name` AS `asset_name`, `ts`.`asset_category` AS `asset_category`, `ts`.`brand` AS `brand`, `ts`.`model` AS `model`, `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `pb`.`department_name` AS `department_name`, `cp`.`assign_date` AS `assign_date`, `cp`.`expected_return_date` AS `expected_return_date`, `cp`.`assignment_status` AS `assignment_status` FROM (((`phieucapphattaisan` `cp` join `danhmuctaisan` `ts` on(`cp`.`asset_id` = `ts`.`asset_id`)) join `nhanvien` `nv` on(`cp`.`employee_id` = `nv`.`employee_id`)) left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) WHERE `cp`.`assignment_status` = 'ACTIVE' ;

-- --------------------------------------------------------

--
-- Structure for view `v_thongtinnhanvien`
--
DROP TABLE IF EXISTS `v_thongtinnhanvien`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_thongtinnhanvien`  AS SELECT `nv`.`employee_id` AS `employee_id`, `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `nv`.`date_of_birth` AS `date_of_birth`, year(curdate()) - year(`nv`.`date_of_birth`) AS `age`, `nv`.`gender` AS `gender`, `nv`.`phone` AS `phone`, `nv`.`work_email` AS `work_email`, `pb`.`department_name` AS `department_name`, `cv`.`position_name` AS `position_name`, `nv`.`join_date` AS `join_date`, (to_days(curdate()) - to_days(`nv`.`join_date`)) / 365 AS `years_of_service`, `nv`.`employment_status` AS `employment_status`, concat(`ql`.`full_name`) AS `manager_name`, `nv`.`created_at` AS `created_at` FROM (((`nhanvien` `nv` left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) left join `chucvu` `cv` on(`nv`.`position_id` = `cv`.`position_id`)) left join `nhanvien` `ql` on(`nv`.`direct_manager_id` = `ql`.`employee_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_tonghopchamcong`
--
DROP TABLE IF EXISTS `v_tonghopchamcong`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_tonghopchamcong`  AS SELECT `bcc`.`timesheet_id` AS `timesheet_id`, `nv`.`employee_code` AS `employee_code`, `nv`.`full_name` AS `full_name`, `pb`.`department_name` AS `department_name`, `bcc`.`year` AS `year`, `bcc`.`month` AS `month`, `bcc`.`total_working_days` AS `total_working_days`, `bcc`.`total_present_days` AS `total_present_days`, `bcc`.`total_absent_days` AS `total_absent_days`, `bcc`.`total_late_times` AS `total_late_times`, `bcc`.`total_early_leave_times` AS `total_early_leave_times`, `bcc`.`total_overtime_hours` AS `total_overtime_hours`, `bcc`.`status` AS `status`, `bcc`.`approved_at` AS `approved_at` FROM ((`bangchamcong` `bcc` join `nhanvien` `nv` on(`bcc`.`employee_id` = `nv`.`employee_id`)) left join `phongban` `pb` on(`nv`.`department_id` = `pb`.`department_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bangchamcong`
--
ALTER TABLE `bangchamcong`
  ADD PRIMARY KEY (`timesheet_id`),
  ADD UNIQUE KEY `uk_employee_month` (`employee_id`,`year`,`month`),
  ADD KEY `idx_year_month` (`year`,`month`);

--
-- Indexes for table `bangluong`
--
ALTER TABLE `bangluong`
  ADD PRIMARY KEY (`payroll_id`),
  ADD UNIQUE KEY `uk_employee_month` (`employee_id`,`year`,`month`),
  ADD KEY `idx_year_month` (`year`,`month`),
  ADD KEY `idx_status` (`payroll_status`),
  ADD KEY `idx_luong_report` (`year`,`month`,`payroll_status`);

--
-- Indexes for table `calamviec`
--
ALTER TABLE `calamviec`
  ADD PRIMARY KEY (`shift_id`),
  ADD UNIQUE KEY `shift_code` (`shift_code`);

--
-- Indexes for table `cauhinhcongty`
--
ALTER TABLE `cauhinhcongty`
  ADD PRIMARY KEY (`config_id`);

--
-- Indexes for table `chitietchamcong`
--
ALTER TABLE `chitietchamcong`
  ADD PRIMARY KEY (`attendance_id`),
  ADD UNIQUE KEY `uk_employee_date` (`employee_id`,`attendance_date`),
  ADD KEY `timesheet_id` (`timesheet_id`),
  ADD KEY `shift_id` (`shift_id`),
  ADD KEY `idx_date` (`attendance_date`),
  ADD KEY `idx_chamcong_report` (`employee_id`,`attendance_date`,`attendance_status`);

--
-- Indexes for table `chitietdanhgia`
--
ALTER TABLE `chitietdanhgia`
  ADD PRIMARY KEY (`review_detail_id`),
  ADD UNIQUE KEY `uk_review_criteria` (`review_id`,`criteria_id`),
  ADD KEY `criteria_id` (`criteria_id`);

--
-- Indexes for table `chitietphucap`
--
ALTER TABLE `chitietphucap`
  ADD PRIMARY KEY (`payroll_allowance_id`),
  ADD KEY `allowance_type_id` (`allowance_type_id`),
  ADD KEY `idx_payroll` (`payroll_id`);

--
-- Indexes for table `chucvu`
--
ALTER TABLE `chucvu`
  ADD PRIMARY KEY (`position_id`),
  ADD UNIQUE KEY `position_code` (`position_code`),
  ADD KEY `idx_position_code` (`position_code`);

--
-- Indexes for table `chukydanhgia`
--
ALTER TABLE `chukydanhgia`
  ADD PRIMARY KEY (`review_cycle_id`),
  ADD KEY `idx_dates` (`start_date`,`end_date`);

--
-- Indexes for table `chungchi`
--
ALTER TABLE `chungchi`
  ADD PRIMARY KEY (`certificate_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_expiry` (`expiry_date`);

--
-- Indexes for table `danhgianhanvien`
--
ALTER TABLE `danhgianhanvien`
  ADD PRIMARY KEY (`review_id`),
  ADD KEY `reviewer_id` (`reviewer_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_cycle` (`review_cycle_id`);

--
-- Indexes for table `danhmuchethong`
--
ALTER TABLE `danhmuchethong`
  ADD PRIMARY KEY (`catalog_id`),
  ADD UNIQUE KEY `uk_type_code` (`catalog_type`,`catalog_code`),
  ADD KEY `idx_type` (`catalog_type`);

--
-- Indexes for table `danhmuctaisan`
--
ALTER TABLE `danhmuctaisan`
  ADD PRIMARY KEY (`asset_id`),
  ADD UNIQUE KEY `asset_code` (`asset_code`),
  ADD UNIQUE KEY `serial_number` (`serial_number`),
  ADD KEY `current_holder_id` (`current_holder_id`),
  ADD KEY `idx_asset_code` (`asset_code`),
  ADD KEY `idx_category` (`asset_category`),
  ADD KEY `idx_status` (`asset_status`);

--
-- Indexes for table `donnghiphep`
--
ALTER TABLE `donnghiphep`
  ADD PRIMARY KEY (`leave_request_id`),
  ADD KEY `leave_type_id` (`leave_type_id`),
  ADD KEY `approver_id` (`approver_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_status` (`request_status`),
  ADD KEY `idx_dates` (`start_date`,`end_date`);

--
-- Indexes for table `hanmucphep`
--
ALTER TABLE `hanmucphep`
  ADD PRIMARY KEY (`leave_quota_id`),
  ADD UNIQUE KEY `uk_employee_year_type` (`employee_id`,`year`,`leave_type_id`),
  ADD KEY `leave_type_id` (`leave_type_id`);

--
-- Indexes for table `hocvan`
--
ALTER TABLE `hocvan`
  ADD PRIMARY KEY (`education_id`),
  ADD KEY `idx_employee` (`employee_id`);

--
-- Indexes for table `hopdonglaodong`
--
ALTER TABLE `hopdonglaodong`
  ADD PRIMARY KEY (`contract_id`),
  ADD UNIQUE KEY `contract_number` (`contract_number`),
  ADD KEY `contract_type_id` (`contract_type_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_status` (`contract_status`),
  ADD KEY `idx_end_date` (`end_date`),
  ADD KEY `idx_hopdong_active` (`employee_id`,`contract_status`,`end_date`);

--
-- Indexes for table `khenthuong`
--
ALTER TABLE `khenthuong`
  ADD PRIMARY KEY (`award_id`),
  ADD KEY `idx_employee` (`employee_id`);

--
-- Indexes for table `kinhnghiemlamviec`
--
ALTER TABLE `kinhnghiemlamviec`
  ADD PRIMARY KEY (`experience_id`),
  ADD KEY `idx_employee` (`employee_id`);

--
-- Indexes for table `kyluat`
--
ALTER TABLE `kyluat`
  ADD PRIMARY KEY (`discipline_id`),
  ADD KEY `payroll_id` (`payroll_id`),
  ADD KEY `idx_employee` (`employee_id`);

--
-- Indexes for table `lichsuphongban`
--
ALTER TABLE `lichsuphongban`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `department_id` (`department_id`),
  ADD KEY `position_id` (`position_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_current` (`is_current`);

--
-- Indexes for table `loaihopdong`
--
ALTER TABLE `loaihopdong`
  ADD PRIMARY KEY (`contract_type_id`),
  ADD UNIQUE KEY `type_code` (`type_code`);

--
-- Indexes for table `loainghiphep`
--
ALTER TABLE `loainghiphep`
  ADD PRIMARY KEY (`leave_type_id`),
  ADD UNIQUE KEY `type_code` (`type_code`);

--
-- Indexes for table `loaiphucap`
--
ALTER TABLE `loaiphucap`
  ADD PRIMARY KEY (`allowance_type_id`),
  ADD UNIQUE KEY `type_code` (`type_code`);

--
-- Indexes for table `ngaynghile`
--
ALTER TABLE `ngaynghile`
  ADD PRIMARY KEY (`holiday_id`),
  ADD KEY `idx_date` (`holiday_date`);

--
-- Indexes for table `nguoinhanthongbao`
--
ALTER TABLE `nguoinhanthongbao`
  ADD PRIMARY KEY (`recipient_id`),
  ADD UNIQUE KEY `uk_notification_employee` (`notification_id`,`employee_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_unread` (`is_read`);

--
-- Indexes for table `nhanvien`
--
ALTER TABLE `nhanvien`
  ADD PRIMARY KEY (`employee_id`),
  ADD UNIQUE KEY `employee_code` (`employee_code`),
  ADD UNIQUE KEY `national_id` (`national_id`),
  ADD KEY `direct_manager_id` (`direct_manager_id`),
  ADD KEY `idx_employee_code` (`employee_code`),
  ADD KEY `idx_full_name` (`full_name`),
  ADD KEY `idx_department` (`department_id`),
  ADD KEY `idx_position` (`position_id`),
  ADD KEY `idx_status` (`employment_status`),
  ADD KEY `idx_join_date` (`join_date`),
  ADD KEY `idx_nhanvien_search` (`full_name`,`employee_code`,`phone`);

--
-- Indexes for table `nhatkyhoatdong`
--
ALTER TABLE `nhatkyhoatdong`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_account` (`account_id`),
  ADD KEY `idx_action_type` (`action_type`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `phieucapphattaisan`
--
ALTER TABLE `phieucapphattaisan`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_asset` (`asset_id`),
  ADD KEY `idx_status` (`assignment_status`);

--
-- Indexes for table `phongban`
--
ALTER TABLE `phongban`
  ADD PRIMARY KEY (`department_id`),
  ADD UNIQUE KEY `department_code` (`department_code`),
  ADD KEY `parent_department_id` (`parent_department_id`),
  ADD KEY `idx_dept_code` (`department_code`),
  ADD KEY `idx_manager` (`manager_id`);

--
-- Indexes for table `quyenhan`
--
ALTER TABLE `quyenhan`
  ADD PRIMARY KEY (`permission_id`),
  ADD UNIQUE KEY `permission_code` (`permission_code`),
  ADD KEY `idx_module` (`module`);

--
-- Indexes for table `taikhoan`
--
ALTER TABLE `taikhoan`
  ADD PRIMARY KEY (`account_id`),
  ADD UNIQUE KEY `employee_id` (`employee_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_username` (`username`);

--
-- Indexes for table `taikhoan_vaitro`
--
ALTER TABLE `taikhoan_vaitro`
  ADD PRIMARY KEY (`account_role_id`),
  ADD UNIQUE KEY `uk_account_role` (`account_id`,`role_id`),
  ADD KEY `role_id` (`role_id`);

--
-- Indexes for table `tailieudinhkem`
--
ALTER TABLE `tailieudinhkem`
  ADD PRIMARY KEY (`document_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_type` (`document_type`);

--
-- Indexes for table `thongbao`
--
ALTER TABLE `thongbao`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `target_department_id` (`target_department_id`),
  ADD KEY `target_position_id` (`target_position_id`),
  ADD KEY `idx_type` (`notification_type`),
  ADD KEY `idx_active` (`is_active`),
  ADD KEY `idx_dates` (`start_date`,`end_date`);

--
-- Indexes for table `thuong`
--
ALTER TABLE `thuong`
  ADD PRIMARY KEY (`bonus_id`),
  ADD KEY `payroll_id` (`payroll_id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_date` (`bonus_date`);

--
-- Indexes for table `tieuchidanhgia`
--
ALTER TABLE `tieuchidanhgia`
  ADD PRIMARY KEY (`criteria_id`),
  ADD UNIQUE KEY `criteria_code` (`criteria_code`);

--
-- Indexes for table `vaitro`
--
ALTER TABLE `vaitro`
  ADD PRIMARY KEY (`role_id`),
  ADD UNIQUE KEY `role_code` (`role_code`),
  ADD KEY `idx_role_code` (`role_code`);

--
-- Indexes for table `vaitro_quyenhan`
--
ALTER TABLE `vaitro_quyenhan`
  ADD PRIMARY KEY (`role_permission_id`),
  ADD UNIQUE KEY `uk_role_permission` (`role_id`,`permission_id`),
  ADD KEY `permission_id` (`permission_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bangchamcong`
--
ALTER TABLE `bangchamcong`
  MODIFY `timesheet_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bangluong`
--
ALTER TABLE `bangluong`
  MODIFY `payroll_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `calamviec`
--
ALTER TABLE `calamviec`
  MODIFY `shift_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `cauhinhcongty`
--
ALTER TABLE `cauhinhcongty`
  MODIFY `config_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `chitietchamcong`
--
ALTER TABLE `chitietchamcong`
  MODIFY `attendance_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chitietdanhgia`
--
ALTER TABLE `chitietdanhgia`
  MODIFY `review_detail_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chitietphucap`
--
ALTER TABLE `chitietphucap`
  MODIFY `payroll_allowance_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chucvu`
--
ALTER TABLE `chucvu`
  MODIFY `position_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `chukydanhgia`
--
ALTER TABLE `chukydanhgia`
  MODIFY `review_cycle_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chungchi`
--
ALTER TABLE `chungchi`
  MODIFY `certificate_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `danhgianhanvien`
--
ALTER TABLE `danhgianhanvien`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `danhmuchethong`
--
ALTER TABLE `danhmuchethong`
  MODIFY `catalog_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `danhmuctaisan`
--
ALTER TABLE `danhmuctaisan`
  MODIFY `asset_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `donnghiphep`
--
ALTER TABLE `donnghiphep`
  MODIFY `leave_request_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hanmucphep`
--
ALTER TABLE `hanmucphep`
  MODIFY `leave_quota_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `hocvan`
--
ALTER TABLE `hocvan`
  MODIFY `education_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hopdonglaodong`
--
ALTER TABLE `hopdonglaodong`
  MODIFY `contract_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `khenthuong`
--
ALTER TABLE `khenthuong`
  MODIFY `award_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `kinhnghiemlamviec`
--
ALTER TABLE `kinhnghiemlamviec`
  MODIFY `experience_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `kyluat`
--
ALTER TABLE `kyluat`
  MODIFY `discipline_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lichsuphongban`
--
ALTER TABLE `lichsuphongban`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `loaihopdong`
--
ALTER TABLE `loaihopdong`
  MODIFY `contract_type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `loainghiphep`
--
ALTER TABLE `loainghiphep`
  MODIFY `leave_type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `loaiphucap`
--
ALTER TABLE `loaiphucap`
  MODIFY `allowance_type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `ngaynghile`
--
ALTER TABLE `ngaynghile`
  MODIFY `holiday_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `nguoinhanthongbao`
--
ALTER TABLE `nguoinhanthongbao`
  MODIFY `recipient_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nhanvien`
--
ALTER TABLE `nhanvien`
  MODIFY `employee_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `nhatkyhoatdong`
--
ALTER TABLE `nhatkyhoatdong`
  MODIFY `log_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phieucapphattaisan`
--
ALTER TABLE `phieucapphattaisan`
  MODIFY `assignment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phongban`
--
ALTER TABLE `phongban`
  MODIFY `department_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `quyenhan`
--
ALTER TABLE `quyenhan`
  MODIFY `permission_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `taikhoan`
--
ALTER TABLE `taikhoan`
  MODIFY `account_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `taikhoan_vaitro`
--
ALTER TABLE `taikhoan_vaitro`
  MODIFY `account_role_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tailieudinhkem`
--
ALTER TABLE `tailieudinhkem`
  MODIFY `document_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `thongbao`
--
ALTER TABLE `thongbao`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `thuong`
--
ALTER TABLE `thuong`
  MODIFY `bonus_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tieuchidanhgia`
--
ALTER TABLE `tieuchidanhgia`
  MODIFY `criteria_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `vaitro`
--
ALTER TABLE `vaitro`
  MODIFY `role_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `vaitro_quyenhan`
--
ALTER TABLE `vaitro_quyenhan`
  MODIFY `role_permission_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bangchamcong`
--
ALTER TABLE `bangchamcong`
  ADD CONSTRAINT `bangchamcong_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `bangluong`
--
ALTER TABLE `bangluong`
  ADD CONSTRAINT `bangluong_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `chitietchamcong`
--
ALTER TABLE `chitietchamcong`
  ADD CONSTRAINT `chitietchamcong_ibfk_1` FOREIGN KEY (`timesheet_id`) REFERENCES `bangchamcong` (`timesheet_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chitietchamcong_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chitietchamcong_ibfk_3` FOREIGN KEY (`shift_id`) REFERENCES `calamviec` (`shift_id`) ON DELETE SET NULL;

--
-- Constraints for table `chitietdanhgia`
--
ALTER TABLE `chitietdanhgia`
  ADD CONSTRAINT `chitietdanhgia_ibfk_1` FOREIGN KEY (`review_id`) REFERENCES `danhgianhanvien` (`review_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chitietdanhgia_ibfk_2` FOREIGN KEY (`criteria_id`) REFERENCES `tieuchidanhgia` (`criteria_id`);

--
-- Constraints for table `chitietphucap`
--
ALTER TABLE `chitietphucap`
  ADD CONSTRAINT `chitietphucap_ibfk_1` FOREIGN KEY (`payroll_id`) REFERENCES `bangluong` (`payroll_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chitietphucap_ibfk_2` FOREIGN KEY (`allowance_type_id`) REFERENCES `loaiphucap` (`allowance_type_id`);

--
-- Constraints for table `chungchi`
--
ALTER TABLE `chungchi`
  ADD CONSTRAINT `chungchi_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `danhgianhanvien`
--
ALTER TABLE `danhgianhanvien`
  ADD CONSTRAINT `danhgianhanvien_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `danhgianhanvien_ibfk_2` FOREIGN KEY (`review_cycle_id`) REFERENCES `chukydanhgia` (`review_cycle_id`),
  ADD CONSTRAINT `danhgianhanvien_ibfk_3` FOREIGN KEY (`reviewer_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE SET NULL;

--
-- Constraints for table `danhmuctaisan`
--
ALTER TABLE `danhmuctaisan`
  ADD CONSTRAINT `danhmuctaisan_ibfk_1` FOREIGN KEY (`current_holder_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE SET NULL;

--
-- Constraints for table `donnghiphep`
--
ALTER TABLE `donnghiphep`
  ADD CONSTRAINT `donnghiphep_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `donnghiphep_ibfk_2` FOREIGN KEY (`leave_type_id`) REFERENCES `loainghiphep` (`leave_type_id`),
  ADD CONSTRAINT `donnghiphep_ibfk_3` FOREIGN KEY (`approver_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE SET NULL;

--
-- Constraints for table `hanmucphep`
--
ALTER TABLE `hanmucphep`
  ADD CONSTRAINT `hanmucphep_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `hanmucphep_ibfk_2` FOREIGN KEY (`leave_type_id`) REFERENCES `loainghiphep` (`leave_type_id`);

--
-- Constraints for table `hocvan`
--
ALTER TABLE `hocvan`
  ADD CONSTRAINT `hocvan_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `hopdonglaodong`
--
ALTER TABLE `hopdonglaodong`
  ADD CONSTRAINT `hopdonglaodong_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `hopdonglaodong_ibfk_2` FOREIGN KEY (`contract_type_id`) REFERENCES `loaihopdong` (`contract_type_id`);

--
-- Constraints for table `khenthuong`
--
ALTER TABLE `khenthuong`
  ADD CONSTRAINT `khenthuong_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `kinhnghiemlamviec`
--
ALTER TABLE `kinhnghiemlamviec`
  ADD CONSTRAINT `kinhnghiemlamviec_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `kyluat`
--
ALTER TABLE `kyluat`
  ADD CONSTRAINT `kyluat_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kyluat_ibfk_2` FOREIGN KEY (`payroll_id`) REFERENCES `bangluong` (`payroll_id`) ON DELETE SET NULL;

--
-- Constraints for table `lichsuphongban`
--
ALTER TABLE `lichsuphongban`
  ADD CONSTRAINT `lichsuphongban_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `lichsuphongban_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `phongban` (`department_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `lichsuphongban_ibfk_3` FOREIGN KEY (`position_id`) REFERENCES `chucvu` (`position_id`) ON DELETE SET NULL;

--
-- Constraints for table `nguoinhanthongbao`
--
ALTER TABLE `nguoinhanthongbao`
  ADD CONSTRAINT `nguoinhanthongbao_ibfk_1` FOREIGN KEY (`notification_id`) REFERENCES `thongbao` (`notification_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `nguoinhanthongbao_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `nhanvien`
--
ALTER TABLE `nhanvien`
  ADD CONSTRAINT `nhanvien_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `phongban` (`department_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `nhanvien_ibfk_2` FOREIGN KEY (`position_id`) REFERENCES `chucvu` (`position_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `nhanvien_ibfk_3` FOREIGN KEY (`direct_manager_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE SET NULL;

--
-- Constraints for table `nhatkyhoatdong`
--
ALTER TABLE `nhatkyhoatdong`
  ADD CONSTRAINT `nhatkyhoatdong_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `taikhoan` (`account_id`) ON DELETE SET NULL;

--
-- Constraints for table `phieucapphattaisan`
--
ALTER TABLE `phieucapphattaisan`
  ADD CONSTRAINT `phieucapphattaisan_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `danhmuctaisan` (`asset_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `phieucapphattaisan_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `phongban`
--
ALTER TABLE `phongban`
  ADD CONSTRAINT `fk_dept_manager` FOREIGN KEY (`manager_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `phongban_ibfk_1` FOREIGN KEY (`parent_department_id`) REFERENCES `phongban` (`department_id`) ON DELETE SET NULL;

--
-- Constraints for table `taikhoan`
--
ALTER TABLE `taikhoan`
  ADD CONSTRAINT `taikhoan_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `taikhoan_vaitro`
--
ALTER TABLE `taikhoan_vaitro`
  ADD CONSTRAINT `taikhoan_vaitro_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `taikhoan` (`account_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `taikhoan_vaitro_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `vaitro` (`role_id`) ON DELETE CASCADE;

--
-- Constraints for table `tailieudinhkem`
--
ALTER TABLE `tailieudinhkem`
  ADD CONSTRAINT `tailieudinhkem_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE;

--
-- Constraints for table `thongbao`
--
ALTER TABLE `thongbao`
  ADD CONSTRAINT `thongbao_ibfk_1` FOREIGN KEY (`target_department_id`) REFERENCES `phongban` (`department_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `thongbao_ibfk_2` FOREIGN KEY (`target_position_id`) REFERENCES `chucvu` (`position_id`) ON DELETE SET NULL;

--
-- Constraints for table `thuong`
--
ALTER TABLE `thuong`
  ADD CONSTRAINT `thuong_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `nhanvien` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `thuong_ibfk_2` FOREIGN KEY (`payroll_id`) REFERENCES `bangluong` (`payroll_id`) ON DELETE SET NULL;

--
-- Constraints for table `vaitro_quyenhan`
--
ALTER TABLE `vaitro_quyenhan`
  ADD CONSTRAINT `vaitro_quyenhan_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `vaitro` (`role_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `vaitro_quyenhan_ibfk_2` FOREIGN KEY (`permission_id`) REFERENCES `quyenhan` (`permission_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
