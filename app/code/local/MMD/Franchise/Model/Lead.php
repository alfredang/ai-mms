<?php
/**
 * @method string getName()
 * @method string getEmail()
 * @method string getTelephone()
 * @method string getCompany()
 * @method string getCountry()
 * @method string getMessage()
 * @method string getStatus()
 * @method string getCreatedAt()
 */
class MMD_Franchise_Model_Lead extends Mage_Core_Model_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_franchise/lead');
    }
}
