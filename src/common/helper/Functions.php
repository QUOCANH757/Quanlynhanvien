<?php
/**
 * File: src/common/helper/Functions.php
 * Các hàm tiện ích dùng chung cho ứng dụng
 */

if (!function_exists('redirect')) {
	function redirect($url) {
		header('Location: ' . $url);
		exit;
	}
}

if (!function_exists('e')) {
	function e($value) {
		return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
	}
}

if (!function_exists('flash')) {
	function flash($key, $default = null) {
		if (isset($_SESSION[$key])) {
			$value = $_SESSION[$key];
			unset($_SESSION[$key]);
			return $value;
		}
		return $default;
	}
}


