<?php
/**
 * Transaction detail block — tolerate orders whose payment method is no
 * longer available.
 *
 * Core Mage_Adminhtml_Block_Sales_Transactions_Detail::__construct()
 * gates the "Fetch" button on:
 *
 *     $txn->getOrderPaymentObject()->getMethodInstance()->canFetchTransactionInfo()
 *
 * getMethodInstance() throws Mage_Core_Exception "The requested Payment
 * Method is not available." for any order paid with a method that has
 * since been disabled / unconfigured for its store (e.g. a removed or
 * reconfigured Stripe / HitPay method — common here across the country
 * stores). Because that throw happens inside block construction during
 * loadLayout(), the controller can't catch it and the whole
 * Transactions → View page renders as a blank content area (no error
 * report is written either).
 *
 * This override calls the grandparent (Widget_Container) constructor
 * directly, then rebuilds the Back / Fetch buttons with the payment
 * lookup wrapped in try/catch — so a dead payment method just means "no
 * Fetch button", not a blank page. Everything else is inherited.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Transactions_Detail
    extends Mage_Adminhtml_Block_Sales_Transactions_Detail
{
    public function __construct()
    {
        // Deliberately skip the core Detail::__construct (the source of
        // the fatal) and run its grandparent instead.
        Mage_Adminhtml_Block_Widget_Container::__construct();

        $this->_txn = Mage::registry('current_transaction');

        $backUrl = ($this->_txn && $this->_txn->getOrderUrl())
            ? $this->_txn->getOrderUrl()
            : $this->getUrl('*/*/');
        $this->_addButton('back', array(
            'label'   => Mage::helper('sales')->__('Back'),
            'onclick' => Mage::helper('core/js')->getSetLocationJs($backUrl),
            'class'   => 'back',
        ));

        try {
            if ($this->_txn
                && Mage::getSingleton('admin/session')->isAllowed('sales/transactions/fetch')
            ) {
                $payment = $this->_txn->getOrderPaymentObject();
                if ($payment
                    && $payment->getMethodInstance()->canFetchTransactionInfo()
                ) {
                    $this->_addButton('fetch', array(
                        'label'   => Mage::helper('sales')->__('Fetch'),
                        'onclick' => Mage::helper('core/js')->getSetLocationJs(
                            $this->getUrl('*/*/fetch', array('_current' => true))
                        ),
                        'class'   => 'button',
                    ));
                }
            }
        } catch (Throwable $e) {
            // Payment method no longer available — skip Fetch, keep the
            // page alive. Logged at notice level for traceability.
            Mage::log(
                'Transactions Detail: Fetch button skipped — ' . $e->getMessage(),
                Zend_Log::NOTICE
            );
        }
    }

    /**
     * Core Detail::_toHtml() calls $txn->getHtmlTxnId(), which dispatches
     * the `sales_html_txn_id` event. Mage_Paypal_Model_Observer::
     * observeHtmlTransactionId() handles it and calls
     * $payment->getMethodInstance() *before* checking the method type —
     * so the same "The requested Payment Method is not available."
     * Mage_Core_Exception is thrown again here (this time from inside
     * _toHtml during layout output), 500-ing the whole page.
     *
     * Reimplement _toHtml() identically to core but with getHtmlTxnId()
     * wrapped — falling back to the plain (escaped) txn id — and the
     * order lookup guarded, then delegate to the grandparent renderer
     * (Widget_Container::_toHtml) instead of core Detail::_toHtml so the
     * fragile original isn't re-entered.
     */
    protected function _toHtml()
    {
        if (!$this->_txn) {
            return Mage_Adminhtml_Block_Widget_Container::_toHtml();
        }

        try {
            $txnIdHtml = Mage::helper('adminhtml/sales')->escapeHtmlWithLinks(
                $this->_txn->getHtmlTxnId(),
                array('a')
            );
        } catch (Throwable $e) {
            // Payment method gone — the rich/linked txn id can't be
            // built; fall back to the raw transaction id.
            $txnIdHtml = $this->escapeHtml($this->_txn->getTxnId());
            Mage::log(
                'Transactions Detail: getHtmlTxnId() fell back to raw id — '
                    . $e->getMessage(),
                Zend_Log::NOTICE
            );
        }
        $this->setTxnIdHtml($txnIdHtml);

        $this->setParentTxnIdUrlHtml($this->escapeHtml(
            $this->getUrl('*/sales_transactions/view',
                array('txn_id' => $this->_txn->getParentId()))
        ));
        $this->setParentTxnIdHtml($this->escapeHtml($this->_txn->getParentTxnId()));

        $order = $this->_txn->getOrder();
        $this->setOrderIncrementIdHtml($this->escapeHtml(
            ($order && $order->getId()) ? $order->getIncrementId() : $this->__('N/A')
        ));

        $this->setTxnTypeHtml($this->escapeHtml($this->_txn->getTxnType()));

        $this->setOrderIdUrlHtml($this->escapeHtml(
            $this->getUrl('*/sales_order/view',
                array('order_id' => $this->_txn->getOrderId()))
        ));

        $this->setIsClosedHtml(
            ($this->_txn->getIsClosed())
                ? Mage::helper('sales')->__('Yes')
                : Mage::helper('sales')->__('No')
        );

        $createdAt = (strtotime($this->_txn->getCreatedAt()))
            ? $this->formatDate(
                $this->_txn->getCreatedAt(),
                Mage_Core_Model_Locale::FORMAT_TYPE_MEDIUM,
                true
            )
            : $this->__('N/A');
        $this->setCreatedAtHtml($this->escapeHtml($createdAt));

        return Mage_Adminhtml_Block_Widget_Container::_toHtml();
    }
}
