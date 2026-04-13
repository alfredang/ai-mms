<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Abstract
{ 
    protected $_type       = '';
    protected $_label      = '';
    protected $_fieldLabel = '';
    
    protected $_errors    = array();    
    
    public function __construct($type='')
    {
        $this->_type = $type;
    }
    
    /**
     * Factory method. Creates a new command object by its type
     *
     * @param string $type command type
     * @return MMD_Catalogmanagement_Model_Command_Abstract
     */
    public static function factory($type)
    {
        $className = 'MMD_Catalogmanagement_Model_Command_' . ucfirst($type);
        return new $className($type);
    }
    
    /**
     * Executes the command
     *
     * @param array $ids product ids
     * @param int $storeId store id
     * @param string $val field value
     * @return string success message if any
     */
    public function execute($ids, $storeId, $val)
    {
        $this->_errors = array();
        
        $hlp = Mage::helper('catalogmanagement');
        if (!is_array($ids)) {
            throw new Exception($hlp->__('Please select product(s)')); 
        }
        if (!strlen($val)) {
            throw new Exception($hlp->__('Please provide the value for the action')); 
        }                  
               
        return '';
    }
    
    /**
     * Adds the command label to the mass actions list
     *
     * @param MMD_Catalogmanagement_Block_Adminhtml_Catalog_Product_Grid $grid
     * @return MMD_Catalogmanagement_Model_Command_Abstract
     */
    public function addAction($grid)
    {
        $storeId = intVal(Mage::app()->getRequest()->getParam('store'));
        $grid->getMassactionBlock()->addItem('catalogmanagement_' . $this->_type, array(
            'label'      => $grid->__($this->_label),
		    'url'        => $grid->getUrl('catalogmanagement/adminhtml_index/do/command/' . $this->_type . '/store/'.$storeId), 
            'additional' => $this->_getValueField($grid->__($this->_fieldLabel)),		    
        ));
        
        return $this;         
    }    
    
    /**
     * Returns value field options for the mass actions block
     *
     * @param string $title field title
     * @return array
     */
    protected function _getValueField($title)
    {
        $field = array('catalogmanagement_value' => array(
            'name'  => 'catalogmanagement_value',
            'type'  => 'text',
            'class' => 'required-entry',
            'label' => $title,
        )); 
        return $field;       
    }
    
    /**
     * Gets list of not critical errors after the command execution
     *
     * @return array
     */
    public function getErrors()
    {
        return $this->_errors;       
    }   
    

}