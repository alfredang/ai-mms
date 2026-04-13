<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2008-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Uncrosssell extends MMD_Catalogmanagement_Model_Command_Unrelate
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label = 'Remove Cross-Sells';
    }
}