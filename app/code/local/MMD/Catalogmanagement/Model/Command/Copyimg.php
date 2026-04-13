<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Copyimg extends MMD_Catalogmanagement_Model_Command_Abstract 
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Copy Images';
        $this->_fieldLabel = 'From'; 
    }
    
    /**
     * Executes the command
     *
     * @param array $ids product ids
     * @param int $storeId store id
     * @param string $val field value
     * @return string success message if any
     */    
    public function execute($ids, $storeId, $val)
    {
        $success = parent::execute($ids, $storeId, $val);
        
        $hlp = Mage::helper('catalogmanagement');
        
        $fromId = intVal(trim($val));
        if (!$fromId) {
            throw new Exception($hlp->__('Please provide a valid product ID'));
        }
        
        if (in_array($fromId, $ids)) {
            throw new Exception($hlp->__('Please remove source product from the selected products'));
        }        
        
        $product = Mage::getModel('catalog/product')
            ->setStoreId($storeId)
            ->load($fromId); 
        if (!$product->getId()){
            throw new Exception($hlp->__('Please provide a valid product ID'));
        }
        
        // we do not use store id as it is a global action;
        $attribute = $product->getResource()->getAttribute('media_gallery');
        foreach ($ids as $id){
            $this->_copyData($attribute->getId(), $fromId, $id);
        }        
        
        $success = $hlp->__('Images and labels have been successfully copied.');
        
        return $success; 
    }
    
    protected function _copyImage($file)
    {
        try {
            $ioObject = new Varien_Io_File();
            $destDirectory = dirname($this->_getConfig()->getMediaPath($file));
            $ioObject->open(array('path'=>$destDirectory));

            $destFile = $this->_getUniqueFileName($file, $ioObject->dirsep());

            if (!$ioObject->fileExists($this->_getConfig()->getMediaPath($file), true)) {
                throw new Exception('File not exists');
            }

            if ($this->_checkDb()) {
                Mage::helper('core/file_storage_database')
                    ->copyFile($this->_getConfig()->getMediaShortUrl($file),
                               $this->_getConfig()->getMediaShortUrl($destFile));

                $ioObject->rm($this->_getConfig()->getMediaPath($destFile));
            } else {
                $ioObject->cp(
                    $this->_getConfig()->getMediaPath($file),
                    $this->_getConfig()->getMediaPath($destFile)
                );
            }

        } 
        catch (Exception $e) {
            $file = $this->_getConfig()->getMediaPath($file);
            Mage::throwException(
                Mage::helper('catalog')->__('Failed to copy file %s. Please, delete media with non-existing images and try again.', $file)
            );
            $e = $e; // for zend debugger
        }

        return str_replace($ioObject->dirsep(), '/', $destFile);
    }
    
    protected function _copyData($attrId, $originalProductId, $newProductId)
    {
        $db = Mage::getSingleton('core/resource')->getConnection('core_write'); 
        $table = Mage::getSingleton('core/resource')->getTableName('catalog/product_attribute_media_gallery');
        
        $select = $db->select()
            ->from($table, array('value_id', 'value'))
            ->where('attribute_id = ?', $attrId)
            ->where('entity_id = ?', $originalProductId);

        $valueIdMap = array();
        // Duplicate main entries of gallery
        foreach ($db->fetchAll($select) as $row) {
            $data = array(
                'attribute_id' => $attrId,
                'entity_id'    => $newProductId,
                'value'        => $this->_copyImage($row['value']),
            );

            $db->insert($table, $data);
            $valueIdMap[$row['value_id']] = $db->lastInsertId($table);
        }

        if (!$valueIdMap) {
            return false;
        }

        // Duplicate per store gallery values
        $tableLabels = Mage::getSingleton('core/resource')->getTableName('catalog/product_attribute_media_gallery_value');
        $select = $db->select()
            ->from($tableLabels)
            ->where('value_id IN(?)', array_keys($valueIdMap));

        foreach ($db->fetchAll($select) as $row) {
            $data = $row;
            $data['value_id'] = $valueIdMap[$row['value_id']];
            $db->insert($tableLabels, $data);
        }

        return true;
    }
    
    
    protected function _getConfig()
    {
        return Mage::getSingleton('catalog/product_media_config');
    }

    /**
     * Check whether file to move exists. Getting unique name
     *
     * @param <type> $file
     * @param <type> $dirsep
     * @return string
     */
    protected function _getUniqueFileName($file, $dirsep) 
    {
        if ($this->_checkDb()) {
            $destFile = Mage::helper('core/file_storage_database')
                ->getUniqueFilename(
                    Mage::getSingleton('catalog/product_media_config')->getBaseMediaUrlAddition(),
                    $file
                );
        } 
        else {
            $destFile = dirname($file) . $dirsep;
            if (version_compare(Mage::getVersion(), '1.5') > 0){
                $destFile .= Mage_Core_Model_File_Uploader::getNewFileName($this->_getConfig()->getMediaPath($file));
            }
            else {
                $destFile .= Varien_File_Uploader::getNewFileName($this->_getConfig()->getMediaPath($file));
            }
        }

        return $destFile;
    }
    
    protected function _checkDb()
    {
        $res = (version_compare(Mage::getVersion(), '1.5') > 0);
        if ($res){
            $res = Mage::helper('core/file_storage_database')->checkDbUsage();
        }
        return $res;
    }
    
}