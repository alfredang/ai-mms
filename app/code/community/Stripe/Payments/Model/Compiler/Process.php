<?php

class Stripe_Payments_Model_Compiler_Process extends Mage_Compiler_Model_Process
{
    protected function _copyAll($source, $target)
    {
        if (is_dir($source)) {
            $this->_mkdir($target);
            $dir = dir($source);
            while (false !== ($file = $dir->read())) {
                if (($file[0] == '.')) {
                    continue;
                }
                $sourceFile = $source . DS . $file;
                $targetFile = $target . DS . $file;
                $this->_copyAll($sourceFile, $targetFile);
            }
        } else {
            if (!in_array(substr($source, strlen($source)-4, 4), array('.php','.crt'))) {
                return $this;
            }
            copy($source, $target);
        }
        return $this;
    }
}
