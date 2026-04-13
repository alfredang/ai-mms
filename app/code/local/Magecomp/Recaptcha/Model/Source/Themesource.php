<?php
class Magecomp_Recaptcha_Model_Source_Themesource{
	public function toOptionArray(){
		return array(
			array('value'=>'0','label'=>'Light'),
			array('value'=>'1','label'=>'Dark'),
		);	
	}
}
?>