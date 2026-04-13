<?php

namespace HitPay\Response;

/**
 * Class PaymentStatus - https://staging.hit-pay.com/docs.html?shell#get-payment-status
 *
 * @package HitPay\Response
 */
class PaymentStatus extends CreatePayment
{
    /**
     * array of payments made to this request ID. Will contain more than one if its a repeating payment link
     *
     * @var array
     */
    public $payments;

    /**
     * PaymentStatus constructor.
     * @param \stdClass $response
     */
    public function __construct(\stdClass $response)
    {
        parent::__construct($response);

        if (isset($response->payments)) {
            $this->setPayments($response->payments);
        }
    }

    /**
     * @return mixed
     */
    public function getPayments()
    {
        return $this->payments;
    }

    /**
     * @param mixed $payments
     * @return PaymentStatus
     */
    public function setPayments($payments)
    {
        $this->payments = $payments;

        return $this;
    }
}
