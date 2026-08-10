<?php
/**
 * Mail diagnostics — bypasses every silent try/catch in the SMTPPro stack
 * and reports what the SMTP transport actually does when asked to send.
 *
 * Visit:  /<frontName>/mmd_email_adminhtml_maildiagnose/index
 * Send:   /<frontName>/mmd_email_adminhtml_maildiagnose/send?to=you@example.com
 *
 * The "send" action constructs a Zend_Mail_Transport_Smtp directly using the
 * same config SMTPPro reads, so we see the exact connect/auth/handshake
 * errors instead of the swallowed exception that landed in var/log.
 */
class MMD_Email_Adminhtml_MaildiagnoseController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return true;
    }

    /**
     * Per-website SMTP cards exposed in the Credentials panel. Keys are
     * the website codes; ids must match core_website.website_id.
     *
     * Singapore is included as a fallback path: SG primary transport is
     * Gmail OAuth (configured in the Google OAuth card above), but if the
     * OAuth token is revoked / quota hits / Gmail API is unreachable, the
     * order-email path falls back to whatever SMTP creds are saved here.
     */
    protected $_smtpWebsites = array(
        // One store per site — Nigeria (website 4) retired, card removed
        // 2026-08-10 (its website id no longer exists on any instance).
        'singapore' => array('id' => 1, 'label' => 'Singapore (fallback)'),
    );

    /**
     * Field-suffix → SMTPPro config path. Used by both the save action
     * and the credentials-panel render. SMTPPro stores everything under
     * `smtppro/general/*`; `option` is the connection mode
     * (`disabled` | `smtp` | `google` | `ses` | `sendgrid`).
     */
    protected $_smtpFields = array(
        'enabled'  => 'smtppro/general/option',
        'host'     => 'smtppro/general/smtp_host',
        'port'     => 'smtppro/general/smtp_port',
        'ssl'      => 'smtppro/general/smtp_ssl',
        'auth'     => 'smtppro/general/smtp_authentication',
        'username' => 'smtppro/general/smtp_username',
        'password' => 'smtppro/general/smtp_password',
    );

    /**
     * Public accessors so the dashboard template can render cards without
     * duplicating the website / field maps.
     * @return array<string, array{id:int,label:string}>
     */
    public function getSmtpWebsites()
    {
        return $this->_smtpWebsites;
    }
    /**
     * @return array<string, string>
     */
    public function getSmtpFields()
    {
        return $this->_smtpFields;
    }

    /**
     * Persist credentials submitted from the dashboard Credentials panel.
     * Accepts POST with form_key, ignores empty fields and unchanged masked
     * values (so users can leave secrets alone). Writes to default scope and
     * clears any matching website-1 overrides so the new value actually wins.
     */
    public function savecredsAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);

        if (!$this->getRequest()->isPost()) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'POST required']));
            return;
        }

        // Form-key check (same as the rest of admin).
        $postedKey = (string) $this->getRequest()->getPost('form_key');
        $sessionKey = (string) Mage::getSingleton('core/session')->getFormKey();
        if ($postedKey === '' || $postedKey !== $sessionKey) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'invalid form key']));
            return;
        }

        // Map form fields → config paths. Each entry: input_name → core_config path.
        $map = [
            'anthropic_key'        => 'mmd_marketing/api/anthropic_key',
            'anthropic_model'      => 'mmd_marketing/api/anthropic_model',
            'mailerlite_key'       => 'mmd_marketing/api/mailerlite_key',
            'from_name'            => 'mmd_marketing/api/from_name',
            'from_email'           => 'mmd_marketing/api/from_email',
            'gmail_user'           => 'mmd_email/google/user',
            'gmail_client_id'      => 'mmd_email/google/client_id',
            'gmail_client_secret'  => 'mmd_email/google/client_secret',
            'gmail_refresh_token'  => 'mmd_email/google/refresh_token',
            'kael_review_key'      => 'mmd_company/api/kael_review_key',
            'whatsapp_singapore'   => 'mmd_company/whatsapp/singapore',
        ];

        try {
            $cfg = Mage::getConfig();
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $table = Mage::getSingleton('core/resource')->getTableName('core/config_data');
            $touched = [];

            foreach ($map as $field => $path) {
                if (!$this->getRequest()->has($field)) continue;
                $val = (string) $this->getRequest()->getPost($field);
                // Ignore values still showing the masked placeholder — user
                // didn't touch them, keep DB row as-is.
                if (strpos($val, '•') !== false) continue;
                $val = trim($val);
                $cfg->saveConfig($path, $val, 'default', 0);
                $touched[] = $path;
            }

            // Wipe website-1 overrides on the same paths so default-scope wins.
            if (!empty($touched)) {
                $write->delete($table, [
                    'scope = ?'    => 'websites',
                    'scope_id = ?' => 1,
                    'path IN (?)'  => $touched,
                ]);
            }

            // Per-website SMTP cards (Nigeria).
            // Fields are `smtp_<code>_<field>` and each writes to
            // smtppro/general/* at scope=websites, scope_id=<website_id>.
            // Passwords go through core/encrypt before they hit the row so
            // SMTPPro's runtime decrypt round-trip works as it does for the
            // default-scope creds. An empty masked password is skipped.
            //
            // Trap-guard: SMTPPro's `option` toggle is easy to miss. If the
            // user fills host + username but forgets the Enable checkbox,
            // the website inherits `option=disabled` from default scope and
            // mail silently never sends. So we ignore the checkbox when
            // deciding the option: if host AND username come through with
            // non-empty values, force option='smtp'. Only if BOTH are
            // explicitly cleared do we write option='disabled'.
            $smtpTouched = [];
            foreach ($this->_smtpWebsites as $code => $w) {
                $wid = (int) $w['id'];
                $resolvedHost = null;
                $resolvedUser = null;
                foreach ($this->_smtpFields as $suffix => $path) {
                    if ($suffix === 'enabled') continue; // handled below from host/user state
                    $field = 'smtp_' . $code . '_' . $suffix;
                    if (!$this->getRequest()->has($field)) continue;
                    $val = (string) $this->getRequest()->getPost($field);
                    if (strpos($val, '•') !== false) continue; // masked, untouched
                    $val = trim($val);
                    if ($suffix === 'password' && $val !== '') {
                        $val = Mage::helper('core')->encrypt($val);
                    }
                    if ($suffix === 'host')     $resolvedHost = $val;
                    if ($suffix === 'username') $resolvedUser = $val;
                    $cfg->saveConfig($path, $val, 'websites', $wid);
                    $smtpTouched[] = $code . ':' . $path;
                }

                // Resolve the post-save host+username (use the newly written
                // values when present, otherwise fall back to the already-
                // saved website-scope rows) and flip option accordingly.
                if ($this->getRequest()->has('smtp_' . $code . '_host')
                    || $this->getRequest()->has('smtp_' . $code . '_username')
                    || $this->getRequest()->has('smtp_' . $code . '_enabled')) {
                    $store = Mage::app()->getWebsite($wid)->getDefaultStore();
                    $sid   = $store ? (int) $store->getId() : 0;
                    if ($resolvedHost === null) {
                        $resolvedHost = (string) Mage::getStoreConfig('smtppro/general/smtp_host', $sid);
                    }
                    if ($resolvedUser === null) {
                        $resolvedUser = (string) Mage::getStoreConfig('smtppro/general/smtp_username', $sid);
                    }
                    // Explicit Disable wins; otherwise host+username present → enable.
                    $explicitOff = $this->getRequest()->has('smtp_' . $code . '_enabled')
                        && (string) $this->getRequest()->getPost('smtp_' . $code . '_enabled') === '0'
                        && ($resolvedHost === '' && $resolvedUser === '');
                    $shouldEnable = ($resolvedHost !== '' && $resolvedUser !== '') && !$explicitOff;
                    $optionVal = $shouldEnable ? 'smtp' : 'disabled';
                    $cfg->saveConfig('smtppro/general/option', $optionVal, 'websites', $wid);
                    $smtpTouched[] = $code . ':smtppro/general/option=' . $optionVal;
                }
            }

            Mage::app()->getCacheInstance()->cleanType('config');
            Mage::app()->cleanCache();

            $this->getResponse()->setBody(json_encode([
                'ok'          => true,
                'saved'       => $touched,
                'smtp_saved'  => $smtpTouched,
            ]));
        } catch (Exception $e) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => $e->getMessage()]));
        }
    }

    /**
     * Reveal the decrypted SMTP password for a single website so the
     * operator can copy it (e.g. to set up the same App Password on
     * production after first saving it on local). Admin-auth protected
     * (controller extends Mage_Adminhtml_Controller_Action) and form-key
     * gated, so it can't be hit by anyone outside an authenticated admin
     * session. POST only.
     *
     * POST /maildiagnose/revealsmtp  body: website=<code>&form_key=…
     * Returns JSON {ok, password|error}.
     */
    public function revealsmtpAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);

        $postedKey = (string) $this->getRequest()->getPost('form_key');
        $sessionKey = (string) Mage::getSingleton('core/session')->getFormKey();
        if (!$this->getRequest()->isPost() || $postedKey === '' || $postedKey !== $sessionKey) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'invalid request']));
            return;
        }

        $code = (string) $this->getRequest()->getPost('website');
        if (!isset($this->_smtpWebsites[$code])) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'unknown website']));
            return;
        }

        try {
            $wid     = (int) $this->_smtpWebsites[$code]['id'];
            $storeId = (int) Mage::app()->getWebsite($wid)->getDefaultStore()->getId();

            // Aschroder's smtp_password field is registered in system.xml
            // with backend_model = adminhtml/system_config_backend_encrypted,
            // so Magento auto-decrypts it on read via getStoreConfig. We just
            // need to return what getStoreConfig gives us — calling decrypt()
            // again on that plaintext would produce garbage. Fall back to a
            // direct decrypt of the raw DB row only if the auto-decrypted
            // value looks like base64-encoded ciphertext (defensive against
            // older rows saved without the backend_model in effect).
            $plain = (string) Mage::getStoreConfig('smtppro/general/smtp_password', $storeId);
            if ($plain === '') {
                $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'no password saved']));
                return;
            }
            // Defensive: if what we got back still looks like base64 ciphertext
            // (no spaces, all base64 alphabet, length divisible by 4), try a
            // manual decrypt as a fallback. Real App Passwords contain spaces.
            if (strpos($plain, ' ') === false
                && preg_match('/^[A-Za-z0-9+\/=]+$/', $plain)
                && strlen($plain) % 4 === 0
                && strlen($plain) > 24) {
                try {
                    $maybe = Mage::helper('core')->decrypt($plain);
                    if ($maybe !== '' && preg_match('/^[\x20-\x7e]+$/', $maybe)) {
                        $plain = $maybe;
                    }
                } catch (Exception $ignored) {}
            }
            $this->getResponse()->setBody(json_encode(['ok' => true, 'password' => $plain]));
        } catch (Exception $e) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => $e->getMessage()]));
        }
    }

    /**
     * Whitelisted credential paths the reveal endpoint will serve.
     * Keyed by the field name used in the Credentials panel inputs, so
     * the JS can pass a symbolic name and the server resolves to the
     * real core_config_data path. Anything not in this list is rejected
     * — we never echo arbitrary config back to the client.
     */
    protected $_revealableCreds = array(
        'anthropic_key'       => 'mmd_marketing/api/anthropic_key',
        'mailerlite_key'      => 'mmd_marketing/api/mailerlite_key',
        'kael_review_key'     => 'mmd_company/api/kael_review_key',
        'gmail_client_id'     => 'mmd_email/google/client_id',
        'gmail_client_secret' => 'mmd_email/google/client_secret',
        'gmail_refresh_token' => 'mmd_email/google/refresh_token',
    );

    /**
     * Generic reveal for the partial-mask credential cards (API keys +
     * Google OAuth secrets). Sister of revealsmtpAction but for the
     * default-scope config rows the Credentials panel writes. Admin-auth
     * (controller class) + form-key gated.
     *
     * POST /maildiagnose/revealcred  body: field=<symbolic>&form_key=…
     * Returns JSON {ok, value|error}.
     */
    public function revealcredAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);

        $postedKey = (string) $this->getRequest()->getPost('form_key');
        $sessionKey = (string) Mage::getSingleton('core/session')->getFormKey();
        if (!$this->getRequest()->isPost() || $postedKey === '' || $postedKey !== $sessionKey) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'invalid request']));
            return;
        }

        $field = (string) $this->getRequest()->getPost('field');
        if (!isset($this->_revealableCreds[$field])) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'field not revealable']));
            return;
        }

        try {
            $value = (string) Mage::getStoreConfig($this->_revealableCreds[$field]);
            if ($value === '') {
                $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'no value saved']));
                return;
            }
            $this->getResponse()->setBody(json_encode(['ok' => true, 'value' => $value]));
        } catch (Exception $e) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => $e->getMessage()]));
        }
    }

    /**
     * Send a real test email through a single website's SMTP configuration.
     * Wired to a "Test" button on each per-website SMTP card in the
     * Credentials panel. Builds Zend_Mail_Transport_Smtp directly from the
     * website-scope `smtppro/general/*` rows we just saved, so the round
     * trip mirrors what a real Magento order/contact-us send would do —
     * without depending on Aschroder's own test controller (which is
     * scope-aware via the System Configuration page only).
     *
     * POST /maildiagnose/testsmtp  body: website=<code>&to=<email>&form_key=…
     *
     * Returns JSON {ok, message|error, elapsed_ms, host, port}.
     */
    public function testsmtpAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);

        $postedKey = (string) $this->getRequest()->getPost('form_key');
        $sessionKey = (string) Mage::getSingleton('core/session')->getFormKey();
        if (!$this->getRequest()->isPost() || $postedKey === '' || $postedKey !== $sessionKey) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'invalid request']));
            return;
        }

        $code = (string) $this->getRequest()->getPost('website');
        $to   = trim((string) $this->getRequest()->getPost('to'));

        if (!isset($this->_smtpWebsites[$code])) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'unknown website']));
            return;
        }
        if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
            $this->getResponse()->setBody(json_encode(['ok' => false, 'error' => 'invalid recipient email']));
            return;
        }

        try {
            // Read at the website's default store so per-website overrides
            // resolve the way SMTPPro sees them at send time.
            $wid     = (int) $this->_smtpWebsites[$code]['id'];
            $storeId = (int) Mage::app()->getWebsite($wid)->getDefaultStore()->getId();

            $host = trim((string) Mage::getStoreConfig('smtppro/general/smtp_host', $storeId));
            $port = (int) Mage::getStoreConfig('smtppro/general/smtp_port', $storeId);
            $ssl  = (string) Mage::getStoreConfig('smtppro/general/smtp_ssl', $storeId);
            $auth = (string) Mage::getStoreConfig('smtppro/general/smtp_authentication', $storeId);
            $user = (string) Mage::getStoreConfig('smtppro/general/smtp_username', $storeId);
            $pass = (string) Mage::getStoreConfig('smtppro/general/smtp_password', $storeId);
            $option = (string) Mage::getStoreConfig('smtppro/general/option', $storeId);

            if ($host === '' || !$port) {
                throw new Exception('SMTP host / port not configured for ' . $code . ' — fill the form and Save first.');
            }
            if ($option === 'disabled') {
                throw new Exception('SMTPPro is disabled for ' . $code . ' — toggle "Enabled" on, Save, then Test.');
            }

            $transportConfig = array('port' => $port);
            if ($auth !== '' && $auth !== 'none') {
                $transportConfig['auth']     = $auth;
                $transportConfig['username'] = $user;
                $transportConfig['password'] = $pass;
            }
            if ($ssl !== '' && $ssl !== 'none') {
                $transportConfig['ssl'] = $ssl;
            }

            $fromEmail = (string) Mage::getStoreConfig('trans_email/ident_general/email', $storeId);
            $fromName  = (string) Mage::getStoreConfig('trans_email/ident_general/name', $storeId);
            if ($fromEmail === '') $fromEmail = $user;
            if ($fromName === '')  $fromName  = 'Tertiary Infotech Academy';

            $t0   = microtime(true);
            $transport = new Zend_Mail_Transport_Smtp($host, $transportConfig);

            $mail = new Zend_Mail('utf-8');
            $mail->setFrom($fromEmail, $fromName);
            $mail->addTo($to);
            $mail->setSubject('SMTP test (' . ucfirst($code) . ') — ' . date('Y-m-d H:i:s'));
            $mail->setBodyHtml(
                '<p>This is a one-shot SMTP test from the <strong>' . htmlspecialchars(ucfirst($code)) . '</strong> store.</p>'
                . '<p>Host: ' . htmlspecialchars($host) . ':' . $port . ' (' . htmlspecialchars($ssl ?: 'plain') . ', auth=' . htmlspecialchars($auth ?: 'none') . ')</p>'
                . '<p>If you can read this in your inbox, real order-confirmation + contact-us mail will follow the same path.</p>'
            );
            $mail->send($transport);

            $this->getResponse()->setBody(json_encode([
                'ok'         => true,
                'message'    => 'Accepted by ' . $host . ':' . $port . ' for ' . $to,
                'host'       => $host,
                'port'       => $port,
                'elapsed_ms' => (int) round((microtime(true) - $t0) * 1000),
            ]));
        } catch (Exception $e) {
            $this->getResponse()->setBody(json_encode([
                'ok'        => false,
                'error'     => $e->getMessage(),
                'exception' => get_class($e),
            ]));
        }
    }

    public function indexAction()
    {
        $this->_emit($this->_collectConfig());
    }

    /**
     * One-shot credential writer. The admin form save path is racy enough
     * across scope and cache that two attempts in a row can land on the
     * wrong row; this writes default-scope smtp_username + smtp_password
     * directly, encrypting under the running environment's key (so it
     * round-trips correctly through getStoreConfig later) and clears the
     * config cache.
     *
     *   /maildiagnose/setcreds?username=foo@bar&password=secret
     *
     * Returns the JSON the index action would return, after the write,
     * so you can see the new effective config in the same hop.
     */
    public function setcredsAction()
    {
        $username = trim((string) $this->getRequest()->getParam('username'));
        $password = (string) $this->getRequest()->getParam('password');
        // Optional — change the SMTP relay host too. Needed when migrating
        // from one mail provider (e.g. cPanel) to another (e.g. Gmail).
        // Pass ?host=smtp.gmail.com&port=587&ssl=tls in one shot.
        $host = trim((string) $this->getRequest()->getParam('host'));
        $port = trim((string) $this->getRequest()->getParam('port'));
        $ssl  = trim((string) $this->getRequest()->getParam('ssl'));   // 'tls' | 'ssl' | 'none'
        $auth = trim((string) $this->getRequest()->getParam('auth'));  // 'login' | 'plain' | 'crammd5' | 'none'

        if ($username === '' || $password === '') {
            $this->_emit(['error' => 'Pass ?username=<email>&password=<plain> [&host=<smtp_host>&port=<587>&ssl=tls&auth=login]']);
            return;
        }

        try {
            $encrypted = Mage::helper('core')->encrypt($password);
            $cfg = Mage::getConfig();
            $cfg->saveConfig('smtppro/general/smtp_username', $username, 'default', 0);
            $cfg->saveConfig('smtppro/general/smtp_password', $encrypted, 'default', 0);

            $optionalPaths = ['smtppro/general/smtp_username', 'smtppro/general/smtp_password'];
            if ($host !== '') {
                $cfg->saveConfig('smtppro/general/smtp_host', $host, 'default', 0);
                $optionalPaths[] = 'smtppro/general/smtp_host';
            }
            if ($port !== '') {
                $cfg->saveConfig('smtppro/general/smtp_port', $port, 'default', 0);
                $optionalPaths[] = 'smtppro/general/smtp_port';
            }
            if ($ssl !== '') {
                $cfg->saveConfig('smtppro/general/smtp_ssl', $ssl, 'default', 0);
                $optionalPaths[] = 'smtppro/general/smtp_ssl';
            }
            if ($auth !== '') {
                $cfg->saveConfig('smtppro/general/smtp_authentication', $auth, 'default', 0);
                $optionalPaths[] = 'smtppro/general/smtp_authentication';
            }

            // Belt-and-suspenders: also wipe any website-1 overrides on the
            // same paths so the default-scope values we just wrote actually
            // win at the storefront scope.
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $table = Mage::getSingleton('core/resource')->getTableName('core/config_data');
            $write->delete($table, [
                'scope = ?'    => 'websites',
                'scope_id = ?' => 1,
                'path IN (?)'  => $optionalPaths,
            ]);

            Mage::app()->getCacheInstance()->cleanType('config');
            Mage::app()->cleanCache();
        } catch (Exception $e) {
            $this->_emit(['error' => $e->getMessage(), 'exception' => get_class($e)]);
            return;
        }

        $report = $this->_collectConfig();
        $report['setcreds_result'] = 'OK — credentials saved at default scope and website-1 overrides cleared. Hit /send?to=... to verify.';
        $this->_emit($report);
    }

    /**
     * Tail the marketing.log file as JSON so we can diagnose newsletter
     * errors without shell access. Default last 80 lines, override with
     * ?lines=N. Bounded so we never spam huge logs into a JSON response.
     */
    public function marketinglogAction()
    {
        $path = Mage::getBaseDir('log') . DIRECTORY_SEPARATOR . 'marketing.log';
        $lines = max(1, min(500, (int) $this->getRequest()->getParam('lines', 80)));
        $report = [
            'path'   => $path,
            'exists' => file_exists($path),
            'size'   => file_exists($path) ? filesize($path) : 0,
        ];
        if ($report['exists']) {
            $content = @file_get_contents($path);
            if ($content !== false) {
                $arr = preg_split("/\r?\n/", $content);
                $arr = array_slice($arr, -$lines);
                $report['tail'] = implode("\n", $arr);
            }
        }
        $this->_emit($report);
    }

    /**
     * Inspect what the Anthropic / MailerLite credentials Magento has
     * cached actually look like (length, prefix/suffix, has whitespace).
     * Masks the secret in the middle so the page is safe to paste back.
     */
    /**
     * One-shot Gmail OAuth2 credential writer. Sister of /setcreds for
     * SMTP. Paste the four values into the URL and they land in
     * core_config_data without ever passing through git — keeps GitHub
     * push protection happy and avoids permanent credential exposure in
     * commit history.
     *
     *   /maildiagnose/setgmail?user=...&client_id=...&client_secret=...&refresh_token=...
     */
    public function setgmailAction()
    {
        $user         = trim((string) $this->getRequest()->getParam('user'));
        $clientId     = trim((string) $this->getRequest()->getParam('client_id'));
        $clientSecret = trim((string) $this->getRequest()->getParam('client_secret'));
        $refreshToken = trim((string) $this->getRequest()->getParam('refresh_token'));

        $missing = array();
        if ($user === '')         $missing[] = 'user';
        if ($clientId === '')     $missing[] = 'client_id';
        if ($clientSecret === '') $missing[] = 'client_secret';
        if ($refreshToken === '') $missing[] = 'refresh_token';
        if (!empty($missing)) {
            $this->_emit(['error' => 'Missing: ' . implode(', ', $missing) . '. Pass all four: ?user=&client_id=&client_secret=&refresh_token=']);
            return;
        }

        try {
            $cfg = Mage::getConfig();
            $cfg->saveConfig('mmd_email/google/user',          $user,         'default', 0);
            $cfg->saveConfig('mmd_email/google/client_id',     $clientId,     'default', 0);
            $cfg->saveConfig('mmd_email/google/client_secret', $clientSecret, 'default', 0);
            $cfg->saveConfig('mmd_email/google/refresh_token', $refreshToken, 'default', 0);
            Mage::app()->getCacheInstance()->cleanType('config');
            Mage::app()->cleanCache();
        } catch (Exception $e) {
            $this->_emit(['error' => $e->getMessage(), 'exception' => get_class($e)]);
            return;
        }

        // Try a token-refresh round-trip so we surface scope / credential
        // problems right here instead of waiting for the next order.
        $tokenTest = null;
        try {
            $token = Mage::helper('mmd_email/gmail')->getAccessToken();
            $tokenTest = ['ok' => true, 'access_token_length' => strlen((string) $token)];
        } catch (Exception $e) {
            $tokenTest = ['ok' => false, 'error' => $e->getMessage()];
        }

        $this->_emit([
            'setgmail_result' => 'OK — Gmail OAuth2 credentials saved at default scope.',
            'token_test'      => $tokenTest,
            'note'            => $tokenTest['ok']
                ? 'Credentials work. Place a test order to verify end-to-end.'
                : 'Credentials saved but token refresh failed — see token_test.error for the reason (often scope / revoked token).',
        ]);
    }

    /**
     * Store (or clear) the domain-wide-delegated service-account key that
     * the Gmail helper prefers over the user refresh token. POST the full
     * key JSON (as downloaded from Google Cloud Console) in the `sa_json`
     * field — never a GET query string, the private key is too large and
     * would land in access logs. Pass clear=1 to remove the key and fall
     * back to the refresh-token flow.
     *
     *   POST /maildiagnose/setgmailsa   body: sa_json=<key json>
     *   POST /maildiagnose/setgmailsa   body: clear=1
     *
     * One-time prerequisites in Google Workspace Admin → Security → API
     * Controls → Domain-wide Delegation: the SA's OAuth2 client id must be
     * granted scope https://www.googleapis.com/auth/gmail.send.
     */
    public function setgmailsaAction()
    {
        if (!$this->getRequest()->isPost()) {
            $this->_emit(['error' => 'POST required — send the key JSON as sa_json=<...> (or clear=1).']);
            return;
        }

        if ((string) $this->getRequest()->getPost('clear') === '1') {
            try {
                Mage::getConfig()->saveConfig('mmd_email/google/sa_key', '', 'default', 0);
                Mage::app()->getCacheInstance()->cleanType('config');
                Mage::app()->cleanCache();
            } catch (Exception $e) {
                $this->_emit(['error' => $e->getMessage()]);
                return;
            }
            $this->_emit(['setgmailsa_result' => 'OK — service-account key cleared; Gmail falls back to the refresh-token flow.']);
            return;
        }

        $raw = trim((string) $this->getRequest()->getPost('sa_json'));
        if ($raw === '') {
            $this->_emit(['error' => 'Missing sa_json — POST the full service-account key JSON.']);
            return;
        }
        $key = json_decode($raw, true);
        if (!is_array($key)
            || (isset($key['type']) ? $key['type'] : '') !== 'service_account'
            || empty($key['client_email'])
            || empty($key['private_key'])) {
            $this->_emit(['error' => 'sa_json is not a valid service-account key (need type=service_account, client_email, private_key).']);
            return;
        }

        try {
            Mage::getConfig()->saveConfig('mmd_email/google/sa_key', $raw, 'default', 0);
            Mage::app()->getCacheInstance()->cleanType('config');
            Mage::app()->cleanCache();
        } catch (Exception $e) {
            $this->_emit(['error' => $e->getMessage(), 'exception' => get_class($e)]);
            return;
        }

        // Round-trip a token so DWD / scope problems surface immediately.
        // getAccessToken() prefers the SA path we just saved.
        $tokenTest = null;
        try {
            $token = Mage::helper('mmd_email/gmail')->getAccessToken();
            $tokenTest = ['ok' => true, 'access_token_length' => strlen((string) $token)];
        } catch (Exception $e) {
            $tokenTest = ['ok' => false, 'error' => $e->getMessage()];
        }

        $this->_emit([
            'setgmailsa_result' => 'OK — service-account key saved (' . $key['client_email'] . '). Gmail now prefers it over the refresh token.',
            'impersonating'     => (string) Mage::getStoreConfig('mmd_email/google/user'),
            'token_test'        => $tokenTest,
            'note'              => $tokenTest['ok']
                ? 'Service-account token works. Sends are now immune to refresh-token expiry/revocation.'
                : 'Key saved but the token grant failed — usually the DWD grant (client id + gmail.send scope) is missing in Workspace Admin, or the impersonated user is not a Workspace mailbox.',
        ]);
    }

    public function marketingcfgAction()
    {
        // Clear Magento's config cache so we read the fresh value from DB,
        // not whatever's stuck in cache from before the user updated it.
        Mage::app()->getCacheInstance()->cleanType('config');

        $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $report = ['cache_cleared' => true];
        foreach (['anthropic_key', 'mailerlite_key', 'anthropic_model', 'from_email', 'from_name'] as $k) {
            $v = isset($cfg[$k]) ? (string) $cfg[$k] : '';
            $rawLen = strlen($v);
            $trim   = trim($v);
            $report[$k] = [
                'raw_length'    => $rawLen,
                'trim_length'   => strlen($trim),
                'has_whitespace_around' => $rawLen !== strlen($trim),
                'prefix'        => $trim === '' ? '' : substr($trim, 0, 12),
                'suffix'        => $trim === '' || strlen($trim) <= 6 ? '' : substr($trim, -6),
                'masked'        => $trim === '' ? '(empty)' : (strlen($trim) <= 14
                    ? str_repeat('*', strlen($trim))
                    : substr($trim, 0, 8) . str_repeat('*', max(0, strlen($trim) - 14)) . substr($trim, -6)),
            ];
        }
        $report['note'] = 'Compare the prefix/suffix of anthropic_key against the key you pasted from console.anthropic.com. Anthropic keys start with "sk-ant-".';
        $this->_emit($report);
    }

    public function sendAction()
    {
        $to = trim((string) $this->getRequest()->getParam('to'));
        $report = $this->_collectConfig();
        $report['send_test'] = ['to' => $to];

        if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
            $report['send_test']['error'] = 'Pass ?to=<valid email>';
            $this->_emit($report);
            return;
        }

        $cfg = $report['effective_config'];
        try {
            $transportConfig = ['port' => $cfg['port']];
            if ($cfg['authentication'] && $cfg['authentication'] !== 'none') {
                $transportConfig['auth']     = $cfg['authentication'];
                $transportConfig['username'] = $cfg['username'];
                $transportConfig['password'] = (string) Mage::getStoreConfig('smtppro/general/smtp_password');
            }
            if ($cfg['ssl'] && $cfg['ssl'] !== 'none') {
                $transportConfig['ssl'] = $cfg['ssl'];
            }

            $t0 = microtime(true);
            $transport = new Zend_Mail_Transport_Smtp($cfg['host'], $transportConfig);

            $mail = new Zend_Mail('utf-8');
            $mail->setFrom($cfg['from_email'], $cfg['from_name']);
            $mail->addTo($to);
            $mail->setSubject('MMD mail diagnostic ' . date('Y-m-d H:i:s'));
            $mail->setBodyText("If you're reading this, SMTP from the Coolify-hosted box reached your inbox.");
            $mail->send($transport);

            $report['send_test']['result']     = 'OK — accepted by ' . $cfg['host'] . ':' . $cfg['port'];
            $report['send_test']['elapsed_ms'] = round((microtime(true) - $t0) * 1000);
        } catch (Exception $e) {
            $report['send_test']['error']        = $e->getMessage();
            $report['send_test']['exception']    = get_class($e);
            $report['send_test']['trace_first']  = strtok($e->getTraceAsString(), "\n");
        }

        $this->_emit($report);
    }

    /**
     * Probe the same mail server's IMAP-over-TLS endpoint with the same
     * credentials that SMTP is using. cPanel/Exim hosts share one password
     * across SMTP, IMAP, POP3 and webmail, so this disambiguates "password
     * actually wrong" from "SMTP-only lockout / SMTP-disabled-for-mailbox".
     *
     *   /maildiagnose/imapauth
     *
     * IMAP OK   → password is correct; SMTP failure is server-side
     *             (cPHulk lockout, outgoing-mail disabled for mailbox).
     * IMAP fail → password Magento has does not match the mailbox.
     */
    public function imapauthAction()
    {
        $report = $this->_collectConfig();
        $cfg    = $report['effective_config'];
        $host   = (string) $cfg['host'];
        $user   = (string) $cfg['username'];
        $pass   = (string) Mage::getStoreConfig('smtppro/general/smtp_password');

        $report['imap_auth_test'] = ['host' => $host, 'username' => $user];

        if ($host === '' || $user === '' || $pass === '') {
            $report['imap_auth_test']['error'] = 'host / username / password missing';
            $this->_emit($report);
            return;
        }

        // Try implicit TLS on 993 first; if that doesn't connect, fall
        // back to plain 143 with STARTTLS-less LOGIN (cPanel allows it
        // when "secure connection" is disabled).
        $candidates = [
            ['scheme' => 'tls',  'port' => 993],
            ['scheme' => 'tcp',  'port' => 143],
        ];

        $attempts = [];
        foreach ($candidates as $c) {
            $endpoint = $c['scheme'] . '://' . $host . ':' . $c['port'];
            $t0 = microtime(true);
            $errno = 0; $errstr = '';
            $sock = @stream_socket_client($endpoint, $errno, $errstr, 5,
                STREAM_CLIENT_CONNECT,
                stream_context_create(['ssl' => ['verify_peer' => false, 'verify_peer_name' => false]])
            );
            if (!$sock) {
                $attempts[] = ['endpoint' => $endpoint, 'connect' => 'failed', 'error' => $errstr ?: ('errno ' . $errno)];
                continue;
            }
            stream_set_timeout($sock, 5);
            $banner = trim((string) fgets($sock, 1024));

            // IMAP LOGIN — quote any " or \ in user/pass per RFC 3501.
            $qUser = '"' . str_replace(['\\', '"'], ['\\\\', '\\"'], $user) . '"';
            $qPass = '"' . str_replace(['\\', '"'], ['\\\\', '\\"'], $pass) . '"';
            fwrite($sock, "a1 LOGIN {$qUser} {$qPass}\r\n");

            $loginResp = '';
            $deadline = microtime(true) + 5;
            while (microtime(true) < $deadline) {
                $line = fgets($sock, 4096);
                if ($line === false) break;
                $loginResp .= $line;
                if (preg_match('/^a1 (OK|NO|BAD)\b/m', $line)) break;
            }
            @fwrite($sock, "a2 LOGOUT\r\n");
            @fclose($sock);

            $verdict = 'unknown';
            if (preg_match('/^a1 OK\b/m',  $loginResp)) $verdict = 'accepted';
            if (preg_match('/^a1 NO\b/m',  $loginResp)) $verdict = 'rejected';
            if (preg_match('/^a1 BAD\b/m', $loginResp)) $verdict = 'bad_request';

            $attempts[] = [
                'endpoint'    => $endpoint,
                'banner'      => $banner,
                'login_reply' => trim($loginResp),
                'verdict'     => $verdict,
                'elapsed_ms'  => round((microtime(true) - $t0) * 1000),
            ];

            if ($verdict === 'accepted' || $verdict === 'rejected') break;
        }

        $report['imap_auth_test']['attempts'] = $attempts;
        $accepted = false;
        foreach ($attempts as $a) {
            if (isset($a['verdict']) && $a['verdict'] === 'accepted') { $accepted = true; break; }
        }
        $report['imap_auth_test']['interpretation'] = $accepted
            ? 'Password is correct mailbox-side. SMTP rejection is a server-side block (cPHulk lockout, or "outgoing mail" disabled for this mailbox in cPanel > Email Accounts > Restrictions).'
            : 'Password Magento is sending does not match the mailbox. Re-set the password in cPanel and re-enter the SAME value via /maildiagnose/setcreds.';

        $this->_emit($report);
    }

    private function _collectConfig()
    {
        $store   = Mage::app()->getStore();
        $storeId = $store->getId();

        $get = function ($path) use ($storeId) {
            return Mage::getStoreConfig($path, $storeId);
        };

        // getStoreConfig() auto-decrypts encrypted backend fields, so the
        // value here is already plaintext. Don't expose it — mask all but
        // the first and last char to confirm "we're sending something" without
        // leaking the actual secret to anyone who can hit /maildiagnose.
        $passwordPlain = (string) $get('smtppro/general/smtp_password');
        $passwordMasked = $this->_mask($passwordPlain);

        return [
            'now'             => date('c'),
            'magento_store'   => $store->getCode() . ' (id=' . $storeId . ', website=' . $store->getWebsite()->getCode() . ')',
            'php_version'     => PHP_VERSION,
            'effective_config' => [
                'option'             => $get('smtppro/general/option'),
                'host'               => $get('smtppro/general/smtp_host'),
                'port'               => $get('smtppro/general/smtp_port'),
                'ssl'                => $get('smtppro/general/smtp_ssl'),
                'authentication'     => $get('smtppro/general/smtp_authentication'),
                'username'           => $get('smtppro/general/smtp_username'),
                'password_length'    => strlen($passwordPlain),
                'password_masked'    => $passwordMasked,
                'from_email'         => $get('trans_email/ident_sales/email'),
                'from_name'          => $get('trans_email/ident_sales/name'),
                'queue_usage'        => $get('smtppro/queue/usage'),
            ],
            'connect_test'    => $this->_tryConnect($get('smtppro/general/smtp_host'), (int) $get('smtppro/general/smtp_port')),
            'core_email_queue' => $this->_queueSnapshot(),
            'note'             => 'Hit /send?to=<email> to send a real test message. Errors will be shown here verbatim.',
        ];
    }

    private function _tryConnect($host, $port)
    {
        if (!$host || !$port) {
            return ['status' => 'skipped', 'reason' => 'no host/port configured'];
        }
        $t0 = microtime(true);
        $errno = 0;
        $errstr = '';
        $sock = @fsockopen($host, $port, $errno, $errstr, 5);
        $elapsed = round((microtime(true) - $t0) * 1000);
        if (!$sock) {
            return ['status' => 'failed', 'errno' => $errno, 'error' => $errstr, 'elapsed_ms' => $elapsed];
        }
        $banner = '';
        stream_set_timeout($sock, 3);
        $banner = (string) fgets($sock, 1024);
        @fclose($sock);
        return ['status' => 'ok', 'banner' => trim($banner), 'elapsed_ms' => $elapsed];
    }

    private function _queueSnapshot()
    {
        try {
            $read = Mage::getSingleton('core/resource')->getConnection('core_read');
            $table = Mage::getSingleton('core/resource')->getTableName('core/email_queue');
            $row = $read->fetchRow(
                "SELECT
                    COUNT(*) total,
                    SUM(processed_at IS NULL) unsent,
                    MAX(created_at) last_created,
                    MAX(processed_at) last_processed
                 FROM {$table}"
            );
            return $row ?: ['note' => 'queue table empty'];
        } catch (Exception $e) {
            return ['error' => $e->getMessage()];
        }
    }

    private function _mask($value)
    {
        $len = strlen($value);
        if ($len === 0) {
            return '';
        }
        if ($len <= 2) {
            return str_repeat('*', $len);
        }
        return $value[0] . str_repeat('*', $len - 2) . $value[$len - 1];
    }

    private function _emit(array $payload)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }

    // ------------------------------------------------------------------ //
    //  One-click Gmail OAuth renewal (Credentials panel "Renew via Google
    //  Sign-In" button). Replaces the OAuth Playground copy-paste dance:
    //
    //    gmailauth     → redirects to Google's consent screen using the
    //                    SAVED client_id (state nonce in the admin session)
    //    gmailcallback → exchanges the returned code server-side with the
    //                    saved client_secret, stores the new refresh token
    //                    (+ the authenticated mailbox), clears config cache
    //
    //  ONE-TIME prerequisite in Google Cloud Console: the OAuth client must
    //  list <base>/adminlogin/maildiagnose/gmailcallback/ as an Authorized
    //  redirect URI (the panel prints the exact URL for this site).
    //  The token exchange itself returns a working access token, so a
    //  successful callback IS the verification round-trip.
    // ------------------------------------------------------------------ //

    protected function _gmailRedirectUri()
    {
        $frontName = (string) Mage::getConfig()->getNode('admin/routers/adminhtml/args/frontName');
        return Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB) . $frontName . '/maildiagnose/gmailcallback/';
    }

    protected function _credentialsPanelUrl()
    {
        return Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('_query' => array('panel' => 'credentials')));
    }

    public function gmailauthAction()
    {
        $session  = Mage::getSingleton('adminhtml/session');
        $clientId = trim((string) Mage::getStoreConfig('mmd_email/google/client_id'));
        if ($clientId === '') {
            $session->addError('Save a Google Client ID first — the sign-in flow needs it.');
            $this->_redirectUrl($this->_credentialsPanelUrl());
            return;
        }

        $state = Mage::helper('core')->getRandomString(32);
        $session->setGmailOauthState($state);

        $params = array(
            'response_type' => 'code',
            'client_id'     => $clientId,
            'redirect_uri'  => $this->_gmailRedirectUri(),
            // mail.google.com is the scope the Gmail send helper uses;
            // openid+email lets us read WHICH mailbox was authenticated so
            // the saved "user" always matches the token's account.
            'scope'         => 'https://mail.google.com/ openid email',
            'access_type'   => 'offline',
            // prompt=consent forces Google to issue a NEW refresh token even
            // when the account previously consented (default re-auth returns
            // no refresh_token at all).
            'prompt'        => 'consent',
            'state'         => $state,
        );
        $loginHint = trim((string) Mage::getStoreConfig('mmd_email/google/user'));
        if ($loginHint !== '') {
            $params['login_hint'] = $loginHint;
        }
        $this->_redirectUrl('https://accounts.google.com/o/oauth2/v2/auth?' . http_build_query($params));
    }

    public function gmailcallbackAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        $request = $this->getRequest();

        $expectedState = (string) $session->getGmailOauthState();
        $session->unsGmailOauthState();

        if ($request->getParam('error')) {
            $session->addError('Google sign-in was cancelled or refused: ' . Mage::helper('core')->escapeHtml($request->getParam('error')));
            $this->_redirectUrl($this->_credentialsPanelUrl());
            return;
        }

        $code  = (string) $request->getParam('code');
        $state = (string) $request->getParam('state');
        if ($code === '' || $expectedState === '' || !hash_equals($expectedState, $state)) {
            $session->addError('Gmail renewal failed: invalid or expired sign-in state. Please click "Renew via Google Sign-In" again.');
            $this->_redirectUrl($this->_credentialsPanelUrl());
            return;
        }

        $clientId     = trim((string) Mage::getStoreConfig('mmd_email/google/client_id'));
        $clientSecret = trim((string) Mage::getStoreConfig('mmd_email/google/client_secret'));

        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query(array(
                'code'          => $code,
                'client_id'     => $clientId,
                'client_secret' => $clientSecret,
                'redirect_uri'  => $this->_gmailRedirectUri(),
                'grant_type'    => 'authorization_code',
            )),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 20,
        ));
        $raw  = curl_exec($ch);
        $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        $data = json_decode((string) $raw, true) ?: array();

        if ($http !== 200 || empty($data['refresh_token'])) {
            $why = isset($data['error_description']) ? $data['error_description']
                 : (isset($data['error']) ? $data['error'] : ('HTTP ' . $http));
            $session->addError('Gmail token exchange failed: ' . Mage::helper('core')->escapeHtml($why)
                . '. Check that the redirect URI shown on the Credentials panel is registered on the OAuth client in Google Cloud Console.');
            $this->_redirectUrl($this->_credentialsPanelUrl());
            return;
        }

        // The Gmail API sends as the AUTHENTICATED account, so keep the saved
        // mailbox in lockstep with the id_token's email claim.
        $email = '';
        if (!empty($data['id_token'])) {
            $parts = explode('.', (string) $data['id_token']);
            if (isset($parts[1])) {
                $claims = json_decode((string) base64_decode(strtr($parts[1], '-_', '+/')), true) ?: array();
                $email  = isset($claims['email']) ? trim((string) $claims['email']) : '';
            }
        }

        try {
            $cfg = Mage::getConfig();
            $cfg->saveConfig('mmd_email/google/refresh_token', $data['refresh_token'], 'default', 0);
            if ($email !== '') {
                $cfg->saveConfig('mmd_email/google/user', $email, 'default', 0);
            }
            Mage::app()->getCacheInstance()->cleanType('config');
        } catch (Exception $e) {
            Mage::logException($e);
            $session->addError('Google issued a token but saving it failed: ' . Mage::helper('core')->escapeHtml($e->getMessage()));
            $this->_redirectUrl($this->_credentialsPanelUrl());
            return;
        }

        $session->addSuccess('Gmail refresh token renewed' . ($email !== '' ? ' for ' . Mage::helper('core')->escapeHtml($email) : '')
            . ' — verified working (Google returned a live access token with it).');
        $this->_redirectUrl($this->_credentialsPanelUrl());
    }
}
