<?php


class RS_Sfec_Model_Sfec extends Mage_Payment_Model_Method_Abstract
{
    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    */
    protected $_code = 'sfec';

    protected $_formBlockType = 'sfec/form';
    protected $_infoBlockType = 'sfec/info';
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
