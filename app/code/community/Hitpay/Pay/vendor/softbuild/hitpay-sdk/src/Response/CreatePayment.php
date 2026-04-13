<?php

namespace HitPay\Response;

/**
 * Class CreatePayment
 * @package HitPay\Response
 */
class CreatePayment
{
    /**
     * @var string
     */
    public $id;

    /**
     * @var string
     */
    public $name;

    /**
     * @var string
     */
    public $email;

    /**
     * @var int
     */
    public $phone;

    /**
     * @var float
     */
    public $amount;

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
    public $purpose;

    /**
     * @var string
     */
    public $reference_number;

    /**
     * @var array
     */
    public $payment_methods = array();

    /**
     * @var string
     */
    public $url;

    /**
     * @var string
     */
    public $redirect_url;

    /**
     * @var string
     */
    public $webhook;

    /**
     * @var int
     */
    public $send_sms;

    /**
     * @var int
     */
    public $send_email;

    /**
     * @var string
     */
    public $sms_status;

    /**
     * @var string
     */
    public $email_status;

    /**
     * @var string
     */
    public $allow_repeated_payments;

    /**
     * @var string
     */
    public $expiry_date;

    /**
     * @var string
     */
    public $created_at;

    /**
     * @var string
     */
    public $updated_at;

    /**
     * CreatePayment constructor.
     * @param \stdClass $result
     */
    public function __construct(\stdClass $result)
    {
        $this->setId($result->id);
        $this->setName($result->name);
        $this->setEmail($result->email);
        $this->setPhone($result->phone);
        $this->setAmount($result->amount);
        $this->setCurrency($result->currency);
        $this->setStatus($result->status);
        $this->setPurpose($result->purpose);
        $this->setReferenceNumber($result->reference_number);
        $this->setPaymentMethods($result->payment_methods);
        $this->setUrl($result->url);
        $this->setRedirectUrl($result->redirect_url);
        $this->setWebhook($result->webhook);
        $this->setSendSms($result->send_sms);
        $this->setSendEmail($result->send_email);
        $this->setSmsStatus($result->sms_status);
        $this->setEmailStatus($result->email_status);
        $this->setAllowRepeatedPayments($result->allow_repeated_payments);
        $this->setExpiryDate($result->expiry_date);
        $this->setCreatedAt($result->created_at);
        $this->setUpdatedAt($result->updated_at);
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
    public function getName()
    {
        return $this->name;
    }

    /**
     * @return string
     */
    public function getEmail()
    {
        return $this->email;
    }

    /**
     * @return int
     */
    public function getPhone()
    {
        return $this->phone;
    }

    /**
     * @return float
     */
    public function getAmount()
    {
        return $this->amount;
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
    public function getPurpose()
    {
        return $this->purpose;
    }

    /**
     * @return string
     */
    public function getReferenceNumber()
    {
        return $this->reference_number;
    }

    /**
     * @return array
     */
    public function getPaymentMethods()
    {
        return $this->payment_methods;
    }

    /**
     * @return string
     */
    public function getUrl()
    {
        return $this->url;
    }

    /**
     * @return string
     */
    public function getRedirectUrl()
    {
        return $this->redirect_url;
    }

    /**
     * @return string
     */
    public function getWebhook()
    {
        return $this->webhook;
    }

    /**
     * @return int
     */
    public function getSendSms()
    {
        return $this->send_sms;
    }

    /**
     * @return int
     */
    public function getSendEmail()
    {
        return $this->send_email;
    }

    /**
     * @return string
     */
    public function getSmsStatus()
    {
        return $this->sms_status;
    }

    /**
     * @return string
     */
    public function getEmailStatus()
    {
        return $this->email_status;
    }

    /**
     * @return string
     */
    public function getAllowRepeatedPayments()
    {
        return $this->allow_repeated_payments;
    }

    /**
     * @return string
     */
    public function getExpiryDate()
    {
        return $this->expiry_date;
    }

    /**
     * @return string
     */
    public function getCreatedAt()
    {
        return $this->created_at;
    }

    /**
     * @return string
     */
    public function getUpdatedAt()
    {
        return $this->updated_at;
    }

    /**
     * @param string $id
     * @return CreatePayment
     */
    public function setId($id)
    {
        $this->id = $id;

        return $this;
    }

    /**
     * @param string $name
     * @return CreatePayment
     */
    public function setName($name)
    {
        $this->name = $name;

        return $this;
    }

    /**
     * @param string $email
     * @return CreatePayment
     */
    public function setEmail($email)
    {
        $this->email = $email;

        return $this;
    }

    /**
     * @param int $phone
     */
    public function setPhone($phone)
    {
        $this->phone = $phone;
    }

    /**
     * @param float $amount
     * @return CreatePayment
     */
    public function setAmount($amount)
    {
        $this->amount = $amount;

        return $this;
    }

    /**
     * @param string $currency
     * @return CreatePayment
     */
    public function setCurrency($currency)
    {
        $this->currency = $currency;

        return $this;
    }

    /**
     * @param string $status
     * @return CreatePayment
     */
    public function setStatus($status)
    {
        $this->status = $status;

        return $this;
    }

    /**
     * @param string $purpose
     * @return CreatePayment
     */
    public function setPurpose($purpose)
    {
        $this->purpose = $purpose;

        return $this;
    }

    /**
     * @param string $reference_number
     * @return CreatePayment
     */
    public function setReferenceNumber($reference_number)
    {
        $this->reference_number = $reference_number;

        return $this;
    }

    /**
     * @param array $payment_methods
     * @return CreatePayment
     */
    public function setPaymentMethods($payment_methods)
    {
        $this->payment_methods = $payment_methods;

        return $this;
    }

    /**
     * @param string $url
     * @return CreatePayment
     */
    public function setUrl($url)
    {
        $this->url = $url;

        return $this;
    }

    /**
     * @param string $redirect_url
     * @return CreatePayment
     */
    public function setRedirectUrl($redirect_url)
    {
        $this->redirect_url = $redirect_url;

        return $this;
    }

    /**
     * @param string $webhook
     * @return CreatePayment
     */
    public function setWebhook($webhook)
    {
        $this->webhook = $webhook;

        return $this;
    }

    /**
     * @param int $send_sms
     * @return CreatePayment
     */
    public function setSendSms($send_sms)
    {
        $this->send_sms = $send_sms;

        return $this;
    }

    /**
     * @param int $send_email
     * @return CreatePayment
     */
    public function setSendEmail($send_email)
    {
        $this->send_email = $send_email;

        return $this;
    }

    /**
     * @param string $sms_status
     * @return CreatePayment
     */
    public function setSmsStatus($sms_status)
    {
        $this->sms_status = $sms_status;

        return $this;
    }

    /**
     * @param string $email_status
     * @return CreatePayment
     */
    public function setEmailStatus($email_status)
    {
        $this->email_status = $email_status;

        return $this;
    }

    /**
     * @param string $allow_repeated_payments
     * @return CreatePayment
     */
    public function setAllowRepeatedPayments($allow_repeated_payments)
    {
        $this->allow_repeated_payments = $allow_repeated_payments;

        return $this;
    }

    /**
     * @param string $expiry_date
     * @return CreatePayment
     */
    public function setExpiryDate($expiry_date)
    {
        $this->expiry_date = $expiry_date;

        return $this;
    }

    /**
     * @param string $created_at
     * @return CreatePayment
     */
    public function setCreatedAt($created_at)
    {
        $this->created_at = $created_at;

        return $this;
    }

    /**
     * @param string $updated_at
     * @return CreatePayment
     */
    public function setUpdatedAt($updated_at)
    {
        $this->updated_at = $updated_at;

        return $this;
    }
}
