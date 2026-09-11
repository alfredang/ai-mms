<?php
/** CLI regression test. Temporary tables and a fake provider: no emails or API calls. */
if (PHP_SAPI !== 'cli') { exit(1); }
require dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

class FlyerChangesTestMailer extends MMD_Marketing_Helper_Mailerlite
{
    public $responses = array();
    public $requests = array();
    public $fail = false;
    public function getCampaign($id) { return array_shift($this->responses); }
    protected function _send($method, $path, array $body)
    {
        $this->requests[] = array($method, $path);
        if ($this->fail) { throw new Exception('Simulated provider failure'); }
        return array();
    }
    public function createAndSchedule($subject, $html, DateTime $sendAt, $groupId = null)
    {
        throw new Exception('TEST FAILURE: scheduling must never be reached');
    }
}
class FlyerChangesTestGuard extends MMD_Marketing_Helper_Blastguard
{
    public function canScheduleNow(&$reason = '') { return true; }
    public function nextSendSlot() { return new DateTime('next Monday 08:00'); }
}
class FlyerChangesTestModel extends MMD_Marketing_Model_Cron_Flyer
{
    protected function _read() { return $this->_write(); }
    protected function _guard() { return new FlyerChangesTestGuard(); }
}
function check($value, $message)
{
    if (!$value) { throw new Exception('FAIL: ' . $message); }
    echo 'PASS: ' . $message . PHP_EOL;
}
function rejects($callback, $message)
{
    try { $callback(); } catch (Exception $e) {
        if (strpos($e->getMessage(), 'TEST FAILURE') !== false) { throw $e; }
        check(true, $message); return;
    }
    check(false, $message);
}
function campaign($status, $sending = false)
{
    return array('data' => array('id' => 'fixture-campaign', 'status' => $status, 'is_currently_sending_out' => $sending));
}
$ml = new FlyerChangesTestMailer();
Mage::unregister('_helper/mmd_marketing/mailerlite');
Mage::register('_helper/mmd_marketing/mailerlite', $ml);
$resource = Mage::getSingleton('core/resource');
$db = $resource->getConnection('core_write');
$table = $resource->getTableName('newsletters');
$ledger = $resource->getTableName('mmd_marketing_blast_log');
// Session-local shadows vanish at process exit; never truncate real tables.
foreach (array($table, $ledger) as $shadow) {
    $definition = $db->fetchRow('SHOW CREATE TABLE ' . $shadow);
    $db->query(preg_replace('/^CREATE TABLE/', 'CREATE TEMPORARY TABLE', $definition['Create Table']));
}
$db->insert($table, array('country_code' => 'SG', 'template_key' => 'test', 'title' => 'Fixture',
    'subject' => 'Fixture', 'status' => 'scheduled', 'review_status' => 'approved',
    'mailerlite_id' => 'fixture-campaign', 'scheduled_send_at' => '2030-01-07 08:00:00',
    'review_decisions' => json_encode(array('angch@tertiaryinfotech.com' => 'approve', '_linkedin_url' => 'fixture'))));
$id = (int) $db->lastInsertId();
$db->insert($ledger, array('newsletter_id' => $id, 'mailerlite_id' => 'fixture-campaign', 'blasted_at' => '2030-01-07 08:00:00'));
$db->insert($ledger, array('newsletter_id' => $id, 'mailerlite_id' => 'other-campaign', 'blasted_at' => '2030-01-10 08:00:00'));
$model = new FlyerChangesTestModel();
$request = function () use ($model, $id) { $model->requestScheduledChanges($id, 'SG', 'Shorten the headline', 'admin@example.test'); };
rejects(function () use ($model, $id) { $model->requestScheduledChanges($id, 'MY', 'Change', 'admin@example.test'); }, 'country mismatch rejected');
rejects(function () use ($model, $id) { $model->requestScheduledChanges($id, 'SG', ' ', 'admin@example.test'); }, 'empty feedback rejected');
foreach (array('sent', 'scheduling', 'draft') as $status) {
    $db->update($table, array('status' => $status), array('newsletter_id = ?' => $id));
    rejects($request, $status . ' local state rejected');
}
$db->update($table, array('status' => 'scheduled'), array('newsletter_id = ?' => $id));
foreach (array(campaign('sent'), campaign('ready', true), null, campaign('unknown')) as $response) {
    $ml->responses = array($response);
    rejects($request, 'unsafe or unavailable provider state rejected');
}
$ml->responses = array(campaign('ready'));
$ml->fail = true;
rejects($request, 'provider cancellation failure rejected');
$ml->fail = false;
$ml->responses = array(campaign('ready'), campaign('ready'));
rejects($request, 'unconfirmed cancellation rejected');
check($db->fetchOne('SELECT status FROM ' . $table . ' WHERE newsletter_id = ?', $id) === 'scheduled', 'failure preserves scheduled row');
check((int) $db->fetchOne('SELECT COUNT(*) FROM ' . $ledger) === 2, 'failure preserves reservations');
$ml->responses = array(campaign('ready'), campaign('draft'));
$request();
$row = $db->fetchRow('SELECT * FROM ' . $table . ' WHERE newsletter_id = ?', $id);
$decisions = json_decode($row['review_decisions'], true);
check($row['status'] === 'draft' && $row['review_status'] === 'changes_requested', 'confirmed cancellation queues regeneration');
check($row['mailerlite_id'] === null && $row['scheduled_send_at'] === null, 'cancelled booking cleared');
check($row['review_feedback'] === 'Shorten the headline', 'revision feedback retained');
check(!isset($decisions['angch@tertiaryinfotech.com']) && isset($decisions['_cancelled_campaign']) && $decisions['_linkedin_url'] === 'fixture', 'approvals reset and cancellation/social history preserved');
check((int) $db->fetchOne('SELECT COUNT(*) FROM ' . $ledger) === 1, 'only cancelled reservation released');
rejects($request, 'duplicate request cannot reopen same version');
foreach (array('changes_requested', 'superseded', 'expired') as $reviewStatus) {
    $db->update($table, array('review_status' => $reviewStatus), array('newsletter_id = ?' => $id));
    list($ok, $message) = $model->scheduleApproved($id);
    check(!$ok, $reviewStatus . ' cannot be scheduled with old approval');
}
$ml->responses = array(campaign('draft'), campaign('draft'));
$before = count($ml->requests);
$ml->cancelScheduledCampaign('fixture-campaign');
check(count($ml->requests) === $before, 'retry accepts verified draft without cancelling twice');
echo "All scheduled-flyer regression tests passed. No external requests made.\n";
