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
 * @copyright  Copyright (c) 2013 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

class MMD_Adminhtml_Customoptions_OptionsController extends Mage_Adminhtml_Controller_Action {

    /**
     * Course Schedules / custom-options template management. Exposed in
     * the Super Admin + Admin sidebars under "Course Schedules" (and
     * legacy Catalog menu paths). The parent class' default _isAllowed
     * returns false because no ADMIN_RESOURCE is declared on this
     * controller, so without an explicit override the page is unreachable
     * for everyone — even Super Admin.
     */
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin',
        ));
    }

    public function indexAction() {
        $this->_title($this->__('APO'))->_title($this->__('Manage Templates'));
        $this->loadLayout()
            ->_setActiveMenu('catalog/customoptions')
            ->_addBreadcrumb($this->__('APO'), $this->__('Manage Templates'))
            ->renderLayout();
    }

    public function newAction() {
        $this->_forward('edit');
    }

    public function editAction() {
        $id = (int) $this->getRequest()->getParam('group_id');
        $storeId = (int) $this->getRequest()->getParam('store', 0);        
        Mage::register('store_id', $storeId);
        $model = Mage::getModel('customoptions/group')->load($id);

        if ($model->getId() || $id == 0) {
            $data = Mage::getSingleton('adminhtml/session')->getFormData(true);
            if (!empty($data)) {
                $model->setData($data);
                if ($id) {
                    $model->setId($id);
                }
            }
                        
            Mage::register('customoptions_data', $model);
            $title = $model->getTitle()?$model->getTitle():$this->__('New Template');
            $this->_title($this->__('APO'))->_title($this->__('Manage Templates'))->_title($title);
            $this->loadLayout()
            ->_setActiveMenu('catalog/customoptions')
            ->_addBreadcrumb($this->__('APO'), $this->__('Manage Templates'));

            // Generate Course Dates panel — only for an already-saved template
            // (needs a group_id to write into). Prefill the code from the title.
            if ($id) {
                $defaultCode = '';
                if (preg_match('/([A-Ea-e]0*\d+)/', (string) $model->getTitle(), $cm)) {
                    $defaultCode = strtoupper($cm[1]);
                }
                $genParams = array('group_id' => $id);
                if ($storeId > 0) {
                    $genParams['store'] = $storeId;
                }
                $this->_addContent(
                    $this->getLayout()->createBlock('adminhtml/template')
                        ->setTemplate('customoptions/schedule-generate.phtml')
                        ->setData('group_id', $id)
                        ->setData('store_id', $storeId)
                        ->setData('form_action', $this->getUrl('*/*/generateDates', $genParams))
                        ->setData('default_code', $defaultCode)
                );
            }

            $this->_addContent($this->getLayout()->createBlock('mmd/customoptions_options_edit'))
            ->_addLeft($this->getLayout()->createBlock('adminhtml/store_switcher'))
            ->_addLeft($this->getLayout()->createBlock('mmd/customoptions_options_edit_tabs'));

            $this->renderLayout();
        } else {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Options do not exist'));
            $this->_redirect('*/*/');
        }
    }

    private function _isEmptyOptions($options) {
        $result = true;
        if ($options && is_array($options)) {
            foreach ($options as $value) {
                if ($value['is_delete'] != 1) {
                    $result = false;
                    break;
                }
            }
        }
        return $result;
    }

    private function _prepareOptions($options, $groupId) {                
        
        if ($options && is_array($options)) {
            $helper = Mage::helper('customoptions');
            // is_delete + sort_order            
            $optionPrepare = array();
            foreach ($options as $key => $option) {
                
                // option
                $options[$key]['previous_type'] = $option['type'];
                if (!isset($option['is_delete']) || $option['is_delete']!=1) {                   
                    $sortOrder = substr('00000000'.(isset($option['sort_order'])?$option['sort_order']:'0'), -8).'_'.$key;
                    $optionPrepare[$sortOrder] = $option;                                    
                    // item option
                    if (isset($option['values']) && is_array($option['values'])) {
                        $itemsOptionPrepare = array();
                        foreach ($option['values'] as $k => $value) {
                            if (!isset($value['is_delete']) || $value['is_delete']!=1) {
                                $itemSortOrder = substr('00000000'.(isset($value['sort_order'])?$value['sort_order']:'0'), -8).'_'.$k;
                                
                                if (isset($value['weight'])) $value['weight'] = floatval($value['weight']);                                                                
                                $value['sku'] = trim($value['sku']);
                                
                                // prepare customoptions_qty
                                $customoptionsQty = '';
                                if (isset($value['customoptions_qty']) && $helper->getProductIdBySku($value['sku'])==0) {                        
                                    $customoptionsQty = strtolower(trim($value['customoptions_qty']));
                                    if (substr($customoptionsQty, 0, 1)!='x' && !is_numeric($customoptionsQty)) $customoptionsQty='';
                                    if (is_numeric($customoptionsQty)) $customoptionsQty = intval($customoptionsQty);
                                    $value['customoptions_qty'] = $customoptionsQty;
                                }
                                
                                $itemsOptionPrepare[$itemSortOrder] = $value;
                            }
                        }
                        ksort($itemsOptionPrepare);                        
                        unset($optionPrepare[$sortOrder]['values']);                        
                        foreach ($itemsOptionPrepare as $value) {
                            $optionPrepare[$sortOrder]['values'][$value['option_type_id']] = $value;
                        }                        
                    }                                  
                }                                
                
            }
            ksort($optionPrepare);
            $options = array();            
            foreach ($optionPrepare as $value) {
                $options[$value['option_id']] = $value;
            }            
        }
        return $options;
    }
    
    // comparison arrays - quadruple nesting
    public function comparisonArrays4(array $newOptions, array $prevOptions) {
        $diffOptions = array();
        foreach ($newOptions as $key=>$op) {
            if (isset($prevOptions[$key])) {
                if (is_array($op)) {
                    foreach ($op as $kkk=>$ooo) {
                        if (isset($prevOptions[$key][$kkk])) {
                            if (is_array($ooo)) {
                                foreach ($ooo as $kk=>$oo) {
                                    if (isset($prevOptions[$key][$kkk][$kk])) {
                                        if (is_array($oo)) {
                                            foreach ($oo as $k=>$o) {
                                                if (isset($prevOptions[$key][$kkk][$kk][$k])) {
                                                    if ($prevOptions[$key][$kkk][$kk][$k]!=$o) $diffOptions[$key][$kkk][$kk][$k] = $o;
                                                } else {
                                                    $diffOptions[$key][$kkk][$kk][$k] = $o;
                                                }
                                            }
                                        } else {
                                            if ($prevOptions[$key][$kkk][$kk]!=$oo) $diffOptions[$key][$kkk][$kk] = $oo;
                                        }    
                                    } else {
                                        $diffOptions[$key][$kkk][$kk] = $oo;
                                    }
                                }
                            } else {
                                if ($prevOptions[$key][$kkk]!=$ooo) $diffOptions[$key][$kkk] = $ooo;
                            }
                        } else {
                            $diffOptions[$key][$kkk] = $ooo;
                        }
                    }
                } else {
                    if ($prevOptions[$key]!=$op) $diffOptions[$key] = $op;
                }
            } else {                    
                $diffOptions[$key] = $op;
            }    
        }        
        return $diffOptions;        
    }
    

    public function duplicateAction() {
        $id = (int) $this->getRequest()->getParam('group_id');

        try {
            $group = Mage::getSingleton('customoptions/group')->load($id);
            $newGroupId = $group->duplicate();
            
            $helper = Mage::helper('customoptions');
            
            $helper->copyFolder($helper->getCustomOptionsPath($id), $helper->getCustomOptionsPath($newGroupId));
            
        } catch (Exception $e) {
            if ($e->getMessage()) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                $this->_redirect('*/*/edit', array('group_id' => $id));
            }
        }

        Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Options were successfully duplicated'));
        
        $this->_redirect('*/*/edit', array('group_id' => $newGroupId));
    }

    public function saveAction() {
        @ini_set('max_execution_time', 1800);
        @ini_set('memory_limit', 534003200);
        
        $helper = Mage::helper('customoptions');
        $productOptionModel = Mage::getModel('catalog/product_option');
        
        $data = $this->getRequest()->getPost();
		
		/*echo "<pre>";
		print_r($data ); die;*/
		
        $id = (int) $this->getRequest()->getParam('group_id');
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        $redirectParams = array('group_id' => $id);
        if ($storeId>0) $redirectParams['store'] = $storeId;
        
        $error = false;
        if ($data) {
            $data = $helper->getFilter($data);
            try {
                // prepare Assign by -> $data['in_products']
                if (isset($data['products_area_type']) && $data['products_area_type']>1 && isset($data['products_area'])) {
                    if ($data['in_products']) $productIds = explode(',', $data['in_products']); else $productIds = array();                    
                    switch ($data['products_area_type']) {
                        case 2: // by product ids
                            $productArea = explode(',', $data['products_area']);
                            foreach($productArea as $productId) {
                                $productId = intval($productId);
                                if ($productId && !in_array($productId, $productIds)) {
                                    $product = Mage::getSingleton('catalog/product')->load($productId);
                                    if ($product && $product->getId() > 0) $productIds[] = $productId;
                                }
                            }
                            $data['in_products'] = implode(',', $productIds);
                            break;
                        case 3: // by SKUs     
                            $productArea = explode(',', $data['products_area']);
                            foreach($productArea as $sku) {
                                $sku = trim($sku);
                                $productId = $helper->getProductIdBySku($sku);
                                if ($productId && !in_array($productId, $productIds)) $productIds[] = $productId;
                            }
                            $data['in_products'] = implode(',', $productIds);
                            break;
                    }
                }
                
                $productOptions = array();
                if (!isset($data['product']['options']) || $this->_isEmptyOptions($data['product']['options'])) {
                    Mage::getSingleton('adminhtml/session')->addError($this->__('There are no Options'));
                    $error = true;
                } else {                    
                    // first prepare options: id=-1 -> id=$key
                    $productOptions = $data['product']['options'];                    
                    foreach ($productOptions as $i => $option) {
                        if (isset($option['values'])) {
                            if (count($option['values'])>0) {
                                foreach($option['values'] as $key => $value) {
                                    if ($value['option_type_id']=='-1') $option['values'][$key]['option_type_id'] = (string)$key;
                                    
                                    if (!isset($value['scope']['price'])) {
                                        if (!isset($value['price'])) $option['values'][$key]['price'] = '0.00';
                                        if (!isset($value['price_type'])) $option['values'][$key]['price_type'] = 'fixed';
                                    }
                                    
                                    if (isset($value['tiers'])) {
                                        if (count($value['tiers'])>0) {                                            
                                            // uniq by qty
                                            $tiers = array();
                                            foreach ($value['tiers'] as $tkey=>$tValue) {
                                                if ($tValue['is_delete']=='1') continue;
                                                
                                                $tValue['qty'] = intval($tValue['qty']);
                                                if ($tValue['qty']==0) continue;
                                                
                                                if ($tValue['tier_price_id']=='-1') $tValue['tier_price_id'] = (string)$tkey;
                                                
                                                $tiers[$tValue['qty']] = $tValue;                                                
                                            }
                                            ksort($tiers);
                                            $option['values'][$key]['tiers'] = array();
                                            foreach ($tiers as $tierValue) {
                                                $option['values'][$key]['tiers'][$tierValue['tier_price_id']] = $tierValue;
                                            }
                                        } else {
                                            unset($option['values'][$key]['tiers']);
                                        }
                                    }
                                }
                            } else {
                                unset($option['values']);
                            }                           
                        } else {
                            if (!isset($option['scope']['price'])) {
                                if (!isset($option['price'])) $option['price'] = '0.00';
                                if (!isset($option['price_type'])) $option['price_type'] = 'fixed';
                            }
                        }
                        $option['option_id'] = $i;
                        // qnty_input
                        if (!isset($option['qnty_input']) || $productOptionModel->getGroupByType($option['type'])!=Mage_Catalog_Model_Product_Option::OPTION_GROUP_SELECT || $option['type']=='multiple') $option['qnty_input'] = 0;
                                                
                        // exclude_first_image
                        if (!isset($option['exclude_first_image']) || $productOptionModel->getGroupByType($option['type'])!=Mage_Catalog_Model_Product_Option::OPTION_GROUP_SELECT) $option['exclude_first_image'] = 0;
                        
                        $productOptions[$i] = $option;
                    }                    
                    $data['general']['hash_options'] = serialize(array());
                }
                if ($error) {
                    if (isset($data['in_products']) && is_array($data['in_products']) && count($data['in_products']) > 0) {
                        $data['in_products'] = implode(',', $data['in_products']);
                    }
                    throw new Exception();
                }

                $optionsPrev = array();
                $prevGroupIsActive = 1;
                if ($id) {
                    $group = Mage::getSingleton('customoptions/group')->load($id);
                    $prevGroupIsActive = $group->getIsActive();
                    if ($group->getHashOptions()!='') $optionsPrev = unserialize($group->getHashOptions());
                } else {
                    $group = Mage::getSingleton('customoptions/group');
                }                
                
                
                // insert
                if (!$id) {
                    $group->setData($data['general']);
                    $group->save();
                    $id = $group->getId();
                }                                
                
                $productIds = array();
                if (isset($data['in_products']) && $data['in_products']) {
                    $productIds = explode(',', $data['in_products']);
                }                                


                //remove files
                if (isset($data['image_delete'])) {
                    foreach ($data['image_delete'] as $optionId) {
                        if ($optionId) $helper->deleteOptionFile($group->getId(), $optionId);
                    }
                }                
                
                //upload files
                foreach ($productOptions as $key=>$option) {
                    if ($option['option_id'] == 0) $option['option_id'] = 1;
                    
                    switch ($option['type']) {
                        case 'field':
                        case 'area':                        
                           // $this->_uploadImage('file_' . $option['option_id'], $id, $option['option_id']);
                            if (isset($option['id'])) {
                                if ($helper->isCustomOptionsFile($id, $option['id'])) {
                                    $option['image_path'] = $id . DS . $option['id'] . DS;
                                } else {
                                    $option['image_path'] = '';
                                }
                            }
                            $productOptions[$key] = $option;
                            break;
                        case 'drop_down':
                        case 'radio':
                        case 'checkbox':
                        case 'multiple':
                        case 'swatch':    
                            if (isset($option['values']) && is_array($option['values']) && !empty($option['values'])) {
                                foreach ($option['values'] as $k => $value) {
                                    $counter = $value['option_type_id'] == '-1' ? $k : $value['option_type_id'];
                                    $value['images'] = $this->_uploadImage('file_' . $option['option_id'] . '_' . $counter, $id, $option['option_id'], $counter, $value);
                                    
                                    $productOptions[$key]['values'][$k] = $value;
                                }
                            }    
                            break;
                        case 'file':
                        case 'date':
                        case 'date_time':
                        case 'time':
                            // no image
                            if (isset($option['option_id'])) $helper->deleteOptionFile($id, $option['option_id']);
                            break;
                    }
                }
                                
                $prevStoreOptionsData = array();
                if ($storeId>0) { // if no default store
                    $defaultOptions = $optionsPrev;
                    // add to store defoult values + add new options to defoult or mark is_delete flag
                    foreach ($productOptions as $key=>$option) {
                        if (isset($optionsPrev[$key])) {
                            if (isset($option['scope'])) {
                                foreach ($option['scope'] as $field=>$value) {
                                    if ($value && isset($optionsPrev[$key][$field])) $productOptions[$key][$field] = $optionsPrev[$key][$field];
                                }
                                unset($productOptions[$key]['scope']);
                            }                            
                            $defaultOptions[$key]['is_delete'] = $option['is_delete'];                            
                            
                            if (isset($option['values'])) {
                                foreach ($option['values'] as $valueId=>$optionValue) {
                                    if (isset($optionsPrev[$key]['values'][$valueId])) {                                    
                                        if (isset($optionValue['scope'])) {
                                            foreach ($optionValue['scope'] as $field=>$value) {
                                                if ($value && isset($optionsPrev[$key]['values'][$valueId][$field])) $productOptions[$key]['values'][$valueId][$field] = $optionsPrev[$key]['values'][$valueId][$field];
                                            }
                                            unset($productOptions[$key]['values'][$valueId]['scope']);
                                        }
                                        $defaultOptions[$key]['values'][$valueId]['is_delete'] = $optionValue['is_delete'];
                                    } else {
                                        // found new option value
                                        $defaultOptions[$key]['values'][$valueId] = $optionValue;
                                    }
                                }
                            }                                                        
                        } else {
                            // found new option
                            $defaultOptions[$key] = $option;
                        }
                    }                    
                    //$storeOptions = Mage::getSingleton('catalog/product_option')->comparisonArrays($productOptions, $defaultOptions);
                    // difference default and store - quadruple nesting
                    $storeOptions = $this->comparisonArrays4($productOptions, $defaultOptions);
                    
                    
                    
                    // add option_id/option_type_id/type to $storeOptions
                    foreach($storeOptions as $optionId=>$option) {
                        $storeOptions[$optionId]['option_id'] = $optionId;
                        $storeOptions[$optionId]['type'] = $productOptions[$optionId]['type'];
                        
                        if (isset($option['price']) && !isset($option['price_type'])) $storeOptions[$optionId]['price_type'] = $productOptions[$optionId]['price_type'];
                        if (!isset($option['price']) && isset($option['price_type'])) $storeOptions[$optionId]['price'] = $productOptions[$optionId]['price'];
                        
                        if (isset($option['values'])) {
                            foreach ($option['values'] as $valueId=>$optionValue) {
                                $storeOptions[$optionId]['values'][$valueId]['option_type_id'] = $valueId;
                                if (isset($optionValue['tiers']) && !isset($optionValue['price_type'])) $storeOptions[$optionId]['values'][$valueId]['price_type'] = $productOptions[$optionId]['values'][$valueId]['price_type'];
                                if (isset($optionValue['tiers']) && !isset($optionValue['price'])) $storeOptions[$optionId]['values'][$valueId]['price'] = $productOptions[$optionId]['values'][$valueId]['price'];                                
                                if (isset($optionValue['price']) && !isset($optionValue['price_type'])) $storeOptions[$optionId]['values'][$valueId]['price_type'] = $productOptions[$optionId]['values'][$valueId]['price_type'];
                                if (!isset($optionValue['price']) && isset($optionValue['price_type'])) $storeOptions[$optionId]['values'][$valueId]['price'] = $productOptions[$optionId]['values'][$valueId]['price'];
                            }
                        }
                    }
                    
                    // save store options
                    $groupStore = Mage::getSingleton('customoptions/group_store')->loadByGroupAndStore($id, $storeId);                    
                    $prevStoreOptionsData = $groupStore->getData();                    
                    $groupStore->setGroupId($id)->setStoreId($storeId)
                        ->setHashOptions(serialize($this->_prepareOptions($storeOptions, $id)))
                        ->save();

//                    print_r($optionsPrev);
//                    print_r($defaultOptions);                    
//                    print_r($storeOptions);
//                    exit;
                    
                    
                } else {
                    // default store
                    $defaultOptions = $productOptions;                    
                    
                    // foreach all no default store and mark is_delete flag or no option
                    $groupStoreCollection = Mage::getResourceModel('customoptions/group_store_collection')->addFieldToFilter('group_id', $id);                    
                    if (count($groupStoreCollection)>0) {
                        foreach ($groupStoreCollection as $groupStore) {
                            $groupStoreOptions = $groupStore->getHashOptions();
                            if ($groupStoreOptions) $groupStoreOptions = unserialize($groupStoreOptions);
                            $changeFlag = false;
                            foreach ($groupStoreOptions as $optionId=>$option) {
                                if (!isset($defaultOptions[$optionId]) || (isset($defaultOptions[$optionId]['is_delete']) && $defaultOptions[$optionId]['is_delete'])) {
                                    unset($groupStoreOptions[$optionId]);
                                    $changeFlag = true;
                                } else {
                                    if (isset($option['values']) && count($option['values'])>0) {
                                        foreach ($option['values'] as $valueId=>$value) {
                                            if (!isset($defaultOptions[$optionId]['values'][$valueId]) || (isset($defaultOptions[$optionId]['values'][$valueId]['is_delete']) && $defaultOptions[$optionId]['values'][$valueId]['is_delete'])) {
                                                unset($groupStoreOptions[$optionId]['values'][$valueId]);
                                                if (count($groupStoreOptions[$optionId]['values'])==0) unset($groupStoreOptions[$optionId]['values']);
                                                $changeFlag = true;
                                            } else if (isset($value['tiers']) && count($value['tiers'])>0) {
                                                if (!isset($defaultOptions[$optionId]['values'][$valueId]['tiers'])) {
                                                    unset($groupStoreOptions[$optionId]['values'][$valueId]['tiers']);
                                                    $changeFlag = true;
                                                } else {
                                                    foreach ($value['tiers'] as $tierId=>$tierValue) {
                                                        if (!isset($defaultOptions[$optionId]['values'][$valueId]['tiers'][$tierId])) {
                                                            unset($groupStoreOptions[$optionId]['values'][$valueId]['tiers'][$tierId]);
                                                            $changeFlag = true;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if ($changeFlag) {
                                if (count($groupStoreOptions)>0) {
                                    $groupStore->setHashOptions(serialize($groupStoreOptions))->save();
                                } else {
                                    $groupStore->delete();
                                }
                            }    
                        }
                    }                    
                }                               

                //print_r($defaultOptions); exit;
                
                
                
                // save default options
                if (!isset($data['general']['absolute_price'])) $data['general']['absolute_price'] = 0;
                if (!isset($data['general']['absolute_weight'])) $data['general']['absolute_weight'] = 0;
                $data['general']['hash_options'] = serialize($this->_prepareOptions($defaultOptions, $id));
                $approximateOptionCount = ceil((strlen($data['general']['hash_options'])+1)/500); // 500 byte = ~1 option
                
                $group->setData($data['general']);
                $group->setId($id);
                $group->save();
                Mage::getSingleton('adminhtml/session')->setCustomoptionsData(null);
                
                if ($this->getRequest()->getParam('back')) {
                    $redirectParams['group_id'] = $group->getId();
                    $redirectData = array('*/*/edit', $redirectParams);
                } else {
                    $redirectData = array('*/*/', array());
                }                                
                
                // apply options to products
                if ($productOptions && isset($productIds) && is_array($productIds)) {
                    if (count($productIds) > 0) {
                        if (count($productIds)*$approximateOptionCount<250) {
                            // apply default and store
                            $productOptionModel->saveProductOptions($defaultOptions, $optionsPrev, $productIds, $group, $prevGroupIsActive, 'apo', $prevStoreOptionsData);
                            //Mage::getModel('catalog/product_indexer_price')->reindexAll(); // make reindex
                            Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds); // make reindex
                        } else {
                            // start multi-step apply — store group ID (int), not the model object,
                            // to avoid PDO serialisation errors in PHP 8.2 session writes.
                            $limit = ceil(250/$approximateOptionCount);
                            Mage::getSingleton('adminhtml/session')->setCustomoptionsApplyData(array($defaultOptions, $optionsPrev, $productIds, $group->getId(), $prevGroupIsActive, $prevStoreOptionsData, $redirectData, $limit));
                            return $this->_redirect('*/*/apply');
                        }
                    } else {
                        if ($productOptionModel->removeProductOptionsAndRelationByGroup($group->getId())) {
                            Mage::getModel('catalog/product_indexer_price')->reindexAll(); // make reindex
                        }
                    }
                }

                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Options were successfully saved'));
                return $this->_redirect($redirectData[0], $redirectData[1]);
                
            } catch (Exception $e) {
                if ($e->getMessage()) {
                    Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                }
                Mage::getSingleton('adminhtml/session')->setData('customoptions_data', $data);
                $this->_redirect('*/*/edit', $redirectParams);
                return;
            }
        }
        Mage::getSingleton('adminhtml/session')->addError($this->__('Unable to find Options to save'));
        $this->_redirect('*/*/');
    }
    
    public function applyAction() {
        $this->loadLayout();
        $this->renderLayout();
    }
    
    protected function _apply($current, $limit, $customoptionsApplyData) {
        $defaultOptions = $customoptionsApplyData[0];
        $optionsPrev = $customoptionsApplyData[1];
        $productIds = array_slice($customoptionsApplyData[2], $current, $limit);
        $group = Mage::getModel('customoptions/group')->load($customoptionsApplyData[3]);
        $prevGroupIsActive = $customoptionsApplyData[4];
        $prevStoreOptionsData = $customoptionsApplyData[5];
        Mage::getModel('catalog/product_option')->saveProductOptions($defaultOptions, $optionsPrev, $productIds, $group, $prevGroupIsActive, 'product', $prevStoreOptionsData);
    }

    public function runApplyAction() {
        @ini_set('max_execution_time', 1800);
        @ini_set('memory_limit', 734003200);

        $current = $this->getRequest()->getParam('current', 0);
        $customoptionsApplyData = Mage::getSingleton('adminhtml/session')->getCustomoptionsApplyData();
        if (!is_array($customoptionsApplyData) || count($customoptionsApplyData) != 8) return $this->_redirect('*/*/');

        $limit = $customoptionsApplyData[7];
        $productIds = $customoptionsApplyData[2];
        $total = count($productIds);
        $result = array();

        if ($current=='checkUnassigned') { // check and remove of unassigned options
            $group = Mage::getModel('customoptions/group')->load($customoptionsApplyData[3]);
            Mage::getModel('catalog/product_option')->saveProductOptions(null, array(), $productIds, $group, 1, 'apo');
            $result['url'] = $this->getUrl('*/*/runApply/', array('current'=>'reindex'));
            $result['text'] = $this->__('Unassigned options removed (100%)...');
        } elseif ($current=='reindex') {
            $result['stop'] = 1;
            //Mage::getModel('catalog/product_indexer_price')->reindexAll(); // make reindex
            Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds); // make reindex
            
            Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Options were successfully saved'));
            $result['url'] = $this->getUrl($customoptionsApplyData[6][0], $customoptionsApplyData[6][1]); // $redirectData
            $result['text'] = $this->__('Product prices reindexed (100%)...');
        } elseif ($current<$total) {
            $this->_apply($current, $limit, $customoptionsApplyData);
            $current += $limit;            
            if ($current>=$total) {
                $current = $total;
                $result['url'] = $this->getUrl('*/*/runApply/', array('current'=>'checkUnassigned'));
            } else {
                $result['url'] = $this->getUrl('*/*/runApply/', array('current'=>$current));
            }
            $result['text'] = $this->__('Total %1$s, processed %2$s products (%3$s%%)...', $total, $current, round($current*100/$total, 2));
        }
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }
    

    public function productGridAction() {
        $this->loadLayout();
        $this->getResponse()->setBody(
                $this->getLayout()->createBlock('mmd/customoptions_options_edit_tab_product')->toHtml()
        );
    }

    public function deleteAction() {
        $id = (int) $this->getRequest()->getParam('group_id');
        if ($id > 0) {
            try {
                $model = Mage::getModel('customoptions/group');
                $model->load($id);
                $model->setId($id)->delete();
                
                $helper = Mage::helper('customoptions');
                $helper->deleteFolder($helper->getCustomOptionsPath($id));

                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Options were successfully deleted'));
                $this->_redirect('*/*/');
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                $this->_redirect('*/*/edit', array('id' => $id));
            }
        }
        $this->_redirect('*/*/');
    }

    /**
     * Shared generate+merge+save logic.
     *
     * Generates dates for $code in [$start, $end], merges new entries into
     * $group's "Course Date" option (deduped by reg_course|title signature),
     * saves hash_options, and returns the count of newly added entries.
     *
     * $group must already be load()ed. The in_products value set by _afterLoad
     * survives this call because we only call setHashOptions()+save(), not load().
     */
    /**
     * Return the product IDs assigned to $group.
     * Prefers the in_products virtual column populated by _afterLoad, but falls
     * back to custom_options_relation for environments where the in_products DB
     * column is absent (e.g. local dev with an older schema dump).
     */
    /* ── Bulk-schedule run-state helpers (persisted in var/bulk_schedule_state.json) ── */

    protected function _bulkStatePath()
    {
        return Mage::getBaseDir('var') . DS . 'bulk_schedule_state.json';
    }

    protected function _loadBulkState()
    {
        $path = $this->_bulkStatePath();
        if (!file_exists($path)) return array('status' => 'idle');
        $raw = @file_get_contents($path);
        $s   = $raw ? @json_decode($raw, true) : null;
        return is_array($s) ? $s : array('status' => 'idle');
    }

    protected function _saveBulkState(array $state)
    {
        file_put_contents($this->_bulkStatePath(), json_encode($state));
    }

    /* ── Returns the current bulk-run state as JSON (used by the inline panel) ── */
    public function getBulkStateAction()
    {
        $this->getResponse()->setHeader('Content-Type',  'application/json', true);
        $this->getResponse()->setHeader('Cache-Control', 'no-store, no-cache, must-revalidate', true);
        $this->getResponse()->setHeader('Pragma',        'no-cache', true);
        $this->getResponse()->setBody(json_encode($this->_loadBulkState()));
    }

    protected function _resolveProductIds(Varien_Object $group)
    {
        $ids = array_values(array_filter(
            array_map('intval', explode(',', (string) $group->getInProducts()))
        ));
        if (!empty($ids)) return $ids;

        // Fallback: derive from the relation table
        $db  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $tbl = (string) Mage::getConfig()->getTablePrefix() . 'custom_options_relation';
        $rows = $db->fetchAll(
            'SELECT DISTINCT product_id FROM ' . $tbl . ' WHERE group_id = ?',
            [(int) $group->getId()]
        );
        return array_values(array_map('intval', array_column($rows, 'product_id')));
    }

    protected function _generateAndMerge($group, $code, $start, $end)
    {
        $generator = Mage::getModel('mmd/schedule_generator');
        $entries   = $generator->generateForCode($code, $start, $end);
        if (empty($entries)) {
            return 0;
        }

        $hash = $group->getHashOptions();
        $opts = ($hash !== '' && $hash !== null) ? @unserialize($hash) : array();
        if (!is_array($opts)) {
            $opts = array();
        }

        $cdOptId = null;
        foreach ($opts as $optId => $opt) {
            if (!empty($opt['title']) && strcasecmp(trim($opt['title']), 'course date') === 0) {
                $cdOptId = $optId;
                break;
            }
        }
        if ($cdOptId === null) {
            $cdOptId = 1;
            foreach (array_keys($opts) as $k) {
                if ((int) $k >= $cdOptId) $cdOptId = (int) $k + 1;
            }
            $opts[$cdOptId] = array(
                'option_id'  => (string) $cdOptId,
                'title'      => 'Course Date',
                'type'       => 'drop_down',
                'is_require' => '1',
                'sort_order' => '1',
                'values'     => array(),
            );
        }
        if (empty($opts[$cdOptId]['values']) || !is_array($opts[$cdOptId]['values'])) {
            $opts[$cdOptId]['values'] = array();
        }

        // Resolve Course Time dep_ids: sort Course Time values by sort_order;
        // first = morning/daytime, last = evening. Generated date titles that
        // contain "Evening" get the evening dep_id, all others get morning.
        $morningDepId = '';
        $eveningDepId = '';
        foreach ($opts as $opt) {
            if (empty($opt['title']) || strcasecmp(trim($opt['title']), 'course time') !== 0) continue;
            if (empty($opt['values']) || !is_array($opt['values'])) break;
            $ctVals = array_values($opt['values']);
            usort($ctVals, function ($a, $b) {
                return (int) ($a['sort_order'] ?? 0) - (int) ($b['sort_order'] ?? 0);
            });
            // Use in_group_id as the dep reference — _prepareOptions multiplies it by
            // (groupId * 65535) and the product-side in_group_id is computed the same way,
            // so they match. option_type_id is a separate DB identifier that happens to
            // equal in_group_id on some templates but not all.
            $morningDepId = (string) (($ctVals[0]['in_group_id'] ?? '') !== '' ? $ctVals[0]['in_group_id'] : ($ctVals[0]['option_type_id'] ?? ''));
            if (count($ctVals) >= 2) {
                $last = $ctVals[count($ctVals) - 1];
                $eveningDepId = (string) (($last['in_group_id'] ?? '') !== '' ? $last['in_group_id'] : ($last['option_type_id'] ?? ''));
            }
            break;
        }

        // Compute the max in_group_id across ALL options so new values get unique IDs.
        // Empty in_group_id makes _prepareOptions map every value to the same 'IGI0' key,
        // causing saveProductOptions to keep only the last value per option (silent data loss).
        $maxInGroupId = 0;
        foreach ($opts as $o) {
            foreach ((array) ($o['values'] ?? array()) as $v) {
                if (isset($v['in_group_id']) && $v['in_group_id'] !== '') {
                    $maxInGroupId = max($maxInGroupId, (int) $v['in_group_id']);
                }
            }
        }

        $seen     = array();
        $maxValId = 0;
        $maxSort  = 0;
        $fixed    = 0;
        $hasCourseTime = ($morningDepId !== '' || $eveningDepId !== '');
        foreach ($opts[$cdOptId]['values'] as $vid => $v) {
            $sig = strtolower(trim((isset($v['reg_course']) ? $v['reg_course'] : '') . '|' . (isset($v['title']) ? $v['title'] : '')));
            $seen[$sig] = true;
            $maxValId   = max($maxValId, (int) ($v['option_type_id'] ?? $vid));
            if (isset($v['sort_order'])) $maxSort = max($maxSort, (int) $v['sort_order']);

            // Fix existing values whose dep_id is wrong or empty (silently — not surfaced in UI).
            if ($hasCourseTime) {
                $isEvening  = (stripos($v['title'] ?? '', 'Evening') !== false);
                $correctDep = $isEvening ? $eveningDepId : $morningDepId;
                if ($correctDep !== '' && (string) ($v['dependent_ids'] ?? '') !== $correctDep) {
                    $opts[$cdOptId]['values'][$vid]['dependent_ids'] = $correctDep;
                    $fixed++;
                }
            }
        }

        $added    = 0;
        $existing = 0; // dates in the requested range that are already in the template
        foreach ($entries as $e) {
            $sig = strtolower(trim($e['reg_course'] . '|' . $e['title']));
            if (isset($seen[$sig])) { $existing++; continue; }
            $seen[$sig] = true;
            $maxValId++;
            $maxSort++;
            $maxInGroupId++;  // unique in_group_id — must never be empty or 0
            $isEvening = (stripos($e['title'], 'Evening') !== false);
            $depId = $isEvening ? $eveningDepId : $morningDepId;
            $opts[$cdOptId]['values'][$maxValId] = array(
                'option_type_id'    => (string) $maxValId,
                'is_delete'         => '',
                'in_group_id'       => (string) $maxInGroupId,
                'title'             => $e['title'],
                'reg_course'        => $e['reg_course'],
                'price'             => '0.00',
                'price_type'        => 'fixed',
                'sku'               => '',
                'sort_order'        => (string) $maxSort,
                'customoptions_qty' => '',
                'dependent_ids'     => $depId,
                'images'            => array(),
            );
            $added++;
        }

        if ($added > 0 || $fixed > 0) {
            // Re-sort all Course Date values chronologically by the date in their title,
            // then reassign sort_order 1, 2, 3... so the dropdown always shows dates in order.
            $vals = array_values($opts[$cdOptId]['values']);
            usort($vals, function ($a, $b) {
                return $this->_parseTitleTimestamp($a['title'] ?? '')
                     - $this->_parseTitleTimestamp($b['title'] ?? '');
            });
            $sorted = array();
            foreach ($vals as $i => $v) {
                $v['sort_order'] = (string) ($i + 1);
                $sorted[(int) $v['option_type_id']] = $v;
            }
            $opts[$cdOptId]['values'] = $sorted;
            $group->setHashOptions(serialize($opts))->save();
        }
        return array('added' => $added, 'fixed' => $fixed, 'existing' => $existing);
    }

    /**
     * Parse a date from an option title like "8 Jan 2027 (Fri)",
     * "11/12 Feb 2027 Evening Thu/Fri", "7/8 Jan 2027 (Sat/Sun)".
     * Returns a Unix timestamp for sorting, or PHP_INT_MAX on failure.
     */
    protected function _parseTitleTimestamp($title)
    {
        // Strip day-range prefix (e.g. "7/8 " → "7 "), evening suffix, day-of-week suffix
        $clean = preg_replace('/^(\d+)\/\d+\s+/', '$1 ', trim($title));
        $clean = preg_replace('/\s+(Evening|Morning|Afternoon|Night)\b.*/i', '', $clean);
        $clean = preg_replace('/\s*\([^)]*\)\s*$/', '', $clean);
        $clean = trim($clean);

        // Try strtotime directly first
        $ts = strtotime($clean);
        if ($ts !== false) return $ts;

        // Fallback: extract day + month + year with regex
        if (preg_match('/(\d{1,2})\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{4})/i', $clean, $m)) {
            $ts = strtotime($m[1] . ' ' . $m[2] . ' ' . $m[3]);
            if ($ts !== false) return $ts;
        }

        return PHP_INT_MAX; // Unrecognised — sort to end
    }

    /**
     * Server-side batch generate: processes ALL checked templates in one request.
     * Accepts group_ids (comma-separated) + start + end. Sets ignore_user_abort
     * so a page refresh doesn't kill the run; browser polls getBulkStateAction.
     */
    public function runBulkGenerateBatchAction()
    {
        ignore_user_abort(true);
        set_time_limit(0);
        @ini_set('memory_limit', '512M');
        @ini_set('display_errors', '0');
        @ob_start();

        $groupIdsRaw = trim((string) $this->getRequest()->getParam('group_ids', ''));
        $start       = trim((string) $this->getRequest()->getParam('start', ''));
        $end         = trim((string) $this->getRequest()->getParam('end',   ''));

        $groupIds = array_values(array_filter(array_map('intval', explode(',', $groupIdsRaw))));

        if (empty($groupIds) || $start === '' || $end === '') {
            $this->getResponse()->setHeader('Content-Type', 'application/json', true);
            $this->getResponse()->setBody(json_encode(array('error' => 'Missing parameters')));
            return;
        }

        $total     = count($groupIds);
        $generator = Mage::getModel('mmd/schedule_generator');

        $this->_saveBulkState(array(
            'status'        => 'generating',
            'start_date'    => $start,
            'end_date'      => $end,
            'total'         => $total,
            'started_at'    => time(),
            'gen_results'   => array(),
            'apply_list'    => array(),
            'apply_results' => array(),
        ));

        foreach ($groupIds as $idx => $groupId) {
            $result = array(
                'group_id'      => $groupId,
                'title'         => '',
                'group_id'      => $groupId,
                'added'         => 0,
                'fixed'         => 0,
                'existing'      => 0,
                'changed'       => 0,
                'product_count' => 0,
                'status'        => 'ok',
                'text'          => '',
            );

            try {
                $group = Mage::getModel('customoptions/group')->load($groupId);
                if (!$group->getId()) throw new Exception('Template #' . $groupId . ' not found');

                $code   = $generator->normalizeCode((string) $group->getTitle());
                $merged   = $this->_generateAndMerge($group, $code, $start, $end);
                $added    = is_array($merged) ? (int) $merged['added']    : 0;
                $fixed    = is_array($merged) ? (int) $merged['fixed']    : 0;
                $existing = is_array($merged) ? (int) $merged['existing'] : 0;
                $changed  = $added + $fixed;

                $summary = $added > 0
                    ? $this->__('%d new date(s)', $added)
                    : ($existing > 0 ? $this->__('%d already exist', $existing) : $this->__('no changes'));

                $productIds = $this->_resolveProductIds($group);

                $result['title']         = (string) $group->getTitle();
                $result['added']         = $added;
                $result['fixed']         = $fixed;
                $result['existing']      = $existing;
                $result['changed']       = $changed;
                $result['product_count'] = count($productIds);
                $result['text']          = sprintf('[%d/%d] %s — %s', $idx + 1, $total, $group->getTitle(), $summary);
                $result['status']        = $changed > 0 ? 'ok' : 'skip';
            } catch (\Throwable $e) {
                Mage::log('bulk generate error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine(), Zend_Log::ERR, 'exception.log');
                $result['text']   = sprintf('[%d/%d] ERROR: %s', $idx + 1, $total, $e->getMessage());
                $result['status'] = 'error';
            }
            gc_collect_cycles();

            $state = $this->_loadBulkState();
            if (!isset($state['gen_results']) || !is_array($state['gen_results'])) {
                $state['gen_results'] = array();
            }
            $state['gen_results'][] = $result;
            if ($result['changed'] > 0) {
                if (!isset($state['apply_list']) || !is_array($state['apply_list'])) {
                    $state['apply_list'] = array();
                }
                $state['apply_list'][] = array(
                    'group_id'      => $groupId,
                    'title'         => $result['title'],
                    'changed'       => $result['changed'],
                    'product_count' => $result['product_count'],
                );
            }
            if (count($state['gen_results']) >= $total) {
                $state['status'] = 'complete_generate';
            }
            $this->_saveBulkState($state);
        }

        @ob_end_clean();
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(json_encode($this->_loadBulkState()));
    }

    /**
     * Auto-generate "Course Date" values for a single template.
     * Uses _generateAndMerge; propagation to products via the normal Save flow.
     */
    public function generateDatesAction()
    {
        $id      = (int) $this->getRequest()->getParam('group_id');
        $code    = trim((string) $this->getRequest()->getParam('schedule_code'));
        $start   = trim((string) $this->getRequest()->getParam('start_date'));
        $end     = trim((string) $this->getRequest()->getParam('end_date'));
        $storeId = (int) $this->getRequest()->getParam('store', 0);

        $redirect = array('group_id' => $id);
        if ($storeId > 0) {
            $redirect['store'] = $storeId;
        }

        if ($id <= 0) {
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('Save the template before generating dates.')
            );
            return $this->_redirect('*/*/index');
        }

        $sd = DateTime::createFromFormat('Y-m-d', $start);
        $ed = DateTime::createFromFormat('Y-m-d', $end);
        if (!($sd instanceof DateTime) || !($ed instanceof DateTime)) {
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('Enter a valid start date and end date.')
            );
            return $this->_redirect('*/*/edit', $redirect);
        }
        if ($sd > $ed) {
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('Start date must be on or before the end date.')
            );
            return $this->_redirect('*/*/edit', $redirect);
        }

        $generator = Mage::getModel('mmd/schedule_generator');
        if (!$generator->isKnownCode($code)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__(
                "Schedule code '%s' is not a recognised slot. Use A01-A20, B01/03/05…21, C01-C04, D01-D04 or E01-E04.",
                Mage::helper('core')->escapeHtml($code)
            ));
            return $this->_redirect('*/*/edit', $redirect);
        }

        try {
            $group = Mage::getModel('customoptions/group')->load($id);
            if (!$group->getId()) {
                Mage::getSingleton('adminhtml/session')->addError($this->__('Template not found.'));
                return $this->_redirect('*/*/index');
            }
            $result   = $this->_generateAndMerge($group, $code, $start, $end);
            $added    = (int) $result['added'];
            $existing = (int) $result['existing'];
            $changed  = $added + (int) $result['fixed'];
            if ($changed === 0) {
                $msg = $existing > 0
                    ? $this->__('All %d dates in that range already exist for %s — no changes made.', $existing, Mage::helper('core')->escapeHtml(strtoupper($code)))
                    : $this->__('No dates were generated for %s in that range.', Mage::helper('core')->escapeHtml(strtoupper($code)));
                Mage::getSingleton('adminhtml/session')->addNotice($msg);
            } else {
                Mage::getSingleton('adminhtml/session')->addSuccess($this->__(
                    '%d new Course Date entries added for %s. Click "Save And Continue Edit" to apply them to assigned courses.',
                    $added,
                    Mage::helper('core')->escapeHtml(strtoupper($code))
                ));
            }
        } catch (Exception $e) {
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        }

        return $this->_redirect('*/*/edit', $redirect);
    }

    /**
     * Deprecated: bulk generation is now driven by the inline panel on the
     * index page. Redirect any stale bookmarks back to the index.
     */
    public function globalGenerateAction()
    {
        return $this->_redirect('*/*/');
    }

    public function globalProgressAction()
    {
        return $this->_redirect('*/*/');
    }

    /**
     * AJAX Step 1: generate+save dates for one template.
     * Accepts direct GET params: group_id, code, start, end, idx, total.
     * Saves incremental progress to var/bulk_schedule_state.json so the
     * inline panel can restore history on page reload.
     */
    public function runGlobalGenerateAction()
    {
        @ini_set('max_execution_time', 300);
        @ini_set('memory_limit', 512000000);

        $groupId = (int)   $this->getRequest()->getParam('group_id', 0);
        $code    = trim((string) $this->getRequest()->getParam('code',  ''));
        $start   = trim((string) $this->getRequest()->getParam('start', ''));
        $end     = trim((string) $this->getRequest()->getParam('end',   ''));
        $idx     = (int)   $this->getRequest()->getParam('idx',   0);
        $total   = (int)   $this->getRequest()->getParam('total', 1);

        // Initialise state on first call of a new run
        if ($idx === 0) {
            $this->_saveBulkState(array(
                'status'        => 'generating',
                'start_date'    => $start,
                'end_date'      => $end,
                'total'         => $total,
                'started_at'    => time(),
                'gen_results'   => array(),
                'apply_list'    => array(),
                'apply_results' => array(),
            ));
        }

        if ($groupId <= 0 || $code === '' || $start === '' || $end === '') {
            $this->getResponse()->setBody(json_encode(array(
                'stop' => 1, 'text' => 'Invalid parameters.', 'status' => 'error',
            )));
            return;
        }

        $result = array(
            'group_id'      => $groupId,
            'code'          => $code,
            'title'         => '',
            'added'         => 0,
            'fixed'         => 0,
            'existing'      => 0,
            'changed'       => 0,
            'product_count' => 0,
            'status'        => 'ok',
            'text'          => '',
        );

        try {
            $group = Mage::getModel('customoptions/group')->load($groupId);
            if (!$group->getId()) throw new Exception('Template not found.');

            $merged     = $this->_generateAndMerge($group, $code, $start, $end);
            $productIds = $this->_resolveProductIds($group);
            $added      = (int) $merged['added'];
            $fixed      = (int) $merged['fixed'];
            $existing   = (int) $merged['existing'];
            $changed    = $added + $fixed;

            $summary = $added > 0
                ? $this->__('%d new date(s)', $added)
                : ($existing > 0 ? $this->__('%d already exist', $existing) : $this->__('no changes'));

            $result['title']         = (string) $group->getTitle();
            $result['added']         = $added;
            $result['fixed']         = $fixed;
            $result['existing']      = $existing;
            $result['changed']       = $changed;
            $result['product_count'] = count($productIds);
            $result['text']          = sprintf('[%d/%d] %s — %s', $idx + 1, $total, $group->getTitle(), $summary);
            $result['status']        = $changed > 0 ? 'ok' : 'skip';
        } catch (\Throwable $e) {
            Mage::log('generate error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine(), Zend_Log::ERR, 'exception.log');
            $result['text']   = sprintf('[%d/%d] ERROR: %s', $idx + 1, $total, $e->getMessage());
            $result['status'] = 'error';
        }

        // Save progress to state file
        $state = $this->_loadBulkState();
        if (!isset($state['gen_results']) || !is_array($state['gen_results'])) {
            $state['gen_results'] = array();
        }
        $state['gen_results'][] = $result;

        if ($idx + 1 >= $total) {
            $state['status']     = 'complete_generate';
            $state['apply_list'] = array();
            foreach ($state['gen_results'] as $r) {
                if (!empty($r['changed'])) {
                    $state['apply_list'][] = array(
                        'group_id'      => $r['group_id'],
                        'title'         => $r['title'],
                        'product_count' => $r['product_count'],
                    );
                }
            }
            $result['stop'] = 1;
        }
        $this->_saveBulkState($state);

        $this->getResponse()->setBody(json_encode($result));
    }

    /**
     * Server-side batch apply: processes ALL templates from apply_list in one
     * request. Sets ignore_user_abort so a page refresh doesn't kill the run.
     * The browser polls getBulkStateAction() every 2s to show live progress.
     */
    public function runBulkApplyBatchAction()
    {
        ignore_user_abort(true);
        set_time_limit(0);
        @ini_set('memory_limit', '512M');
        @ini_set('display_errors', '0');  // prevent PHP notices from corrupting the JSON response
        @ob_start();                       // capture any stray output before we flush

        // Mutex: only one apply process may run at a time.
        // Without this, JS staleness auto-retry fires a second PHP process while
        // the first is still running, causing duplicate template processing and
        // out-of-order results. The lock is released automatically when the process exits.
        $lockFile = Mage::getBaseDir('var') . '/bulk_apply.lock';
        $lockFp   = fopen($lockFile, 'w');
        if (!$lockFp || !flock($lockFp, LOCK_EX | LOCK_NB)) {
            if ($lockFp) fclose($lockFp);
            @ob_end_clean();
            $this->getResponse()->setHeader('Content-Type', 'application/json', true);
            $this->getResponse()->setBody(json_encode(array('status' => 'locked')));
            return;
        }
        // Release lock when PHP process exits (normal or fatal).
        register_shutdown_function(function () use ($lockFp, $lockFile) {
            flock($lockFp, LOCK_UN);
            fclose($lockFp);
            @unlink($lockFile);
        });

        $state     = $this->_loadBulkState();
        $applyList = isset($state['apply_list']) && is_array($state['apply_list'])
                     ? $state['apply_list'] : array();

        // When apply_list is empty (idempotency run where generate found no changes),
        // re-use the same templates that went through generate so Apply All still
        // pushes the current template state to all the selected courses.
        // Fallback for "Apply All with no prior generate": all active templates.
        if (empty($applyList)) {
            if (!empty($state['gen_results'])) {
                foreach ($state['gen_results'] as $r) {
                    if (isset($r['group_id'])) {
                        $applyList[] = array(
                            'group_id'      => (int) $r['group_id'],
                            'title'         => (string) ($r['title'] ?? ''),
                            'product_count' => (int)  ($r['product_count'] ?? 0),
                        );
                    }
                }
            }
            if (empty($applyList)) {
                $collection = Mage::getModel('customoptions/group')->getCollection();
                $collection->getSelect()->where('is_active = 1')->order('title ASC');
                foreach ($collection as $g) {
                    $applyList[] = array('group_id' => (int)$g->getId(), 'title' => (string)$g->getTitle());
                }
            }
            $state['apply_list'] = $applyList;
        }

        if (empty($applyList)) {
            $this->getResponse()->setHeader('Content-Type', 'application/json', true);
            $this->getResponse()->setBody(json_encode(array('error' => 'No active templates found.')));
            return;
        }

        // Resume mid-run only when status is 'applying' (process died partway through).
        // For any other status (complete, idle, complete_generate), start fresh.
        $isMidRun        = (isset($state['status']) && $state['status'] === 'applying');
        $existingResults = ($isMidRun && isset($state['apply_results']) && is_array($state['apply_results']))
                           ? $state['apply_results'] : array();
        $doneCount = count($existingResults);

        $state['status']        = 'applying';
        $state['apply_results'] = $existingResults;
        $this->_saveBulkState($state);

        $total = count($applyList);
        foreach ($applyList as $idx => $item) {
            // Skip already-processed templates on resume
            if ($idx < $doneCount) continue;
            $groupId = (int) $item['group_id'];
            try {
                $group = Mage::getModel('customoptions/group')->load($groupId);
                if (!$group->getId()) throw new \Exception('Template #' . $groupId . ' not found.');

                $newOpts    = @unserialize($group->getHashOptions());
                if (!is_array($newOpts)) $newOpts = array();

                // Fix any values with empty in_group_id BEFORE sorting.
                // Empty in_group_id causes _prepareOptions to map all such values
                // to the same 'IGI0' key, so saveProductOptions silently drops all
                // but the last value. Assign unique sequential IDs.
                $maxIgi = 0;
                foreach ($newOpts as $o) {
                    foreach ((array)($o['values'] ?? array()) as $v) {
                        if (isset($v['in_group_id']) && $v['in_group_id'] !== '') {
                            $maxIgi = max($maxIgi, (int) $v['in_group_id']);
                        }
                    }
                }
                foreach ($newOpts as &$optFix) {
                    if (!empty($optFix['values']) && is_array($optFix['values'])) {
                        foreach ($optFix['values'] as $k => &$vFix) {
                            if (!isset($vFix['in_group_id']) || $vFix['in_group_id'] === '') {
                                $vFix['in_group_id'] = (string)(++$maxIgi);
                            }
                        }
                        unset($vFix);
                    }
                }
                unset($optFix);

                // Sort Course Date values chronologically before applying so the
                // storefront dropdown always shows dates in ascending date order.
                // Preserve option_type_id as the array key (required by _prepareOptions).
                foreach ($newOpts as &$opt) {
                    if (empty($opt['values']) || !is_array($opt['values'])) continue;
                    $title = strtolower(trim($opt['title'] ?? ''));
                    if (strpos($title, 'date') === false && strpos($title, 'course') === false) continue;
                    $vals = array_values($opt['values']);
                    usort($vals, function ($a, $b) {
                        return $this->_parseTitleTimestamp($a['title'] ?? '')
                             - $this->_parseTitleTimestamp($b['title'] ?? '');
                    });
                    $sorted = array();
                    foreach ($vals as $i => $v) {
                        $v['sort_order'] = (string)($i + 1);
                        // Use existing option_type_id as the array key; fall back to
                        // loop index for new values that have no DB-assigned ID yet.
                        // Also write it back inside $v — Option.php line 292 reads
                        // $val['option_type_id'] directly, and a missing field triggers
                        // a PHP 8.2 warning that Magento converts to a Throwable.
                        $keyId = (isset($v['option_type_id']) && $v['option_type_id'] !== '')
                                 ? (int)$v['option_type_id'] : $i;
                        $v['option_type_id'] = (string)$keyId;
                        $sorted[$keyId] = $v;
                    }
                    $opt['values'] = $sorted;
                }
                unset($opt);

                // Persist the sorted order (with corrected in_group_ids) back to the template.
                $group->setHashOptions(serialize($newOpts))->save();

                $productIds = $this->_resolveProductIds($group);

                if (!empty($productIds)) {
                    Mage::getModel('catalog/product_option')->saveProductOptions(
                        $newOpts, array(), $productIds, $group, $group->getIsActive(), 'apo', array()
                    );
                    $note = sprintf('applied to %d product(s)', count($productIds));
                } else {
                    $note = 'no products assigned';
                }
                $result = array(
                    'text'   => sprintf('[%d/%d] %s — %s', $idx + 1, $total, $group->getTitle(), $note),
                    'status' => 'ok',
                );
            } catch (\Throwable $e) {
                Mage::log('bulk apply error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine(), Zend_Log::ERR, 'exception.log');
                $result = array(
                    'text'   => sprintf('[%d/%d] ERROR: %s', $idx + 1, $total, $e->getMessage()),
                    'status' => 'error',
                );
            }
            gc_collect_cycles();

            // Reload state before writing to avoid clobbering concurrent writes
            $state = $this->_loadBulkState();
            if (!isset($state['apply_results']) || !is_array($state['apply_results'])) {
                $state['apply_results'] = array();
            }
            $state['apply_results'][] = $result;
            if (count($state['apply_results']) >= $total) {
                $state['status'] = 'complete';
                // Flush block/page cache so storefront shows new dates immediately
                try { Mage::app()->getCacheInstance()->cleanType('block_html'); } catch (Exception $ce) {}
                try { Mage::app()->getCacheInstance()->cleanType('full_page'); } catch (Exception $ce) {}
            }
            $this->_saveBulkState($state);
        }

        @ob_end_clean();  // discard any stray PHP output so JSON is clean
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(json_encode($this->_loadBulkState()));
    }

    /**
     * AJAX Step 2: apply one template's current hash_options to its products.
     * Accepts group_id, idx, total. Saves apply progress to state file.
     */
    public function runGlobalApplyAction()
    {
        @ini_set('max_execution_time', 300);
        @ini_set('memory_limit', 512000000);

        $groupId = (int) $this->getRequest()->getParam('group_id');
        $idx     = (int) $this->getRequest()->getParam('idx', 0);
        $total   = (int) $this->getRequest()->getParam('total', 1);

        if ($groupId <= 0) {
            $this->getResponse()->setBody(json_encode(array(
                'status' => 'error',
                'text'   => sprintf('[%d/%d] Invalid group ID', $idx + 1, $total),
            )));
            return;
        }

        // Mark apply as started on first call
        if ($idx === 0) {
            $state = $this->_loadBulkState();
            $state['status']        = 'applying';
            $state['apply_results'] = array();
            $this->_saveBulkState($state);
        }

        try {
            $group = Mage::getModel('customoptions/group')->load($groupId);
            if (!$group->getId()) throw new Exception('Template #' . $groupId . ' not found.');

            $newOpts    = @unserialize($group->getHashOptions());
            if (!is_array($newOpts)) $newOpts = array();

            // Patch empty in_group_id before sorting — same fix as runBulkApplyBatchAction.
            $maxIgi = 0;
            foreach ($newOpts as $o) {
                foreach ((array)($o['values'] ?? array()) as $v) {
                    if (isset($v['in_group_id']) && $v['in_group_id'] !== '') {
                        $maxIgi = max($maxIgi, (int) $v['in_group_id']);
                    }
                }
            }
            foreach ($newOpts as &$optFix) {
                if (!empty($optFix['values']) && is_array($optFix['values'])) {
                    foreach ($optFix['values'] as $k => &$vFix) {
                        if (!isset($vFix['in_group_id']) || $vFix['in_group_id'] === '') {
                            $vFix['in_group_id'] = (string)(++$maxIgi);
                        }
                    }
                    unset($vFix);
                }
            }
            unset($optFix);

            // Sort Course Date values chronologically and write option_type_id inside each value.
            foreach ($newOpts as &$opt) {
                if (empty($opt['values']) || !is_array($opt['values'])) continue;
                $title = strtolower(trim($opt['title'] ?? ''));
                if (strpos($title, 'date') === false && strpos($title, 'course') === false) continue;
                $vals = array_values($opt['values']);
                usort($vals, function ($a, $b) {
                    return $this->_parseTitleTimestamp($a['title'] ?? '')
                         - $this->_parseTitleTimestamp($b['title'] ?? '');
                });
                $sorted = array();
                foreach ($vals as $i => $v) {
                    $v['sort_order'] = (string)($i + 1);
                    $keyId = (isset($v['option_type_id']) && $v['option_type_id'] !== '')
                             ? (int)$v['option_type_id'] : $i;
                    $v['option_type_id'] = (string)$keyId;
                    $sorted[$keyId] = $v;
                }
                $opt['values'] = $sorted;
            }
            unset($opt);

            $productIds = $this->_resolveProductIds($group);

            if (!empty($productIds)) {
                Mage::getModel('catalog/product_option')->saveProductOptions(
                    $newOpts, array(), $productIds, $group, $group->getIsActive(), 'apo', array()
                );
                Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds);
                $note = sprintf('applied to %d product(s)', count($productIds));
            } else {
                $note = 'no products assigned';
            }

            $result = array(
                'text'   => sprintf('[%d/%d] %s — %s', $idx + 1, $total, $group->getTitle(), $note),
                'status' => 'ok',
            );
        } catch (Exception $e) {
            Mage::logException($e);
            $result = array(
                'text'   => sprintf('[%d/%d] ERROR: %s', $idx + 1, $total, $e->getMessage()),
                'status' => 'error',
            );
        }

        // Save apply progress
        $state = $this->_loadBulkState();
        if (!isset($state['apply_results']) || !is_array($state['apply_results'])) {
            $state['apply_results'] = array();
        }
        $state['apply_results'][] = $result;
        $applyListCount = isset($state['apply_list']) ? count($state['apply_list']) : $total;
        if (count($state['apply_results']) >= $applyListCount) {
            $state['status'] = 'complete';
        }
        $this->_saveBulkState($state);

        $this->getResponse()->setBody(json_encode($result));
    }

    /**
     * Parse the reg_course varchar (stored as "%m/%d/%y", e.g. "03/14/26")
     * into a unix timestamp at local 00:00. Returns false if unparseable.
     */
    protected function _parseRegCourseTs($value)
    {
        $v = trim((string) $value);
        if ($v === '') return false;
        if (!preg_match('#^(\d{1,2})/(\d{1,2})/(\d{2,4})$#', $v, $m)) return false;
        $yy = (int) $m[3];
        if ($yy < 100) $yy += 2000;
        $ts = mktime(0, 0, 0, (int) $m[1], (int) $m[2], $yy);
        return $ts === false ? false : $ts;
    }

    /**
     * STEP 1 — Clean templates only.
     *
     * Walks every option-template's serialized hash_options (and per-store
     * overrides) and removes Course Date values whose reg_course is in the
     * past. Does NOT touch any product-side rows. After this the templates
     * are clean but products still hold the historical dates; run Step 2
     * ("Apply to Products") to propagate.
     */
    public function cleanTemplatesPastDatesAction()
    {
        $today = strtotime('today');
        $rowsRemoved = 0;
        $templatesAffected = 0;

        try {
            $collection = Mage::getResourceModel('customoptions/group_collection');
            foreach ($collection as $group) {
                $changed = false;
                $hash = $group->getHashOptions();
                if ($hash) {
                    $opts = @unserialize($hash);
                    if (is_array($opts)) {
                        list($opts, $removed) = $this->_stripPastCourseDates($opts, $today);
                        if ($removed > 0) {
                            $group->setHashOptions(serialize($opts))->save();
                            $rowsRemoved += $removed;
                            $changed = true;
                        }
                    }
                }

                $storeColl = Mage::getResourceModel('customoptions/group_store_collection')
                    ->addFieldToFilter('group_id', $group->getId());
                foreach ($storeColl as $gs) {
                    $sh = $gs->getHashOptions();
                    if (!$sh) continue;
                    $sOpts = @unserialize($sh);
                    if (!is_array($sOpts)) continue;
                    list($sOpts, $sRemoved) = $this->_stripPastCourseDates($sOpts, $today);
                    if ($sRemoved > 0) {
                        $gs->setHashOptions(serialize($sOpts))->save();
                        $changed = true;
                    }
                }

                if ($changed) $templatesAffected++;
            }

            if ($rowsRemoved === 0) {
                Mage::getSingleton('adminhtml/session')->addNotice(
                    $this->__('No past Course Date entries found in any template.')
                );
            } else {
                Mage::getSingleton('adminhtml/session')->addSuccess(
                    $this->__(
                        'Step 1 done: removed %d past Course Date entry/entries across %d template(s). Verify, then click "Apply to Products" to propagate.',
                        $rowsRemoved, $templatesAffected
                    )
                );
            }
        } catch (Exception $e) {
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        }

        $this->_redirect('*/*/index');
    }

    /**
     * Helper for Step 1 — strip past-dated entries from the "Course Date"
     * option inside an unserialized hash_options array. Returns
     * [cleanedOpts, removedCount].
     */
    protected function _stripPastCourseDates(array $opts, $todayTs)
    {
        $removed = 0;
        foreach ($opts as $optId => $opt) {
            if (empty($opt['title']) || strcasecmp(trim($opt['title']), 'course date') !== 0) continue;
            if (empty($opt['values']) || !is_array($opt['values'])) continue;
            foreach ($opt['values'] as $valId => $val) {
                $ts = $this->_parseRegCourseTs(isset($val['reg_course']) ? $val['reg_course'] : '');
                if ($ts !== false && $ts < $todayTs) {
                    unset($opts[$optId]['values'][$valId]);
                    $removed++;
                }
            }
        }
        return array($opts, $removed);
    }

    /**
     * STEP 2 — Apply cleaned templates to products.
     *
     * Deletes every Course Date row in the past from products'
     * catalog_product_option_type_value (+ linked title/price/image rows),
     * then reindexes prices for affected products and flushes storefront
     * caches. Title scoped to "Course Date" so other dropdowns are safe.
     */
    public function applyTemplatesToProductsAction()
    {
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $tValue  = $resource->getTableName('catalog_product_option_type_value');
        $tTitle  = $resource->getTableName('catalog_product_option_type_title');
        $tPrice  = $resource->getTableName('catalog_product_option_type_price');
        $tImage  = $resource->getTableName('custom_options_option_type_image');
        $tOpt    = $resource->getTableName('catalog_product_option');
        $tOptTit = $resource->getTableName('catalog_product_option_title');

        try {
            $rows = $write->fetchAll(
                "SELECT DISTINCT v.option_type_id, o.product_id
                 FROM {$tValue} v
                 JOIN {$tOpt} o       ON o.option_id = v.option_id
                 JOIN {$tOptTit} ot   ON ot.option_id = v.option_id
                 WHERE LOWER(TRIM(ot.title)) = 'course date'
                   AND v.reg_course IS NOT NULL
                   AND v.reg_course <> ''
                   AND STR_TO_DATE(v.reg_course, '%m/%d/%y') IS NOT NULL
                   AND STR_TO_DATE(v.reg_course, '%m/%d/%y') < CURDATE()"
            );

            if (empty($rows)) {
                Mage::getSingleton('adminhtml/session')->addNotice(
                    $this->__('No past Course Date rows found on any product.')
                );
                $this->_redirect('*/*/index');
                return;
            }

            $ids = $productIds = array();
            foreach ($rows as $r) {
                $ids[] = $r['option_type_id'];
                if (!empty($r['product_id'])) $productIds[$r['product_id']] = true;
            }
            $productIds = array_keys($productIds);

            $write->beginTransaction();
            $deleted = $write->delete($tValue, array('option_type_id IN (?)' => $ids));
            $write->delete($tTitle, array('option_type_id IN (?)' => $ids));
            $write->delete($tPrice, array('option_type_id IN (?)' => $ids));
            if ($write->isTableExists($tImage)) {
                $write->delete($tImage, array('option_type_id IN (?)' => $ids));
            }
            $write->commit();

            try {
                if (!empty($productIds)) {
                    Mage::getResourceModel('catalog/product_indexer_price')
                        ->reindexProductIds($productIds);
                }
                Mage::app()->getCacheInstance()->cleanType('block_html');
                Mage::app()->getCacheInstance()->cleanType('full_page');
                Mage::app()->getCacheInstance()->cleanType('collections');
                $flat = Mage::getModel('index/process')->load('catalog_product_flat', 'indexer_code');
                if ($flat && $flat->getId()) {
                    $flat->changeStatus(Mage_Index_Model_Process::STATUS_REQUIRE_REINDEX);
                }
            } catch (Exception $cacheEx) {
                Mage::logException($cacheEx);
            }

            Mage::getSingleton('adminhtml/session')->addSuccess(
                $this->__(
                    'Step 2 done: deleted %d past Course Date row(s) across %d product(s). Price index refreshed; storefront caches flushed.',
                    $deleted, count($productIds)
                )
            );
        } catch (Exception $e) {
            if (isset($write) && $write) {
                try { $write->rollBack(); } catch (Exception $rb) {}
            }
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        }

        $this->_redirect('*/*/index');
    }

    public function massDeleteAction() {
        $ids = $this->getRequest()->getParam('groups');
        if (!is_array($ids)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Please select Option(s)'));
        } else {
            try {
                if (isset($ids) && is_array($ids))
                    foreach ($ids as $id) {
                        $model = Mage::getModel('customoptions/group')->load($id);
                        $model->delete();
                    }
                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Total of %d record(s) were successfully deleted', count($ids)));
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            }
        }
        $this->_redirect('*/*/index');
    }

    public function massStatusAction() {
        $ids = $this->getRequest()->getParam('groups');
        if (!is_array($ids)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Please select Option(s)'));
        } else {
            try {
                $data = array();
                $relation = Mage::getSingleton('customoptions/relation');
                $model = Mage::getSingleton('customoptions/group');
                if (isset($ids) && is_array($ids)) {
                    foreach ($ids as $id) {
                        $model->load($id)
                            ->setIsActive((int) $this->getRequest()->getParam('is_active'))
                            ->save();
                        $relation->changeOptionsStatus($model);
                        $data[$model->getId()] = $model;
                    }
                    $relation->changeHasOptions($data);
                    $this->_getSession()->addSuccess($this->__('Total of %d record(s) were successfully updated', count($ids)));
                }
            } catch (Exception $e) {
                $this->_getSession()->addError($e->getMessage());
            }
        }
        $this->_redirect('*/*/index');
    }

    public function _uploadImage($keyFile, $groupId, $optionId, $valueId = false, &$value) {
        
        $helper = Mage::helper('customoptions');
        
        $imageSort = isset($value['image_sort'])?$value['image_sort']:array();
        $imageDelete = isset($value['image_delete'])?$value['image_delete']:array();
        $imageChange = isset($value['image_change'])?$value['image_change']:0;

        // check and save image_sort_change
        if ($imageChange) {
            // image_delete
            foreach ($imageDelete as $fileName) {
                if ($fileName) $helper->deleteOptionFile($groupId, $optionId, $valueId, $fileName);
            }
            
            // if change color
            foreach($imageSort as $sort=>$fileName) {
                if (isset($value['image_color'][$fileName])) $imageSort[$sort] = $value['image_color'][$fileName];
            }
        }
        
        
        $imagesCount = count($imageSort);
        
        $uploadType = isset($value['upload_type'])?$value['upload_type']:array();
        $files = array();
        $colors = array();
        $galleries = array();
        foreach($uploadType as $index=>$type) {
            if ($type=='file') {
                $files[] = $index;
            } else if ($type=='color') {
                $colors[] = $index;
            } else if ($type=='gallery') {
                $galleries[] = $index;
            }
        }
        
        // upload image(s)
        if (isset($_FILES[$keyFile]['name'])) {
            $keyFileArr = array($keyFile);
        } else {
            $keyFileArr = array();
            foreach ($files as $index) {
                if (isset($_FILES[$keyFile . '_' . $index]['name'])) {
                    $keyFileArr[$index] = $keyFile . '_' . $index;
                }
            }
        }
        foreach ($keyFileArr as $index=>$keyFile) {
            if (isset($_FILES[$keyFile]['name']) && $_FILES[$keyFile]['name'] != '') {
                try {
                    $isUpdate = $helper->deleteOptionFile($groupId, $optionId, $valueId, ($valueId?$_FILES[$keyFile]['name']:''));

                    $uploader = new Varien_File_Uploader($keyFile);
                    $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
                    $uploader->setAllowRenameFiles(false);
                    $uploader->setFilesDispersion(false);
                    
                    $saveResult = $uploader->save($helper->getCustomOptionsPath($groupId, $optionId, $valueId), $_FILES[$keyFile]['name']);
                    if ($saveResult && isset($saveResult['file'])) {
                        if ($valueId && !$isUpdate) {
                            $imageSort[$imagesCount+$index] = $saveResult['file'];
                        }
                    }
                } catch (Exception $e) {
                    if ($e->getMessage()) {
                        Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                    }
                }
            }
        }
        
        // upload colors
        $colorArr = array();
        foreach($colors as $index) {
            if (isset($value['upload_color'][$index]) && strlen($value['upload_color'][$index])>4) $colorArr[$index] = $value['upload_color'][$index];
        }
        foreach ($colorArr as $index=>$color) {
            $imageSort[$imagesCount+$index] = $color;
        }
        
        ksort($imageSort);
        
        unset($value['image_sort']);
        unset($value['image_delete']);
        unset($value['image_change']);
        unset($value['upload_type']);
        unset($value['upload_color']);
        
        return $imageSort;
    }
}