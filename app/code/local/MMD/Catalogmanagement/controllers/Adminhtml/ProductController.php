<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2010-2012 MMD (http://www.mmd.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Adminhtml_ProductController extends Mage_Adminhtml_Controller_Action
{
    /**
     * Export order grid to CSV format
     */
    public function exportCsvAction()
    {
        $fileName   = 'products.csv';
        $grid       = $this->getLayout()->createBlock('adminhtml/catalog_product_grid');
        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
    }

    /**
     *  Export order grid to Excel XML format
     */
    public function exportExcelAction()
    {
        $fileName   = 'products.xml';
        $grid       = $this->getLayout()->createBlock('adminhtml/catalog_product_grid');
        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
    }
}