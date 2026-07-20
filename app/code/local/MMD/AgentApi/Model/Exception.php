<?php
/**
 * Typed exception carrying an API error code + HTTP status, so capability
 * models can signal precise failures (forbidden_field, not_found, conflict...)
 * that the dispatch helper maps straight into the JSON error envelope.
 */
class MMD_AgentApi_Model_Exception extends Mage_Core_Exception
{
    protected $_errorCode;
    protected $_httpStatus;

    public function __construct($errorCode, $message, $httpStatus = 400)
    {
        parent::__construct($message);
        $this->_errorCode = $errorCode;
        $this->_httpStatus = (int) $httpStatus;
    }

    public function getErrorCode()
    {
        return $this->_errorCode;
    }

    public function getHttpStatus()
    {
        return $this->_httpStatus;
    }
}
