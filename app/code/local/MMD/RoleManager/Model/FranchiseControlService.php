<?php
/**
 * SG-side certificate-release control over the franchisees.
 *
 * Per-franchisee mode, stored on SG in mmd/franchise_cert/{my,gh}_mode and
 * pushed to the partner's /courses/api_franchise_control endpoint:
 *   auto        — partner's daily 18:30 certificate sweep is ON
 *   on_payment  — partner's sweep is OFF; when the Franchise Admin marks a
 *                 class fee as paid, releaseCerts() tells the partner to
 *                 generate + email that class's certificates right away.
 * Defaults (migration 1894): MY = auto, GH = on_payment.
 */
class MMD_RoleManager_Model_FranchiseControlService
{
    const LOG_FILE = 'franchise-report.log';

    public function modes()
    {
        $out = array();
        foreach (array('MY', 'GH') as $cc) {
            $m = strtolower(trim((string) Mage::getStoreConfig('mmd/franchise_cert/' . strtolower($cc) . '_mode')));
            $out[$cc] = in_array($m, array('auto', 'on_payment'), true) ? $m : 'auto';
        }
        return $out;
    }

    public function mode($cc)
    {
        $m = $this->modes();
        return isset($m[strtoupper($cc)]) ? $m[strtoupper($cc)] : 'auto';
    }

    /** Store the mode on SG and push it to the partner. Returns the partner reply. */
    public function setMode($cc, $mode)
    {
        $cc = strtoupper($cc);
        if (!in_array($mode, array('auto', 'on_payment'), true)) throw new Exception('mode must be auto or on_payment.');
        Mage::getConfig()->saveConfig('mmd/franchise_cert/' . strtolower($cc) . '_mode', $mode, 'default', 0);
        Mage::getConfig()->reinit();
        $rsp = $this->_call($cc, array('op' => 'cert_mode', 'mode' => $mode));
        Mage::log("FranchiseControl: $cc certificate mode -> $mode (" . json_encode($rsp) . ')', Zend_Log::INFO, self::LOG_FILE, true);
        return $rsp;
    }

    /** Ask the partner to release certificates for one class now. */
    public function releaseCerts($cc, $classCode)
    {
        $rsp = $this->_call(strtoupper($cc), array('op' => 'release_certs', 'class_code' => $classCode), 600);
        Mage::log("FranchiseControl: $cc release certs $classCode -> " . json_encode($rsp), Zend_Log::INFO, self::LOG_FILE, true);
        return $rsp;
    }

    protected function _call($cc, array $body, $timeout = 60)
    {
        $partner = null;
        foreach (Mage::getModel('mmd_rolemanager/franchiseReportService')->getPartners() as $p) {
            if ($p['country'] === $cc) { $partner = $p; break; }
        }
        if ($partner === null) throw new Exception($cc . ' is not connected — add its URL and API key under Partner Settings first.');

        $ch = curl_init($partner['url'] . '/courses/api_franchise_control');
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true, CURLOPT_FOLLOWLOCATION => true, CURLOPT_MAXREDIRS => 5,
            CURLOPT_POST => true, CURLOPT_POSTFIELDS => http_build_query($body),
            CURLOPT_TIMEOUT => $timeout, CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_USERAGENT => 'Mozilla/5.0 (compatible; MMD-FranchiseControl/1.0)',
            CURLOPT_HTTPHEADER => array('X-API-Key: ' . $partner['key'], 'Accept: application/json'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);
        if ($raw === false || $raw === '') throw new Exception($cc . ' unreachable: ' . ($err ?: 'no response'));
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error'] : ('HTTP ' . $code . ' — partner has not deployed /courses/api_franchise_control yet?');
            throw new Exception($cc . ': ' . $msg);
        }
        return $rsp;
    }
}
