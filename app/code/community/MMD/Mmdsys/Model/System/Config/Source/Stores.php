<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Model_System_Config_Source_Stores
{
    public function toOptionArray()
    {
        $storeModel = Mage::getSingleton('adminhtml/system_store');
        /* @var $storeModel Mage_Adminhtml_Model_System_Store */
        
        $options = array();
        
        foreach ($storeModel->getWebsiteCollection() as $website) {
            $groupOptions = array();
            foreach ($storeModel->getGroupCollection() as $group) {
                if ($group->getWebsiteId() != $website->getId()) {
                    continue;
                }
                $groupOptions[] = array('label' => $group->getName(), 'value' => $group->getId());
            }
            $options[] = array('label' => $website->getName(), 'value' => $groupOptions);
        }
        return $options;
    }
}