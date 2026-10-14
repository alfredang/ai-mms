<?php
class MMD_RegistrationOnly_Block_Form extends Mage_Payment_Block_Form
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('mmd/registrationonly/form.phtml');
    }
}
