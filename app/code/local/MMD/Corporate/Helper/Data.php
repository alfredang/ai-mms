<?php
class MMD_Corporate_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function getRecipients()
    {
        $raw = (string) Mage::getStoreConfig('mmd_corporate/lead/recipient_email');
        $list = array_values(array_filter(array_map('trim', preg_split('/[,;]+/', $raw) ?: array())));
        return $list ?: array('angch@tertiaryinfotech.com');
    }
}
