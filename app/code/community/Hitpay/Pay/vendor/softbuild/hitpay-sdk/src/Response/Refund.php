<?php

namespace HitPay\Response;

/**
 * Class Refund
 * @package HitPay\Response
 */
class Refund
{
    /**
     * @var string
     */
    public $id;

    /**
     * @var string
     */
    public $payment_id;

    /**
     * @var float
     */
    public $amount_refunded;

    /**
     * @var float
     */
    public $total_amount;

    /**
     * @var string
     */
    public $currency;

    /**
     * @var string
     */
    public $status;

    /**
     * @var string
     */
    public $payment_method;

    /**
     * @var string
     */
    public $created_at;

    /**
     * Refund constructor.
     * @param \stdClass $result
     */
    public function __construct(\stdClass $result)
    {
        $this->setId($result->id);
        $this->setPaymentId($result->payment_id);
        $this->setAmountRefunded($result->amount_refunded);
        $this->setTotalAmount($result->total_amount);
        $this->setCurrency($result->currency);
        $this->setStatus($result->status);
        $this->setPaymentMethod($result->payment_method);
        $this->setCreatedAt($result->created_at);
    }

    /**
     * @return string
     */
    public function getId()
    {
        return $this->id;
    }

    /**
     * @return string
     */
    public function getPaymentId()
    {
        return $this->payment_id;
    }

    /**
     * @return float
     */
    public function getAmountRefunded()
    {
        return $this->amount_refunded;
    }

    /**
     * @return float
     */
    public function getTotalAmount()
    {
        return $this->total_amount;
    }

    /**
     * @return string
     */
    public function getCurrency()
    {
        return $this->currency;
    }

    /**
     * @return string
     */
    public function getStatus()
    {
        return $this->status;
    }

    /**
     * @return string
     */
    public function getPaymentMethod()
    {
        return $this->payment_method;
    }

    /**
     * @return string
     */
    public function getCreatedAt()
    {
        return $this->created_at;
    }

    /**
     * @param string $id
     * @return Refund
     */
    public function setId($id)
    {
        $this->id = $id;

        return $this;
    }

    /**
     * @param string $name
     * @return Refund
     */
    public function setPaymentId($payment_id)
    {
        $this->payment_id = $payment_id;

        return $this;
    }

    /**
     * @param string $amount_refunded
     * @return Refund
     */
    public function setAmountRefunded($amount_refunded)
    {
        $this->amount_refunded = $amount_refunded;

        return $this;
    }

    /**
     * @param float $total_amount
     * @return Refund
     */
    public function setTotalAmount($total_amount)
    {
        $this->total_amount = $total_amount;

        return $this;
    }

    /**
     * @param string $currency
     * @return Refund
     */
    public function setCurrency($currency)
    {
        $this->currency = $currency;

        return $this;
    }

    /**
     * @param string $status
     * @return Refund
     */
    public function setStatus($status)
    {
        $this->status = $status;

        return $this;
    }

    /**
     * @param array $payment_methods
     * @return Refund
     */
    public function setPaymentMethod($payment_method)
    {
        $this->payment_method = $payment_method;

        return $this;
    }

    /**
     * @param string $created_at
     * @return Refund
     */
    public function setCreatedAt($created_at)
    {
        $this->created_at = $created_at;

        return $this;
    }
}
