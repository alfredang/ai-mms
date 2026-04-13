<?php


class RS_Cheque_Model_Cheque extends Mage_Payment_Model_Method_Abstract
{
    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    */
    protected $_code = 'cheque';

    protected $_formBlockType = 'cheque/form';
    protected $_infoBlockType = 'cheque/info';
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
