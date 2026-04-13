<?php
class MMD_Fbfanbox_Model_Source_Position {
	public function toOptionArray() {
		$options = array();
		$options[] = array('value'=>'left', 'label'=>'Left Column');
		$options[] = array('value'=>'center', 'label'=>'Center Column / CMS Page');
		$options[] = array('value'=>'right', 'label'=>'Right Column');		
		return $options;
	}
}