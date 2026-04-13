<?php
class MMD_Courses_IndexController extends Mage_Core_Controller_Front_Action
{ 
	public function indexAction()
	{
    $this->loadLayout();   
    $this->renderLayout();
	}
	
		
	public function findprovidersAction()
	{
	$this->loadLayout();   
    $query = $this->getRequest()->getParam('s');
	if(!isset($query) || $query=='')
	{
			return;
	}
	$results = Mage::getModel('courses/providers')->getCollection()
	->addFieldToFilter('title', array('like' => $query.'%'));
    Mage::register('provider_results',$results);
	$this->getLayout()->getBlock('root')->setTemplate('page/1column.phtml');
	$this->renderLayout();
	}
	
		

	
}