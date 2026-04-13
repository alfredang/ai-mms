<?php
/**
 * @copyright  Copyright (c) 2011 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Core_Database extends MMD_Mmdsys_Abstract_Model
{
    protected $_conn;
    
    /**
     * @var array()
     */
    protected $_statuses;
    
    /**
     * @var array()
     */
    protected $_cachedConfig;
    
    protected function _connection()
    {
        if (is_null($this->_conn))
        {
            if (!Mage::registry('_singleton/core/resource'))
            {
                $config = $this->_config();
                $this->_conn = new Varien_Db_Adapter_Pdo_Mysql(array(
                    'host'     => (string)$config->global->resources->default_setup->connection->host,
                    'username' => (string)$config->global->resources->default_setup->connection->username,
                    'password' => (string)$config->global->resources->default_setup->connection->password,
                    'dbname'   => (string)$config->global->resources->default_setup->connection->dbname ,
                    'port'     => (string)$config->global->resources->default_setup->connection->port,
                    'type'     => 'pdo_mysql' ,
                    'model'    => 'mysql4' ,
                    'active'   => 1
                ));
            }
            else
            {
                $this->_conn = Mage::getSingleton('core/resource')->getConnection('core_read');
            }
        }
        return $this->_conn;
    }
    
    /**
     * Get table name using magento tables' prefix
     * 
     * @param string $table
     */
    protected function _table($table)
    {
        if(isset($this->_config()->global->resources->db) && isset($this->_config()->global->resources->db->table_prefix))
        {
            return $this->_config()->global->resources->db->table_prefix.$table;
        }

        return $table;
    }
    
    protected function _config()
    {
        if (is_null($this->_localConfig)) {
            $path = BP . '/app/etc/local.xml';
            if (file_exists($path))
            {
                $this->_localConfig = new Zend_Config_Xml($path);
            }
        }
        return $this->_localConfig;
    }
    
    /**
     * Get config value from local
     * 
     * @param string $type
     * @param mixed $value
     */
    /* removed from 2.20
    protected function _getCachedConfig($type)
    {
        if(is_null($this->_cachedConfig))
        {
            $this->_cachedConfig = $this->tool()->getCache()->load('mmdsys_db_config', array());
        }
        $type = md5($type);
        return isset($this->_cachedConfig[$type]) ? $this->_cachedConfig[$type] : null;
    }
    */
    
    /**
     * Save config value from database to local cache to prevent future queries
     * 
     * @param string $type
     * @param mixed $value
     */
    /* removed from 2.20
    protected function _updateCachedConfig($type, $value)
    {
        $type = md5($type);
        $this->_cachedConfig[$type] = $value;
        $this->tool()->getCache()->save($this->_cachedConfig, 'mmdsys_db_config');
        
        return $this->_cachedConfig[$type];
    }
    */
    
    /**
     * Get value from magento core_config_data table
     * 
     * @param string $path
     * @param mixed $defaultValue
     */
    public function getConfigValue($path, $defaultValue = null)
    {
        // if (!$data = $this->_getCachedConfig($path)) { // removed from 2.20
            $conn = $this->_connection();
            $select = $conn->select()
               ->from($this->_table('core_config_data'))
               ->where('path = ?',$path)
               ->where('scope = ?','default');
            $data = $conn->fetchRow($select);
    
            //$conn->closeConnection();
            if ($data === false || !isset($data['value']) || $data['value'] === '') {
                $data = $defaultValue;
            } else {
                $data = $data['value'];
            }
            
            $data = $this->tool()->unserialize($data);
            /*
            $this->_updateCachedConfig($path, $data);
        }
        */
        return $data;
    }
    
    /**
     * Retrieves stored modules' statuses.
     * 
     * @param string $key Module key like MMD_Aitmodulename
     * @return array|bool
     */
    public function getStatus($key = '')
    {
        if (is_null($this->_statuses)) {
            // $this->_statuses = $this->tool()->getCache()->load('mmdsys_db_statuses', array()); // removed from 2.20
            $this->_statuses = array();
            // if(empty($this->_statuses)) {
                $conn = $this->_connection();
                $select = $conn->select()->from($this->_table('mmdsys_status'));
                $data = $conn->fetchAll($select);
                
                foreach($data as $module) {
                    $this->_statuses[$module['module']] = $module['status'];
                }
                // $this->tool()->getCache()->save($this->_statuses, 'mmdsys_db_statuses'); // removed from 2.20
            //}
        }
        
        if ($key) {
            return isset($this->_statuses[$key]) ? (bool)$this->_statuses[$key] : false;
        } else {
            return $this->_statuses; 
        }
    }
    
    /**
     * Return current Mmdsys db resource version
     * 
     * @return string
     */
    public function dbVersion()
    {
        // if(is_null($this->_dbVersion) && !($this->_dbVersion = $this->_getCachedConfig('db_version'))) { // removed from 2.20
            $conn = $this->_connection();
            $select = $conn->select()
                        ->from($this->_table('core_resource'), 'version')
                        ->where('code =?', 'mmdsys_setup');
            $this->_dbVersion = $conn->fetchOne($select);
            /* removed from 2.20
            $this->_updateCachedConfig('db_version', $this->_dbVersion);
        } */
        return $this->_dbVersion;
    }
}