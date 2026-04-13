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
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdinstall_Helper_Data extends Mage_Core_Helper_Abstract
{
    /**
     * @var string
     */
    static protected $_classPath = '/app/code/%s/MMD/Mmdsys/Model/Mmdsys.php';
    
    /**
     * @var string
     */
    static protected $_licensesPath = '/app/code/local/MMD/Mmdsys/install/*.xml';

    /**
     * @var array
     */
    static protected $_pools = array('community', 'local');

    /**
     * Check whether both new and old installers are installed or only one of them
     * 
     * @return bool
     */
    public function isDoubleInstallerVersion()
    {
        foreach (self::$_pools as $pool) {
            if (!file_exists( BP . sprintf(self::$_classPath, $pool) )) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * Check whether old installer contains some licenses
     * 
     * @return bool
     */
    public function isThereAnyLicenses()
    {
        $licenses = glob(BP . self::$_licensesPath);
        return !empty($licenses);
    }
    
    /**
     * @return string
     */
    public function getInfoLink()
    {
        return 'http://www.mmd.com/media/guides/license_convertation_guide.pdf';
    }
    
    /**
     * @return string
     */
    public function getSupportLink()
    {
        return 'https://www.mmd.com/en/contacts.html?support';
    }
}