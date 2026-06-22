<?php
class MMD_Franchise_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Franchise enquiry notification recipient(s) — comma/semicolon separated. */
    public function getRecipients()
    {
        $raw = (string) Mage::getStoreConfig('mmd_franchise/lead/recipient_email');
        $list = array_values(array_filter(array_map('trim', preg_split('/[,;]+/', $raw) ?: array())));
        return $list ?: array('angch@tertiaryinfotech.com');
    }
}
