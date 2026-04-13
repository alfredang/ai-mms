<?php
/**
 * @copyright  Copyright (c) 2012 MMD, Inc. 
 */
class MMD_Mmdsys_Helper_Statistics extends MMD_Mmdsys_Helper_Data
{
    public function getServerInfo() 
    {
        return array(
            'name'        => isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : '!!!' ,
            'host'        => isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : '!!!' ,
            'addr'        => isset($_SERVER['SERVER_ADDR']) ? $_SERVER['SERVER_ADDR'] : '!!!',
            'os'          => PHP_OS,
            'php_version' => PHP_VERSION,
            'apc'         => (int)function_exists('apc_cache_info')
        );
        
    }
}