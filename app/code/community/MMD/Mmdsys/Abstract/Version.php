<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Abstract_Version extends MMD_Mmdsys_Abstract_Model
{
    
    protected $_versionCompare = array();
    
    public function isMagentoVersion( $sourceVersion , $mageVersion )
    {
        if (!isset($this->_versionCompare[$mageVersion][$sourceVersion]))
        {
            $version = $sourceVersion;
            $directive = '=';
            if (!is_numeric(substr($version,0,1)))
            {
                $directive = is_numeric(substr($version,1,1)) ? substr($version,0,1) : substr($version,0,2);
                $version = substr($version,strlen($directive));
            }
            $this->tool()->testMsg('Total directive: '.$directive);
            $versionInfo = explode('.',$version);
            $info = explode('.',$mageVersion);
            if (preg_match('/[+-]/',$version) || '=' == $directive)
            {
                $this->tool()->testMsg("Use custom");
                $this->_versionCompare[$mageVersion][$sourceVersion] = self::_compareVersion($directive,$versionInfo,$info);
            }
            else
            {
                $this->tool()->testMsg("Use default");
                $this->tool()->testMsg(array($version,$mageVersion,$directive));
                $this->_versionCompare[$mageVersion][$sourceVersion] = version_compare($mageVersion,$version,$directive);
                $this->tool()->testMsg(strval($this->_versionCompare[$mageVersion][$sourceVersion]));
            }
        }
        return $this->_versionCompare[$mageVersion][$sourceVersion];
    }
    
    static private function _compareVersion( $directive , $version , $info )
    {
        foreach ($version as $index => $item)
        {
            $end = $index == (sizeof($version)-1);
            switch(true)
            {
                case (false !== strstr($item,'+')):
                    if (!self::_compareDirective($directive,'+',(int)$item,(int)$info[$index],$end))
                    {
                        MMD_Mmdsys_Abstract_Service::get()->testMsg('+');
                        return false;
                    }
                    break;
                case (false !== strstr($item,'-')):
                    if (!self::_compareDirective($directive,'-',(int)$item,(int)$info[$index],$end))
                    {
                        MMD_Mmdsys_Abstract_Service::get()->testMsg('-');
                        return false;
                    }
                    break;
                default:
                    if (!self::_compareDirective($directive,'.',(int)$item,(int)$info[$index],$end))
                    {
                        MMD_Mmdsys_Abstract_Service::get()->testMsg('.');
                        return false;
                    }
                    break;
            }
        }
        return true;
    }
    
    static private function _compareDirective( $directive , $case , $etalon , $value , $end = null )
    {
        if (('=' != $directive) && !$end && self::_compareDirective('=',$case,$etalon,$value))
        {
            return true;
        }
        switch ($directive)
        {
            default:
            case '=':
                switch ($case)
                {
                    case '+':
                        MMD_Mmdsys_Abstract_Service::get()->testMsg($value .'>='. $etalon);
                        return $value >= $etalon;
                    case '-':
                        MMD_Mmdsys_Abstract_Service::get()->testMsg($value .'<'. $etalon);
                        return $value < $etalon;
                    default:
                        MMD_Mmdsys_Abstract_Service::get()->testMsg($value .'=='. $etalon);
                        return $value == $etalon;
                }
                break;
            case '<':
                switch ($case)
                {
                    case '+':
                        return $value < $etalon;
                    case '-':
                        return $value <= $etalon;
                    default:
                        return $value < $etalon;
                }
                break;
            case '>':
                switch ($case)
                {
                    case '+':
                        return $value > $etalon;
                    case '-':
                        return $value >= $etalon;
                    default:
                        return $value > $etalon;
                }
                break;
            case '>=':
                switch ($case)
                {
                    case '+':
                        return $value >= $etalon+1;
                    case '-':
                        return $value > $etalon;
                    default:
                        return $value >= $etalon;
                }
                break;
            case '<=':
                switch ($case)
                {
                    case '+':
                        return $value < $etalon;
                    case '-':
                        return $value <= $etalon-1;
                    default:
                        return $value <= $etalon;
                }
                break;
        }
    }
    
}