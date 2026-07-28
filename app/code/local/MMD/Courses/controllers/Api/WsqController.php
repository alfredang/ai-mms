<?php
/**
 * Public read-only API: the WSQ course catalog.
 *
 * GET /courses/api_wsq[?fields=full]
 *   Header:  X-API-Key: <shared secret>
 *   Returns: EVERY enabled SG course whose code is TGS-prefixed (WSQ).
 *            Compact rows by default; ?fields=full adds the long description,
 *            suitability, prerequisites, assessment and certification.
 *
 * Deliberately separate from /courses/api_nonwsq — the two funding tracks are
 * never mixed in one response. Non-WSQ (C-prefixed) courses live there.
 *
 * Unlike /courses/api_schedule (which is also TGS-only but returns class dates),
 * this endpoint returns catalog data: fee, duration, funding badges, categories.
 *
 * Auth/scope/shape are shared with the non-WSQ feed via
 * MMD_Courses_Helper_Catalogfeed.
 */
class MMD_Courses_Api_WsqController extends Mage_Core_Controller_Front_Action
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
            $body = $helper->buildFeed(true, $full);
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
