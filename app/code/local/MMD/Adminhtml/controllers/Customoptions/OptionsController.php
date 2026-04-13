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
            ->_addBreadcrumb($this->__('APO'), $this->__('Manage Templates'))
            ->_addContent($this->getLayout()->createBlock('mmd/customoptions_options_edit'))
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
                            // start multi-step apply
                            $limit = ceil(250/$approximateOptionCount);
                            Mage::getSingleton('adminhtml/session')->setCustomoptionsApplyData(array($defaultOptions, $optionsPrev, $productIds, $group, $prevGroupIsActive, $prevStoreOptionsData, $redirectData, $limit));
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
        $group = $customoptionsApplyData[3];
        $prevGroupIsActive = $customoptionsApplyData[4];
        $prevStoreOptionsData = $customoptionsApplyData[5];
        Mage::getModel('catalog/product_option')->saveProductOptions($defaultOptions, $optionsPrev, $productIds, $group, $prevGroupIsActive, 'product', $prevStoreOptionsData);
    }
    
    public function runApplyAction() {
        @ini_set('max_execution_time', 1800);
        @ini_set('memory_limit', 734003200);        
        
        $current = $this->getRequest()->getParam('current', 0);
        $customoptionsApplyData = Mage::getSingleton('adminhtml/session')->getCustomoptionsApplyData();
        if (count($customoptionsApplyData)!=8) return $this->_redirect('*/*/');
        
        $limit = $customoptionsApplyData[7];
        $productIds = $customoptionsApplyData[2];        
        $total = count($productIds);
        $result = array();        
        
        if ($current=='checkUnassigned') { // check and remove of unassigned options
            $group = $customoptionsApplyData[3];
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