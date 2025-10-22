<?php
class ContactController
{
    private $contactModel;
    
    public function __construct()
    {
        require_once MODELS_PATH . '/Contact.php';
        $this->contactModel = new Contact();
    }
    
    public function index()
    {
        $this->view('contact/form');
    }
    
    public function store()
    {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $name = $_POST['name'] ?? '';
            $email = $_POST['email'] ?? '';
            $content = $_POST['content'] ?? '';
            
            $result = $this->contactModel->create($name, $email, $content);
            
            $this->view('contact/form', ['result' => $result]);
        }
    }
    
    private function view($path, $data = [])
    {
        extract($data);
        require VIEWS_PATH . '/' . $path . '.php';
    }
}
?>