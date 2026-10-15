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
      $statusAttrId = (int) Mage::getSingleton('eav/config')
          ->getAttribute(Mage_Catalog_Model_Product::ENTITY, 'status')->getId();
      // Course counts split by enable/disable status (store 0 — status is
      // global on every site). Joining the status row also drops relation
      // rows whose product was deleted, so Total = Active + Disabled.
      $collection->getSelect()
          ->joinLeft(array('relation' => $collection->getTable('customoptions/relation')),
              'relation.group_id = main_table.group_id', array())
          ->joinLeft(array('pst' => $collection->getTable('catalog/product') . '_int'),
              'pst.entity_id = relation.product_id AND pst.store_id = 0 AND pst.attribute_id = ' . $statusAttrId,
              array(
                  'products'          => 'COUNT(DISTINCT pst.entity_id)',
                  'active_products'   => 'COUNT(DISTINCT IF(pst.value = 1, pst.entity_id, NULL))',
                  'disabled_products' => 'COUNT(DISTINCT IF(pst.value <> 1, pst.entity_id, NULL))',
              ))
          ->columns(array(
              'schedule_type' => new Zend_Db_Expr(self::scheduleTypeSql('main_table.title')),
              'duration_code' => new Zend_Db_Expr(self::durationCodeSql('main_table.title')),
          ))
          ->group('main_table.group_id');
      $collection->setShellRequest();
      $this->setCollection($collection);
      return parent::_prepareCollection();
    }

    /** WSQ templates carry "WSQ" in the title ("(SG) WSQ-B09 …"); everything else is non-WSQ. */
    public static function scheduleTypeSql($titleExpr) {
      return "IF({$titleExpr} LIKE '%WSQ%', 'wsq', 'nonwsq')";
    }

    /** Series letter of the template code (A=1 day … E=5 days); 'X' when the title has no A–E code. */
    public static function durationCodeSql($titleExpr) {
      $sql = 'CASE';
      foreach (array_keys(self::getDurationOptions()) as $letter) {
        if ($letter === 'X') continue;
        $sql .= " WHEN {$titleExpr} REGEXP BINARY '(^|[^A-Za-z]){$letter}[0-9]{2}' THEN '{$letter}'";
      }
      return $sql . " ELSE 'X' END";
    }

    public static function getScheduleTypeOptions() {
      return array('wsq' => 'WSQ', 'nonwsq' => 'Non-WSQ');
    }

    public static function getDurationOptions() {
      return array(
        'A' => 'A - 1 day',
        'B' => 'B - 2 days',
        'C' => 'C - 3 days',
        'D' => 'D - 4 days',
        'E' => 'E - 5 days',
        'X' => 'Other',
      );
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
        
        $this->addColumn('schedule_type', array(
            'header'  => $helper->__('Type'),
            'index'   => 'schedule_type',
            'type'    => 'options',
            'options' => self::getScheduleTypeOptions(),
            'width'   => 90,
        ));

        $this->addColumn('duration_code', array(
            'header'  => $helper->__('Duration'),
            'index'   => 'duration_code',
            'type'    => 'options',
            'options' => self::getDurationOptions(),
            'width'   => 100,
        ));

        $this->addColumn('active_products', array(
            'header' => $helper->__('Active Courses'),
            'type'   => 'number',
            'index'  => 'active_products',
            'width'  => 80,
        ));

        $this->addColumn('disabled_products', array(
            'header' => $helper->__('Disabled Courses'),
            'type'   => 'number',
            'index'  => 'disabled_products',
            'width'  => 80,
        ));

        $this->addColumn('products', array(
            'header' => $helper->__('Total Courses'),
            'type'   => 'number',
            'index'  => 'products',
            'width'  => 80,
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
            'header'    => $helper->__('Action'),
            'width'     => 80,
            'renderer'  => 'mmd/customoptions_options_renderer_action',
            'store_id'  => $this->getStoreId(),
            'filter'    => false,
            'sortable'  => false,
            'is_system' => true,
            'align'     => 'center',
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