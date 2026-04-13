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
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @copyright  Copyright (c) 2012 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

class MMD_Adminhtml_Block_Customoptions_Options_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct() {
      parent::__construct();

      $this->setId('customoptionsOptionsGrid');
      $this->setDefaultSort('title');
      $this->setDefaultDir(Varien_Data_Collection::SORT_ORDER_ASC);
      $this->setSaveParametersInSession(true);
    }

    protected function _prepareCollection() {
      $collection = Mage::getModel('customoptions/group')->getCollection();
      $collection->addProductsCount()->setShellRequest();      
      $this->setCollection($collection);
      return parent::_prepareCollection();
    }

    protected function getStoreId() {
        return Mage::registry('store_id');
    }

    protected function _prepareColumns() {
        $helper = $this->_getHelper();
        $this->addColumn('title', array(
            'header' => $helper->__('Title'),
            'index' => 'title',
            'align' => 'left',
        ));
        
        $this->addColumn('products', array(
            'header' => $helper->__('Products'),
            'type' => 'number',
            'index' => 'products',
            'width' => 80
        ));

	
		$this->addColumn('is_active', array(
            'header' => $helper->__('Status'),
            'width' => 80,
            'index' => 'is_active',
            'type' => 'options',
            'options' => $helper->getOptionStatusArray(),
            'align' => 'center'
        ));

        $this->addColumn('action', array(
            'header' => $helper->__('Action'),
            'width' => 100,
            'type' => 'action',
            'getter' => 'getId',
            'actions' => array(
                array(
                    'caption' => $helper->__('Edit'),
                    'url' => array('base' => '*/*/edit', array('store' => $this->getStoreId())),
                    'field' => 'group_id'
                )
            ),
            'filter' => false,
            'sortable' => false,
            'index' => 'stores',
            'is_system' => true,
            'align' => 'center'
        ));

        return parent::_prepareColumns();
    }

    protected function _afterLoadCollection() {
        $this->getCollection()->walk('afterLoad');
        parent::_afterLoadCollection();
    }

    protected function _prepareMassaction()
    {
    	$helper = $this->_getHelper();
        $this->setMassactionIdField('group_id');
        $this->getMassactionBlock()->setFormFieldName('groups');

        $this->getMassactionBlock()->addItem('delete', array(
             'label'   => $helper->__('Delete'),
             'url'     => $this->getUrl('*/*/massDelete', array('store' => $this->getStoreId())),
             'confirm' => $helper->__('If you delete this item(s) all the options inside will be deleted as well?')
        ));

        $statuses = $helper->getOptionStatusArray();
        array_unshift($statuses, array('label' => '', 'value' => ''));

        $this->getMassactionBlock()->addItem('status', array(
             'label'      => $helper->__('Change status'),
             'url'        => $this->getUrl('*/*/massStatus', array('_current' => true, 'store' => $this->getStoreId())),
             'additional' => array(
	             'visibility' => array(
	                  'name'   => 'is_active',
	                  'type'   => 'select',
	                  'class'  => 'required-entry',
	                  'label'  => $helper->__('Status'),
	                  'values' => $statuses
	              )
             )
        ));
        return $this;
    }

    protected function _getHelper()
    {
    	return Mage::helper('customoptions');
    }

    public function getRowUrl($row)
    {
      return $this->getUrl('*/*/edit', array('group_id' => $row->getGroupId(), 'store' => $this->getStoreId()));
    }
}