<?php

/**
 * OpenMage
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available at https://opensource.org/license/osl-3-0-php
 *
 * @category   Mage
 * @package    Mage_Adminhtml
 * @copyright  Copyright (c) 2006-2020 Magento, Inc. (https://www.magento.com)
 * @copyright  Copyright (c) 2021-2024 The OpenMage Contributors (https://www.openmage.org)
 * @license    https://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */

/**
 * Legacy Magento CE "merchant survey" admin notice. The upstream survey
 * service (surveys.magentocommerce.com) no longer exists, so this always
 * declines to show rather than link out to a dead service.
 *
 * @category   Mage
 * @package    Mage_Adminhtml
 */
class Mage_Adminhtml_Block_Notification_Survey extends Mage_Adminhtml_Block_Template
{
    /**
     * @return bool
     */
    public function canShow()
    {
        return false;
    }

    /**
     * @return string
     */
    public function getSurveyUrl()
    {
        return (string) Mage::getStoreConfig('general/promo/survey_url');
    }
}
