<?php
/**
 * Facebook Page posting client (Graph API) — the Facebook counterpart of
 * MMD_Marketing_Helper_Linkedin, shared by the newsletter pipeline and the
 * blog auto-publisher.
 *
 * Posts a link to the configured Page feed; Facebook renders the visual card
 * from the target URL's OpenGraph tags (blog posts and course pages both emit
 * them), so no image upload is needed.
 *
 * Credentials (core_config_data, set directly like the LinkedIn ones):
 *   mmd_marketing/facebook/page_id       — the numeric Facebook Page ID
 *   mmd_marketing/facebook/access_token  — a long-lived PAGE access token with
 *                                          pages_manage_posts (core-encrypted)
 *   mmd_marketing/facebook/enabled       — optional kill switch ('0' disables)
 * Env fallbacks FACEBOOK_PAGE_ID / FACEBOOK_PAGE_ACCESS_TOKEN are honoured for
 * container-level configuration.
 *
 * postLink() never throws — callers must be able to treat a Facebook failure
 * as cosmetic (a blast/blog publish must never depend on it).
 */
class MMD_Marketing_Helper_Facebook extends Mage_Core_Helper_Abstract
{
    const GRAPH_BASE = 'https://graph.facebook.com/v23.0';

    public function isConfigured()
    {
        if ((string) Mage::getStoreConfig('mmd_marketing/facebook/enabled') === '0') {
            return false;
        }
        return $this->_pageId() !== '' && $this->_token() !== '';
    }

    /**
     * Publish a link post on the Page feed.
     *
     * @return array{ok:bool,id:string,url:string,msg:string}
     */
    public function postLink($message, $linkUrl)
    {
        try {
            if (!$this->isConfigured()) {
                return array('ok' => false, 'id' => '', 'url' => '', 'msg' => 'Facebook not configured');
            }
            $endpoint = self::GRAPH_BASE . '/' . rawurlencode($this->_pageId()) . '/feed';
            $payload  = http_build_query(array(
                'message'      => (string) $message,
                'link'         => (string) $linkUrl,
                'access_token' => $this->_token(),
            ));
            $ch = curl_init($endpoint);
            curl_setopt_array($ch, array(
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => $payload,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 60,
                CURLOPT_CONNECTTIMEOUT => 10,
            ));
            $raw  = (string) curl_exec($ch);
            $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            $rsp = json_decode($raw, true);
            if ($code >= 200 && $code < 300 && !empty($rsp['id'])) {
                $id = (string) $rsp['id'];      // "<page_id>_<post_id>"
                return array(
                    'ok'  => true,
                    'id'  => $id,
                    'url' => 'https://www.facebook.com/' . $id,
                    'msg' => 'posted',
                );
            }
            $err = isset($rsp['error']['message']) ? $rsp['error']['message'] : substr($raw, 0, 300);
            return array('ok' => false, 'id' => '', 'url' => '', 'msg' => "HTTP {$code}: {$err}");
        } catch (Exception $e) {
            return array('ok' => false, 'id' => '', 'url' => '', 'msg' => $e->getMessage());
        }
    }

    protected function _pageId()
    {
        $v = trim((string) Mage::getStoreConfig('mmd_marketing/facebook/page_id'));
        if ($v === '') {
            $v = trim((string) getenv('FACEBOOK_PAGE_ID'));
        }
        return $v;
    }

    protected function _token()
    {
        $enc = trim((string) Mage::getStoreConfig('mmd_marketing/facebook/access_token'));
        if ($enc !== '') {
            // Stored core-encrypted (like mmd_marketing/linkedin/access_token) —
            // decrypt() returns garbage on a plaintext value, so tolerate both.
            $dec = (string) Mage::helper('core')->decrypt($enc);
            $val = (preg_match('/^[\x20-\x7E]+$/', $dec) && $dec !== '') ? $dec : $enc;
            return trim($val);
        }
        return trim((string) getenv('FACEBOOK_PAGE_ACCESS_TOKEN'));
    }
}
