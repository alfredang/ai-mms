<?php


class RS_Invoicing_Model_Invoicing extends Mage_Payment_Model_Method_Abstract
{
    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    */
    protected $_code = 'invoicing';

    protected $_formBlockType = 'invoicing/form';
    protected $_infoBlockType = 'invoicing/info';
	protected $canUseCheckout    = TRUE;
  
   

    public function getCustomText($addNl2Br = true)
    {
        $customText = $this->getConfigData('customtext');
        if ($addNl2Br) {
            $customText = nl2br($customText);
        }
        return $customText;
    }
   
}
