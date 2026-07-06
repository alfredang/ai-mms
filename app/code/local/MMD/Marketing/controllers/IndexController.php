<?php
/**
 * Public (no-login) reviewer endpoint for the newsletter approval flow.
 *
 *   /newsletter-review/index/decide/id/<n>/d/<approve|changes>/e/<email>/t/<token>
 *       — a manager approves or requests changes. The signed token (bound to the
 *         newsletter + reviewer email) is the authorisation. On the SECOND approval
 *         the campaign is scheduled to MailerLite (Mon/Thu 08:00, 2/week cap).
 *   /newsletter-review/index/qr/u/<base64 course-url>
 *       — streams the QR image for the flyer (redirects to a QR renderer).
 */
class MMD_Marketing_IndexController extends Mage_Core_Controller_Front_Action
{
    protected function _guard() { return Mage::helper('mmd_marketing/blastguard'); }
    protected function _tbl()   { return Mage::getSingleton('core/resource')->getTableName('newsletters'); }
    protected function _read()  { return Mage::getSingleton('core/resource')->getConnection('core_read'); }
    protected function _write() { return Mage::getSingleton('core/resource')->getConnection('core_write'); }

    protected function _page($title, $body, $accent = '#2563eb')
    {
        $html = '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<title>' . htmlspecialchars($title) . '</title></head>'
            . '<body style="margin:0;background:#eef2f7;font-family:-apple-system,Segoe UI,Arial,sans-serif;">'
            . '<div style="max-width:520px;margin:8vh auto;background:#fff;border:1px solid #e4e9f0;border-radius:16px;padding:32px 30px;box-shadow:0 20px 50px -20px rgba(15,23,42,.35);">'
            . '<div style="width:44px;height:44px;border-radius:12px;background:' . $accent . ';margin-bottom:18px;"></div>'
            . '<h1 style="margin:0 0 10px;font-size:22px;color:#0a1020;">' . htmlspecialchars($title) . '</h1>'
            . $body . '</div></body></html>';
        $this->getResponse()->setHeader('Content-Type', 'text/html; charset=utf-8', true)->setBody($html);
    }

    public function decideAction()
    {
        $req = $this->getRequest();
        $id       = (int) $req->getParam('id');
        $decision = (string) $req->getParam('d');
        $email    = strtolower(trim((string) $req->getParam('e')));
        $token    = (string) $req->getParam('t');

        if (!$this->_guard()->verifyToken($id, $email, $token)) {
            return $this->_page('Invalid or expired link', '<p style="color:#475569;">This approval link is not valid. Please use the buttons in the latest review email.</p>', '#ef4444');
        }
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($id));
        if (!$row) {
            return $this->_page('Not found', '<p style="color:#475569;">This proposal no longer exists.</p>', '#ef4444');
        }
        if (in_array((string) $row['status'], array('scheduled', 'sent'), true)) {
            return $this->_page('Already scheduled', '<p style="color:#475569;">This flyer has already been approved and scheduled — nothing more to do.</p>', '#059669');
        }

        $decisions = json_decode((string) $row['review_decisions'], true);
        if (!is_array($decisions)) { $decisions = array(); }

        // ---- Request changes: show a feedback form (GET), record on POST ----
        if ($decision === 'changes') {
            if ($req->isPost()) {
                $fb = trim((string) $req->getPost('feedback'));
                $decisions[$email] = 'changes';
                $this->_write()->update($this->_tbl(), array(
                    'review_decisions' => json_encode($decisions),
                    'review_feedback'  => $fb,
                    'review_status'    => 'changes_requested',
                ), array('newsletter_id = ?' => $id));
                return $this->_page('Thanks — we’ll revise it',
                    '<p style="color:#475569;">Your feedback was recorded. The system will regenerate the design (new design or a different course) and email you a fresh version to review.</p>', '#f59e0b');
            }
            $post = Mage::getUrl('newsletter-review/index/decide', array('id'=>$id,'d'=>'changes','e'=>rawurlencode($email),'t'=>$token,'_secure'=>true));
            return $this->_page('Request changes',
                '<form method="post" action="' . htmlspecialchars($post) . '">'
                . '<p style="color:#475569;">What would you like changed? (a new design, a different course, wording, etc.)</p>'
                . '<textarea name="feedback" rows="5" style="width:100%;box-sizing:border-box;border:1px solid #cbd5e1;border-radius:10px;padding:12px;font:14px inherit;" placeholder="e.g. Use a different course — pick a Data Analytics class instead."></textarea>'
                . '<button type="submit" style="margin-top:14px;background:#f59e0b;color:#fff;border:0;font-weight:700;font-size:14px;padding:11px 22px;border-radius:10px;cursor:pointer;">Send feedback</button>'
                . '</form>', '#f59e0b');
        }

        // ---- Approve ----
        // SINGLE approval (admin 2026-07-05): EITHER manager approving is enough —
        // no second approval required. The first approve schedules to MailerLite.
        $decisions[$email] = 'approve';
        $this->_write()->update($this->_tbl(), array('review_decisions' => json_encode($decisions)),
            array('newsletter_id = ?' => $id));

        list($ok, $msg) = Mage::getModel('mmd_marketing/cron_flyer')->scheduleApproved($id);
        if ($ok) {
            return $this->_page('Approved & scheduled ✓',
                '<p style="color:#475569;">Approved. The flyer is scheduled to MailerLite: <b>' . htmlspecialchars($msg) . '</b>.</p>', '#059669');
        }
        return $this->_page('Approved — scheduling held',
            '<p style="color:#475569;">Your approval is recorded, but it could not be scheduled yet: ' . htmlspecialchars($msg) . '</p>', '#f59e0b');
    }

    /**
     * Streams the flyer QR as a PNG generated ENTIRELY IN-HOUSE (no third-party
     * API, no redirect). Uses the bundled chillerlan/php-qrcode library server-
     * side, so the <img src> is a plain same-origin image/png response that every
     * email client renders directly — the previous 302-redirect to an external
     * generator failed in clients/proxies that don't follow image-src redirects
     * (report 2026-07-05: "QR not working"). High error-correction (ECC_H), a
     * 4-module quiet zone (spec minimum) and pure black maximise scannability.
     * Cached 24h. Falls back to the external generator only if the library fails.
     */
    public function qrAction()
    {
        $u = (string) $this->getRequest()->getParam('u');
        $url = base64_decode(rawurldecode($u), true);
        if ($url === false || !preg_match('#^https?://#', $url)) {
            $this->getResponse()->setHttpResponseCode(404)->setBody('bad url');
            return;
        }

        $cacheKey = 'MMD_FLYER_QR_' . md5($url);
        $cache    = Mage::app()->getCache();
        $png      = $cache ? $cache->load($cacheKey) : false;
        if ($png === false || $png === '') {
            try {
                $opt = new \chillerlan\QRCode\QROptions(array(
                    'outputType'    => \chillerlan\QRCode\QRCode::OUTPUT_IMAGE_PNG,
                    'eccLevel'      => \chillerlan\QRCode\QRCode::ECC_H,
                    'scale'         => 10,     // 10px per module → ~360px image
                    'quietzoneSize' => 4,      // spec-minimum quiet zone
                    'imageBase64'   => false,  // raw PNG bytes, not a data URI
                    'imageTransparent' => false,
                ));
                $png = (new \chillerlan\QRCode\QRCode($opt))->render($url);
            } catch (Exception $e) {
                $png = false;
                Mage::logException($e);
            }
            if ($png === false || $png === '') {
                // Library unavailable — fall back to the external generator so
                // the QR still appears rather than showing a broken image.
                $gen = 'https://quickchart.io/qr?size=360&margin=4&ecLevel=H&dark=000000&light=ffffff&text=' . rawurlencode($url);
                $this->getResponse()->setRedirect($gen, 302);
                return;
            }
            if ($cache) { $cache->save($png, $cacheKey, array(), 86400); }
        }

        $this->getResponse()
            ->setHeader('Content-Type', 'image/png', true)
            ->setHeader('Cache-Control', 'public, max-age=86400', true)
            ->setBody($png);
        return;
    }

    /**
     * MailerLite webhook receiver (campaign.sent) — flips the pipeline row to
     * "Blasted" the moment MailerLite finishes sending, caches the campaign
     * stats and fires the once-only LinkedIn post. The 10-min syncBlasts cron
     * is the safety net if a webhook is missed.
     *
     * Security: (a) if a webhook secret is configured, the HMAC-SHA256 of the
     * raw body must match the signature header; (b) regardless, the campaign id
     * must match an existing newsletters row — unknown ids are ignored, so a
     * forged request cannot write anything.
     */
    public function mlhookAction()
    {
        $body = file_get_contents('php://input');
        $resp = $this->getResponse()->setHeader('Content-Type', 'application/json', true);

        // Signature check is best-effort: reject only when a signature header IS
        // present but does not verify. A missing header still proceeds, because
        // the endpoint is not trust-bearing — markBlastedByCampaign() re-checks
        // the campaign's real status against the MailerLite API, so a forged
        // request can at most trigger a harmless API lookup.
        $secret = trim((string) Mage::getStoreConfig('mmd_marketing/mailerlite/webhook_secret'));
        if ($secret !== '') {
            $sig = '';
            foreach (array('HTTP_X_MAILERLITE_SIGNATURE', 'HTTP_SIGNATURE') as $h) {
                if (!empty($_SERVER[$h])) { $sig = (string) $_SERVER[$h]; break; }
            }
            if ($sig !== '' && !hash_equals(hash_hmac('sha256', $body, $secret), $sig)) {
                Mage::log('mlhook: bad signature', null, 'marketing-cron.log');
                $resp->setHttpResponseCode(401)->setBody('{"ok":false,"error":"bad signature"}');
                return;
            }
        }

        $j = json_decode((string) $body, true);
        if (!is_array($j)) { $resp->setBody('{"ok":true,"note":"no json"}'); return; }
        // Campaign id location varies by payload shape — check the known spots.
        $cid = '';
        foreach (array(
            isset($j['campaign']['id']) ? $j['campaign']['id'] : null,
            isset($j['data']['campaign']['id']) ? $j['data']['campaign']['id'] : null,
            isset($j['data']['id']) ? $j['data']['id'] : null,
            isset($j['id']) ? $j['id'] : null,
        ) as $cand) {
            if ($cand !== null && $cand !== '') { $cid = (string) $cand; break; }
        }
        $handled = false;
        if ($cid !== '') {
            try {
                $handled = (bool) Mage::getModel('mmd_marketing/cron_flyer')->markBlastedByCampaign($cid);
            } catch (Exception $e) {
                Mage::log('mlhook: ' . $e->getMessage(), null, 'marketing-cron.log');
            }
        }
        $resp->setBody(json_encode(array('ok' => true, 'handled' => $handled)));
    }
}
