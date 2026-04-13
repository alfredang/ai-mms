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
class MMD_Checkoutoptions_IndexController extends Mage_Adminhtml_Controller_Action
{

    protected $_checkoutTypeId;	
    protected $_type;
    public function preDispatch()
    {
        parent::preDispatch();
        $this->_checkoutTypeId = Mage::getModel('eav/entity')->setType('mmd_checkout')->getTypeId();
        $this->_type = 'checkout';
    }
    
    protected function _initAction($ids=null) {
        $this->loadLayout($ids);
        return $this;
    }
	
    public function indexAction()
    {
        $this->_initAction()
                ->_setActiveMenu('system/mmd')
                ->_addContent($this->getLayout()->createBlock('checkoutoptions/Grid'));
        $this->renderLayout();
    }
        
    public function _initItem()
    {
        $id     = (int)$this->getRequest()->getParam('attribute_id');
        $model = Mage::getModel('catalog/resource_eav_attribute');
        $oResource = Mage::getResourceModel('eav/entity_attribute');
        $collection = Mage::getResourceModel('eav/entity_attribute_collection');
        $collection->getSelect()->join(
            array('additional_table' => $oResource->getTable('catalog/eav_attribute')),
            'additional_table.attribute_id=main_table.attribute_id'
        );

        $collection->getSelect()->where('main_table.attribute_id = ' . $id);                

        $aAttributeList = $collection->getData();

        if ($aAttributeList and !empty($aAttributeList[0]))
        {
            $model->load($id);
            $model->addData($aAttributeList[0]);
        }

        if ($model->getId() || $id == 0) {
            $data = Mage::getSingleton('adminhtml/session')->getFormData(true);
            if (!empty($data)) {
                    $model->setData($data);
            }
            Mage::register('checkoutoptions_data', $model);
            Mage::register('current_product', $model);
            return true;
        }
        else
        {
            return false;
        }
    }
        
    public function categoriesAction()
    {
        $this->_initItem();
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('checkoutoptions/edit_tab_categories')->toHtml()
        );
    }    
        
     public function categoriesJsonAction()
    {
         $this->_initItem();
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('checkoutoptions/edit_tab_categories')
                ->getCategoryChildrenJson($this->getRequest()->getParam('category'))
        );
    }        

    
    public function relatedAction()
    {
        $this->_initItem();
        
        $grid = $this->getLayout()->createBlock('checkoutoptions/edit_tab_related')
            ->setProductsRelated(Mage::getModel('checkoutoptions/attributecatalogrefs')->getRefs(Mage::app()->getRequest()->getParam('attribute_id'),'product'));
        $serializer = $this->getLayout()->createBlock('adminhtml/widget_grid_serializer');
        $serializer ->initSerializerBlock($grid, 'getSelectedRelatedProducts', 'in_products', 'products_related');
        $this->getResponse()->setBody(
            $grid->toHtml().$serializer->toHtml()
            );        

    }    

    public function relatedGridAction()
    {
        $this->_initItem();
        $this->getResponse()->setBody(
        $this->getLayout()->createBlock('checkoutoptions/edit_tab_related')
            ->setProductsRelated($this->getRequest()->getPost('products_related', null))->toHtml());

    }    
    
    public function editAction() 
    {
        
        if($this->_initItem()){

            $this->loadLayout();
            $this->_setActiveMenu('system/mmd');
            $this->getLayout()->getBlock('head')->setCanLoadExtJs(true);
            $this->_addContent($this->getLayout()->createBlock('checkoutoptions/edit'))
                 ->_addLeft($this->getLayout()->createBlock('checkoutoptions/edit_tabs'));
            $this->renderLayout();
                
        } else {
            
            Mage::getSingleton('adminhtml/session')->addError(Mage::helper('checkoutoptions')->__('Item does not exist'));
            $this->_redirect('*/*/');
            
        }
    }
 
    public function newAction() 
    {
            $this->_forward('edit');
    }
	
    public function validateAction()
    {
        $response = new Varien_Object();
        $response->setError(false);
        
        $attributeCode  = $this->getRequest()->getParam('attribute_code');
        $attributeId    = $this->getRequest()->getParam('attribute_id');
        $attribute = Mage::getModel('catalog/resource_eav_attribute')
                ->loadByCode($this->_checkoutTypeId, $attributeCode);

        if ($attribute->getId() && !$attributeId) {
            Mage::getSingleton('adminhtml/session')->addError(Mage::helper('catalog')->__('Attribute with the same code already exists'));
            $this->_initLayoutMessages('adminhtml/session');
            $response->setError(true);
            $response->setMessage($this->getLayout()->getMessagesBlock()->getGroupedHtml());
        }

        $this->getResponse()->setBody($response->toJson());
        
    }
    /* to refactor*/
	public function saveAction() {
				
		if ($data = $this->getRequest()->getPost()) {

		    $model = Mage::getModel('catalog/resource_eav_attribute');		    
            /* @var $model Mage_Catalog_Model_Entity_Attribute */

            if ($id = $this->getRequest()->getParam('attribute_id'))
            {
                $model->load($id);
                $data['attribute_code'] = $model->getAttributeCode();
                $data['frontend_input'] = $model->getFrontendInput();
            }
			
            $sRealInput = $data['frontend_input'];
            
            if ($data['frontend_input'] == 'checkbox')
            {
                $data['frontend_input'] = 'multiselect';
            }
            
            if ($data['frontend_input'] == 'radio')
            {
                $data['frontend_input'] = 'select';
            }
            
            $defaultValueField = $model->getDefaultValueByInput($data['frontend_input']);
            if($data['frontend_input']==='static')
            {
                $defaultValueField = 'default_value_static';
            }
            
            if ($defaultValueField) {
                $data['default_value'] = $this->getRequest()->getParam($defaultValueField);
            }
			
			// process website/store assign

			if (!isset($data['is_visible_in_advanced_search']))
			{
			    $data['is_visible_in_advanced_search'] = 0;
			}
			
            if (!isset($data['is_configurable'])) {
                $data['is_configurable'] = 0;
            }
            if (!isset($data['is_filterable'])) {
                $data['is_filterable'] = 0;
            }
            if (!isset($data['is_filterable_in_search'])) {
                $data['is_filterable_in_search'] = 0;
            }
			
			if (!$data['is_visible_in_advanced_search']) // is not global
			{
    			if (isset($data['assign_website']) AND $data['assign_website'])
    			{
    			    $data['apply_to'] = implode(',', array_keys($data['assign_website']));
    			}
    			else 
    			{
    			    $data['apply_to'] = '';
    			}
    			
    			if (isset($data['assign_store']) AND $data['assign_store'])
    			{
    			    $sCommonData = '';
    			    
    			    $aStoreHash = array();
    			    
    			    foreach ($data['assign_store'] as $iWebsiteKey => $aStoreData)
    			    {
    			        $aStoreHash[] = implode(',', $aStoreData);
    			    }
    			    
    			    $data['note'] = implode(',', $aStoreHash);
    			}
    			else 
    			{
    			    $data['note'] = '';
    			}
			}
			

            $data['backend_type'] = $model->getBackendTypeByInput($data['frontend_input']);

            if(!isset($data['apply_to'])) {
                $data['apply_to'] = array();
            }
            
            if (!isset($data['is_global'])) {
                $data['is_global'] = 0;
            }
            
            if (!isset($data['is_unique'])) {
                $data['is_unique'] = 0;
            }
            
            if (!isset($data['is_wysiwyg_enabled'])) {
                $data['is_wysiwyg_enabled'] = 0;
            }
            
            if (!isset($data['is_html_allowed_on_front'])) {
                $data['is_html_allowed_on_front'] = 1;
            }
            
            if (!isset($data['is_visible_on_front'])) {
                $data['is_visible_on_front'] = 1;
            }
            
            if (!isset($data['used_for_sort_by'])) {
                $data['used_for_sort_by'] = 1;
            }
            if (in_array($data['frontend_input'], array('multiselect', 'select', 'radio', 'checkbox')))
            {
                $data['source_model']='eav/entity_attribute_source_table';
            }
            if ($data['frontend_input']==='date')
            {
                $data['backend_type']='varchar';   
            }

            $model->addData($data);


            $iProductEntityTypeId = Mage::getModel('eav/entity')->setType('catalog_product')->getTypeId(); // to imitate product attribute saving
            $model->setEntityTypeId($iProductEntityTypeId);
            $model->setIsUserDefined(1);

			
			try {

//                if (in_array($data['frontend_input'], array('multiselect', 'select', 'radio', 'checkbox')))
//                {
//                    echo '<pre>';print_r($data); echo '</pre>';
//                    if (!empty($data['default']))
//                    {
//                        $sDefValue = $data['default'];
//                    }
//                    else 
//                    {
//                        $sDefValue = '';
//                    }
//                }
//                else 
//                {
//        			$sDefValue = $model->getDefaultValue();
//                }


				$model->save();

				$id=$model->getId();
                                                                
                if (isset($data['frontend_desc']))
				{
                    Mage::getModel('checkoutoptions/attributecustomergroups')->saveGroups($id, $data['customer_group_ids']);
                }
                                                                
                if (isset($data['category_ids']))
				{
                    $category_ids = explode(',',$data['category_ids']);
                    $category_ids = array_unique($category_ids);
                    Mage::getModel('checkoutoptions/attributecatalogrefs')->saveRefs($id, 'category',$category_ids);
                }
                                                                
                if (isset($data['in_products']))
				{  
                    $product_ids = explode('&',$data['in_products']);
                    $product_ids = array_unique($product_ids);                    
                    Mage::getModel('checkoutoptions/attributecatalogrefs')->saveRefs($id, 'product',$product_ids);
                }
                                                                
                // save descs
				
				$aDescription = array();
				
				if (isset($data['frontend_desc']) AND $data['frontend_desc'])
				{
				    $aDescription = $data['frontend_desc'];
				}
				
				Mage::getModel('checkoutoptions/checkoutoptions')->saveAttributeDescription($id, $aDescription);

			    $oUpdateModel = Mage::getModel('catalog/entity_attribute');
			    $oUpdateModel->load($id);
				
				if ($data['frontend_input'] != $sRealInput)
				{
    				$oUpdateModel->setFrontendInput($sRealInput);
				}
				
//				if ($sDefValue AND is_array($sDefValue))
//				{
//				    $sDefValue = implode(',', $sDefValue);
//				}
//				
//
//				$oUpdateModel->setDefaultValue($sDefValue);
				$oUpdateModel->setMMDflag(true);
                $oUpdateModel->setEntityTypeId($this->_checkoutTypeId);
			    $oUpdateModel->save();

				
				// save need select
				
				$aNeedSelect = array();
				
				if (isset($data['frontend_need_sel']) AND $data['frontend_need_sel'])
				{
				    $aNeedSelect = $data['frontend_need_sel'];
				}
				
				Mage::getModel('checkoutoptions/checkoutoptions')->saveAttributeNeedSelect($id, $aNeedSelect);
				
				
                /**
                 * Clear translation cache because attribute labels are stored in translation
                 */
                Mage::getSingleton('adminhtml/session')->setAttributeData(false);
				
				
				Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('checkoutoptions')->__('Item was successfully saved'));
				Mage::getSingleton('adminhtml/session')->setFormData(false);

				if ($this->getRequest()->getParam('back')) {
					$this->_redirect('*/*/edit', array('attribute_id' => $id));
					return;
				}
				
				$this->_redirect('*/*/index/filter//');
				return;
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                Mage::getSingleton('adminhtml/session')->setFormData($data);
                $this->_redirect('*/*/edit', array('attribute_id' => $this->getRequest()->getParam('attribute_id')));
                return;
            }
        }
        Mage::getSingleton('adminhtml/session')->addError(Mage::helper('checkoutoptions')->__('Unable to find item to save'));
        $this->_redirect('*/*/index/filter//');
	}
 
	public function deleteAction() {
		if( $this->getRequest()->getParam('attribute_id') > 0 ) {
			try {
				$model = Mage::getModel('eav/entity_attribute');
				$id = $this->getRequest()->getParam('attribute_id');
				$model->setId($id)->delete();
                Mage::getModel('checkoutoptions/checkoutoptions')
                      ->setId($id)->delete();
				Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('adminhtml')->__('Item was successfully deleted'));
				$this->_redirect('*/*/index/filter//');
			} catch (Exception $e) {
				Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
				$this->_redirect('*/*/edit', array('attribute_id' => $this->getRequest()->getParam('attribute_id')));
			}
		}
		$this->_redirect('*/*/index/filter//');
	}


    public function ordereditAction()
    {
        $id = $this->getRequest()->getParam('order_id');
        $model = Mage::getModel('sales/order');

        if ($id) {
            
            $model->load($id);
            
            Mage::register('mmd_order_saved_object', $model);
            
            if (!$model->getId()) 
            {
                $this->_redirect('adminhtml/sales_order');
                return;
            }
        }
        else 
        {
            $this->_redirect('adminhtml/sales_order');
            return;
        }

       
        $block = $this->getLayout()->createBlock('checkoutoptions/orderedit_edit')
                      ->setData('action', $this->getUrl('*/*/save'));

        $this->_initAction();
        $this->getLayout()->getBlock('head')
             ->setCanLoadExtJs(true)
             ->setCanLoadRulesJs(true);

        $this->_addContent($block)
             ->renderLayout();

    }    
    
    
	public function ordersaveAction() {
	    
        $id = $this->getRequest()->getParam('order_id');
        $model = Mage::getModel('sales/order');

        if ($id)
        {
            $model->load($id);
            if (!$model->getId()) 
            {
                $this->_redirect('adminhtml/sales_order');
                return;
            }
        }
        else 
        {
            $this->_redirect('adminhtml/sales_order');
            return;
        }
	    
	    
		if ($data = $this->getRequest()->getPost('order'))
        {
	    //saveEditedCustomOrderData
            try
            {
				
                Mage::getModel('checkoutoptions/checkoutoptions')->saveEditedCustomOrderData($data, $id);
                Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('salesrule')->__('Order custom data were successfully saved'));
                $this->_redirect('adminhtml/sales_order/view', array('order_id' => $id));
                return;
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                $this->_redirect('*/*/orderedit', array('order_id' => $id));
                return;
            }
        }
        $this->_redirect('*/*/');
	}    
	
    /**
     * Check the permission to run it
     *
     * @return boolean
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('system/checkoutoptions');
    }


    public function exportexcelcfmAction()
    {
        $fileName   = 'checkoutfields.xml';
        Mage::register('checkoutoptions_excel', 1);
        $grid       = $this->getLayout()->createBlock('adminhtml/sales_order_grid');
        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
    }
    /*to refactor*/
    public function importAction() {
        $resource = Mage::getSingleton('core/resource');
    	$connection = $resource->getConnection('core_read');
    	$tables = $connection->fetchCol("SHOW TABLES LIKE 'mmd_sufm%'");
    	if (in_array('mmd_sufm_customer_entity_data', $tables) && in_array('mmd_sufm_custom_attribute_description', $tables) && in_array('mmd_sufm_custom_attribute_need_select', $tables)) /* Comment: MMD_Checkoutoptions_IndexController -> importAction() */
    	{
			try {
				$typeId = Mage::getModel('eav/entity')->setType('mmd_signup')->getTypeId();
				
				$select = 
	            	'INSERT IGNORE INTO '.$resource->getTableName('mmd_customer_entity_data').' SELECT * FROM mmd_sufm_customer_entity_data;'.                  /* Mage::getSingleton('core/resource')->getTableName('aitsignupfields/customerentitydata')   // Don't works with turned off module */
	            	'INSERT IGNORE INTO '.$resource->getTableName('mmd_custom_attribute_description').' SELECT * FROM mmd_sufm_custom_attribute_description;'.  /* Mage::getSingleton('core/resource')->getTableName('aitsignupfields/attributedescription') // Don't works with turned off module */
	            	'INSERT IGNORE INTO '.$resource->getTableName('mmd_custom_attribute_need_select').' SELECT * FROM mmd_sufm_custom_attribute_need_select;'   /* Mage::getSingleton('core/resource')->getTableName('aitsignupfields/attributeneedselect')  // Don't works with turned off module */
	            ;
	            $connection->query($select);
	            
	            $select = 'SELECT * FROM '.$resource->getTableName('eav_attribute').' WHERE entity_type_id = '.$typeId.';';
	            $rows = $connection->fetchAll($select);
	            
	            foreach ($rows as $row)
	            {
	            	$select = 'SELECT * FROM '.$resource->getTableName('catalog/eav_attribute').' WHERE attribute_id = '.$row['attribute_id'].';';
	           		$rowsAttr = $connection->fetchRow($select);
	           		$attributeId = $row['attribute_id'];
	            	unset($row['attribute_id']);
	            	
	            	$row['entity_type_id'] = Mage::getModel('eav/entity')->setType('mmd_checkout')->getTypeId();
	            
	            	$connection->insert($resource->getTableName('eav_attribute'), $row);
	            	
					$lastInsertId  = $connection->fetchOne('SELECT last_insert_id()'); 
	            	
	            	$rowsAttr['attribute_id'] = $lastInsertId;
	            	$rowsAttr['mmd_registration_page'] = $rowsAttr['mmd_sufm_registration_page'];
	            	$rowsAttr['mmd_registration_place'] = $rowsAttr['mmd_sufm_registration_place'];
	            	$rowsAttr['mmd_registration_position'] = $rowsAttr['mmd_sufm_registration_position'];
	            	$connection->insert($resource->getTableName('catalog/eav_attribute'), $rowsAttr);
	            	
	            	$connection->query('UPDATE '.$resource->getTableName('mmd_customer_entity_data').' SET attribute_id = '.$lastInsertId.' WHERE attribute_id = '.$attributeId.';');
	            	$connection->query('UPDATE '.$resource->getTableName('mmd_custom_attribute_description').' SET attribute_id = '.$lastInsertId.' WHERE attribute_id = '.$attributeId.';');
	            	$connection->query('UPDATE '.$resource->getTableName('mmd_custom_attribute_need_select').' SET attribute_id = '.$lastInsertId.' WHERE attribute_id = '.$attributeId.';');
	            	
	            	$lastInsertIdAttr  = $connection->fetchOne('SELECT last_insert_id()');
	            	$select = 'SELECT * FROM '.$resource->getTableName('eav_attribute_option').' WHERE attribute_id = '.$attributeId.';';
	           		$rowsAttrOptions = $connection->fetchAll($select);
	           		foreach ($rowsAttrOptions as $rowAttrOptions)
	            	{
	            		$optionId = $rowAttrOptions['option_id'];
	            		unset($rowAttrOptions['option_id']);
	            		$rowAttrOptions['attribute_id'] = $lastInsertIdAttr;
	            		$connection->insert($resource->getTableName('eav_attribute_option'), $rowAttrOptions);
	            		
	            		$lastInsertIdAttrOpt  = $connection->fetchOne('SELECT last_insert_id()');
		            	$select = 'SELECT * FROM '.$resource->getTableName('eav_attribute_option_value').' WHERE option_id = '.$optionId.';';
		           		$rowsAttrOptionsValue = $connection->fetchAll($select);
		           		
		           		if (in_array($row['frontend_input'], array('multiselect', 'checkbox')))
		           		{
		           			$select = 'SELECT value FROM '.$resource->getTableName('mmd_customer_entity_data').' WHERE attribute_id = '.$lastInsertIdAttr.';';
		           			$rowCustomerAttrValue = $connection->fetchOne($select);
		           			$customerAttrValues = explode(',', $rowCustomerAttrValue);
		           			if (in_array($optionId, $customerAttrValues))
		           			{
		           				$optionIds[$row['frontend_input']][] = $lastInsertIdAttrOpt;
		           			}
		           		}
		           		elseif (in_array($row['frontend_input'], array('radio', 'select')))
		           		{
		           			$connection->query('UPDATE '.$resource->getTableName('mmd_customer_entity_data').' SET value = '.$lastInsertIdAttrOpt.' WHERE value = '.$optionId.';');
		           		}
		           		
		           		foreach ($rowsAttrOptionsValue as $rowAttrOptionsValue)
	            		{
	            			unset($rowAttrOptionsValue['value_id']);
		            		$rowAttrOptionsValue['option_id'] = $lastInsertIdAttrOpt;
		            		$connection->insert($resource->getTableName('eav_attribute_option_value'), $rowAttrOptionsValue);
	            		}
	            	}
	            	
	            	if (in_array($row['frontend_input'], array('multiselect', 'checkbox')))
	           		{
	           			$connection->query('UPDATE '.$resource->getTableName('mmd_customer_entity_data').' SET value = "'.implode(',', $optionIds[$row['frontend_input']]).'" WHERE attribute_id = '.$lastInsertIdAttr.';');
	           		}
	            	
	            	$select = 'SELECT * FROM '.$resource->getTableName('eav_attribute_label').' WHERE attribute_id = '.$attributeId.';';
	           		$rowsAttrLabels = $connection->fetchAll($select);
	           		foreach ($rowsAttrLabels as $rowAttrLabels)
	            	{
	            		unset($rowAttrLabels['attribute_label_id']);
	            		$rowAttrLabels['attribute_id'] = $lastInsertIdAttr;
	            		$connection->insert($resource->getTableName('eav_attribute_label'), $rowAttrLabels);
	            	}
	            }

				$config = new Mage_Core_Model_Config();
				$config->saveConfig('checkoutoptions/display_import', "1", 'default', 0);
	            
	            Mage::getSingleton('adminhtml/session')->addSuccess(
		            Mage::helper('adminhtml')->__(
		                Mage::helper('checkoutoptions')->__('Custom Registration Fields are successfully imported')
		            )
		        );
	        } catch (Exception $e) {
	            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
	        }
    	}
    	else 
    	{
    		Mage::getSingleton('adminhtml/session')->addError('Custom Registration Fields module data tables are not found');
    	}
        
        $this->_redirect('*/*/');
	}
}

?>