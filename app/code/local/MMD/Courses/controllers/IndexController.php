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

	/**
	 * AJAX thumbs-up for the product-page share row (mirrors blog/index/like).
	 * POST product_id → {ok:true, likes:int, liked:bool}.
	 */
	public function likeAction()
	{
		$this->getResponse()->setHeader('Content-Type', 'application/json', true);
		try {
			if (!$this->getRequest()->isPost()) {
				throw new Exception('POST only');
			}
			$productId = (int) $this->getRequest()->getPost('product_id');
			$product   = Mage::getModel('catalog/product')->load($productId);
			if (!$product->getId() || $product->getStatus() != Mage_Catalog_Model_Product_Status::STATUS_ENABLED) {
				throw new Exception('Invalid like request');
			}
			$result = Mage::helper('courses')->likeProduct($productId);
			$this->getResponse()->setBody(json_encode(array('ok' => true) + $result));
		} catch (Exception $e) {
			$this->getResponse()->setHttpResponseCode(400);
			$this->getResponse()->setBody(json_encode(array('ok' => false, 'error' => $e->getMessage())));
		}
	}
	
		

	
}