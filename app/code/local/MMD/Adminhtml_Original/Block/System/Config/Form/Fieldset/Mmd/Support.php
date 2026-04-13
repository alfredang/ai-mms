<?php
/**
 * MMD
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the MMD EULA that is bundled with
 * this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.magemobiledesign.com/LICENSE-1.0.html
 *
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magemobiledesign.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 * or send an email to sales@magemobiledesign.com
 *
 * @category   MMD
 * @package    MMD_Adminhtml
 * @copyright  Copyright (c) 2013 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * MMD Adminhtml extension
 *
 * @category   MMD
 * @package    MMD_Adminhtml
 * @author     MMD Dev Team <developers@magemobiledesign.com>
 */

class MMD_Adminhtml_Block_System_Config_Form_Fieldset_Mmd_Support
	extends MMD_Adminhtml_Block_System_Config_Form_Fieldset_Mmd_Abstract
{
	protected $_dummyElement;
	protected $_fieldRenderer;
	protected $_values;

    public function render(Varien_Data_Form_Element_Abstract $element)
    {
		$html = $this->_getHeaderHtml($element);

		$fields = array(
            array('type' => 'text', 'name' => 'name', 'label' => $this->__('Contact Name'), 'class' => 'required-entry'),
            array('type' => 'text', 'name' => 'email', 'label' => $this->__('Contact Email'), 'class' => 'required-entry validate-email'),
            array('type' => 'text', 'name' => 'subject', 'label' => $this->__('Subject'), 'class' => 'required-entry'),
            array('type' => 'select', 'name' => 'reason', 'label' => $this->__('Reason'), 'values' => $this->_getReasons(), 'class' => 'required-entry', 'onchange' => 'toggleReason();'),
            array('type' => 'text', 'name' => 'other_reason', 'label' => $this->__('Other Reason'), 'class' => 'required-entry', 'onchange' => 'toggleReason();'),
            array('type' => 'textarea', 'name' => 'message', 'label' => $this->__('Message'), 'class' => 'required-entry'),
            array('type' => 'label', 'name' => 'send', 'after_element_html' => '<div class="right"><button type="button" class="scalable save" onclick="mmdSupport();">'.$this->__('Send').'</button></div><div class="notice" id="ajax-response"></div>'),
  		);
        foreach ($fields as $field) {
            $html.= $this->_getFieldHtml($element, $field);
        }
        $html .= $this->_getFooterHtml($element);

        return $html;
    }

    protected function _getFieldRenderer()
    {
    	if (empty($this->_fieldRenderer)) {
    		$this->_fieldRenderer = Mage::getBlockSingleton('adminhtml/system_config_form_field');
    	}
    	return $this->_fieldRenderer;
    }

    protected function _getReasons()
    {
        $modules = array_keys((array)Mage::getConfig()->getNode('modules')->children());

        sort($modules);

        $reasons[] = array('label'=>$this->__('Please select'), 'value'=>'');
        $reasons[] = array('label'=>$this->__('Magento Related Support (paid)'), 'value'=>'Magento v' . Mage::getVersion());
        $reasons[] = array('label'=>$this->__('Request New Extension Development (paid)'), 'value'=>'New Extension');
        foreach ($modules as $moduleName) {
            $name = explode('_', $moduleName, 2);
            if (!isset($name) || $name[0] != 'MMD') {
                continue;
            }
            $moduleConfig = Mage::getConfig()->getNode('modules/' . $moduleName);
            $reasons[] = array('label'=>$this->__('%s Support (free)', $moduleConfig->extension_name . ' v' . $moduleConfig->version), 'value'=>$moduleName.' '.$moduleConfig->version);
        }
        $reasons[] = array('label'=>$this->__('Other Reason'), 'value'=>'other');
    	return $reasons;
    }

    protected function _getFooterHtml($element)
    {
        $ajaxUrl = $this->getUrl('mmd/support');
        $html = parent::_getFooterHtml($element);
        $html = '<h4>'.$this->__('Contact MMD Support Team or visit <a href="%s">%s</a> for additional information', 'http://www.magemobiledesign.com/', 'MMD.com').'</h4>' . $html;
        $html .= Mage::helper('adminhtml/js')->getScript("
            toggleReason = function(){
                if ($('reason').getValue() != 'other'){
                    $('other_reason').up(1).hide();
                    $('other_reason').disable();
                } else {
                    $('other_reason').enable();
                    $('other_reason').up(1).show();
                }
            }
            toggleReason();
            supportForm = new varienForm($('{$element->getHtmlId()}'));
            mmdSupport = function(){
                if (supportForm.validator.validate()){
                    var request = new Ajax.Request(
                        '{$ajaxUrl}',
                        {
                            method:'post',
                            onSuccess: successResponse,
                            parameters: Form.serialize($('{$element->getHtmlId()}'))
                        }
                    );
                }
            }
            successResponse = function(transport){
                if (transport && transport.responseText){
                    try{
                        response = eval('(' + transport.responseText + ')');
                    }
                    catch (e) {
                        response = {};
                    }
                }
                if ((typeof response.message) == 'string') {
                    $('ajax-response').update(response.message);
                } else {
                   $('ajax-response').update(response.message.join(\"\\n\"));
                }
                new PeriodicalExecuter(function(pe){ $('ajax-response').update(''); pe.stop(); }, 5);
            }
        ");

        return $html;
    }

    protected function _getFieldHtml($fieldset, $field)
    {
        $type = $field['type'];
        unset($field['type']);
        $field = $fieldset->addField($field['name'], $type, $field)->setRenderer($this->_getFieldRenderer());

		return $field->toHtml();
    }
}
