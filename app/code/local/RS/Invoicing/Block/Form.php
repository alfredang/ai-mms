<?php
class RS_Invoicing_Block_Form extends Mage_Payment_Block_Form
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('rs_payment/form.phtml');
    }

    public function getCustomFormBlockType()
    {
        return $this->getMethod()->getConfigData('form_block_type');
    }
	
    public function getCustomText($addNl2Br = true)
    {
        return $this->getMethod()->getCustomText($addNl2Br);
    }
}
