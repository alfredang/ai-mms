<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Observer
{
    public function handleAmProductGridMassaction($observer) 
    {
        $grid = $observer->getGrid();

        $types = array('', 'addcategory', 'removecategory', '', 'modifycost', 'modifyprice', 'modifyspecial', 'addspecial', 'addprice', 'addspecialbycost' , '', 
            'relate', 'upsell', 'crosssell', '',
            'unrelate', 'unupsell', 'uncrosssell', '', 
            'copyoptions', 'copyattr', 'copyimg', '', 'changeattributeset', '', 'delete');
        foreach ($types as $i => $type){
            if ($type){
                $command = MMD_Catalogmanagement_Model_Command_Abstract::factory($type);
                $command->addAction($grid);
            }
            else { // separator
                $grid->getMassactionBlock()->addItem('catalogmanagement_separator' . $i, array(
                    'label'=> '---------------------',
                    'url'  => '' 
                ));                
            }
        }
        
        return $this;
    }
}