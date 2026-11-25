<?php
/** Real schedule-page rendering against the isolated MMS fixture only. */
ob_start();
if (getenv('MMS_HANDOVER_ISOLATED_TEST') !== '1') {
    throw new RuntimeException('Isolated MMS fixture required.');
}
$root = dirname(__DIR__, 2);
$config = simplexml_load_file($root . '/app/etc/local.xml');
$connection = $config->global->resources->default_setup->connection;
if ((string) $connection->host !== 'mms-nonfunded-test-mysql'
    || (string) $connection->dbname !== 'mms_handover_test') {
    throw new RuntimeException('Fixture database identity mismatch.');
}
require_once $root . '/app/Mage.php';
Mage::app('admin');
require_once $root . '/app/code/local/MMD/Adminhtml/controllers/Customoptions/OptionsController.php';
Mage::getDesign()->setArea('adminhtml');
$checks = 0;
function schedulePageCheck($condition, $message)
{
    global $checks;
    if (!$condition) throw new RuntimeException($message);
    $checks++;
}

class SchedulePageRenderingController extends MMD_Adminhtml_Customoptions_OptionsController
{
    public function renderLayout($output = '') { return $this; }
    public function allowedForTest() { return $this->_isAllowed(); }
    public function addActionLayoutHandles()
    {
        // Reproduce a deployment with no action-specific extension layout.
        return in_array('normal-layout', $_SERVER['argv'], true) ? parent::addActionLayoutHandles() : $this;
    }
}

$action = $argv[1] ?? 'index';
if (!in_array($action, array('index', 'distribution'), true)) {
    throw new RuntimeException('Unknown schedule-page test action.');
}
$request = Mage::app()->getRequest();
$request->setRouteName('mmd')->setModuleName('mmd')->setControllerName('customoptions_options')
    ->setActionName($action)->setControllerModule('MMD_Adminhtml');
$controller = new SchedulePageRenderingController($request, Mage::app()->getResponse());
if ($action === 'index') {
    $sql = MMD_Adminhtml_Block_Customoptions_Options_Grid::durationCodeSql('sample.title');
    $db = Mage::getSingleton('core/resource')->getConnection('core_read');
    foreach (array('(SG) WSQ-A01 Weekday' => 'A', 'B19 Weekend' => 'B', 'WSQ-C02' => 'C',
        'D04' => 'D', 'E01' => 'E', 'a01 lowercase' => 'X', 'xA01 embedded' => 'X',
        'A1 short code' => 'X', 'Other' => 'X', 'WSQ — C01' => 'C') as $title => $expected) {
        $actual = $db->fetchOne('SELECT ' . $sql . ' FROM (SELECT ? AS title) sample', array($title));
        schedulePageCheck($actual === $expected, 'Incorrect duration classification for ' . $title);
    }
}
$session = Mage::getSingleton('admin/session');
$session->setUser(Mage::getModel('admin/user')->setId(900001));
foreach (array('admin', 'training_provider', 'developer', 'marketing', 'trainer', 'learner') as $role) {
    $session->setActiveRoleCode($role);
    schedulePageCheck($controller->allowedForTest() === in_array($role, array('admin', 'training_provider'), true),
        'Schedule page role access changed for ' . $role);
}
$session->setUser(null);
schedulePageCheck(!$controller->allowedForTest(), 'Anonymous schedule access was allowed.');
$session->setUser(Mage::getModel('admin/user')->setId(900001))->setActiveRoleCode('admin');
$controller->{$action . 'Action'}();
$layout = $controller->getLayout();
$name = $action === 'index' ? 'customoptions_options' : 'customoptions_distribution';
$block = $layout->getBlock($name);
schedulePageCheck((bool) $block, 'Schedule content block is missing.');
schedulePageCheck(count(array_keys($layout->getBlock('content')->getSortedChildren(), $name, true)) === 1,
    'Schedule content must be attached exactly once.');
$html = $layout->getBlock('content')->toHtml();
$marker = $action === 'index' ? 'customoptionsOptionsGrid' : 'Active courses per schedule template';
schedulePageCheck(strpos($html, $marker) !== false, 'Schedule content did not render.');
schedulePageCheck(strpos($html, 'Fatal error') === false, 'Schedule page contains a PHP fatal.');
echo $action . ': ' . $checks . " checks passed; " . strlen($html) . " rendered bytes.\n";
