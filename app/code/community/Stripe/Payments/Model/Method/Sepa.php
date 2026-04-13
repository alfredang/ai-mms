<?php

class Stripe_Payments_Model_Method_Sepa extends Stripe_Payments_Model_Method_Api_Sources
{
    protected $_code = 'stripe_payments_sepa';
    protected $_name = 'Stripe SEPA Direct Debit';
    protected $_type = 'sepa_debit';
    protected $_canUseInternal          = true;

    public function assignData($data)
    {
        $info = $this->getInfoInstance();

        if (!empty($data['iban']))
            $info->setAdditionalInformation('iban', $data['iban']);
        else
            $info->setAdditionalInformation('iban', null);

        if (!empty($data['mandate']) && $data['mandate'] != 'new')
            $info->setAdditionalInformation('mandate', $data['mandate']);
        else
            $info->setAdditionalInformation('mandate', null);

        return $this;
    }

    public function authorize(Varien_Object $payment, $amount)
    {
        $info = $this->getInfoInstance();
        $mandate = $info->getAdditionalInformation('mandate');

        if (empty($mandate))
        {
            return parent::authorize($payment, $amount);
        }
        else if ($amount > 0)
        {
            // As we are using a saved mandate, we will try to charge it directly without a redirect
            try
            {
                $order = $payment->getOrder();
                $customerStripeId = $this->stripe->getCustomerStripeId();
                $source = \Stripe\Source::retrieve($mandate);
                $source->metadata["Order #"] = $order->getIncrementId();
                $source->save();
                $payment->setAdditionalInformation('captured', false);
                $payment->setAdditionalInformation('source_id', $source->id);
                $payment->setAdditionalInformation('customer_stripe_id', $customerStripeId);
                Mage::helper('stripe_payments/webhooks')->charge($order, $source, false);

                $invoiceCollection = $order->getInvoiceCollection();

                foreach ($invoiceCollection as $invoice)
                    $invoice->pay()->save();

                $order->setState(Mage_Sales_Model_Order::STATE_PROCESSING)
                    ->setStatus(Mage_Sales_Model_Order::STATE_PROCESSING)
                    ->save();
            }
            catch (\Stripe\Error\Card $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Stripe\Error $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Exception $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
        }

        return $this;
    }
}
