<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Block_Edit_Tab_Main extends Mage_Adminhtml_Block_Widget_Form
{

    protected function _prepareForm()
    {
        $iTypeId = Mage::getModel('eav/entity')->setType('mmd_checkout')->getTypeId();
        
        $model = Mage::registry('checkoutoptions_data');

        $form = new Varien_Data_Form(array(
            'id' => 'edit_form',
            'action' => $this->getData('action'),
            'method' => 'post'
        ));

        $fieldset = $form->addFieldset('base_fieldset',
            array('legend'=>Mage::helper('catalog')->__('Attribute Properties'))
        );
        if ($model->getId()) {
            $fieldset->addField('attribute_id', 'hidden', array(
                'name' => 'attribute_id',
            ));
        }

        $this->_addElementTypes($fieldset);

        $yesno = array(
            array(
                'value' => 0,
                'label' => Mage::helper('catalog')->__('No')
            ),
            array(
                'value' => 1,
                'label' => Mage::helper('catalog')->__('Yes')
            ));

        $fieldset->addField('attribute_code', 'text', array(
            'name'  => 'attribute_code',
            'label' => Mage::helper('catalog')->__('Attribute Code'),
            'title' => Mage::helper('catalog')->__('Attribute Code'),
            'note'  => Mage::helper('catalog')->__('For internal use. Must be unique with no spaces'),
            'class' => 'validate-code',
            'required' => true,
        ));

        $inputTypes = array(
            array(
                'value' => 'text',
                'label' => Mage::helper('catalog')->__('Text Field')
            ),
            array(
                'value' => 'textarea',
                'label' => Mage::helper('catalog')->__('Text Area')
            ),
            array(
                'value' => 'date',
                'label' => Mage::helper('catalog')->__('Date')
            ),
            array(
                'value' => 'boolean',
                'label' => Mage::helper('catalog')->__('Yes/No')
            ),
            array(
                'value' => 'multiselect',
                'label' => Mage::helper('catalog')->__('Multiple Select')
            ),
            array(
                'value' => 'select',
                'label' => Mage::helper('catalog')->__('Dropdown')
            ),
            array(
                'value' => 'checkbox',
                'label' => Mage::helper('catalog')->__('Checkbox')
            ),
            array(
                'value' => 'radio',
                'label' => Mage::helper('catalog')->__('Radiobutton')
            ),
            array(
                'value' => 'static',
                'label' => Mage::helper('catalog')->__('Static Text')
            )
        );

        $response = new Varien_Object();
        $response->setTypes(array());

        $_disabledTypes = array();
        $_hiddenFields = array();
        foreach ($response->getTypes() as $iTypeId) {
            $inputTypes[] = $iTypeId;
            if (isset($iTypeId['hide_fields'])) {
                $_hiddenFields[$iTypeId['value']] = $iTypeId['hide_fields'];
            }
            if (isset($iTypeId['disabled_types'])) {
                $_disabledTypes[$iTypeId['value']] = $iTypeId['disabled_types'];
            }
        }
        Mage::register('attribute_type_hidden_fields', $_hiddenFields);
        Mage::register('attribute_type_disabled_types', $_disabledTypes);


        $fieldset->addField('frontend_input', 'select', array(
            'name' => 'frontend_input',
            'label' => Mage::helper('catalog')->__('Input Type'),
            'title' => Mage::helper('catalog')->__('Input Type'),
            'value' => 'text',
            'values'=> $inputTypes
        ));
        
        $fieldset->addField('frontend_class', 'select', array(
            'name'  => 'frontend_class',
            'label' => Mage::helper('catalog')->__('Input Validation'),
            'title' => Mage::helper('catalog')->__('Input Validation'),
            'values'=>  array(
                array(
                    'value' => '',
                    'label' => Mage::helper('catalog')->__('None')
                ),
                array(
                    'value' => 'validate-number',
                    'label' => Mage::helper('catalog')->__('Decimal Number')
                ),
                array(
                    'value' => 'validate-digits',
                    'label' => Mage::helper('catalog')->__('Integer Number')
                ),
                array(
                    'value' => 'validate-email',
                    'label' => Mage::helper('catalog')->__('Email')
                ),
                array(
                    'value' => 'validate-url',
                    'label' => Mage::helper('catalog')->__('Url')
                ),
                array(
                    'value' => 'validate-alpha',
                    'label' => Mage::helper('catalog')->__('Letters')
                ),
                array(
                    'value' => 'validate-alphanum',
                    'label' => Mage::helper('catalog')->__('Letters(a-zA-Z) or Numbers(0-9)')
                ),
            )
        ));

        $fieldset->addField('is_filterable', 'select', array(
            'name'  => 'is_filterable',
            'label' => Mage::helper('catalog')->__('Attribute Placeholder'),
            'title' => Mage::helper('catalog')->__('Attribute Placeholder'),
            'note'  => Mage::helper('catalog')->__('If you choose "On Top", the attribute will be displayed in the top placeholder of the checkout step and vice versa if you choose "At the Bottom"'),
            'required' => true,
            'values'=>  array(
                array(
                    'value' => 1,
                    'label' => Mage::helper('catalog')->__('On Top')
                ),
                array(
                    'value' => 2,
                    'label' => Mage::helper('catalog')->__('At the bottom')
                ),
            )
        ));

        $fieldset->addField('position', 'text', array(
            'name'  => 'position',
            'label' => Mage::helper('catalog')->__('Position in Placeholder'),
            'title' => Mage::helper('catalog')->__('Position in Placeholder'),
            'note' => Mage::helper('catalog')->__('Can be used to manage attributes\' positions when there are more than one attribute in one placeholder'),
            'class' => 'validate-digits',
        ));
        
        
        
    /****** champs cach�s dans le formulaire **********/
        $fieldset->addField('entity_type_id', 'hidden', array(
            'name' => 'entity_type_id',
            'value' => $iTypeId
        ));
        
        
        
        $fieldset->addField('is_user_defined', 'hidden', array(
            'name' => 'is_user_defined',
            'value' => 1
        ));

 /************    START MMD CHECKOUT ATTRIBUTES          ************/
        
        $fieldset->addField('default_value_text', 'text', array(
            'name' => 'default_value_text',
            'label' => Mage::helper('catalog')->__('Default value'),
            'title' => Mage::helper('catalog')->__('Default value'),
            'value' => $model->getDefaultValue(),
        ));

        $fieldset->addField('default_value_yesno', 'select', array(
            'name' => 'default_value_yesno',
            'label' => Mage::helper('catalog')->__('Default value'),
            'title' => Mage::helper('catalog')->__('Default value'),
            'values' => $yesno,
            'value' => $model->getDefaultValue(),
        ));

        $dateFormatIso = Mage::app()->getLocale()->getDateFormat(Mage_Core_Model_Locale::FORMAT_TYPE_SHORT);
        $dateElement = $fieldset->addField('default_value_date', 'date', array(
            'name'   => 'default_value_date',
            'label'  => Mage::helper('catalog')->__('Default value'),
            'title'  => Mage::helper('catalog')->__('Default value'),
            'image'  => $this->getSkinUrl('images/grid-cal.gif'),
            'value'  => $model->getDefaultValue(),
            'format' => $dateFormatIso
        ));
        $dateElement->setValue($model->getDefaultValue(),$dateFormatIso);

        $fieldset->addField('default_value_textarea', 'textarea', array(
            'name' => 'default_value_textarea',
            'label' => Mage::helper('catalog')->__('Default value'),
            'title' => Mage::helper('catalog')->__('Default value'),
            'value' => $model->getDefaultValue(),
        ));
        
        $fieldset->addField('default_value_static', 'textarea', array(
            'name' => 'default_value_static',
            'label' => Mage::helper('catalog')->__('Text'),
            'title' => Mage::helper('catalog')->__('Text'),
            'value' => $model->getDefaultValue(),
        ));
        
        
        
        // for one page checkout
        
        $fieldset->addField('is_searchable', 'select', array(
            'name'  => 'is_searchable',
            'label' => Mage::helper('catalog')->__('Step (for one page)'),
            'title' => Mage::helper('catalog')->__('Step (for one page)'),
            'note'  => Mage::helper('catalog')->__('Add the attribute to a step of the one page checkout'),
            'values'=> Mage::helper('checkoutoptions')->getStepData('onepage'),
        ));
        
        // for multi-address checkout
        
        $fieldset->addField('is_comparable', 'select', array(
            'name'  => 'is_comparable',
            'label' => Mage::helper('catalog')->__('Step (for multi-address)'),
            'title' => Mage::helper('catalog')->__('Step (for multi-address)'),
            'note'  => Mage::helper('catalog')->__('Add the attribute to a step of the multi-address checkout'),
            'values'=> Mage::helper('checkoutoptions')->getStepData('multipage'),
        ));

        
        // new field
        
        $fieldset->addField('used_in_product_listing', 'select', array(
            'name'  => 'used_in_product_listing',
            'label' => Mage::helper('catalog')->__('Add default "Please Select" option'),
            'title' => Mage::helper('catalog')->__('Add default "Please Select" option'),
            'note'  => Mage::helper('catalog')->__('If set to "Yes" and Values Are Required customers will not be able to proceed to the next checkout step until they select a different option'),
            'value' => 0,
            'values' => $yesno,
        ));
        
        
        
 /************    FINISH MMD CHECKOUT ATTRIBUTES          ************/
 
        $fieldset->addField('is_required', 'select', array(
            'name' => 'is_required',
            'label' => Mage::helper('catalog')->__('Values Required'),
            'title' => Mage::helper('catalog')->__('Values Required'),
            'values' => $yesno,
        ));

        $fieldset->addField('is_used_for_price_rules', 'select', array(
            'name' => 'is_used_for_price_rules',
            'label' => Mage::helper('catalog')->__('Display on Order Page in Admin Area'),
            'title' => Mage::helper('catalog')->__('Display on Order Page in Admin Area'),
            'value' => 1,
            'values' => $yesno,
        ));
        
        $fieldset->addField('is_display_in_invoice', 'select', array(
            'name' => 'is_display_in_invoice',
            'label' => Mage::helper('catalog')->__('Display on Invoice Page in Admin Area'),
            'title' => Mage::helper('catalog')->__('Display on Invoice Page in Admin Area'),
            'value' => 1,
            'values' => $yesno,
        ));
        


        $fieldset->addField('is_filterable_in_search', 'select', array(
            'name' => 'is_filterable_in_search',
            'label' => Mage::helper('catalog')->__('Display on Order Page in Member Area'),
            'title' => Mage::helper('catalog')->__('Display on Order Page in Member Area'),
            'value' => 1,
            'values' => $yesno,
        ));
        


        $fieldset->addField('mmd_filterable', 'select', array(
            'name' => 'mmd_filterable',
            'label' => Mage::helper('catalog')->__('Use on Sales Grid'),
            'title' => Mage::helper('catalog')->__('Use on Sales Grid'),
            'value' => 0,
            'values' => $yesno,
        ));


        $fieldset->addField('mmd_registration_page', 'select', array(
            'name' => 'mmd_registration_page',
            'label' => Mage::helper('catalog')->__('Use on Registration Page'),
            'title' => Mage::helper('catalog')->__('Use on Registration Page'),
            'value' => 0,
            'values' => $yesno,
        ));
        
        $fieldset->addField('mmd_registration_place', 'select', array(
            'name'  => 'mmd_registration_place',
            'label' => Mage::helper('catalog')->__('Attribute Placeholder (Registration)'),
            'title' => Mage::helper('catalog')->__('Attribute Placeholder (Registration)'),
            'note'  => Mage::helper('catalog')->__('If you choose "On Top", the attribute will be displayed in the top placeholder of the registration page and vice versa if you choose "At the Bottom"'),
            'values'=>  array(
                array(
                    'value' => 1,
                    'label' => Mage::helper('catalog')->__('On Top')
                ),
                array(
                    'value' => 2,
                    'label' => Mage::helper('catalog')->__('At the bottom')
                ),
            )
        ));

        $fieldset->addField('mmd_registration_position', 'text', array(
            'name'  => 'mmd_registration_position',
            'label' => Mage::helper('catalog')->__('Position in Placeholder (Registration)'),
            'title' => Mage::helper('catalog')->__('Position in Placeholder (Registration)'),
            'note' => Mage::helper('catalog')->__('Can be used to manage attributes\' positions on registration page when there are more than one attribute in one placeholder'),
            'class' => 'validate-digits',
        ));

        $fieldset->addField('mmd_in_excel', 'select', array(
            'name' => 'mmd_in_excel',
            'label' => Mage::helper('catalog')->__('Use for excel export'),
            'title' => Mage::helper('catalog')->__('Use for excel export'),
            'value' => 1,
            'values' => $yesno,
        ));
        
        $fieldset->addField('mmd_product_category_dependant', 'select', array(
            'name' => 'mmd_product_category_dependant',
            'label' => Mage::helper('catalog')->__('Depends on product/category of product in cart'),
            'title' => Mage::helper('catalog')->__('Depends on product/category of product in cart'),
            'value' => 0,
            'values' => $yesno,
            'note' => Mage::helper('catalog')->__('Only displayed if certain product or product of certain category is added to cart'),            
        ));        

        if ($model->getId()) {
            $form->getElement('attribute_code')->setDisabled(1);
            $form->getElement('frontend_input')->setDisabled(1);

            if (isset($disableAttributeFields[$model->getAttributeCode()])) {
                foreach ($disableAttributeFields[$model->getAttributeCode()] as $field) {
                    $form->getElement($field)->setDisabled(1);
                }
            }
        }

        $form->addValues($model->getData());
        
        $this->setForm($form);

        return parent::_prepareForm();
    }

    protected function _getAdditionalElementTypes()
    {
        return array(
            'apply' => Mage::getConfig()->getBlockClassName('adminhtml/catalog_product_helper_form_apply')
        );
    }

}