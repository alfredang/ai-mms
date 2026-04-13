<?php

class Stripe_Payments_SavedcardsController extends Mage_Core_Controller_Front_Action
{
    protected function _getSession()
    {
        return Mage::getSingleton('customer/session');
    }

    public function preDispatch()
    {
        parent::preDispatch();
        if (!Mage::getSingleton('customer/session')->authenticate($this)) {
            $this->setFlag('', 'no-dispatch', true);
        }
    }

    public function indexAction()
    {
        $stripe = Mage::getModel('stripe_payments/method');
        $params = $this->getRequest()->getParams();
        $newcard = $this->getRequest()->getParam('newcard', null);
        $deleteCards = $this->getRequest()->getParam('card', null);

        if (!empty($newcard))
        {
            $this->saveCard($newcard);
            $this->_redirect('customer/savedcards');
        }
        else if (!empty($deleteCards))
        {
            $stripe->deleteCards($deleteCards);
            $this->_redirect('customer/savedcards');
        }

        $this->loadLayout();
        $this->renderLayout();
    }

    public function saveCard($newcard)
    {
        $stripe = Mage::getModel('stripe_payments/method');
        $helper = Mage::helper('stripe_payments');

        if (!$stripe->getStore()->getConfig('payment/stripe_payments/ccsave'))
        {
            Mage::getSingleton('core/session')->addError("Sorry, saved cards are currently disabled!");
            $this->loadLayout();
            $this->renderLayout();
            return;
        }

        if (empty($newcard['cc_stripejs_token']))
            return Mage::getSingleton('core/session')->addError("Sorry, the card could not be saved. Unable to use Stripe.js.");

        $parts = explode(":", $newcard['cc_stripejs_token']);

        if (!$helper->isValidToken($parts[0]))
            return Mage::getSingleton('core/session')->addError("Sorry, the card could not be saved. Unable to use Stripe.js.");

        try
        {
            $stripe->ensureStripeCustomer(false);
            $card = $stripe->addCardToCustomer($parts[0]);
            if ($card)
                Mage::getSingleton('core/session')->addSuccess($helper->__("Card **** %s was added successfully.", $card->last4));
        }
        catch (\Stripe\Error\Card $e)
        {
            Mage::getSingleton('core/session')->addError($e->getMessage());
        }
        catch (\Stripe\Error $e)
        {
            Mage::getSingleton('core/session')->addError($e->getMessage());
        }
        catch (\Exception $e)
        {
            Mage::logException($e);
            Mage::getSingleton('core/session')->addError("Sorry, the card could not be added!");
        }
    }

    public function deletecardAction()
    {
        $cardIdArr[] = $this->getRequest()->getParam('card');
        if (!empty($cardIdArr))
        {
            $stripe = Mage::getModel('stripe_payments/method');
            $stripe->deleteCards($cardIdArr);
        }
        $this->_redirectReferer();
        return;
    }
}
