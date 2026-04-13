<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter_Config extends MMD_Mmdsys_Model_Rewriter_Abstract
{
    /**
     * @var string
     */
    protected $_configFile = '';
    
    /**
     * @var array
     */
    protected $_configContent = array();
    
    public function __construct()
    {
        parent::__construct();
        $this->_configFile = $this->_rewriteDir . 'config.php';
    }

    /**
     * @param string $mergedFilename
     * @param array|string $rewriteClasses
     */
    public function add($mergedFilename, $rewriteClasses)
    {
        if (is_array($rewriteClasses)) {
            foreach ($rewriteClasses as $class) {
                $this->_configContent[$class] = $mergedFilename;
            }
        } elseif (is_string($rewriteClasses)) { // will be string for abstract class rewrites
            $this->_configContent[$rewriteClasses] = $mergedFilename;
        }
    }
    
    public function commit()
    {
        $content = $this->tool()->toPhpArray($this->_configContent, 'rewriteConfig');
        $content = "<?php\n".$content;
        
        $this->tool()->filesystem()->putFile($this->_configFile, $content);
    }
}