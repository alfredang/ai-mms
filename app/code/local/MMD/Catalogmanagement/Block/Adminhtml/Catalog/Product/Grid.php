<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Block_Adminhtml_Catalog_Product_Grid extends Mage_Adminhtml_Block_Catalog_Product_Grid
{
    protected $_gridAttributes = array();
    
    protected function _prepareLayout()
    {
        parent::_prepareLayout();
        $this->setExportVisibility('true');
        $this->setChild('attributes_button',
            $this->getLayout()->createBlock('adminhtml/widget_button')
                ->setData(array(
                    'label'     => Mage::helper('catalogmanagement')->__('Grid Attribute Columns'),
                    'onclick'   => 'pAttribute.showConfig();',
                    'class'     => 'task'
                ))
        );

        if (Mage::getStoreConfig('catalogmanagement/general/sorting'))
        {
            $this->setChild('sortcolumns_button',
                $this->getLayout()->createBlock('adminhtml/widget_button')
                    ->setData(array(
                    'label'     => Mage::helper('catalogmanagement')->__('Sort Columns'),
                    'onclick'   => 'pgridSortable.init();',
                    'class'     => 'task',
                    'id'        => 'pgridSortable_button',
                ))
            );
        }
        
        if (Mage::helper('catalogmanagement/mode')->isMulti())
        {
            $this->setChild('saveall_button',
            $this->getLayout()->createBlock('adminhtml/widget_button')
                ->setData(array(
                    'label'     => Mage::helper('catalogmanagement')->__('Save'),
                    'onclick'   => 'peditGrid.saveAll();',
                    'class'     => 'save disabled',
                    'id'        => 'catalogmanagement_saveall_button'
                ))
        );
        }
        
        $this->_gridAttributes = Mage::helper('catalogmanagement')->prepareGridAttributesCollection();
        
        return $this;
    }
    
    protected function _prepareCollection()
    {
        // vvvv ORIGINAL CODE BEGIN
        $store = $this->_getStore();
        $collection = Mage::getModel('catalog/product')->getCollection()
            ->addAttributeToSelect('sku')
            ->addAttributeToSelect('name')
            ->addAttributeToSelect('attribute_set_id')
            ->addAttributeToSelect('type_id')
            ->joinField('qty',
                'cataloginventory/stock_item',
                'qty',
                'product_id=entity_id',
                '{{table}}.stock_id=1',
                'left');
        if (Mage::getStoreConfig('catalogmanagement/additional/avail'))
        {
            $collection->joinField('is_in_stock',
                'cataloginventory/stock_item',
                'is_in_stock',
                'product_id=entity_id',
                '{{table}}.stock_id=1',
                'left');
        }

        if ($store->getId()) {
            //$collection->setStoreId($store->getId());
            $adminStore = Mage_Core_Model_App::ADMIN_STORE_ID;
            $collection->addStoreFilter($store);
            $collection->joinAttribute('name', 'catalog_product/name', 'entity_id', null, 'inner', $adminStore);
            $collection->joinAttribute('custom_name', 'catalog_product/name', 'entity_id', null, 'inner', $store->getId());
            $collection->joinAttribute('status', 'catalog_product/status', 'entity_id', null, 'inner', $store->getId());
            $collection->joinAttribute('visibility', 'catalog_product/visibility', 'entity_id', null, 'inner', $store->getId());
            $collection->joinAttribute('price', 'catalog_product/price', 'entity_id', null, 'left', $store->getId());
        }
        else {
            $collection->addAttributeToSelect('price');
            $collection->joinAttribute('status', 'catalog_product/status', 'entity_id', null, 'inner');
            $collection->joinAttribute('visibility', 'catalog_product/visibility', 'entity_id', null, 'inner');
        }
        // ^^^^ ORIGINAL CODE END


        /**
        * Adding special price if set in configuration        
        */
        if (Mage::getStoreConfig('catalogmanagement/additional/special_price_dates'))
        {
            $collection->joinAttribute('special_from_date', 'catalog_product/special_from_date', 'entity_id', null, 'left', $store->getId());
            $collection->joinAttribute('special_to_date', 'catalog_product/special_to_date', 'entity_id', null, 'left', $store->getId());
        }
        
        /**
        * Adding code to the grid
        */
        
        if (Mage::getStoreConfig('catalogmanagement/additional/thumb'))
        {
            $collection->joinAttribute('thumbnail', 'catalog_product/thumbnail', 'entity_id', null, 'left', $store->getId());
        }
        
        /**
        * Adding attributes
        */
        if ($this->_gridAttributes->getSize() > 0)
        {
            foreach ($this->_gridAttributes as $attribute)
            {
                $collection->joinAttribute($attribute->getAttributeCode(), 'catalog_product/' . $attribute->getAttributeCode(), 'entity_id', null, 'left', $store->getId());
            }
        }
        
        Mage::register('product_collection', $collection);
        
        // vvvv ORIGINAL CODE BEGIN
        $this->setCollection($collection);

        Mage_Adminhtml_Block_Widget_Grid::_prepareCollection(); // THIS IS ONLY MODIFIED
        $this->getCollection()->addWebsiteNamesToResult();
        return $this;
        // ^^^^ ORIGINAL CODE END
    }
    
    protected function _prepareColumns()
    {
        $this->addExportType('catalogmanagement/adminhtml_product/exportCsv', Mage::helper('customer')->__('CSV'));
        $this->addExportType('catalogmanagement/adminhtml_product/exportExcel', Mage::helper('customer')->__('Excel XML'));
        if (Mage::getStoreConfig('catalogmanagement/additional/thumb'))
        {
            // will add thumbnail column to be the first one
            $this->addColumn('thumb',
                array(
                    'header'    => Mage::helper('catalog')->__('Thumbnail'),
                    'renderer'  => 'catalogmanagement/adminhtml_catalog_product_grid_renderer_thumb',
                    'index'		=> 'thumbnail',
                    'sortable'  => true,
                    'filter'    => false,
                    'width'     => 90,
            ));
        }
        
        if (Mage::getStoreConfig('catalogmanagement/additional/category'))
        {
            $categoryFilter  = false;
            $categoryOptions = array();
            if (Mage::getStoreConfig('catalogmanagement/additional/category_filter'))
            {
                $categoryFilter = 'catalogmanagement/adminhtml_catalog_product_grid_filter_category';
                $categoryOptions = Mage::helper('catalogmanagement/category')->getOptionsForFilter();
            }
            
            // adding categories column
            $this->addColumn('categories',
                array(
                    'header'    => Mage::helper('catalog')->__('Categories'),
                    'index'     => 'category_id',
                    'renderer'  => 'catalogmanagement/adminhtml_catalog_product_grid_renderer_category',
                    'sortable'  => false,
                    'filter'    => $categoryFilter,
                    'type'      => 'options',
                    'options'   => $categoryOptions,
            ));
        }
                
        parent::_prepareColumns();
        
        $actionsColumn = null;
        if (isset($this->_columns['action']))
        {
            $actionsColumn = $this->_columns['action'];
            unset($this->_columns['action']);
        }
        // from version 2.4.1
        $colsToRemove = Mage::getStoreConfig('catalogmanagement/additional/remove');
        if ($colsToRemove)
        {
            $colsToRemove = explode(',', $colsToRemove);
            foreach ($colsToRemove as $c)
            {
                $c = trim($c);
                if (isset($this->_columns[$c]))
                {
                    unset($this->_columns[$c]);
                }                
            }
        }
        
        if (Mage::helper('catalog')->isModuleEnabled('Mage_CatalogInventory') && Mage::getStoreConfig('catalogmanagement/additional/avail')) 
        {
            $this->addColumn('is_in_stock',
                array(
                    'header'  => Mage::helper('catalog')->__('Availability'),
                    'type'    => 'options',
                	'options' => array(0 => $this->__('Out of stock'), 1 => $this->__('In stock')),
                    'index'   => 'is_in_stock',
            ));
        }

        if (Mage::getStoreConfig('catalogmanagement/additional/created_at'))
        {
            $this->addColumn('created_at', array(
                'header'        => $this->__('Creation Date'),
                'index'         => 'created_at',
                'type'          => 'date',
            ));
        }

        if (Mage::getStoreConfig('catalogmanagement/additional/modified_at'))
        {
            $this->addColumn('updated_at', array(
                'header'        => $this->__('Last Modified Date'),
                'index'         => 'updated_at',
                'type'          => 'date',
            ));
        }
        
        // adding special price columns
        if (Mage::getStoreConfig('catalogmanagement/additional/special_price_dates'))
        {
            $this->addColumn('special_from_date', array(
                'header'        => $this->__('Special Price From'),
                'index'         => 'special_from_date',
                'type'          => 'date',
            ));
            $this->addColumn('special_to_date', array(
                'header'        => $this->__('Special Price To'),
                'index'         => 'special_to_date',
                'type'          => 'date',
            ));
        }
        
        // adding cost column
        
        if ($this->_gridAttributes->getSize() > 0)
        {
            Mage::register('catalogmanagement_grid_attributes', $this->_gridAttributes);
            foreach ($this->_gridAttributes as $attribute)
            {
                $props = array(
                    'header'=> $attribute->getStoreLabel(),
                    'index' => $attribute->getAttributeCode(),
                );
                if ('price' == $attribute->getFrontendInput())
                {
                    $props['type']          = 'price';
                    $props['currency_code'] = $this->_getStore()->getBaseCurrency()->getCode();
                }
                if ('select' == $attribute->getFrontendInput() || 'multiselect' == $attribute->getFrontendInput() || 'boolean' == $attribute->getFrontendInput())
                {
                    $propOptions = array();
                    
                    if ('multiselect' == $attribute->getFrontendInput())
                    {
                        $propOptions['null'] = $this->__('- No value specified -');
                    }
                    
                    if ('custom_design' == $attribute->getAttributeCode())
                    {
                        $allOptions = $attribute->getSource()->getAllOptions();
                        if (is_array($allOptions) && !empty($allOptions))
                        {
                            foreach ($allOptions as $option)
                            {
                                if (!is_array($option['value']))
                                {
                                    if ($option['value'])
                                    {
                                        $propOptions[$option['value']] = $option['value'];
                                    }
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
                            ->setStoreFilter($this->_getStore()->getId(), false)
                            ->load();
                        if ($valuesCollection->getSize() > 0)
                        {
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
                    
                    if ('multiselect' == $attribute->getFrontendInput())
                    {
                        $props['renderer'] = 'catalogmanagement/adminhtml_catalog_product_grid_renderer_multiselect';
                        $props['filter']   = 'catalogmanagement/adminhtml_catalog_product_grid_filter_multiselect';
                    }
                    
                    $props['type'] = 'options';
                    $props['options'] = $propOptions;
                }
                
                $this->addColumn($attribute->getAttributeCode(), $props);
            }
        }
        
        if ($actionsColumn)
        {
            $this->_columns['action'] = $actionsColumn;
        }

        $this->sortColumnsByDragPosition();
    }

    public function sortColumnsByDragPosition()
    {
        if (!Mage::getStoreConfig('catalogmanagement/general/sorting'))
        {
            return $this;
        }
        $keys = array_keys($this->_columns);
        $values = array_values($this->_columns);

        $extraKey = '';
        if (Mage::getStoreConfig('catalogmanagement/attr/byadmin'))
        {
            $extraKey = Mage::getSingleton('admin/session')->getUser()->getId();
        }
        $orderedFields = (string) Mage::getStoreConfig('catalogmanagement/attributes/sorting' . $extraKey);
        if ($orderedFields)
        {
            $orderedFields = explode(',', $orderedFields);
        } else
        {
            return $this;
        }

        for ($i = 0; $i < count($orderedFields) - 1; $i++)
        {
            $columnsOrder[$orderedFields[$i + 1]] = $orderedFields[$i];
        }

        foreach ($columnsOrder as $columnId => $after) {
            if (array_search($after, $keys) !== false) {
                // Moving grid column
                $positionCurrent = array_search($columnId, $keys);

                $key = array_splice($keys, $positionCurrent, 1);
                $value = array_splice($values, $positionCurrent, 1);

                $positionTarget = array_search($after, $keys) + 1;

                array_splice($keys, $positionTarget, 0, $key);
                array_splice($values, $positionTarget, 0, $value);

                $this->_columns = array_combine($keys, $values);
            }
        }

        end($this->_columns);
        $this->_lastColumnId = key($this->_columns);
        return $this;
    }
    
    public function getAttributesButtonHtml()
    {
        return $this->getChildHtml('attributes_button');
    }

    public function getSortColumnsButtonHtml()
    {
        return $this->getChildHtml('sortcolumns_button');
    }
    
    public function getSaveAllButtonHtml()
    {
        return $this->getChildHtml('saveall_button');
    }
       
    public function getMainButtonsHtml()
    {
        $html = parent::getMainButtonsHtml();
        $html = $this->getSaveAllButtonHtml() . $this->getSortColumnsButtonHtml() . $this->getAttributesButtonHtml() . $html;
        return $html;
    }
    
   protected function _prepareMassaction()
   {
        parent::_prepareMassaction();
        Mage::dispatchEvent('mmd_product_grid_massaction', array('grid' => $this)); 
   }    
}