<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Helper_Strings extends MMD_Mmdsys_Helper_Data
{
    //install license notifications
    const INSTALL_MYSQL_TIMEOUT_NOTIFICATION = 'Due to the small value (%s) of "wmmd_timeout" parameter an automatic installation of the extensions can result in error. If after clicking "Proceed to install" you will get an error, you might try to increase the value of the parameter to a higher one in the MySQL configuration and then attempt to install the license once again. Or you may contact our support team asking them to configure the manual license for you instead. In case of contacting our support service make sure you have also indicated an URL to the administrative area.';
    const INSTALL_TEST_CONNECTION_FAILED = 'An established connection with the MMD server "%s" is required in order to proceed with the installation of the extension. Please check your firewall and server configurations in order to allow outbound SSL queries to the given server.';
    const INSTALL_TEST_SERVER_ERROR = 'MMD server "%s" is not available at the moment and the installation cannot be completed. Please try again in 10 minutes. Sorry for the inconvenience.';

    //errors
    const ER_ENT_HASH = 'The extension isn\'t compatible with this edition of Magento. Please contact us at sales@mmd.com for further instructions. Please note that our working hours are Mon-Fri, 8am - 5pm UTC.';

    private $_errorStringDelimiter = "|||";

    public function getString($const, $translate = true, $args = array())
    {
        if (!is_array($args)) {
            $args = array($args);
        }

        $string = constant('self::'.$const);
        $string = $translate ? $this->__($string) : $string;

        array_unshift($args, $string);

        return call_user_func_array('sprintf', $args);
    }

    public function parseErrorString($error)
    {
        return explode($this->_errorStringDelimiter, $error);
    }
}