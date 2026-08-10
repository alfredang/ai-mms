<?php
/**
 * Gmail OAuth2 sender.
 *
 * Used in place of password-based SMTP because Google blocked "less
 * secure apps" / password logins for Gmail in 2022. The flow:
 *
 *   1. Read client_id, client_secret, refresh_token from core_config_data
 *      (saved on the Credentials page → Emails → Google → Gmail).
 *   2. POST to https://oauth2.googleapis.com/token with the refresh token
 *      to get a short-lived access token (1 hour TTL).
 *   3. Wrap the email as an RFC 2822 message, base64url-encode it, and
 *      POST to Gmail's REST API send endpoint with the access token.
 *
 * No SMTP, no password — Google's preferred path for Workspace mailboxes.
 *
 * Service account (preferred when configured): a Workspace domain-wide-
 * delegated service account key (mmd_email/google/sa_key, the full JSON)
 * mints access tokens by signing a JWT locally — no refresh token, no
 * user consent, nothing to expire or revoke on password changes. The
 * user-consent refresh-token flow above remains as fallback, so either
 * credential alone keeps mail flowing. DWD grant lives in Workspace
 * Admin → Security → API Controls → Domain-wide Delegation (scope
 * https://www.googleapis.com/auth/gmail.send).
 *
 * Token caching: getAccessToken() round-trips to Google every call, which
 * adds ~200ms per email. For now that's fine. If volume becomes an issue,
 * cache the access token in core/cache for ~3500 seconds (just under the
 * 3600s expiry).
 */
class MMD_Email_Helper_Gmail extends Mage_Core_Helper_Abstract
{
    const SA_SCOPE = 'https://www.googleapis.com/auth/gmail.send';

    /**
     * @return array{user:string, client_id:string, client_secret:string, refresh_token:string, sa_key:string}
     */
    public function getConfig()
    {
        return array(
            'user'          => trim((string) Mage::getStoreConfig('mmd_email/google/user')),
            'client_id'     => trim((string) Mage::getStoreConfig('mmd_email/google/client_id')),
            'client_secret' => trim((string) Mage::getStoreConfig('mmd_email/google/client_secret')),
            'refresh_token' => trim((string) Mage::getStoreConfig('mmd_email/google/refresh_token')),
            'sa_key'        => trim((string) Mage::getStoreConfig('mmd_email/google/sa_key')),
        );
    }

    /**
     * True when a usable credential set exists: the sending mailbox plus
     * either the service-account key or the full OAuth refresh-token
     * triple. The Observer checks this before bypassing the SMTP transport.
     */
    public function isConfigured()
    {
        $c = $this->getConfig();
        if ($c['user'] === '') {
            return false;
        }
        return $this->hasServiceAccount()
            || ($c['client_id'] !== '' && $c['client_secret'] !== '' && $c['refresh_token'] !== '');
    }

    /**
     * True when a structurally valid service-account key JSON is saved.
     */
    public function hasServiceAccount()
    {
        return $this->_saKey() !== null;
    }

    /**
     * Parse + validate the saved service-account key. Null when absent
     * or malformed (missing type/client_email/private_key).
     *
     * @return array|null
     */
    protected function _saKey()
    {
        $raw = trim((string) Mage::getStoreConfig('mmd_email/google/sa_key'));
        if ($raw === '') {
            return null;
        }
        $key = json_decode($raw, true);
        if (!is_array($key)
            || (isset($key['type']) ? $key['type'] : '') !== 'service_account'
            || empty($key['client_email'])
            || empty($key['private_key'])) {
            return null;
        }
        return $key;
    }

    /**
     * Singapore (and the admin panel, which is staffed by the SG team)
     * sends all transactional mail through Gmail OAuth2. Every other
     * country store stays on Aschroder SMTPPro, which uses the per-store
     * SMTP credentials still configured in core_config_data.
     *
     * @param int|string|Mage_Core_Model_Store|null $store
     * @return bool
     */
    public function isGmailStore($store = null)
    {
        try {
            $code = Mage::app()->getStore($store)->getCode();
        } catch (Exception $e) {
            return false;
        }
        return $code === 'singapore' || $code === 'admin';
    }

    /**
     * Get a fresh access token. Prefers the service account (self-signed
     * JWT — cannot expire like a user refresh token); falls back to the
     * user-consent refresh-token exchange when the SA is absent or fails,
     * so either credential alone keeps mail flowing.
     *
     * @return string Access token
     * @throws Exception
     */
    public function getAccessToken()
    {
        if (!$this->isConfigured()) {
            throw new Exception('Gmail OAuth2 not configured');
        }

        $saError = null;
        if ($this->hasServiceAccount()) {
            try {
                return $this->_getServiceAccountToken();
            } catch (Exception $e) {
                $saError = $e->getMessage();
                Mage::log('Gmail SA token failed, falling back to refresh token: ' . $saError, Zend_Log::WARN);
            }
        }

        $c = $this->getConfig();
        if ($c['client_id'] === '' || $c['client_secret'] === '' || $c['refresh_token'] === '') {
            throw new Exception('Gmail service-account token failed and no refresh-token fallback is configured: ' . $saError);
        }

        try {
            return $this->_getRefreshTokenToken();
        } catch (Exception $e) {
            throw new Exception($saError !== null
                ? 'Gmail auth failed on both paths. SA: ' . $saError . ' | Refresh: ' . $e->getMessage()
                : $e->getMessage());
        }
    }

    /**
     * Mint an access token from the domain-wide-delegated service account:
     * sign a JWT (RS256) claiming iss = the SA, sub = the impersonated
     * mailbox, scope = gmail.send, then swap it at the token endpoint.
     *
     * @return string Access token
     * @throws Exception
     */
    protected function _getServiceAccountToken()
    {
        $key  = $this->_saKey();
        $user = trim((string) Mage::getStoreConfig('mmd_email/google/user'));
        if ($key === null) {
            throw new Exception('Service-account key missing or malformed');
        }

        $now    = time();
        $b64url = function ($data) {
            return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
        };
        $segments = $b64url(json_encode(array('alg' => 'RS256', 'typ' => 'JWT')))
            . '.' . $b64url(json_encode(array(
                'iss'   => $key['client_email'],
                'sub'   => $user,
                'scope' => self::SA_SCOPE,
                'aud'   => 'https://oauth2.googleapis.com/token',
                'iat'   => $now,
                'exp'   => $now + 3600,
            )));

        $signature = '';
        if (!openssl_sign($segments, $signature, $key['private_key'], OPENSSL_ALGO_SHA256)) {
            throw new Exception('Service-account JWT signing failed: ' . openssl_error_string());
        }
        $jwt = $segments . '.' . $b64url($signature);

        return $this->_postToken(http_build_query(array(
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        )));
    }

    /**
     * Exchange the saved refresh token for a fresh access token.
     * Throws on auth failure so the caller can log a clear error.
     *
     * @return string Access token
     * @throws Exception
     */
    protected function _getRefreshTokenToken()
    {
        $c = $this->getConfig();

        return $this->_postToken(http_build_query(array(
            'client_id'     => $c['client_id'],
            'client_secret' => $c['client_secret'],
            'refresh_token' => $c['refresh_token'],
            'grant_type'    => 'refresh_token',
        )));
    }

    /**
     * POST a form-encoded grant to Google's token endpoint and return the
     * access token. Shared by the SA JWT-bearer and refresh-token grants.
     *
     * @param string $body application/x-www-form-urlencoded body
     * @return string Access token
     * @throws Exception
     */
    protected function _postToken($body)
    {
        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_HTTPHEADER     => array('content-type: application/x-www-form-urlencoded'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('Token endpoint unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !isset($rsp['access_token'])) {
            $msg = isset($rsp['error_description']) ? $rsp['error_description']
                 : (isset($rsp['error']) ? $rsp['error'] : substr($raw, 0, 300));
            throw new Exception('Gmail token grant failed (' . $code . '): ' . $msg);
        }
        return (string) $rsp['access_token'];
    }

    /**
     * Send an email via Gmail's REST API. Body is treated as HTML.
     *
     * @param string $to       Recipient email (single).
     * @param string $subject  Plain-text subject line.
     * @param string $bodyHtml HTML body.
     * @param string $fromName Optional display name; defaults to the configured user.
     * @return string Gmail message id
     * @throws Exception
     */
    public function send($to, $subject, $bodyHtml, $fromName = '', array $cc = array(), $replyTo = '')
    {
        $c = $this->getConfig();
        $from = $fromName !== '' ? '"' . str_replace('"', '\"', $fromName) . '" <' . $c['user'] . '>'
                                 : $c['user'];

        // RFC 2822 message. Use \r\n line endings as the RFC mandates —
        // Gmail's API parses these strictly.
        $headers = array(
            'From: ' . $from,
            'To: ' . $to,
            'Subject: ' . $this->_encodeHeader($subject),
            'MIME-Version: 1.0',
            'Content-Type: text/html; charset=UTF-8',
            'Content-Transfer-Encoding: quoted-printable',
        );
        $cc = array_values(array_filter(array_map('trim', $cc)));
        if (!empty($cc)) {
            $headers[] = 'Cc: ' . implode(', ', $cc);
        }
        if ($replyTo !== '') {
            $headers[] = 'Reply-To: ' . $replyTo;
        }
        $rfc = implode("\r\n", $headers) . "\r\n\r\n" . quoted_printable_encode($bodyHtml);

        // Gmail expects base64url (RFC 4648 §5) — '+' → '-', '/' → '_',
        // and no '=' padding.
        $raw = rtrim(strtr(base64_encode($rfc), '+/', '-_'), '=');

        $token = $this->getAccessToken();
        $userPath = urlencode($c['user']); // 'me' also works, but explicit is clearer.

        $ch = curl_init('https://gmail.googleapis.com/gmail/v1/users/' . $userPath . '/messages/send');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode(array('raw' => $raw)),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $token,
                'Content-Type: application/json',
            ),
        ));
        $rspRaw = curl_exec($ch);
        $code   = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err    = curl_error($ch);
        curl_close($ch);

        if ($rspRaw === false || $rspRaw === '') {
            throw new Exception('Gmail send unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($rspRaw, true);
        if ($code >= 400) {
            $msg = isset($rsp['error']['message']) ? $rsp['error']['message'] : substr($rspRaw, 0, 300);
            throw new Exception('Gmail send failed (' . $code . '): ' . $msg);
        }
        return isset($rsp['id']) ? (string) $rsp['id'] : '';
    }

    /**
     * Send an HTML email with a single binary attachment (e.g. a PDF
     * certificate) via the Gmail API. Builds a multipart/mixed RFC 2822
     * message: part 1 = HTML body (quoted-printable), part 2 = attachment
     * (base64). Mirrors send() for the transport/auth.
     *
     * @param string $to
     * @param string $subject
     * @param string $bodyHtml
     * @param string $attachBytes   Raw attachment bytes.
     * @param string $attachName    Filename shown to the recipient.
     * @param string $attachMime    e.g. 'application/pdf'
     * @param string $fromName
     * @param array  $cc
     * @param string $replyTo
     * @return string Gmail message id
     * @throws Exception
     */
    public function sendWithAttachment($to, $subject, $bodyHtml, $attachBytes, $attachName,
                                       $attachMime = 'application/pdf', $fromName = '', array $cc = array(), $replyTo = '')
    {
        $c = $this->getConfig();
        $from = $fromName !== '' ? '"' . str_replace('"', '\"', $fromName) . '" <' . $c['user'] . '>'
                                 : $c['user'];
        $boundary = 'mmd_' . md5(uniqid('', true));

        $headers = array(
            'From: ' . $from,
            'To: ' . $to,
            'Subject: ' . $this->_encodeHeader($subject),
            'MIME-Version: 1.0',
            'Content-Type: multipart/mixed; boundary="' . $boundary . '"',
        );
        $cc = array_values(array_filter(array_map('trim', $cc)));
        if (!empty($cc)) {
            $headers[] = 'Cc: ' . implode(', ', $cc);
        }
        if ($replyTo !== '') {
            $headers[] = 'Reply-To: ' . $replyTo;
        }

        $nl = "\r\n";
        $body  = '--' . $boundary . $nl;
        $body .= 'Content-Type: text/html; charset=UTF-8' . $nl;
        $body .= 'Content-Transfer-Encoding: quoted-printable' . $nl . $nl;
        $body .= quoted_printable_encode($bodyHtml) . $nl;
        $body .= '--' . $boundary . $nl;
        $body .= 'Content-Type: ' . $attachMime . '; name="' . $attachName . '"' . $nl;
        $body .= 'Content-Transfer-Encoding: base64' . $nl;
        $body .= 'Content-Disposition: attachment; filename="' . $attachName . '"' . $nl . $nl;
        $body .= chunk_split(base64_encode($attachBytes), 76, $nl) . $nl;
        $body .= '--' . $boundary . '--';

        $rfc = implode($nl, $headers) . $nl . $nl . $body;
        $raw = rtrim(strtr(base64_encode($rfc), '+/', '-_'), '=');

        $token    = $this->getAccessToken();
        $userPath = urlencode($c['user']);

        $ch = curl_init('https://gmail.googleapis.com/gmail/v1/users/' . $userPath . '/messages/send');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode(array('raw' => $raw)),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 45,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $token,
                'Content-Type: application/json',
            ),
        ));
        $rspRaw = curl_exec($ch);
        $code   = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err    = curl_error($ch);
        curl_close($ch);

        if ($rspRaw === false || $rspRaw === '') {
            throw new Exception('Gmail send unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($rspRaw, true);
        if ($code >= 400) {
            $msg = isset($rsp['error']['message']) ? $rsp['error']['message'] : substr($rspRaw, 0, 300);
            throw new Exception('Gmail send failed (' . $code . '): ' . $msg);
        }
        return isset($rsp['id']) ? (string) $rsp['id'] : '';
    }

    /**
     * Encode a header value with RFC 2047 base64 encoding when it
     * contains non-ASCII characters. Subjects are the usual culprit.
     */
    protected function _encodeHeader($value)
    {
        $value = (string) $value;
        if (preg_match('/[\x80-\xff]/', $value)) {
            return '=?UTF-8?B?' . base64_encode($value) . '?=';
        }
        return $value;
    }
}
