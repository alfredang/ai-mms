<?php
/**
 * Public read-only API: the non-WSQ course catalog.
 *
 * GET /courses/api_nonwsq[?fields=full]
 *   Header:  X-API-Key: <shared secret>
 *   Returns: EVERY enabled SG course whose code is C-prefixed (non-WSQ).
 *            Compact rows by default; ?fields=full adds the long description,
 *            suitability, prerequisites, assessment and certification.
 *
 * Deliberately separate from /courses/api_wsq — the two funding tracks are never
 * mixed in one response. WSQ (TGS-prefixed) courses live there.
 *
 * This is the feed that had no equivalent before: /courses/api_schedule is
 * TGS-only, so non-WSQ courses were previously unreachable in bulk and had to be
 * scraped from the storefront HTML.
 *
 * Non-WSQ courses carry no SSG funding, so `funding_badges` is normally empty —
 * that is correct data, not a gap.
 *
 * Auth/scope/shape are shared with the WSQ feed via
 * MMD_Courses_Helper_Catalogfeed.
 */
class MMD_Courses_Api_NonwsqController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $helper = Mage::helper('courses/catalogfeed');

        $auth = $helper->authError($this->getRequest()->getHeader('X-API-Key'));
        if ($auth !== null) {
            return $this->_json($auth[0], $auth[1]);
        }

        $full = strtolower(trim((string) $this->getRequest()->getParam('fields', ''))) === 'full';

        try {
            $body = $helper->buildFeed(false, $full);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $helper->errEnvelope('internal_error', $e->getMessage()));
        }

        return $this->_json(200, $body);
    }

    private function _json($status, array $body)
    {
        $json = json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

        // json_encode() returns false on malformed UTF-8. Never ship an empty
        // 200 — that reads as "no courses" to a consumer. Fail loudly instead.
        if ($json === false) {
            $json = json_encode(array(
                'source_url'   => null,
                'last_updated' => gmdate('c'),
                'confidence'   => 'error',
                'error'        => 'encoding_error',
                'message'      => 'Catalog contains data that could not be encoded: '
                                  . json_last_error_msg(),
            ));
            $status = 500;
        }

        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody($json);
        return $this;
    }
}
