<?php


class RS_Citrep_Model_Citrep extends Mage_Payment_Model_Method_Abstract
{
    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    */
    protected $_code = 'citrep';

    protected $_formBlockType = 'citrep/form';
    protected $_infoBlockType = 'citrep/info';
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
