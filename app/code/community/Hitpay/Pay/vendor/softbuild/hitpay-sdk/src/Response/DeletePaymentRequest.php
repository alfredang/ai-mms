<?php

namespace HitPay\Response;

/**
 * Class DeletePaymentRequest - https://staging.hit-pay.com/docs.html?shell#delete-payment-request
 * @package HitPay\Response
 */
class DeletePaymentRequest
{
    /**
     * @var int
     */
    public $success;

    /**
     * DeletePaymentRequest constructor.
     * @param \stdClass $response
     */
    public function __construct(\stdClass $response)
    {
        $this->setSuccess($response->success);
    }

    /**
     * @return mixed
     */
    public function getSuccess()
    {
        return $this->success;
    }

    /**
     * @param mixed $success
     * @return DeletePaymentRequest
     */
    public function setSuccess($success)
    {
        $this->success = $success;

        return $this;
    }
}
