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

class MMD_CustomOptions_Model_Importexport_Export_Entity_Product extends Mage_ImportExport_Model_Export_Entity_Product
{
    
    public function export() {
        /** @var $collection Mage_Catalog_Model_Resource_Eav_Mysql4_Product_Collection */
        $validAttrCodes  = $this->_getExportAttrCodes();
        $writer          = $this->getWriter();
        $resource        = Mage::getSingleton('core/resource');
        $dataRows        = array();
        $rowCategories   = array();
        $rowWebsites     = array();
        $rowTierPrices   = array();
        $stockItemRows   = array();
        $linksRows       = array();
        $gfAmountFields  = array();
        $defaultStoreId  = Mage_Catalog_Model_Abstract::DEFAULT_STORE_ID;
        $collection = $this->_prepareEntityCollection(Mage::getResourceModel('catalog/product_collection'));

        // prepare multi-store values and system columns values
        foreach ($this->_storeIdToCode as $storeId => &$storeCode) { // go through all stores
            $collection->setStoreId($storeId)
                ->load();

            if ($defaultStoreId == $storeId) {
                $collection->addCategoryIds()->addWebsiteNamesToResult();

                // tier price data getting only once
                $rowTierPrices = $this->_prepareTierPrices($collection->getAllIds());
            }
            foreach ($collection as $itemId => $item) { // go through all products
                $rowIsEmpty = true; // row is empty by default

                foreach ($validAttrCodes as &$attrCode) { // go through all valid attribute codes
                    $attrValue = $item->getData($attrCode);

                    if (!empty($this->_attributeValues[$attrCode])) {
                        if (isset($this->_attributeValues[$attrCode][$attrValue])) {
                            $attrValue = $this->_attributeValues[$attrCode][$attrValue];
                        } else {
                            $attrValue = null;
                        }
                    }
                    // do not save value same as default or not existent
                    if ($storeId != $defaultStoreId
                        && isset($dataRows[$itemId][$defaultStoreId][$attrCode])
                        && $dataRows[$itemId][$defaultStoreId][$attrCode] == $attrValue
                    ) {
                        $attrValue = null;
                    }
                    if (is_scalar($attrValue)) {
                        $dataRows[$itemId][$storeId][$attrCode] = $attrValue;
                        $rowIsEmpty = false; // mark row as not empty
                    }
                }
                if ($rowIsEmpty) { // remove empty rows
                    unset($dataRows[$itemId][$storeId]);
                } else {
                    $attrSetId = $item->getAttributeSetId();
                    $dataRows[$itemId][$storeId][self::COL_STORE]    = $storeCode;
                    $dataRows[$itemId][$storeId][self::COL_ATTR_SET] = $this->_attrSetIdToName[$attrSetId];
                    $dataRows[$itemId][$storeId][self::COL_TYPE]     = $item->getTypeId();

                    if ($defaultStoreId == $storeId) {
                        $rowWebsites[$itemId]   = $item->getWebsites();
                        $rowCategories[$itemId] = $item->getCategoryIds();
                    }
                }
                $item = null;
            }
            $collection->clear();
        }

        // remove root categories
        foreach ($rowCategories as $productId => &$categories) {
            $categories = array_intersect($categories, array_keys($this->_categories));
        }

        // prepare catalog inventory information
        $productIds = array_keys($dataRows);
        $stockItemRows = $this->_prepareCatalogInventory($productIds);

        // prepare links information
        $this->_prepareLinks($productIds);
        $linkIdColPrefix = array(
            Mage_Catalog_Model_Product_Link::LINK_TYPE_RELATED   => '_links_related_',
            Mage_Catalog_Model_Product_Link::LINK_TYPE_UPSELL    => '_links_upsell_',
            Mage_Catalog_Model_Product_Link::LINK_TYPE_CROSSSELL => '_links_crosssell_',
            Mage_Catalog_Model_Product_Link::LINK_TYPE_GROUPED   => '_associated_'
        );

        // prepare configurable products data
        $configurableData  = $this->_prepareConfigurableProductData($productIds);
        $configurablePrice = array();
        if ($configurableData) {
            $configurablePrice = $this->_prepareConfigurableProductPrice($productIds);
            foreach ($configurableData as $productId => &$rows) {
                if (isset($configurablePrice[$productId])) {
                    $largest = max(count($rows), count($configurablePrice[$productId]));

                    for ($i = 0; $i < $largest; $i++) {
                        if (!isset($configurableData[$productId][$i])) {
                            $configurableData[$productId][$i] = array();
                        }
                        if (isset($configurablePrice[$productId][$i])) {
                            $configurableData[$productId][$i] = array_merge(
                                $configurableData[$productId][$i],
                                $configurablePrice[$productId][$i]
                            );
                        }
                    }
                }
            }
            unset($configurablePrice);
        }

        // prepare custom options information
        $customOptionsData    = array();
        $customOptionsDataPre = array();
        $customOptCols        = array(
            '_custom_option_store', '_custom_option_type', '_custom_option_title', '_custom_option_is_required',
            '_custom_option_price', '_custom_option_sku', '_custom_option_max_characters',
            '_custom_option_sort_order',
            
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

        foreach ($this->_storeIdToCode as $storeId => &$storeCode) {
            $options = Mage::getResourceModel('catalog/product_option_collection')
                ->reset()
                ->addTitleToResult($storeId)
                ->addPriceToResult($storeId)
                ->addProductToFilter($productIds)
                ->addValuesToResult($storeId);

            foreach ($options as $option) {
                $row = array();
                $productId = $option['product_id'];
                $optionId  = $option['option_id'];
                $customOptions = isset($customOptionsDataPre[$productId][$optionId])
                               ? $customOptionsDataPre[$productId][$optionId]
                               : array();

                if ($defaultStoreId == $storeId) {
                    $row['_custom_option_type']           = $option['type'];
                    $row['_custom_option_title']          = $option['title'];
                    $row['_custom_option_is_required']    = $option['is_require'];
                    $row['_custom_option_price'] = $option['price'] . ($option['price_type'] == 'percent' ? '%' : '');
                    $row['_custom_option_sku']            = $option['sku'];
                    $row['_custom_option_max_characters'] = $option['max_characters'];
                    $row['_custom_option_sort_order']     = $option['sort_order'];
                                        
                    // APO additions block
                    $row['_custom_option_customoptions_is_onetime']     = $option['customoptions_is_onetime'];
                    $row['_custom_option_image_path']     = $option['image_path'];
                    $row['_custom_option_customer_groups'] = $option['customer_groups'];
                    $row['_custom_option_qnty_input']     = $option['qnty_input'];
                    $row['_custom_option_view_mode']     = $option['view_mode'];
                    $row['_custom_option_in_group_id']    = $option['in_group_id'];
                    $row['_custom_option_is_dependent']   = $option['is_dependent'];
                    $row['_custom_option_div_class']   = $option['div_class'];
                    $row['_custom_option_image_mode']   = $option['image_mode'];
                    $row['_custom_option_exclude_first_image']   = $option['exclude_first_image'];

                    // remember default title for later comparisons
                    $defaultTitles[$option['option_id']] = $option['title'];
                } elseif ($option['title'] != $customOptions[0]['_custom_option_title']) {
                    $row['_custom_option_title'] = $option['title'];
                } elseif ($option['price'] . ($option['price_type'] == 'percent' ? '%' : '') != $customOptions[0]['_custom_option_price']) {
                    $row['_custom_option_price'] = $option['price'] . ($option['price_type'] == 'percent' ? '%' : '');
                }
                if ($values = $option->getValues()) {
                    $firstValue = array_shift($values);
                    $priceType  = $firstValue['price_type'] == 'percent' ? '%' : '';

                    if ($defaultStoreId == $storeId) {
                        $row['_custom_option_row_title'] = $firstValue['title'];
                        $row['_custom_option_row_price'] = $firstValue['price'] . $priceType;
                        $row['_custom_option_row_sku']   = $firstValue['sku'];
                        $row['_custom_option_row_sort']  = $firstValue['sort_order'];
                        
                        // APO additions block
                        $row['_custom_option_row_customoptions_qty']  = $firstValue['customoptions_qty'];
                        $row['_custom_option_row_image_path']  = $firstValue['image_path'];
                        $row['_custom_option_row_default']  = $firstValue['default'];
                        $row['_custom_option_row_in_group_id']  = $firstValue['in_group_id'];
                        $row['_custom_option_row_dependent_ids']  = $firstValue['dependent_ids'];
                        $row['_custom_option_row_weight']  = $firstValue['weight'];
                        
                        $defaultValueTitles[$firstValue['option_type_id']] = $firstValue['title'];
                    } elseif ($firstValue['title'] != $customOptions[0]['_custom_option_row_title']) {
                        $row['_custom_option_row_title'] = $firstValue['title'];
                    } elseif ($firstValue['price'] . $priceType != $customOptions[0]['_custom_option_row_price']) {
                        $row['_custom_option_row_price'] = $firstValue['price'] . $priceType;
                    }
                }
                if ($row) {
                    if ($defaultStoreId != $storeId) {
                        $row['_custom_option_store'] = $this->_storeIdToCode[$storeId];
                    }
                    $customOptionsDataPre[$productId][$optionId][] = $row;
                }
                foreach ($values as $value) {
                    $row = array();
                    $valuePriceType = $value['price_type'] == 'percent' ? '%' : '';

                    if ($defaultStoreId == $storeId) {
                        $row['_custom_option_row_title'] = $value['title'];
                        $row['_custom_option_row_price'] = $value['price'] . $valuePriceType;
                        $row['_custom_option_row_sku']   = $value['sku'];
                        $row['_custom_option_row_sort']  = $value['sort_order'];
                                                
                        // APO additions block
                        $row['_custom_option_row_customoptions_qty']  = $value['customoptions_qty'];
                        $row['_custom_option_row_image_path']  = $value['image_path'];
                        $row['_custom_option_row_default']  = $value['default'];
                        $row['_custom_option_row_in_group_id']  = $value['in_group_id'];
                        $row['_custom_option_row_dependent_ids']  = $value['dependent_ids'];
                        $row['_custom_option_row_weight']  = $value['weight'];
                        
                    } elseif ($value['title'] != $customOptions[0]['_custom_option_row_title']) {
                        $row['_custom_option_row_title'] = $value['title'];                        
                    } elseif ($value['price'] . $valuePriceType != $customOptions[0]['_custom_option_row_price']) {
                        $row['_custom_option_row_price'] = $value['price'] . $valuePriceType;
                    }
                    if ($row) {
                        if ($defaultStoreId != $storeId) {
                            $row['_custom_option_store'] = $this->_storeIdToCode[$storeId];
                        }
                        $customOptionsDataPre[$option['product_id']][$option['option_id']][] = $row;
                    }
                }
                $option = null;
            }
            $options = null;
        }
        foreach ($customOptionsDataPre as $productId => &$optionsData) {
            $customOptionsData[$productId] = array();

            foreach ($optionsData as $optionId => &$optionRows) {
                $customOptionsData[$productId] = array_merge($customOptionsData[$productId], $optionRows);
            }
            unset($optionRows, $optionsData);
        }
        unset($customOptionsDataPre);

        // create export file
        $headerCols = array_merge(
            array(
                self::COL_SKU, self::COL_STORE, self::COL_ATTR_SET,
                self::COL_TYPE, self::COL_CATEGORY, '_product_websites'
            ),
            $validAttrCodes,
            reset($stockItemRows) ? array_keys(end($stockItemRows)) : array(),
            $gfAmountFields,
            array(
                '_links_related_sku', '_links_related_position', '_links_crosssell_sku',
                '_links_crosssell_position', '_links_upsell_sku', '_links_upsell_position',
                '_associated_sku', '_associated_default_qty', '_associated_position'
            ),
            array('_tier_price_website', '_tier_price_customer_group', '_tier_price_qty', '_tier_price_price')
        );

        // have we merge custom options columns
        if ($customOptionsData) {
            $headerCols = array_merge($headerCols, $customOptCols);
        }

        // have we merge configurable products data
        if ($configurableData) {
            $headerCols = array_merge($headerCols, array(
                '_super_products_sku', '_super_attribute_code',
                '_super_attribute_option', '_super_attribute_price_corr'
            ));
        }

        $writer->setHeaderCols($headerCols);

        foreach ($dataRows as $productId => &$productData) {
            foreach ($productData as $storeId => &$dataRow) {
                if ($defaultStoreId != $storeId) {
                    $dataRow[self::COL_SKU]      = null;
                    $dataRow[self::COL_ATTR_SET] = null;
                    $dataRow[self::COL_TYPE]     = null;
                } else {
                    $dataRow[self::COL_STORE] = null;
                    if (isset($stockItemRows[$productId]) && is_array($stockItemRows[$productId])) $dataRow += $stockItemRows[$productId];
                }
                if ($rowCategories[$productId]) {
                    $dataRow[self::COL_CATEGORY] = $this->_categories[array_shift($rowCategories[$productId])];
                }
                if ($rowWebsites[$productId]) {
                    $dataRow['_product_websites'] = $this->_websiteIdToCode[array_shift($rowWebsites[$productId])];
                }
                if (!empty($rowTierPrices[$productId])) {
                    $dataRow = array_merge($dataRow, array_shift($rowTierPrices[$productId]));
                }
                foreach ($linkIdColPrefix as $linkId => &$colPrefix) {
                    if (!empty($linksRows[$productId][$linkId])) {
                        $linkData = array_shift($linksRows[$productId][$linkId]);
                        $dataRow[$colPrefix . 'position'] = $linkData['position'];
                        $dataRow[$colPrefix . 'sku'] = $linkData['sku'];

                        if (null !== $linkData['default_qty']) {
                            $dataRow[$colPrefix . 'default_qty'] = $linkData['default_qty'];
                        }
                    }
                }
                if (!empty($customOptionsData[$productId])) {
                    $dataRow = array_merge($dataRow, array_shift($customOptionsData[$productId]));
                }
                if (!empty($configurableData[$productId])) {
                    $dataRow = array_merge($dataRow, array_shift($configurableData[$productId]));
                }

                $writer->writeRow($dataRow);
            }
            // calculate largest links block
            $largestLinks = 0;

            if (isset($linksRows[$productId])) {
                foreach ($linksRows[$productId] as &$linkData) {
                    $largestLinks = max($largestLinks, count($linkData));
                }
            }
            $additionalRowsCount = max(
                count($rowCategories[$productId]),
                count($rowWebsites[$productId]),
                $largestLinks
            );
            if (!empty($rowTierPrices[$productId])) {
                $additionalRowsCount = max($additionalRowsCount, count($rowTierPrices[$productId]));
            }
            if (!empty($customOptionsData[$productId])) {
                $additionalRowsCount = max($additionalRowsCount, count($customOptionsData[$productId]));
            }
            if (!empty($configurableData[$productId])) {
                $additionalRowsCount = max($additionalRowsCount, count($configurableData[$productId]));
            }

            if ($additionalRowsCount) {
                for ($i = 0; $i < $additionalRowsCount; $i++) {
                    $dataRow = array();

                    if ($rowCategories[$productId]) {
                        $dataRow[self::COL_CATEGORY] = $this->_categories[array_shift($rowCategories[$productId])];
                    }
                    if ($rowWebsites[$productId]) {
                        $dataRow['_product_websites'] = $this->_websiteIdToCode[array_shift($rowWebsites[$productId])];
                    }
                    if (!empty($rowTierPrices[$productId])) {
                        $dataRow = array_merge($dataRow, array_shift($rowTierPrices[$productId]));
                    }
                    foreach ($linkIdColPrefix as $linkId => &$colPrefix) {
                        if (!empty($linksRows[$productId][$linkId])) {
                            $linkData = array_shift($linksRows[$productId][$linkId]);
                            $dataRow[$colPrefix . 'position'] = $linkData['position'];
                            $dataRow[$colPrefix . 'sku'] = $linkData['sku'];

                            if (null !== $linkData['default_qty']) {
                                $dataRow[$colPrefix . 'default_qty'] = $linkData['default_qty'];
                            }
                        }
                    }
                    if (!empty($customOptionsData[$productId])) {
                        $dataRow = array_merge($dataRow, array_shift($customOptionsData[$productId]));
                    }
                    if (!empty($configurableData[$productId])) {
                        $dataRow = array_merge($dataRow, array_shift($configurableData[$productId]));
                    }
                    $writer->writeRow($dataRow);
                }
            }
        }
        return $writer->getContents();
    }    
}
