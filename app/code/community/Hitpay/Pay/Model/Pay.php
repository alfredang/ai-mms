<?php
require_once Mage::getModuleDir('', 'Hitpay_Pay').'/vendor/autoload.php';

use HitPay\Client;

class Hitpay_Pay_Model_Pay extends Mage_Payment_Model_Method_Abstract {
    
    protected $_code = 'hitpay';
    
    protected $_isGateway = true;
    protected $_canAuthorize = false;
    protected $_canCapture = false;
    protected $_canCapturePartial = false;
    protected $_canRefund = true;
    protected $_canVoid = false;
    protected $_canUseInternal = false;
    protected $_canUseCheckout = true;
    protected $_canUseForMultishipping = true;
    protected $_paymentMethod = 'Hitpay';
    
    protected $_formBlockType = 'hitpay/form';
    
    public function isAvailable($quote = null)
    {
        $isAvailable = parent::isAvailable($quote);
        if ($isAvailable) {
            $api_key = $this->getConfigData('api_key', $quote ? $quote->getStoreId() : null);
            $salt = $this->getConfigData('salt', $quote ? $quote->getStoreId() : null);
            
            if (empty($api_key) || empty($salt)) {
                $isAvailable = false;
            }
        }
        return $isAvailable;
    }
    
    public function getTitle()
    {
        $title = $this->getConfigData('title');
        $title = trim((string)$title);
        if (empty($title)) {
            $title = 'HitPay Payment Gateway';
        }
        return $title;
    }
    
    public function canUseForCurrency($currencyCode)
    {
        return true;
    }

    public function getOrderPlaceRedirectUrl()
    {
        return Mage::getUrl('hitpay/payment/create');
    }
    
    public function getInstructions()
    {
        return trim((string)$this->getConfigData('instructions'));
    }

    public function isInitializeNeeded()
    {
        return true;
    }

    public function initialize($paymentAction, $stateObject)
    {
        $state = Mage_Sales_Model_Order::STATE_PENDING_PAYMENT;
        $stateObject->setState($state);
        $stateObject->setStatus(Mage_Sales_Model_Order::STATE_PENDING_PAYMENT);
        $stateObject->setIsNotified(false);
    }

    public function getOrder()
    {
        if (!$this->_order) {
            $this->_order = $this->getInfoInstance()->getOrder();
        }
        return $this->_order;
    }
    
    public function processBeforeRefund($invoice, $payment)
    {
        return parent::processBeforeRefund($invoice, $payment);
    }
    
    public function refund(Varien_Object $payment, $amount)
    {
        $order = $order = $payment->getOrder();
        if ($order && $order->getId()) {
            $paymentMethod = $order->getPayment()->getMethodInstance()->getCode();
            if ($paymentMethod == 'hitpay') {
                $payment_id = $payment->getRefundTransactionId();
                if (!empty($payment_id) && $amount > 0) {
                    
                    try {
                        $client = new Client(
                            Mage::helper('hitpay')->getStoreConfig("payment/hitpay/api_key"),
                            Mage::helper('hitpay')->getStoreConfig("payment/hitpay/mode")
                        );

                        $refund_request_param = 'Order Id: '.$order->getId().', Payment Id: '.$payment_id.', Amount: '.$amount;

                        Mage::helper('hitpay')->log('Refund Payment Request:');
                        Mage::helper('hitpay')->log($refund_request_param);

                        $result = $client->refund($payment_id, $amount);

                        Mage::helper('hitpay')->log('Refund Payment Response:');
                        Mage::helper('hitpay')->log((array)$result);

                        $message = Mage::helper("hitpay")->__('Refund successful. Refund Reference Id: '.$result->getId().', '
                                . 'Payment Id: '.$payment_id.', Amount Refunded: '.$result->getAmountRefunded().', '
                                . 'Payment Method: '.$result->getPaymentMethod().', Created At: '.$result->getCreatedAt());
                        $order->addStatusHistoryComment($message);
                        $order->save();
                    } catch (\Exception $e) {
                        Mage::throwException($e->getMessage());
                    }
                }
            }
        }
        return $this;
    }
}
