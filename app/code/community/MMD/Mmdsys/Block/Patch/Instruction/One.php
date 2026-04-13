<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Block_Patch_Instruction_One extends MMD_Mmdsys_Abstract_Adminhtml_Block
{
    /**
     * @var string
     */
    protected $_sourceFile = '';

    /**
     * @var string
     */
    protected $_extensionPath = '';

    /**
     * @var string
     */
    protected $_extensionName = '';

    /**
     * @var string
     */
    protected $_patchFile = '';

    /**
     * @var bool
     */
    protected $_removeBasedir = true;
    
    /**
     * @var string
     */
    protected $_baseDir = '';
    
    /**
     * @param string $path
     */
    public function setSourceFile($path)
    {
        $this->_sourceFile = $path;
    }
    
    /**
     * @param string $path
     */
    public function setExtensionPath($path)
    {
        $this->_extensionPath = $path;
    }
    
    /**
     * @param string $path
     */
    public function setExtensionName($name)
    {
        $this->_extensionName = $name;
    }
    
    /**
     * @param string $path
     */
    public function setPatchFile($file)
    {
        $this->_patchFile = $file;
    }
    
    /**
     * @return string
     */
    protected function _getBaseDir()
    {
        if (!$this->_baseDir) {
            $this->_baseDir = $this->_normalizePath(Mage::getBaseDir());
        }
        return $this->_baseDir;
    }

    /**
     * @param string $path
     * 
     * @return string
     */
    protected function _removeBaseDir($path)
    {
        if ($this->_removeBasedir) {
            $path = str_replace($this->_getBaseDir(), '', $path);
        }
        return $path;
    }
    
    /**
     * @param string $path
     * 
     * @return string
     */
    protected function _normalizePath($path)
    {
        return str_replace(array('/', '\\'), DS, $path);
    }    
    
    /**
     * @param bool $includeBasedir
     * 
     * @return string
     */
    public function getSourceFile($includeBasedir = false)
    {
        $path = $this->_sourceFile;
        $path = $this->_normalizePath($path);
        if (!$includeBasedir) {
            $path = $this->_removeBasedir($path);
        }
        return $path;
    }    
    
    /**
     * @param bool $includeBasedir
     * 
     * @return string
     */
    public function getExtensionPath($includeBasedir = false)
    {
        $path = $this->_extensionPath;
        $path = $this->_normalizePath($path);
        if (!$includeBasedir) {
            $path = $this->_removeBasedir($path);
        }
        return $path;
    }
    
    /**
     * @return string
     */
    public function getExtensionName()
    {
        return $this->_extensionName;
    }

    /**
     * @return string
     */
    public function getPatchFile()
    {
        return $this->_normalizePath($this->_patchFile);
    }
    
    /**
     * @return string
     */
    public function getPatchedFileName()
    {
        return str_replace('.patch', '', $this->getPatchFile());
    }
    
    /**
     * @return string
     */
    public function getDestinationFile()
    {
        $destinationFile = str_replace(Mage::getBaseDir('app'), MMD_Mmdsys_Model_Mmdpatch::getPatchesCacheDir(), $this->getSourceFile(true));
        $destinationFile = substr($destinationFile, 0, strrpos($destinationFile, DS) + 1);
        $destinationFile = str_replace(strstr($destinationFile, 'template'), '', $destinationFile);
        $destinationFile .= 'template' . DS . 'mmdcommonfiles' . DS . str_replace('.patch', '', $this->getPatchFile());
        $destinationFile = $this->_removeBasedir($destinationFile);
        return $destinationFile;
    }
    
    /**
     * @return string
     */
    public function getDestinationDir()
    {
        return dirname($this->getDestinationFile());
    }
    
    /**
     * @return string
     */
    public function getPatchConfigPath()
    {
        $config = $this->getExtensionPath() . DS . 'etc' . DS . 'custom.data.xml';
        return htmlspecialchars($config);
    }
    
    /**
     * @return string
     */
    public function getPatchConfigLine()
    {
        $configLine = '<file path="' . substr($this->getPatchFile(), 0, strpos($this->getPatchFile(), '.')) . '"></file>';
        return htmlspecialchars($configLine);
    }
    
    /**
     * @return MMD_Mmdsys_Model_Mmdfilepatcher
     */
    protected function _makeMmdfilepatcher()
    {
        return new MMD_Mmdsys_Model_Mmdfilepatcher();
    }
    
    /**
     * @return string
     */
    public function getPatchContents()
    {
        $patcher  = $this->_makeMmdfilepatcher();
        /* @var $pathcer MMD_Mmdsys_Model_Mmdfilepatcher */
        
        $oFileSys = $this->tool()->filesystem();
        /* @var $oFileSys MMD_Mmdsys_Model_Core_Filesystem */

        $patchPath = $oFileSys->getPatchFilePath($this->getPatchFile(), $this->getExtensionPath(true) . DS . 'data' . DS)->getFilePath();
        $patchInfo = $patcher->parsePatch(file_get_contents($patchPath));
        $html = '<div class="patch">';
        
        foreach ($patchInfo as $_data) {
            foreach ($_data['aChanges'] as $_data) {
                $bAfter  = false;
                $bAdd    = false;
                $bBefore = false;
                $bLastAfter  = false;
                $bLastAdd    = false;
                $bLastBefore = false;
                $str = '';
                $aChunk = array();
                foreach ($_data['aChangingStrings'] as $_line) {
                    if ($_line[0] == '+') {
                        $bBefore = false;
                        $bAdd    = true;
                        $bAfter  = false;
                    } elseif ($_line[0] == ' ') {
                        if ($bAdd || $bBefore) {
                            $bAfter  = false;
                            $bBefore = true;
                            $bAdd    = false;
                        } else {
                            $bAfter  = true;
                            $bBefore = false;
                        }
                    }
                    
                    if ($bLastAfter && !$bAfter) {
                        $aChunk[] = array(
                            'part' => 'after',
                            'str'  => $str,
                        );
                        $str = '';
                    } elseif ($bLastAdd && !$bAdd) {
                        $aChunk[] = array(
                            'part' => 'add',
                            'str'  => $str,
                        );
                        $str = '';
                    } elseif ($bLastBefore && !$bBefore) {
                        $aChunk[] = array(
                            'part' => 'before',
                            'str'  => $str,
                        );
                        $str = '';
                    }
                    $str .= htmlspecialchars(rtrim($_line[2])) . "\r\n";
                    $bLastAfter  = $bAfter;
                    $bLastAdd    = $bAdd;
                    $bLastBefore = $bBefore;
                }
                if ($bBefore) {
                    $aChunk[] = array(
                        'part' => 'before',
                        'str'  => $str,
                    );
                }
                $html .= $this->_getChunkHtml($aChunk);
            }
        }
        $html .= '</div>';
        return $html;
    }
    
    /**
     * @param array $chunk
     * 
     * @return string
     */
    protected function _getChunkHtml($chunk)
    {
        $html = '';
        foreach ($chunk as $part) {
            if ($part['part'] == 'after') {
                continue;
            }
            if ($part['part'] == 'add') {
                $html .= Mage::helper('mmdsys')->__('You will need to add the following lines &mdash;') ;
                $html .= '<pre>';
                $html .= $part['str'];
                $html .= '</pre>';
            }
            if ($part['part'] == 'before') {
                $html .= Mage::helper('mmdsys')->__('The above lines should be added BEFORE the following code or similar to it &mdash;') ;
                $html .= '<pre>';
                $html .= $part['str'];
                $html .= '</pre>';
            }
        }
        return $html;
    }
}