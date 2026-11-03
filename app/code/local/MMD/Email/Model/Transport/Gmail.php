<?php
/**
 * Zend_Mail transport that ships the message over Gmail's REST API
 * instead of opening an SMTP socket.
 *
 * The Coolify container can reach Google (HTTPS) but cannot reliably
 * reach our legacy SMTP relays from every region — that's why every
 * non-SG store was silently dropping order/invoice/shipment mail.
 * Installing this as Zend_Mail's default transport routes *every*
 * transactional email through the OAuth2 path the MMD_Email observer
 * already uses successfully.
 *
 * Recipients and the full RFC 2822 message are taken straight from
 * the Zend_Mail instance, so anything Zend_Mail produces (multiple
 * TOs, CC/BCC, attachments, multipart bodies) reaches Gmail intact.
 */
class MMD_Email_Model_Transport_Gmail extends Zend_Mail_Transport_Abstract
{
    /**
     * Called by Zend_Mail::send() after _buildBody / _buildHeader have
     * populated $this->header and $this->body. We base64url-encode the
     * full RFC 2822 message and POST it to Gmail's send endpoint.
     */
    protected function _sendMail()
    {
        $helper = Mage::helper('mmd_email/gmail');
        if (!$helper || !$helper->isConfigured()) {
            throw new Exception('Gmail OAuth2 transport selected but not configured');
        }

        // The Gmail API has no separate envelope — it reads To/Cc/Bcc
        // straight off the message headers, so Bcc must be in them. Only
        // the Smtp/Sendmail transports strip Bcc; the abstract
        // _prepareHeaders() used here (zf1-future) keeps it, so re-attach
        // Bcc only when it is missing. Adding it unconditionally listed
        // every Bcc address twice (MY booking #200004310, 3 Nov 2026).
        $headersText = (string) $this->header;
        $bccLine     = preg_match('/^Bcc:/mi', $headersText) ? '' : $this->_buildBccHeader();
        if ($bccLine !== '') {
            $headersText = $bccLine . "\r\n" . $headersText;
        }

        $rfc2822 = $headersText . "\r\n" . $this->body;

        // Gmail expects base64url (RFC 4648 §5).
        $raw = rtrim(strtr(base64_encode($rfc2822), '+/', '-_'), '=');

        // First attempt — on 401 the access token has expired mid-flight,
        // so we refresh once and retry. Anything else bubbles up.
        $result = $this->_postToGmail($helper, $raw);
        if ($result['code'] === 401) {
            $result = $this->_postToGmail($helper, $raw, true);
        }

        if ($result['code'] >= 400) {
            $msg = isset($result['body']['error']['message'])
                ? $result['body']['error']['message']
                : substr((string) $result['raw'], 0, 300);
            throw new Exception('Gmail send failed (' . $result['code'] . '): ' . $msg);
        }
    }

    /**
     * Single round-trip to Gmail's send endpoint. Returns ['code','raw','body'].
     * When $forceFreshToken is true, the helper is asked for a brand-new
     * access token (skipping any cached value), used by the 401 retry path.
     */
    protected function _postToGmail($helper, $raw, $forceFreshToken = false)
    {
        $token = $helper->getAccessToken();
        $cfg   = $helper->getConfig();
        $user  = $cfg['user'];

        $ch = curl_init('https://gmail.googleapis.com/gmail/v1/users/' . urlencode($user) . '/messages/send');
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
        return array(
            'code' => $code,
            'raw'  => $rspRaw,
            'body' => json_decode($rspRaw, true),
        );
    }

    /**
     * Rebuild the Bcc header from $this->_mail (Zend strips it before
     * we get here). Returns "Bcc: a@x, b@x" or '' when there is no Bcc.
     */
    protected function _buildBccHeader()
    {
        if (!$this->_mail) {
            return '';
        }
        $headers = $this->_mail->getHeaders();
        if (!isset($headers['Bcc']) || !is_array($headers['Bcc'])) {
            return '';
        }
        $addrs = array();
        foreach ($headers['Bcc'] as $k => $v) {
            if ($k === 'append') continue;
            if (is_array($v)) {
                foreach ($v as $vk => $vv) {
                    if ($vk === 'append') continue;
                    if (is_string($vv) && strpos($vv, '@') !== false) {
                        $addrs[] = trim($vv);
                    }
                }
            } elseif (is_string($v) && strpos($v, '@') !== false) {
                $addrs[] = trim($v);
            }
        }
        $addrs = array_filter(array_unique($addrs));
        return $addrs ? 'Bcc: ' . implode(', ', $addrs) : '';
    }
}
