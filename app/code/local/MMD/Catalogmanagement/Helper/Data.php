<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Helper_Data extends Mage_Core_Helper_Abstract
{
    protected function _getStore()
    {
        $storeId = (int) Mage::app()->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
    }
    
    public function getColumnsProperties($json = true, $reloadAttributes = false)
    {
        $prop = array();
        
        if (Mage::getStoreConfig('catalogmanagement/cols/name'))
        {
            $prop['name'] = array(
                'type'      => 'text',
                'col'       => 'name',
            );
            
            $prop['custom_name'] = array(
                'type'      => 'text',
                'col'       => 'custom_name',
            );
        }

        if (Mage::getStoreConfig('catalogmanagement/cols/sku'))
        {
            $prop['sku'] = array(
                'type'      => 'text',
                'col'       => 'sku',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/cols/price'))
        {
            $prop['price'] = array(
                'type'      => 'price',
                'col'       => 'price',
                'format'    => 'numeric',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/cols/qty'))
        {
            $prop['qty'] = array(
                'type'      => 'text',
                'col'       => 'qty',
                'obj'       => 'stock_item',
                'format'    => 'numeric',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/additional/avail'))
        {
            $prop['is_in_stock'] = array(
                'type'      => 'select',
                'options'   => array(0 => $this->__('Out of stock'), 1 => $this->__('In stock')),
                'col'       => 'is_in_stock',
                'obj'       => 'stock_item',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/cols/vis'))
        {
            $visibilityOptions = Mage::getModel('catalog/product_visibility')->getOptionArray();
            $prop['visibility'] = array(
                'type'      => 'select',
                'options'   => $visibilityOptions,
                'col'       => 'visibility',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/cols/status'))
        {
            $statusOptions = Mage::getSingleton('catalog/product_status')->getOptionArray();
            $prop['status'] = array(
                'type'      => 'select',
                'options'   => $statusOptions,
                'col'       => 'status',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/additional/special_price'))
        {
            $prop['special_price'] = array(
                'type'      => 'price',
                'col'       => 'special_price',
                'format'    => 'numeric',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/additional/special_price_dates'))
        {
            $prop['special_from_date'] = array(
                'type'      => 'date',
                'col'       => 'special_from_date',
            );
            $prop['special_to_date'] = array(
                'type'      => 'date',
                'col'       => 'special_to_date',
            );
        }
        
        if (Mage::getStoreConfig('catalogmanagement/additional/cost'))
        {
            $prop['cost'] = array(
                'type'      => 'price',
                'col'       => 'cost',
                'format'    => 'numeric',
            );
        }

        if (Mage::getStoreConfig('catalogmanagement/attr/cols'))
        {
            if ($reloadAttributes)
            {
                $attributes = $this->prepareGridAttributesCollection();
                Mage::register('catalogmanagement_grid_attributes', $attributes);
            }
            
            // adding grid attributes to editable columns
            // @see MMD_Catalogmanagement_Block_Adminhtml_Catalog_Product_Grid::_prepareColumns for registry param
            if ($attributes = Mage::registry('catalogmanagement_grid_attributes'))
            {
                foreach ($attributes as $attribute)
                {
                    $prop[$attribute->getAttributeCode()] = array(
                        'col'       => $attribute->getAttributeCode(),
                        'source'    => 'attribute', // will be used to make difference between default columns and attribute columns
                    );
                    if ('select' == $attribute->getFrontendInput() || 'multiselect' == $attribute->getFrontendInput() || 'boolean'  == $attribute->getFrontendInput())
                    {
                        if ('multiselect' == $attribute->getFrontendInput())
                        {
                            $prop[$attribute->getAttributeCode()]['type'] = 'multiselect';
                        } else 
                        {
                            $prop[$attribute->getAttributeCode()]['type'] = 'select';
                        }
                        $propOptions = array();
                        
                        if ('custom_design' == $attribute->getAttributeCode())
                        {
                            $allOptions = $attribute->getSource()->getAllOptions();
                            if (is_array($allOptions) && !empty($allOptions))
                            {
                                foreach ($allOptions as $option)
                                {
                                    if (!is_array($option['value']))
                                    {
                                        $propOptions[$option['value']] = $option['value'];
                                    } else 
                                    {
                                        foreach ($option['value'] as $option2)
                                        {
                                            if (isset($option2['value']))
                                            {
                                                $propOptions[$option2['value']] = $option2['value'];
                                            }
                                        }
                                    }
                                }
                            }
                        } else 
                        {
                            // getting attribute values with translation
                            $valuesCollection = Mage::getResourceModel('eav/entity_attribute_option_collection')
                                ->setAttributeFilter($attribute->getId())
                                ->setStoreFilter($this->getStore()->getId(), false)
                                ->load();
                            if ($valuesCollection->getSize() > 0)
                            {
                                $propOptions[''] = '';
                                foreach ($valuesCollection as $item) {
                                    $propOptions[$item->getId()] = $item->getValue();
                                }
                            } else 
                            {
                                $selectOptions = $attribute->getFrontend()->getSelectOptions();
                                if ($selectOptions)
                                {
                                    foreach ($selectOptions as $selectOption)
                                    {
                                        $propOptions[$selectOption['value']] = $selectOption['label'];
                                    }
                                }
                            }
                        }
                        
                        $prop[$attribute->getAttributeCode()]['options'] = $propOptions;
                        
                        if (!$propOptions)
                        {
                            unset($prop[$attribute->getAttributeCode()]); // we should not make attribute editable, if it has no options
                        }
                    } elseif ('textarea' == $attribute->getFrontendInput()) 
                    {
                        $prop[$attribute->getAttributeCode()]['type'] = 'textarea';
                    } elseif ('price' == $attribute->getFrontendInput())
                    {
                        $prop[$attribute->getAttributeCode()]['type']          = 'price';
                        $prop[$attribute->getAttributeCode()]['currency_code'] = $this->_getStore()->getBaseCurrency()->getCode();
                    }
                    else 
                    {
                        $prop[$attribute->getAttributeCode()]['type'] = 'text';
                    }
                }
            }
        }

        if (!$json)
        {
            return $prop;
        }

        return Mage::helper('core')->jsonEncode($prop);
    }
    
    public function getDefaultColumns()
    {
        return array('name', 'sku', 'price', 'qty', 'visibility', 'status');
    }
    
    public function getGridAttributes()
    {
        // will load columns by admin users, if necessary
        $extraKey = '';
        if (Mage::getStoreConfig('catalogmanagement/attr/byadmin'))
        {
            $extraKey = Mage::getSingleton('admin/session')->getUser()->getId();
        }
        $selected = (string) Mage::getStoreConfig('catalogmanagement/attributes/ongrid' . $extraKey);
        if ($selected)
        {
            return explode(',', $selected);
        }
        return array();
    }
    
    public function prepareGridAttributesCollection()
    {
        $attributes = Mage::getResourceModel('catalog/product_attribute_collection')
                         ->addVisibleFilter()
                         ->addStoreLabel($this->getStore()->getId());
        $attributes->getSelect()->where(
            $attributes->getConnection()->quoteInto('main_table.attribute_id IN (?)', Mage::helper('catalogmanagement')->getGridAttributes())
        );
        return $attributes;
    }
    
    public function getStore()
    {
        $storeId = (int) Mage::app()->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
    }
    
    public function getGridThumbSize()
    {
        return 70;
    }
    
    public function getAllowedQtyMath()
    {
        return 'true';
    }
}