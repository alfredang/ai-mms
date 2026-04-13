<?php
require_once Mage::getModuleDir('', 'Hitpay_Pay').'/vendor/autoload.php';

use HitPay\Client;
use HitPay\Request\CreatePayment;
use HitPay\Response\PaymentStatus;

class Hitpay_Pay_PaymentController extends Mage_Core_Controller_Front_Action {

    public function getCheckout()
    {
        return Mage::getSingleton('checkout/session');
    }
    
    public function getStoreName()
    {
        $storeName = Mage::helper('hitpay')->getStoreConfig("general/store_information/name");
        if (empty($storeName)) {
            $storeName = Mage::getUrl();
        }
        return $storeName;
    }

    public function createAction()
    {
        try {
            $order_id = $this->getCheckout()->getLastRealOrderId();
            $order = Mage::getModel('sales/order')->loadByIncrementId($order_id);
            if ($order && $order->getId() > 0) {
                $client = new Client(
                    Mage::helper('hitpay')->getStoreConfig("payment/hitpay/api_key"),
                    Mage::helper('hitpay')->getStoreConfig("payment/hitpay/mode")
                );

                $redirectUrl = Mage::getUrl('hitpay/payment/confirmation', array('order_id' => $order->getIncrementId()) );
                $webhook = Mage::getUrl('hitpay/payment/webhook', array('order_id' => $order->getIncrementId()) );

                $createPaymentRequest = new CreatePayment();
                $createPaymentRequest->setAmount($order->getGrandTotal())
                    ->setCurrency($order->getOrderCurrencyCode())
                    ->setReferenceNumber($order->getIncrementId())
                    ->setWebhook($webhook)
                    ->setRedirectUrl($redirectUrl)
                    ->setChannel('api_magento');

                $createPaymentRequest->setName($order->getCustomerFirstname() . ' ' . $order->getCustomerLastname());
                $createPaymentRequest->setEmail($order->getCustomerEmail());
                
                $createPaymentRequest->setPurpose($this->getStoreName());
                
                Mage::helper('hitpay')->log('Create Payment Request:');
                Mage::helper('hitpay')->log((array)$createPaymentRequest);

                $result = $client->createPayment($createPaymentRequest);
                
                Mage::helper('hitpay')->log('Create Payment Response:');
                Mage::helper('hitpay')->log((array)$result);
                
                $payment = Mage::getModel('hitpay/payment');
                $payment->load($order->getId(), 'order_id');
                $payment->setPaymentId($result->getId());
                $payment->setAmount($order->getGrandTotal());
                $payment->setCurrencyId($order->getOrderCurrencyCode());
                $payment->setStatus($result->getStatus());
                $payment->setOrderId($order->getId());
                $payment->setOrderIncrementId($order->getIncrementId());
                $payment->save();
                
                if ($result->getStatus() == 'pending') {
                    echo '<script>window.top.location.href = "'.$result->getUrl().'";</script>';
                    exit;
                } else {
                    throw new \Exception(sprintf(Mage::helper('hitpay')->__('Status from gateway is %s .'), $result->getStatus()));
                }
            } else {
                return $this->getResponse()->setRedirect(Mage::getUrl('checkout/cart'));
            }
        } catch (\Exception $e) {
            $message = Mage::helper('hitpay')->__('HitPay Create Payment Request failed. ');
            $message .= $e->getMessage();
            echo $message;exit;
            $this->cancelAction($message);
        }
    }
    
    public function cancelAction($message)
    {
        if (empty($message)) {
            $message = Mage::helper('hitpay')->__('Order canceled.');
        }
        
        Mage::helper("hitpay")->log('Cancel Action:');
        Mage::helper("hitpay")->log($message);
        
        $session = Mage::getSingleton('checkout/session');
        if ($session->getLastRealOrderId()) {
            $order = Mage::getModel('sales/order')->loadByIncrementId($session->getLastRealOrderId());
            if ($order->getId()) {
                if ($order->getState() != Mage_Sales_Model_Order::STATE_CANCELED) {
                    $order->registerCancellation($message)->save();
                }
                $quote = Mage::getModel('sales/quote')
                        ->load($order->getQuoteId());

                if ($quote->getId()) {
                    $quote->setIsActive(1)
                            ->setReservedOrderId(NULL)
                            ->save();
                    $session->replaceQuote($quote);
                }
                $session->unsLastRealOrderId();
            }
        }
        Mage::getSingleton('core/session')->addError($message);
        return $this->getResponse()->setRedirect(Mage::getUrl('checkout/onepage'));
    }
    
    public function confirmationAction()
    {
        try {
            $params = $this->getRequest()->getParams();
            Mage::helper("hitpay")->log('Return From Gateway:');
            Mage::helper("hitpay")->log(json_encode($params));
            
            if (isset($params['order_id']) && !empty($params['order_id'])) {
                $orderId = $params['order_id'];
                $order = Mage::getModel('sales/order')->loadByIncrementId($orderId);
                
                if ($order->getId() > 0) {
                    
                    $state = $order->getState();
                    
                    if ($state == 'processing' || $state == 'complete' || $state == 'closed') {
                       return $this->getResponse()->setRedirect(Mage::getUrl('hitpay/payment/awaiting'));
                    }
                    
                    if ($params['status'] == 'canceled') {
                        throw new \Exception(Mage::helper("hitpay")->__('Transaction canceled by customer/gateway. '));
                    }
                    
                    $payment = Mage::getModel('hitpay/payment');
                    $payment->load($order->getId(), 'order_id');
                    
                    $reference = $params['reference'];
                    if ($payment->getPaymentId() != $reference) {
                        throw new \Exception(Mage::helper("hitpay")->__('Transaction references check failed. '));
                    }
                    
                    return $this->getResponse()->setRedirect(Mage::getUrl('hitpay/payment/awaiting'));

                } else {
                    throw new \Exception(Mage::helper("hitpay")->__('No relation found with this transaction in the store.'));
                }
            } else {
                throw new \Exception(Mage::helper("hitpay")->__('Empty response received from gateway.'));
            }
        } catch (\Exception $e) {
            $this->cancelAction($e->getMessage());
        }
     }
	
    public function webhookAction() 
    {
        $params = $this->getRequest()->getParams();

        Mage::helper("hitpay")->log('Webhook Triggered:');
        Mage::helper("hitpay")->log(json_encode($params));

        if (!isset($params['order_id']) || !$params['hmac']) {
            Mage::helper("hitpay")->log('order_id + hmac check failed');
            exit;
        }

        if (isset($params['order_id']) && !empty($params['order_id'])) {
            $order_id = $params['order_id'];
            $order = Mage::getModel("sales/order")->loadByIncrementId($params['order_id']);
            if ($order && $order->getId() > 0) {

                $webhookTriggered = (int)Mage::helper("hitpay")->isWebhookTriggered($order->getId());
                if ($webhookTriggered == 1) {
                    Mage::helper("hitpay")->log('Alredy Webhook Triggered, so skipped.');
                    exit;
                }

                Mage::helper("hitpay")->updateWebhookTrigger($order->getId());
                
                $payment = Mage::getModel('hitpay/payment');
                $payment->load($order->getId(), 'order_id');

                $HitPay_payment_id = $payment->getPaymentId();

                if (!$HitPay_payment_id || empty($HitPay_payment_id)) {
                    Mage::helper("hitpay")->log('Saved payment not valid');
                    exit;
                }

                try {
                    $data = $_POST;
                    unset($data['hmac']);

                    $salt = Mage::helper('hitpay')->getStoreConfig("payment/hitpay/salt");
                    if (Client::generateSignatureArray($salt, $data) == $params['hmac']) {
                        Mage::helper("hitpay")->log('Hmac check passed');

                        $HitPay_is_paid = $payment->getIsPaid();

                        if (!$HitPay_is_paid) {
                            $status = trim($params['status']);
                            $status = strip_tags($params['status']);

                            if ($status == 'completed'
                                && $order->getGrandTotal() == $params['amount']
                                && $order_id == $params['reference_number']
                                && $order->getOrderCurrencyCode() == $params['currency']
                            ) {
                                $payment_id = $params['payment_id'];
                                $payment_request_id = $params['payment_request_id'];
                                $hitpay_currency = $params['currency'];
                                $hitpay_amount = $params['amount'];

                                $orderState = Mage::helper('hitpay')->getStoreConfig("payment/hitpay/new_order_status");
                                if (empty($orderState)) {
                                    $orderState = Mage_Sales_Model_Order::STATE_PROCESSING;
                                    $orderStatus = Mage_Sales_Model_Order::STATE_PROCESSING;
                                } else {
                                    $orderStatus = $orderState;
                                    $orderState = Mage::helper('hitpay')->getOrderState($orderStatus);
                                }
                                
                                $order->setState(
                                    $orderState, 
                                    $orderStatus,
                                    Mage::helper("hitpay")->__('Hitpay payment successful. '). Mage::helper("hitpay")->__('Transaction ID: '). $payment_id  
                                );
                                $order->save();
                                $order->sendNewOrderEmail();
                                $order->setEmailSent(true);
                                
                                $payment->setTransactionId($payment_id);
                                $payment->setPaymentRequestId($payment_request_id);
                                $payment->setIsPaid(1);
                                $payment->setCurrencyId($hitpay_currency);
                                $payment->setAmount($hitpay_amount);
                                $payment->setStatus($status);
                                $payment->save();
                                
                                $this->createInvoice($order, $payment_id);

                            } elseif ($status == 'failed') {
                                $payment_id = $params['payment_id'];
                                $hitpay_currency = $params['currency'];
                                $hitpay_amount = $params['amount'];

                                $order->cancel();
                                $message = Mage::helper("hitpay")->__('Payment Failed. Transaction Id: '.$payment_id);
                                $order->addStatusHistoryComment($message, Mage_Sales_Model_Order::STATE_CANCELED);
                                $order->save();
                                
                                $payment->setTransactionId($payment_id);
                                $payment->setIsPaid(0);
                                $payment->setCurrencyId($hitpay_currency);
                                $payment->setAmount($hitpay_amount);
                                $payment->setStatus($status);
                                $payment->save();
                            } elseif ($status == 'pending') {
                                $payment_id = $params['payment_id'];
                                $hitpay_currency = $params['currency'];
                                $hitpay_amount = $params['amount'];
                                
                                $status = 'completed';
                                
                                $order->setState(
                                    Mage_Sales_Model_Order::STATE_NEW, 
                                    true,
                                    Mage::helper("hitpay")->__('Hitpay payment is pending. '). Mage::helper("hitpay")->__('Transaction ID: '). $payment_id  
                                );
                                $order->save();
                                $order->sendNewOrderEmail();
                                $order->setEmailSent(true);

                                $payment->setTransactionId($payment_id);
                                $payment->setIsPaid(0);
                                $payment->setCurrencyId($hitpay_currency);
                                $payment->setAmount($hitpay_amount);
                                $payment->setStatus($status);
                                $payment->save();
                            } else {
                                $payment_id = $params['payment_id'];
                                $hitpay_currency = $params['currency'];
                                $hitpay_amount = $params['amount'];

                                $status = 'failed';
                                $order->cancel();
                                $message = Mage::helper("hitpay")->__('Payment returned unknown status. Transaction Id: '.$payment_id);
                                $order->addStatusHistoryComment($message, Mage_Sales_Model_Order::STATE_CANCELED);
                                $order->save();

                                $payment->setTransactionId($payment_id);
                                $payment->setIsPaid(0);
                                $payment->setCurrencyId($hitpay_currency);
                                $payment->setAmount($hitpay_amount);
                                $payment->setStatus($status);
                                $payment->save();
                            }
                        }
                    } else {
                        throw new \Exception('HitPay: hmac is not the same like generated');
                    }
                } catch (\Exception $e) {
                    Mage::helper("hitpay")->log('Webhook Catch');
                    Mage::helper("hitpay")->log('Exception:'.$e->getMessage());

                    $status = 'failed';
                    $order->cancel();
                    $message = Mage::helper("hitpay")->__('Payment failed. Error: '.$e->getMessage());
                    $order->addStatusHistoryComment($message, Mage_Sales_Model_Order::STATE_CANCELED);
                    $order->save();
                    
                    $payment->setStatus($status);
                    $payment->save();
                }
            } else {
                Mage::helper("hitpay")->log('$order && $order->getId() > 0');
            }
        } else {
            Mage::helper("hitpay")->log('else isset($params[order_id]) && !empty($params[order_id])');
        }
    }
    
    public function awaitingAction()
    {
        $this->loadLayout();
        $this->getLayout()->getBlock('head')->setTitle($this->__('Retrieving payment status..'));
        $this->renderLayout();
    }
    
    public function statusAction()
    {
        $status = 'wait';
        $redirect = '';
        $message = '';
        
        try {
            $params = $this->getRequest()->getParams();
            
            $payment_id = $params['payment_id'];
            $payment_id = trim($payment_id);
            $payment_id = strip_tags($payment_id);
            
            if (empty($payment_id)) {
                throw new \Exception($this->module->l('No payment id found.'));
            }

            $order_id = (int)$params['order_id'];
            $order = Mage::getModel('sales/order')->load($order_id);
            
            if ((int)$order->getId() == 0) {
                throw new \Exception($this->module->l('This order is not found.'));
            }

            $payment = Mage::getModel('hitpay/payment');
            $payment->load($order->getId(), 'order_id');
            
            if ($payment->getPaymentId() != $payment_id) {
                throw new \Exception(Mage::helper("hitpay")->__('Transaction references check failed. '));
            }

            $status = $payment->getStatus();
            if ($status == 'pending') {
                $status = 'wait';
            } else if ($status == 'completed') {
                $orderState = Mage::helper('hitpay')->getStoreConfig("payment/hitpay/new_order_status");
                if (empty($orderState)) {
                    $orderState = Mage_Sales_Model_Order::STATE_PROCESSING;
                }
                
                $orderStatus = $order->getStatus();
                if ($orderStatus == $orderState) {
                    $status = 'completed';
                } else {
                    $status = $orderStatus;
                }
                $redirect = Mage::getUrl('checkout/onepage/success');
            } else if ($status == 'failed') {
                $this->restoreQuote();
                $redirect = Mage::getUrl('checkout/onepage');
            }
        } catch (\Exception $e) {
            $status = 'error';
            $message = $e->getMessage();
        }

        $data = [
            'status' => $status,
            'redirect' => $redirect,
            'message' => $message
        ];
        
        echo json_encode($data);
        die();
    }
    
    public function restoreQuote()
    {
        $session = Mage::getSingleton('checkout/session');
        if ($session->getLastRealOrderId()) {
            $order = Mage::getModel('sales/order')->loadByIncrementId($session->getLastRealOrderId());
            if ($order->getId()) {
                if ($order->getState() != Mage_Sales_Model_Order::STATE_CANCELED) {
                    $order->registerCancellation($message)->save();
                }
                $quote = Mage::getModel('sales/quote')
                        ->load($order->getQuoteId());

                if ($quote->getId()) {
                    $quote->setIsActive(1)
                            ->setReservedOrderId(NULL)
                            ->save();
                    $session->replaceQuote($quote);
                }
                $session->unsLastRealOrderId();
            }
        }
    }
    
    public function createInvoice($order, $payment_id)
    {
        if(!$order->canInvoice()) {
            Mage::throwException(Mage::helper('core')->__('Cannot create an invoice.'));
        }

        $invoice = Mage::getModel('sales/service_order', $order)->prepareInvoice();

        if (!$invoice->getTotalQty()) {
            Mage::throwException(Mage::helper('core')->__('Cannot create an invoice without products.'));
        }

        $invoice->setRequestedCaptureCase(Mage_Sales_Model_Order_Invoice::CAPTURE_OFFLINE);
        $invoice->register();
        $invoice->setTransactionId($payment_id);
        $invoice->save();
        
        $transactionSave = Mage::getModel('core/resource_transaction')
            ->addObject($invoice)
            ->addObject($invoice->getOrder());
        $transactionSave->save();
    }
}
