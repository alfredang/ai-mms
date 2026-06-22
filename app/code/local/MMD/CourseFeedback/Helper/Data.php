<?php
class MMD_CourseFeedback_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function getRecipients()
    {
        $raw = (string) Mage::getStoreConfig('mmd_coursefeedback/lead/recipient_email');
        $list = array_values(array_filter(array_map('trim', preg_split('/[,;]+/', $raw) ?: array())));
        return $list ?: array('angch@tertiaryinfotech.com');
    }
}
