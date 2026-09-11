<?php
/** No-network authentication routing regression test. */
if (PHP_SAPI !== 'cli') { exit(1); }
require dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();
class FlyerAuthTestConfig extends Mage_Core_Helper_Abstract
{
    public $key = '';
    public function getMarketingApiConfig() { return array('anthropic_key' => $this->key); }
}
class FlyerAuthTestClient extends MMD_Marketing_Helper_Flyer
{
    public $calls = array();
    public $reply = '{"hook":"Revised copy"}';
    public function generate($prompt) { return $this->_callClaude($prompt); }
    protected function _invokeClaudeClient($prompt)
    {
        $this->calls[] = $prompt;
        return $this->reply;
    }
}
function authCheck($condition, $message)
{
    if (!$condition) { throw new Exception('FAIL: ' . $message); }
    echo 'PASS: ' . $message . PHP_EOL;
}
$cfg = new FlyerAuthTestConfig();
Mage::unregister('_helper/mmd_rolemanager');
Mage::register('_helper/mmd_rolemanager', $cfg);
$client = new FlyerAuthTestClient();
authCheck($client->generate('feedback') === '' && !$client->calls, 'missing credentials fail closed');
$cfg->key = 'sk-ant-oat-test-fixture';
$prompt = 'Hands-on Word, PowerPoint, Excel and Outlook working together. Return JSON.';
authCheck($client->generate($prompt) === $client->reply, 'OAuth uses Claude client rather than direct API');
authCheck($client->calls === array($prompt), 'complete feedback prompt is preserved');
$client->reply = '';
authCheck($client->generate($prompt) === '', 'client failure remains a held revision, not fallback copy');
$cfg->key = '  sk-ant-oat-test-fixture  ';
authCheck($client->generate($prompt) === '' && count($client->calls) === 3, 'credential whitespace does not bypass routing');
class FlyerAuthFakeInvoker
{
    public function invokeClaude($prompt) { return 'Your organization has disabled Claude subscription access for Claude Code'; }
}
class FlyerAuthRealRouting extends MMD_Marketing_Helper_Flyer
{
    public function generate($prompt) { return $this->_callClaude($prompt); }
}
Mage::getConfig()->setNode('global/models/mmd_rolemanager/rewrite/aiSeo', 'FlyerAuthFakeInvoker');
$denied = false;
try { (new FlyerAuthRealRouting())->generate($prompt); }
catch (DomainException $e) { $denied = strpos($e->getMessage(), 'API key') !== false; }
authCheck($denied, 'organisation denial becomes an actionable permanent error');
echo "All authentication routing checks passed; no external calls made.\n";
