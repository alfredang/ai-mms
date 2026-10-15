<?php
/**
 * Adds the "Pro Forma Invoice" download button to the admin order view.
 *
 * Wired on adminhtml_block_html_before so it fires for every admin block render;
 * we act only when the block is the sales order view container, where addButton()
 * is available (Mage_Adminhtml_Block_Widget_Form_Container).
 */
class MMD_Proforma_Model_Observer
{
    public function addOrderViewButton(Varien_Event_Observer $observer)
    {
        $block = $observer->getEvent()->getBlock();

        if (!($block instanceof Mage_Adminhtml_Block_Sales_Order_View)) {
            return;
        }

        $order = $block->getOrder();
        if (!$order || !$order->getId()) {
            return;
        }

        // Malaysia is booking-only — quotations / invoices are prepared offline, and this
        // is a Singapore document (SG legal entity, GST), so no button there.
        if ($order->getStore()->getCode() === 'malaysia') {
            return;
        }

        // Respect the standard sales-order ACL: anyone who can view the order
        // can regenerate its pro forma invoice.
        if (!Mage::getSingleton('admin/session')->isAllowed('sales/order')) {
            return;
        }

        $url = $block->getUrl('adminhtml/proforma/print', array('order_id' => $order->getId()));

        $block->addButton('mmd_proforma_invoice', array(
            'label'   => Mage::helper('proforma')->__('Pro Forma Invoice'),
            'onclick' => "setLocation('" . $url . "')",
            'class'   => 'go',
        ));
    }
}
