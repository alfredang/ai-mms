<?php
/**
 * Override user edit form:
 * - Hide username field (auto-set from email)
 * - Remove current admin password requirement
 * - Lower password restrictions
 */
class MMD_Adminhtml_Block_Permissions_User_Edit_Tab_Main extends Mage_Adminhtml_Block_Permissions_User_Edit_Tab_Main
{
    protected function _prepareForm()
    {
        $model = Mage::registry('permissions_user');

        $form = new Varien_Data_Form();
        $form->setHtmlIdPrefix('user_');

        $fieldset = $form->addFieldset('base_fieldset', [
            'legend' => Mage::helper('adminhtml')->__('Account Information')
        ]);

        if ($model->getUserId()) {
            $fieldset->addField('user_id', 'hidden', ['name' => 'user_id']);
        } else {
            if (!$model->hasData('is_active')) {
                $model->setIsActive(1);
            }
        }

        // Hidden username — auto-synced from email via JS
        $fieldset->addField('username', 'hidden', ['name' => 'username']);

        $fieldset->addField('firstname', 'text', [
            'name' => 'firstname',
            'label' => Mage::helper('adminhtml')->__('First Name'),
            'required' => true,
        ]);

        $fieldset->addField('lastname', 'text', [
            'name' => 'lastname',
            'label' => Mage::helper('adminhtml')->__('Last Name'),
            'required' => true,
        ]);

        $fieldset->addField('email', 'text', [
            'name' => 'email',
            'label' => Mage::helper('adminhtml')->__('Email'),
            'class' => 'required-entry validate-email',
            'required' => true,
            'after_element_html' => '<script type="text/javascript">
                document.observe("dom:loaded", function(){
                    var emailEl = $("user_customer_email") || $("user_email");
                    if (emailEl) {
                        emailEl.observe("change", function(){ $("user_username").value = this.value; });
                        emailEl.observe("keyup", function(){ $("user_username").value = this.value; });
                        if (!$("user_username").value && emailEl.value) $("user_username").value = emailEl.value;
                    }
                });
            </script>',
        ]);

        if ($model->getUserId()) {
            $fieldset->addField('password', 'password', [
                'name' => 'new_password',
                'label' => Mage::helper('adminhtml')->__('New Password'),
                'note' => 'Leave blank to keep current password.',
            ]);
        } else {
            $fieldset->addField('password', 'password', [
                'name' => 'password',
                'label' => Mage::helper('adminhtml')->__('Password'),
                'required' => true,
            ]);
        }

        $fieldset->addField('confirmation', 'password', [
            'name' => 'password_confirmation',
            'label' => Mage::helper('adminhtml')->__('Password Confirmation'),
        ]);

        if (Mage::getSingleton('admin/session')->getUser()->getId() != $model->getUserId()) {
            $fieldset->addField('is_active', 'select', [
                'name' => 'is_active',
                'label' => Mage::helper('adminhtml')->__('This account is'),
                'values' => [
                    ['label' => Mage::helper('adminhtml')->__('Active'), 'value' => 1],
                    ['label' => Mage::helper('adminhtml')->__('Inactive'), 'value' => 0],
                ],
            ]);
        }

        $data = $model->getData();
        unset($data['password']);
        // Auto-set username from email for new users
        if (empty($data['username']) && !empty($data['email'])) {
            $data['username'] = $data['email'];
        }
        $form->setValues($data);
        $this->setForm($form);

        return Mage_Adminhtml_Block_Widget_Form::_prepareForm();
    }
}
