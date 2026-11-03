<?php
/**
 * Shared plumbing for the learner-app JSON endpoints: no PHP session (the
 * bearer token is the identity), JSON in and out, and a uniform envelope —
 * {"ok":true,...} or {"ok":false,"error":"<message for the learner>"}.
 */
abstract class MMD_MobileApi_Controller_Base extends Mage_Core_Controller_Front_Action
{
    /** @var array|null mmd_mobile_session row of the authenticated caller */
    protected $_session;

    public function preDispatch()
    {
        // Stateless API: never start (or set a cookie for) a frontend session.
        $this->setFlag('', self::FLAG_NO_START_SESSION, 1);
        parent::preDispatch();
    }

    /** @return MMD_MobileApi_Helper_Data */
    protected function _helper()
    {
        return Mage::helper('mmd_mobileapi');
    }

    /** JSON body merged over form/query params. */
    protected function _input($key, $default = null)
    {
        static $body = null;
        if ($body === null) {
            $raw  = (string) file_get_contents('php://input');
            $body = $raw !== '' ? (json_decode($raw, true) ?: array()) : array();
        }
        if (array_key_exists($key, $body)) {
            return $body[$key];
        }
        $v = $this->getRequest()->getParam($key);
        return $v === null ? $default : $v;
    }

    protected function _bearer()
    {
        $h = (string) $this->getRequest()->getHeader('Authorization');
        if ($h === '' && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $h = (string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        if (stripos($h, 'Bearer ') === 0) {
            return trim(substr($h, 7));
        }
        return trim((string) $this->getRequest()->getHeader('X-Auth-Token'));
    }

    /** Resolve the caller or answer 401. Returns false when the response is already set. */
    protected function _requireLearner()
    {
        $this->_session = $this->_helper()->sessionForToken($this->_bearer());
        if (!$this->_session) {
            $this->_error(401, 'Your session has ended. Please sign in again.', 'unauthorized');
            return false;
        }
        return true;
    }

    protected function _email()
    {
        return $this->_session ? (string) $this->_session['email'] : '';
    }

    protected function _isDemo()
    {
        return $this->_session && (int) $this->_session['is_demo'] === 1;
    }

    protected function _requirePost()
    {
        if (!$this->getRequest()->isPost()) {
            $this->_error(405, 'Method not allowed.', 'method_not_allowed');
            return false;
        }
        return true;
    }

    protected function _ok(array $data = array())
    {
        return $this->_json(200, array('ok' => true) + $data);
    }

    protected function _error($status, $message, $code = 'error')
    {
        return $this->_json($status, array('ok' => false, 'error' => $message, 'code' => $code));
    }

    protected function _json($status, array $body)
    {
        $body = Mage::helper('courses/catalogfeed')->sanitizeUtf8($body);
        $json = json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        // Malformed UTF-8 makes json_encode return false; never ship an empty 200.
        if ($json === false) {
            $status = 500;
            $json   = json_encode(array('ok' => false, 'error' => 'Something went wrong. Please try again.', 'code' => 'encoding_error'));
        }
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody($json);
        return $this;
    }

    /** Run an action body, turning any uncaught exception into a JSON 500. */
    protected function _guard($fn)
    {
        try {
            return $fn();
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_error(500, 'Something went wrong. Please try again.', 'internal_error');
        }
    }

    protected function _clientIp()
    {
        foreach (array('HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR') as $k) {
            if (!empty($_SERVER[$k])) {
                return trim(explode(',', (string) $_SERVER[$k])[0]);
            }
        }
        return '';
    }
}
