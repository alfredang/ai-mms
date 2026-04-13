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

class MMD_CustomOptions_Model_Importexport_Import_Entity_Product extends Mage_ImportExport_Model_Import_Entity_Product
{
    protected $_particularAttributes = array(
        '_store', '_attribute_set', '_type', '_category', '_product_websites', '_tier_price_website',
        '_tier_price_customer_group', '_tier_price_qty', '_tier_price_price', '_links_related_sku',
        '_links_related_position', '_links_crosssell_sku', '_links_crosssell_position', '_links_upsell_sku',
        '_links_upsell_position', '_custom_option_store', '_custom_option_type', '_custom_option_title',
        '_custom_option_is_required', '_custom_option_price', '_custom_option_sku', '_custom_option_max_characters',
        '_custom_option_sort_order', '_custom_option_file_extension', '_custom_option_image_size_x',
        '_custom_option_image_size_y',
        
        // APO additions block
        '_custom_option_customoptions_is_onetime', '_custom_option_image_path', '_custom_option_customer_groups', 
        '_custom_option_qnty_input', '_custom_option_view_mode', '_custom_option_in_group_id', '_custom_option_is_dependent', '_custom_option_div_class',
        '_custom_option_image_mode', '_custom_option_exclude_first_image',
        
        // Standart magento        
        '_custom_option_row_title', '_custom_option_row_price',
        '_custom_option_row_sku', '_custom_option_row_sort',
        
        // APO additions block
        '_custom_option_row_customoptions_qty', '_custom_option_row_image_path', '_custom_option_row_default', 
        '_custom_option_row_in_group_id', '_custom_option_row_dependent_ids', '_custom_option_row_weight'      
    );
    
    protected function _saveCustomOptions() {
        // to be less support :)
        $coreResource = Mage::getSingleton('core/resource');
        $write = $coreResource->getConnection('core_write');
        $write->query('set foreign_key_checks = 0');        
        
        $productTable   = $coreResource->getTableName('catalog/product');
        $optionTable    = $coreResource->getTableName('catalog/product_option');
        $priceTable     = $coreResource->getTableName('catalog/product_option_price');
        $titleTable     = $coreResource->getTableName('catalog/product_option_title');
        $typePriceTable = $coreResource->getTableName('catalog/product_option_type_price');
        $typeTitleTable = $coreResource->getTableName('catalog/product_option_type_title');
        $typeValueTable = $coreResource->getTableName('catalog/product_option_type_value');
                
        if (version_compare(Mage::getVersion(), '1.6.0', '>=')) {
            $nextOptionId   = Mage::getResourceHelper('importexport')->getNextAutoincrement($optionTable);
            $nextValueId    = Mage::getResourceHelper('importexport')->getNextAutoincrement($typeValueTable);
        } else {
            $nextOptionId   = $this->getNextAutoincrement($optionTable);
            $nextValueId    = $this->getNextAutoincrement($typeValueTable);        
        }        
        
        $lastProductId = 0;
        $priceIsGlobal  = Mage::helper('catalog')->isPriceGlobal();
        $type           = null;
        $typeSpecific   = array(
            'date'      => array('price', 'sku'),
            'date_time' => array('price', 'sku'),
            'time'      => array('price', 'sku'),
            'field'     => array('price', 'sku', 'max_characters'),
            'area'      => array('price', 'sku', 'max_characters'),
            //'file'      => array('price', 'sku', 'file_extension', 'image_size_x', 'image_size_y'),
            'drop_down' => true,
            'radio'     => true,
            'checkbox'  => true,
            'multiple'  => true,
            'swatch'  => true
        );

        while ($bunch = $this->_dataSourceModel->getNextBunch()) {
            $customOptions = array(
                'product_id'    => array(),
                $optionTable    => array(),
                $priceTable     => array(),
                $titleTable     => array(),
                $typePriceTable => array(),
                $typeTitleTable => array(),
                $typeValueTable => array()
            );

            foreach ($bunch as $rowNum => $rowData) {
                if (!$this->isRowAllowedToImport($rowData, $rowNum)) {
                    continue;
                }
                if (self::SCOPE_DEFAULT == $this->getRowScope($rowData)) {
                    $productId = $this->_newSku[$rowData[self::COL_SKU]]['entity_id'];
                } elseif (!isset($productId)) {
                    continue;
                }
                if (!empty($rowData['_custom_option_store'])) {
                    if (!isset($this->_storeCodeToId[$rowData['_custom_option_store']])) {
                        continue;
                    }
                    $storeId = $this->_storeCodeToId[$rowData['_custom_option_store']];
                } else {
                    $storeId = Mage_Catalog_Model_Abstract::DEFAULT_STORE_ID;
                }
                if (!empty($rowData['_custom_option_type'])) { // get CO type if its specified
                    if (!isset($typeSpecific[$rowData['_custom_option_type']])) {
                        $type = null;
                        continue;
                    }
                    $type = $rowData['_custom_option_type'];
                    $rowIsMain = true;
                } else {
                    if (null === $type) {
                        continue;
                    }
                    $rowIsMain = false;
                }
                if (!isset($customOptions['product_id'][$productId])) { // for update product entity table
                    $customOptions['product_id'][$productId] = array(
                        'entity_id'        => $productId,
                        'has_options'      => 0,
                        'required_options' => 0,
                        'updated_at'       => now()
                    );
                }
                if ($rowIsMain) {
                    $solidParams = array(
                        'option_id'      => $nextOptionId,
                        'sku'            => '',
                        'max_characters' => 0,
                        'file_extension' => null,
                        'image_size_x'   => 0,
                        'image_size_y'   => 0,
                        'product_id'     => $productId,
                        'type'           => $type,
                        'is_require'     => empty($rowData['_custom_option_is_required']) ? 0 : 1,
                        'sort_order'     => empty($rowData['_custom_option_sort_order'])
                                            ? 0 : abs($rowData['_custom_option_sort_order']),
                        
                        //APO additions block
                        'customoptions_is_onetime' => $rowData['_custom_option_customoptions_is_onetime'],
                        'image_path' => $rowData['_custom_option_image_path'],
                        'customer_groups' => $rowData['_custom_option_customer_groups'],
                        'qnty_input' => $rowData['_custom_option_qnty_input'],
                        'view_mode' => $rowData['_custom_option_view_mode'],
                        'in_group_id' => $rowData['_custom_option_in_group_id'],
                        'is_dependent' => $rowData['_custom_option_is_dependent'],
                        'div_class' => $rowData['_custom_option_div_class'],
                        'image_mode' => $rowData['_custom_option_image_mode'],
                        'exclude_first_image' => $rowData['_custom_option_exclude_first_image']
                    );

                    if (true !== $typeSpecific[$type]) { // simple option may have optional params
                        $priceTableRow = array(
                            'option_id'  => $nextOptionId,
                            'store_id'   => $storeId,
                            'price'      => 0,
                            'price_type' => 'fixed'
                        );

                        foreach ($typeSpecific[$type] as $paramSuffix) {
                            if (isset($rowData['_custom_option_' . $paramSuffix])) {
                                $data = $rowData['_custom_option_' . $paramSuffix];

                                if (array_key_exists($paramSuffix, $solidParams)) {
                                    $solidParams[$paramSuffix] = $data;
                                } elseif ('price' == $paramSuffix) {
                                    if ('%' == substr($data, -1)) {
                                        $priceTableRow['price_type'] = 'percent';
                                    }
                                    $priceTableRow['price'] = (float) rtrim($data, '%');
                                }
                            }
                        }
                        $customOptions[$priceTable][] = $priceTableRow;
                    }
                    $customOptions[$optionTable][] = $solidParams;
                    $customOptions['product_id'][$productId]['has_options'] = 1;

                    if (!empty($rowData['_custom_option_is_required'])) {
                        $customOptions['product_id'][$productId]['required_options'] = 1;
                    }
                    $prevOptionId = $nextOptionId++; // increment option id, but preserve value for $typeValueTable
                }
                if ($typeSpecific[$type] === true && !empty($rowData['_custom_option_row_title'])
                        && empty($rowData['_custom_option_store'])) {
                    // complex CO option row
                    $customOptions[$typeValueTable][$prevOptionId][] = array(
                        'option_type_id' => $nextValueId,
                        'sort_order'     => empty($rowData['_custom_option_row_sort'])
                                            ? 0 : abs($rowData['_custom_option_row_sort']),
                        'sku'            => !empty($rowData['_custom_option_row_sku'])
                                            ? $rowData['_custom_option_row_sku'] : '',
                        
                        
                        //APO additions block
                        'customoptions_qty'            => $rowData['_custom_option_row_customoptions_qty'],
                        'image_path'            => $rowData['_custom_option_row_image_path'],
                        'default'            => $rowData['_custom_option_row_default'],
                        'in_group_id'            => $rowData['_custom_option_row_in_group_id'],
                        'dependent_ids'            => $rowData['_custom_option_row_dependent_ids'],
                        'weight'            => $rowData['_custom_option_row_weight']
                        
                        
                    );
                    if (!isset($customOptions[$typeTitleTable][$nextValueId][0])) { // ensure default title is set
                        $customOptions[$typeTitleTable][$nextValueId][0] = $rowData['_custom_option_row_title'];
                    }
                    $customOptions[$typeTitleTable][$nextValueId][$storeId] = $rowData['_custom_option_row_title'];

                    if (!empty($rowData['_custom_option_row_price'])) {
                        $typePriceRow = array(
                            'price'      => (float) rtrim($rowData['_custom_option_row_price'], '%'),
                            'price_type' => 'fixed'
                        );
                        if ('%' == substr($rowData['_custom_option_row_price'], -1)) {
                            $typePriceRow['price_type'] = 'percent';
                        }
                        if ($priceIsGlobal) {
                            $customOptions[$typePriceTable][$nextValueId][0] = $typePriceRow;
                        } else {
                            // ensure default price is set
                            if (!isset($customOptions[$typePriceTable][$nextValueId][0])) {
                                $customOptions[$typePriceTable][$nextValueId][0] = $typePriceRow;
                            }
                            $customOptions[$typePriceTable][$nextValueId][$storeId] = $typePriceRow;
                        }
                    }
                    $nextValueId++;
                }
                if (!empty($rowData['_custom_option_title'])) {
                    if (!isset($customOptions[$titleTable][$prevOptionId][0])) { // ensure default title is set
                        $customOptions[$titleTable][$prevOptionId][0] = $rowData['_custom_option_title'];
                    }
                    $customOptions[$titleTable][$prevOptionId][$storeId] = $rowData['_custom_option_title'];
                }
            }
            if ($this->getBehavior() != Mage_ImportExport_Model_Import::BEHAVIOR_APPEND) { // remove old data?
                $productIds = array_keys($customOptions['product_id']);
                if (isset($productIds[0]) && $productIds[0]==$lastProductId) array_shift($productIds);
                if(!empty($productIds)) {
                    $this->_connection->delete(
                        $optionTable,
                        $this->_connection->quoteInto('product_id IN (?)', $productIds)
                    );
                    $lastProductId = array_pop($productIds);
                }
            }
            // if complex options does not contain values - ignore them
            foreach ($customOptions[$optionTable] as $key => $optionData) {
                if ($typeSpecific[$optionData['type']] === true
                        && !isset($customOptions[$typeValueTable][$optionData['option_id']])) {
                    unset($customOptions[$optionTable][$key], $customOptions[$titleTable][$optionData['option_id']]);
                }
            }
            if ($customOptions[$optionTable] || $customOptions[$typeValueTable]) {
                try {$this->_connection->insertMultiple($optionTable, $customOptions[$optionTable]);} catch(Exception $e) {Mage::log("Import error ".$e->getMessage());}
            } else {
                continue; // nothing to save
            }
            $titleRows = array();

            foreach ($customOptions[$titleTable] as $optionId => $storeInfo) {
                foreach ($storeInfo as $storeId => $title) {
                    $titleRows[] = array('option_id' => $optionId, 'store_id' => $storeId, 'title' => $title);
                }
            }
            if ($titleRows) {
                $this->_connection->insertOnDuplicate($titleTable, $titleRows, array('title'));
            }
            if ($customOptions[$priceTable]) {
                $this->_connection->insertOnDuplicate(
                    $priceTable,
                    $customOptions[$priceTable],
                    array('price', 'price_type')
                );
            }
            $typeValueRows = array();

            foreach ($customOptions[$typeValueTable] as $optionId => $optionInfo) {
                foreach ($optionInfo as $row) {
                    $row['option_id'] = $optionId;
                    $typeValueRows[]  = $row;
                }
            }
            if ($typeValueRows) {
                try {$this->_connection->insertMultiple($typeValueTable, $typeValueRows);} catch(Exception $e) {Mage::log("Import error ".$e->getMessage());}
            }
            $optionTypePriceRows = array();
            $optionTypeTitleRows = array();

            foreach ($customOptions[$typePriceTable] as $optionTypeId => $storesData) {
                foreach ($storesData as $storeId => $row) {
                    $row['option_type_id'] = $optionTypeId;
                    $row['store_id']       = $storeId;
                    $optionTypePriceRows[] = $row;
                }
            }
            foreach ($customOptions[$typeTitleTable] as $optionTypeId => $storesData) {
                foreach ($storesData as $storeId => $title) {
                    $optionTypeTitleRows[] = array(
                        'option_type_id' => $optionTypeId,
                        'store_id'       => $storeId,
                        'title'          => $title
                    );
                }
            }
            if ($optionTypePriceRows) {
                $this->_connection->insertOnDuplicate(
                    $typePriceTable,
                    $optionTypePriceRows,
                    array('price', 'price_type')
                );
            }
            if ($optionTypeTitleRows) {
                $this->_connection->insertOnDuplicate($typeTitleTable, $optionTypeTitleRows, array('title'));
            }
            if ($customOptions['product_id']) { // update product entity table to show that product has options
                $this->_connection->insertOnDuplicate(
                    $productTable,
                    $customOptions['product_id'],
                    array('has_options', 'required_options', 'updated_at')
                );
            }
        }
        return $this;
    }
    
    protected function _deleteProducts() {
        parent::_deleteProducts();
        // fix and clean up the debris of tables whith options
        $resource = Mage::getSingleton('core/resource');
        $this->_connection->query("
            DELETE t1 FROM `{$resource->getTableName('catalog_product_option')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_entity')}` WHERE `entity_id` = t1.`product_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('catalog_product_option_title')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('catalog_product_option_price')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('catalog_product_option_type_value')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('catalog_product_option_type_title')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option_type_value')}` WHERE `option_type_id` = t1.`option_type_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('catalog_product_option_type_price')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option_type_value')}` WHERE `option_type_id` = t1.`option_type_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('custom_options_relation')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('custom_options_option_view_mode')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('custom_options_option_description')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
            DELETE t1 FROM `{$resource->getTableName('custom_options_option_default')}` AS t1 WHERE (SELECT COUNT(*) FROM `{$resource->getTableName('catalog_product_option')}` WHERE `option_id` = t1.`option_id`) = 0;
        ");        
        return $this;
    }
    
    protected function _importData() {
        $result = parent::_importData();
        $resource = Mage::getSingleton('core/resource');
        $this->_connection->query("DELETE FROM `{$resource->getTableName('core_resource')}` WHERE `code` = 'customoptions_setup';");
        return $result;
    }
    
}