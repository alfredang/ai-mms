<?php
/**
 * Magento
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/osl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magento.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade Magento to newer
 * versions in the future. If you wish to customize Magento for your
 * needs please refer to http://www.magento.com for more information.
 *
 * @category    Mage
 * @package     Mage
 * @copyright  Copyright (c) 2006-2020 Magento, Inc. (http://www.magento.com)
 * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */

if (version_compare(phpversion(), '7.4.0', '<')===true) {
    echo  '<div style="font:12px/1.35em arial, helvetica, sans-serif;">
<div style="margin:0 0 25px 0; border-bottom:1px solid #ccc;">
<h3 style="margin:0; font-size:1.7em; font-weight:normal; text-transform:none; text-align:left; color:#2f2f2f;">
Whoops, it looks like you have an invalid PHP version.</h3></div><p>Magento supports PHP 5.3.0 or newer.
<a href="http://www.magentocommerce.com/install" target="">Find out</a> how to install</a>
 Magento using PHP-CGI as a work-around.</p></div>';
    exit;
}

/**
 * Compilation includes configuration file
 */
define('MAGENTO_ROOT', getcwd());

$compilerConfig = MAGENTO_ROOT . '/includes/config.php';
if (file_exists($compilerConfig)) {
    include $compilerConfig;
}

$mageFilename = MAGENTO_ROOT . '/app/Mage.php';
$maintenanceFile = 'maintenance.flag';

if (!file_exists($mageFilename)) {
    if (is_dir('downloader')) {
        header("Location: downloader");
    } else {
        echo $mageFilename." was not found";
    }
    exit;
}

if (file_exists($maintenanceFile)) {
    include_once dirname(__FILE__) . '/errors/503.php';
    exit;
}

require MAGENTO_ROOT . '/app/bootstrap.php';
require_once $mageFilename;

#Varien_Profiler::enable();

if (isset($_SERVER['MAGE_IS_DEVELOPER_MODE'])) {
    Mage::setIsDeveloperMode(true);
}

ini_set('display_errors', 1);

umask(0);

// Country instances (MMS_MODE=country) bypass domain-based routing — the
// correct website is forced directly from MMS_COUNTRY_CODE so the store
// is served correctly even when accessed via IP before DNS is set up.
if (getenv('MMS_MODE') === 'country') {
    $countryWebsiteMap = [
        'MY' => 'malaysia',
        'GH' => 'ghana',
        'NG' => 'nigeria',
        'BT' => 'bhutan',
        'IN' => 'india',
    ];
    $cc = strtoupper((string)getenv('MMS_COUNTRY_CODE'));
    $mageRunCode = $countryWebsiteMap[$cc] ?? 'base';
    $mageRunType = 'website';
} else {
    switch($_SERVER['HTTP_HOST']) {
        case 'tertiarycourses.com.sg':
        case 'www.tertiarycourses.com.sg':
            $mageRunCode = 'base';
            $mageRunType = 'website';
        break;
        case 'tertiarycourses.com.ng':
        case 'www.tertiarycourses.com.ng':
            $mageRunCode = 'nigeria';
            $mageRunType = 'website';
        break;
        default:
            $mageRunCode = 'base';
            $mageRunType = 'website';
        break;
    }
}

Mage::run($mageRunCode, $mageRunType);
