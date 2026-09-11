<?php
/** Isolated, no-network provider validation/routing tests. No actual credentials. */
if (PHP_SAPI !== 'cli') exit(1);
ob_start();
require dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();
$resource = Mage::getSingleton('core/resource');
$db = $resource->getConnection('core_write');
$table = $resource->getTableName('core/config_data');
$ddl = $db->fetchRow('SHOW CREATE TABLE ' . $db->quoteIdentifier($table));
$db->query(preg_replace('/^CREATE TABLE /', 'CREATE TEMPORARY TABLE ', $ddl['Create Table']));
class ProviderTestClient extends MMD_RoleManager_Model_AiProvider
{
    public $reply = 'OK';
    public $fail = false;
    protected function runClient($prompt, $system, array $images, $webSearch, &$auth)
    {
        if ($this->fail) throw new DomainException('Test failure');
        return $this->reply;
    }
}
function providerCheck($ok, $label) {
    if (!$ok) throw new Exception('FAIL: ' . $label);
    echo 'PASS: ' . $label . PHP_EOL;
}
$p = new ProviderTestClient();
$fixture = json_encode(array('auth_mode' => 'chatgpt', 'tokens' => array(
    'access_token' => 'fixture-access', 'refresh_token' => 'fixture-refresh',
    'id_token' => 'fixture-id', 'account_id' => 'fixture-account')));
class ProviderProcessTest extends MMD_RoleManager_Model_AiProvider {
    protected function clientBinary() { return __DIR__ . '/fixtures/openai-client.php'; }
    public function call($auth) { return $this->runClient('Test prompt', 'System instructions', array(), false, $auth); }
}
$before = glob(sys_get_temp_dir() . '/mmd-openai-*');
providerCheck((new ProviderProcessTest())->call($fixture) === 'OK', 'subprocess uses private OAuth files, requested model and restricted environment');
providerCheck(glob(sys_get_temp_dir() . '/mmd-openai-*') === $before, 'private OAuth session is removed after invocation');
providerCheck(!$p->isOpenAi(), 'legacy installations default to Claude');
foreach (array('{}', '{broken', str_repeat('x', 65537), '{"OPENAI_API_KEY":"fixture"}') as $invalid) {
    $rejected = false;
    try { $p->validateAuth($invalid); } catch (DomainException $e) { $rejected = true; }
    providerCheck($rejected, 'invalid or API-key credentials rejected');
}
$p->fail = true;
try { $p->selectProvider('openai', $fixture); } catch (DomainException $e) {}
providerCheck(!$p->isOpenAi() && !$p->hasOpenAiAuth(), 'failed test leaves provider and credentials unchanged');
$p->fail = false;
$p->selectProvider('openai', $fixture);
providerCheck($p->isOpenAi() && $p->hasOpenAiAuth(), 'successful test activates OpenAI');
$encrypted = $db->fetchOne($db->select()->from($table, 'value')->where('path = ?', MMD_RoleManager_Model_AiProvider::AUTH_PATH));
providerCheck(strpos($encrypted, 'fixture') === false && json_decode(Mage::helper('core')->decrypt($encrypted), true)['tokens']['account_id'] === 'fixture-account', 'stored credential is encrypted');
$p->selectProvider('claude');
providerCheck(!$p->isOpenAi() && $p->hasOpenAiAuth(), 'switch back retains saved OpenAI login');
class ProviderRoutingFake extends MMD_RoleManager_Model_AiProvider
{
    public static $calls = array();
    public function isOpenAi() { return true; }
    public function invoke($prompt, $system = '', array $images = array(), $webSearch = false) {
        self::$calls[] = array($prompt, $system, $images, $webSearch);
        return 'OPENAI-TEST';
    }
}
Mage::getConfig()->setNode('global/models/mmd_rolemanager/rewrite/aiProvider', 'ProviderRoutingFake');
class ProviderFlyerTest extends MMD_Marketing_Helper_Flyer {
    public function call($prompt) { return $this->_callClaude($prompt); }
}
class ProviderLeadTest extends MMD_Leads_Helper_AiDraft {
    public function call($prompt) { return $this->_invokeClaude('Email system', $prompt); }
}
providerCheck((new ProviderFlyerTest())->call('Flyer') === 'OPENAI-TEST', 'flyer routes to OpenAI without Claude key');
providerCheck((new ProviderLeadTest())->call('Email') === 'OPENAI-TEST', 'email replies route to OpenAI');
providerCheck(Mage::getModel('mmd_rolemanager/aiSeo')->invokeClaude('SEO') === 'OPENAI-TEST', 'shared SEO routes to OpenAI');
$blog = Mage::getModel('mmd_blog/cron_autoblog');
$method = new ReflectionMethod($blog, '_invokeClaude');
$method->setAccessible(true);
providerCheck($method->invoke($blog, 'Research', 'Blog', 3000, true) === 'OPENAI-TEST', 'blog routes to OpenAI');
providerCheck(end(ProviderRoutingFake::$calls)[3] === true, 'blog research retains web search');
require Mage::getBaseDir('code') . '/local/MMD/RoleManager/controllers/Adminhtml/MarketingnewsletterController.php';
class ProviderNewsletterTest extends MMD_RoleManager_Adminhtml_MarketingnewsletterController {
    public function call(array $messages) { return $this->_callClaude($messages, 'wsq', 'SG', array()); }
}
$controller = new ProviderNewsletterTest(new Mage_Core_Controller_Request_Http(), new Mage_Core_Controller_Response_Http());
$image = array('data' => 'fixture-image', 'media_type' => 'image/png');
$response = $controller->call(array(array('role' => 'user', 'content' => 'Revise newsletter', 'images' => array($image))));
providerCheck($response['text'] === 'OPENAI-TEST' && !$response['stubbed'], 'newsletter routes without a Claude key or stub');
$call = end(ProviderRoutingFake::$calls);
providerCheck($call[2] === array($image) && strpos($call[0], 'Revise newsletter') !== false, 'newsletter preserves images and revision instructions');
require Mage::getBaseDir('code') . '/local/MMD/RoleManager/controllers/Adminhtml/AiproviderController.php';
class ProviderControllerTest extends MMD_RoleManager_Adminhtml_AiproviderController {
    protected function _isAllowed() { return true; }
}
class ProviderPostRequest extends Mage_Core_Controller_Request_Http {
    public function isPost() { return true; }
}
$request = new ProviderPostRequest();
$request->setPost('provider', 'claude')->setParam('form_key', 'wrong');
$response = new Mage_Core_Controller_Response_Http();
(new ProviderControllerTest($request, $response))->saveAction();
providerCheck($response->getHttpResponseCode() === 403 && !json_decode($response->getBody(), true)['success'], 'provider save rejects an invalid CSRF form key');
providerCheck(MMD_RoleManager_Model_AiProvider::OPENAI_MODEL === 'gpt-5.6-sol', 'requested model is pinned');
echo "All provider checks passed. No network requests or real configuration writes.\n";
