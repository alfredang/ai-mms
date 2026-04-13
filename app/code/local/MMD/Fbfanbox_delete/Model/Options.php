<?php
class Mdd_Fbfanbox__Model_Options
{
  public function toOptionArray()
  {
    return array(
      array('value' => 0, 'label' => Mage::helper()->__('First item')),
      array('value' => 1, 'label' => Mage::helper()->__('Second item')),
      array('value' => 2, 'label' => Mage::helper()->__('third item')),
     // and so on...
    );
  }
}

?>