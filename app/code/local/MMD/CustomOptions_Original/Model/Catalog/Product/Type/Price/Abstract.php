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

if ((string)Mage::getConfig()->getModuleConfig('FME_Csvpricing')->active == 'true'){
    class MMD_CustomOptions_Model_Catalog_Product_Type_Price_Abstract extends FME_Csvpricing_Model_Product_Type_Price {                
        protected function _applyOptionsPriceFME($product, $qty, $finalPrice) {
            if ($optionIds = $product->getCustomOption('option_ids')) {

                $lengthlabel = Mage::getStoreConfig('csvpricing/general/rowlabel');
                $widthlabel = Mage::getStoreConfig('csvpricing/general/columnlabel');

                //$basePrice = $finalPrice;
                foreach (explode(',', $optionIds->getValue()) as $optionId) {
                    if ($option = $product->getOptionById($optionId)) {

                        $confItemOption = $product->getCustomOption('option_' . $option->getId());
//                        $group = $option->groupFactory($option->getType())
//                                ->setOption($option)
//                                ->setConfigurationItemOption($confItemOption);

                        //$finalPrice += $group->getOptionPrice($confItemOption->getValue(), $basePrice);


                        $resource = Mage::getSingleton('core/resource');
                        $writeConnection = $resource->getConnection('core_write');
                        $readConnection = $resource->getConnection('core_read');
                        $catalog_product_option_title = $resource->getTableName('catalog_product_option_title');

                        $k = $option->getId();
                        $query = "SELECT title FROM {$catalog_product_option_title} WHERE option_id='{$k}'";
                        $title = $readConnection->fetchOne($query);

                        if ($title == $lengthlabel) {
                            $fme_length = $confItemOption->getValue();
                        }

                        if ($title == $widthlabel) {
                            $fme_width = $confItemOption->getValue();
                        }
                    }
                }

                $params = Mage::app()->getRequest()->getParams();
                //echo "hello"; echo $product->getId(); 

                $prod_id = $product->getId();
                $csvPrice = 0;

                $csvpricing_status = Mage::getStoreConfig('csvpricing/general/csvpricing_status');
                if ($csvpricing_status) {

                    $csvfilename = Mage::Helper('csvpricing')->getCsvFilename($prod_id);

                    if ($csvfilename != '') {

                        //Find Length and Width option
//                foreach ($params['options'] as $k => $param)
//                {
//                    $title = '';
////                    echo $k."__".$param."<br/>";
//                    $query = "SELECT title FROM {$catalog_product_option_title} WHERE option_id='{$k}'";
//                    $title = $readConnection->fetchOne($query);
//                    
//                    if($title == 'Length')
//                    {
//                        $fme_length = $param;
//                    }
//                    
//                    if($title == 'Width')
//                    {
//                        $fme_width = $param;
//                    }
//                }
                        //echo "<br/>".$fme_length."___".$fme_width;

                        $csvpath = Mage::getBaseDir('media') . DS . "csvpricing" . DS . "csv" . DS . $csvfilename;
                        $fh = fopen($csvpath, 'r');


                        //+++++++++++++++++++++++++++++++++++++++++++++
                        if ($fh) {
                            $csvObject = new Varien_File_Csv();
                            $csvData = $csvObject->getData($csvpath);

                            fclose($fh);

                            $priceSheet = Array();

                            foreach ($csvData as $k => $row) {
                                $priceSheet[] = $row;
//                    if ($k == 0) {
//                        $hrow = $row;
//                    }
//
//                    foreach ($row as $l => $col) {
//
//
//                        if ($k > 0) {//print_r($col);
//                            if ($l == 0) {
//                                echo '"' . $col . '":{';
//                            }
//                            if ($l > 0) {
//                                if ($l == (int) (count($row) - 1))
//                                    echo '"' . $hrow[$l] . '":' . $col;
//                                else
//                                    echo '"' . $hrow[$l] . '":' . $col . ',';
//                            }
//                        }
//                    }
//                    if ($k > 0) {
//                        if ($k == (int) (count($csvData) - 1))
//                            echo '}';
//                        else
//                            echo '},';
//                    }
                            }

                            $rowMin = $priceSheet[1][0];
                            $rowMax = $priceSheet[count($priceSheet) - 1][0];
                            $colMin = $priceSheet[0][1];
                            $colMax = $priceSheet[0][count($priceSheet[0]) - 1];


                            $csvPrice = Mage::Helper('csvpricing')->getCsvPrice($priceSheet, $fme_length, $fme_width);
                        }// if file is open
                        //+++++++++++++++++++++++++++++++++++++++++++++
                    }
                    //exit;
                }//module enabled
            }
            //echo $finalPrice+$csvPrice;
            $finalPrice += $csvPrice;
            return $finalPrice;
        }
    }
} else {
    class MMD_CustomOptions_Model_Catalog_Product_Type_Price_Abstract extends Mage_Catalog_Model_Product_Type_Price {}
}