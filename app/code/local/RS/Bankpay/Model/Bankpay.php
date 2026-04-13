<?php


class RS_Bankpay_Model_Bankpay extends Mage_Payment_Model_Method_Abstract
{
    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    */
    protected $_code = 'bankpay';

    protected $_formBlockType = 'bankpay/form';
    protected $_infoBlockType = 'bankpay/info';
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
