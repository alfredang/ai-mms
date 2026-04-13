<?php 
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Options extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{ 
    /**
    * Render product details
    *
    * @param   Varien_Object $row
    * @return  string
    */
    public function render(Varien_Object $row)
    {
        $arr = unserialize($row->getProduct_options());
		
		if(is_array($arr['options']))
		{  /*return print_r($arr['options']);*/
		  $return ="";
		  foreach($arr['options'] as $opt)
		  {
		    $return .="<b>".$opt['label']."</b>: ".$opt['value']."<br/>";
		  }
		  return $return;
		}else
		{
		 return "------";
		}
    }
}