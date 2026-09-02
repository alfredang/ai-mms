<?php
/**
 * Social credential health monitor.
 *
 * WHY THIS EXISTS: on 2026-08-29 the Facebook page token was saved without the
 * long-lived exchange step, so it died ~17h later. Blog posts #47, #130 and #131
 * then failed to reach the page for FOUR DAYS with nobody noticing, because
 * MMD_Blog_Model_Cron_Autoblog::shareEverywhere() returns a per-network STRING
 * and never throws — "the blog published" stayed true while Facebook was dead.
 *
 * This job probes the credentials the way the platforms actually see them and
 * emails the reviewers BEFORE a share silently starts failing:
 *
 *   - Facebook : /debug_token -> is_valid + expires_at. expires_at MUST be 0
 *                (permanent, derived from a long-lived user token). A non-zero
 *                expiry is itself a defect worth alerting on, even while valid.
 *   - LinkedIn : member + org tokens are 60-day by design (LinkedIn has no
 *                permanent token), so warn while there is still time to renew.
 *
 * Read-only: it never rotates or writes a credential, it only reports.
 */
class MMD_Marketing_Model_Cron_Tokenhealth
{
    /** Warn this many days before a non-permanent token lapses. */
    const WARN_DAYS = 14;

    public function run()
    {
        $problems = array();
        $lines    = array();

        foreach (array_merge($this->_checkFacebook(), $this->_checkLinkedin()) as $c) {
            $lines[] = $c['label'] . ': ' . $c['detail'];
            if ($c['level'] !== 'ok') { $problems[] = $c; }
        }

        $this->_log('tokenhealth: ' . implode(' | ', $lines));

        if ($problems) {
            $this->_alert($problems, $lines);
        }
        return $this;
    }

    protected function _checkFacebook()
    {
        $out = array();
        try {
            $fb = Mage::helper('mmd_marketing/facebook');
            if (!Mage::getStoreConfigFlag('mmd_marketing/facebook/enabled')) {
                return array(array('label' => 'facebook', 'level' => 'warn', 'detail' => 'DISABLED in config'));
            }
            if (!$fb->isConfigured()) {
                return array(array('label' => 'facebook', 'level' => 'error', 'detail' => 'not configured'));
            }

            $token  = Mage::helper('core')->decrypt(Mage::getStoreConfig('mmd_marketing/facebook/access_token'));
            $appId  = trim((string) Mage::getStoreConfig('mmd_marketing/facebook/app_id'));
            $secret = Mage::helper('core')->decrypt(Mage::getStoreConfig('mmd_marketing/facebook/app_secret'));

            if ($appId === '' || $secret === '') {
                // Without app credentials the permanent-token exchange cannot be
                // re-run without a developer-portal visit + password re-auth.
                $out[] = array('label' => 'facebook/appcreds', 'level' => 'warn',
                    'detail' => 'app_id/app_secret missing - renewal needs the developer portal');
                return $out;
            }

            $j = $this->_json('https://graph.facebook.com/v23.0/debug_token'
                . '?input_token=' . urlencode($token)
                . '&access_token=' . urlencode($appId . '|' . $secret));
            $d = isset($j['data']) ? $j['data'] : array();

            if (empty($d['is_valid'])) {
                $msg = isset($j['error']['message']) ? $j['error']['message'] : 'token reported invalid';
                $out[] = array('label' => 'facebook', 'level' => 'error', 'detail' => $msg);
                return $out;
            }

            $exp = isset($d['expires_at']) ? (int) $d['expires_at'] : -1;
            if ($exp === 0) {
                $out[] = array('label' => 'facebook', 'level' => 'ok', 'detail' => 'valid, PERMANENT');
            } else {
                $days = (int) floor(($exp - time()) / 86400);
                $out[] = array('label' => 'facebook', 'level' => $days <= self::WARN_DAYS ? 'error' : 'warn',
                    'detail' => 'NOT permanent - expires ' . date('Y-m-d', $exp) . " ({$days}d). "
                        . 'Re-derive the page token from a LONG-LIVED user token.');
            }
        } catch (Exception $e) {
            $out[] = array('label' => 'facebook', 'level' => 'error', 'detail' => 'probe failed: ' . $e->getMessage());
        }
        return $out;
    }

    protected function _checkLinkedin()
    {
        $out = array();
        try {
            $li = Mage::helper('mmd_blog/linkedin');
            if (!$li->isConfigured()) {
                return array(array('label' => 'linkedin', 'level' => 'error', 'detail' => 'not configured'));
            }
            // A cheap authenticated call: userinfo works for both member scopes
            // and org tokens; a 401 is what an expired token actually returns.
            $out[] = $this->_probeLinkedinToken('linkedin/member',
                Mage::helper('core')->decrypt(Mage::getStoreConfig('mmd_marketing/linkedin/access_token')));

            $orgUrn = $li->orgUrn();
            if (!$orgUrn) {
                $out[] = array('label' => 'linkedin/org', 'level' => 'warn',
                    'detail' => 'org_urn EMPTY - company-page posts are silently skipped');
            } else {
                $orgTok = Mage::helper('core')->decrypt(
                    Mage::getStoreConfig('mmd_marketing/linkedin/org_access_token'));
                if ($orgTok === '') { $orgTok = null; }
                $out[] = $this->_probeLinkedinToken('linkedin/org', $orgTok, $orgUrn);
            }
        } catch (Exception $e) {
            $out[] = array('label' => 'linkedin', 'level' => 'error', 'detail' => 'probe failed: ' . $e->getMessage());
        }
        return $out;
    }

    /**
     * LinkedIn exposes no expiry introspection without the client secret, so
     * probe with a real call: 401 means the token is already dead.
     */
    protected function _probeLinkedinToken($label, $token, $orgUrn = null)
    {
        if (!$token) {
            return array('label' => $label, 'level' => 'warn', 'detail' => 'no dedicated token (falls back to member)');
        }
        $url = $orgUrn
            ? 'https://api.linkedin.com/v2/organizationAcls?q=roleAssignee&role=ADMINISTRATOR&count=1'
            : 'https://api.linkedin.com/v2/userinfo';
        $ch = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 25,
            CURLOPT_HTTPHEADER => array('Authorization: Bearer ' . $token,
                'X-Restli-Protocol-Version: 2.0.0'),
        ));
        curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($code === 401) {
            return array('label' => $label, 'level' => 'error', 'detail' => 'EXPIRED/revoked (HTTP 401) - renew now');
        }
        if ($code === 200 || $code === 403) {
            // 403 = token alive but lacking that specific scope; not an outage.
            return array('label' => $label, 'level' => 'ok', 'detail' => 'alive (HTTP ' . $code . ')');
        }
        return array('label' => $label, 'level' => 'warn', 'detail' => 'unexpected HTTP ' . $code);
    }

    protected function _json($url)
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, array(CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 25));
        $r = curl_exec($ch);
        curl_close($ch);
        return json_decode((string) $r, true);
    }

    /**
     * Email the flyer reviewers. Reuses the Gmail-OAuth-then-SMTPPro transport
     * order proven in Flyer.php (the container has no sendmail).
     */
    protected function _alert(array $problems, array $lines)
    {
        try {
            // HARD SAFETY (same contract as Flyer::sendForReview): never email
            // the real managers from a non-production env. Localhost has no
            // credentials configured, so every dev run would otherwise fire a
            // live-looking "credentials broken" alert at angch@/tansc@.
            $host = strtolower((string) parse_url(
                (string) Mage::getStoreConfig('web/unsecure/base_url'), PHP_URL_HOST));
            $isProd = (bool) preg_match('/(^|\.)tertiarycourses\.com(\.[a-z]{2,3})?$/', $host);
            if (!$isProd && !(bool) Mage::getStoreConfig('mmd_marketing/newsletter/allow_local_review_email')) {
                $this->_log('tokenhealth: alert SKIPPED — non-production base_url (' . ($host ?: 'empty') . ')');
                return;
            }

            // reviewers() lives on the Blastguard helper (the flyer cron reaches
            // it via $this->_guard()), not on the cron model itself.
            $to = Mage::helper('mmd_marketing/blastguard')->reviewers();
            if (!$to) { $to = array(Mage::getStoreConfig('trans_email/ident_general/email')); }

            $worst   = 'warn';
            foreach ($problems as $p) { if ($p['level'] === 'error') { $worst = 'error'; } }
            $subject = ($worst === 'error' ? '[ACTION] ' : '[Warning] ')
                . 'Social auto-post credentials need attention';

            $html = '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;max-width:660px;">'
                . '<p style="font-size:15px;color:#0a1020;">The weekly credential check found '
                . count($problems) . ' issue(s). Blog and newsletter auto-posting may be '
                . 'failing <b>silently</b> — a share reports success even when one network is dead.</p><ul>';
            foreach ($problems as $p) {
                $html .= '<li style="margin:6px 0;"><b>' . htmlspecialchars($p['label']) . '</b>: '
                      . htmlspecialchars($p['detail']) . '</li>';
            }
            $html .= '</ul><p style="font-size:13px;color:#475569;">Full status: '
                  . htmlspecialchars(implode(' | ', $lines)) . '</p></div>';

            $gmail = null;
            try {
                $gh = Mage::helper('mmd_email/gmail');
                if ($gh && $gh->isConfigured()) { $gmail = $gh; }
            } catch (Exception $e) { $gmail = null; }

            foreach ($to as $email) {
                if ($gmail) {
                    $gmail->send($email, $subject, $html);
                    continue;
                }
                $mail = new Zend_Mail('utf-8');
                $mail->addTo($email)->setSubject($subject)->setBodyHtml($html)
                     ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'),
                               Mage::getStoreConfig('trans_email/ident_general/name'));
                if (Mage::helper('core')->isModuleEnabled('Aschroder_SMTPPro')) {
                    $mail->send(Mage::helper('smtppro')->getTransport());
                } else {
                    $mail->send();
                }
            }
            $this->_log('tokenhealth: alerted ' . implode(', ', $to));
        } catch (Exception $e) {
            $this->_log('tokenhealth: alert failed: ' . $e->getMessage());
        }
    }

    protected function _log($msg)
    {
        Mage::log($msg, null, 'mmd_marketing.log');
    }
}
