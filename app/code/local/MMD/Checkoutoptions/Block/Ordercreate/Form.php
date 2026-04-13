<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Block_Ordercreate_Form extends Mage_Adminhtml_Block_Sales_Order_Create_Abstract
{
    protected $_form;
    
	public function __construct()
    {
        $this->setTemplate('checkoutoptions/order/create/form.phtml');
    }
    
    public function getForm()
    {
        $this->_prepareForm();
        return $this->_form;
    }
    
    protected function _afterToHtml($html)
    {
        $html = str_replace('__*__', ' <span class="required">*</span>', $html);
        
		if(version_compare(Mage::getVersion(), '1.4.1.1', '<='))
		{
		     $html .= '<script type="text/javascript">
AdminOrder.prototype.productGridAddSelected = function(area){
        if(this.productGridShowButton) Element.show(this.productGridShowButton);
        var data = {};
        data["add_products"] = this.gridProducts.toJSON();
        data["reset_shipping"] = 1;
        this.gridProducts = $H({});
        this.hideArea("search");
        this.loadArea(["search", "items", "shipping_method", "totals", "giftmessage","billing_method", "form_account"], true, data);
    };
    
AdminOrder.prototype.removeQuoteItem = function(id){
        this.loadArea(["items", "shipping_method", "totals", "billing_method", "form_account"], true,
            {remove_item:id, from:"quote",reset_shipping: true});
    };

AdminOrder.prototype.moveQuoteItem = function(id, to){
        this.loadArea(["sidebar_"+to, "items", "shipping_method", "totals", "billing_method", "form_account"], this.getAreaId("items"),
            {move_item:id, to:to, reset_shipping: true});
    };
    
AdminOrder.prototype.sidebarApplyChanges = function(){
        if($(this.getAreaId("sidebar"))){
            var data  = {};
            var elems = $(this.getAreaId("sidebar")).select("input");
            for(var i=0; i<elems.length; i++){
                if(elems[i].getValue()){
                    data[elems[i].name] = elems[i].getValue();
                }
            }
            data.reset_shipping = true;
            this.loadArea(["sidebar", "items", "shipping_method", "billing_method","totals", "giftmessage", "form_account"], true, data);
        }
    };

AdminOrder.prototype.itemsUpdate = function(){
        var info = $("order-items_grid").select("input", "select", "textarea");
        var data = {};
        for(var i=0; i<info.length; i++){
            if(!info[i].disabled && (info[i].type != "checkbox" || info[i].checked)) {
                data[info[i].name] = info[i].getValue();
            }
        }
        data.reset_shipping = true;
        data.update_items = true;
        this.orderItemChanged = false;
        this.loadArea(["sidebar", "items", "shipping_method", "billing_method","totals", "giftmessage", "form_account"], true, data);
    };
    
</script>
';
		}
		else
		{
		$html .= '<script type="text/javascript">
		
AdminOrder.prototype.prepareArea = function(area){
        if(typeof(area) != "object")
		{
		    return area;
		}

        area[area.size()] = "form_account";
        if (this.giftMessageDataChanged) {
            return area.without("giftmessage");
        }
        
        return area;
    };
</script>
';
        }       
		
        return parent::_afterToHtml($html);
    }
    
    protected function _prepareForm()
    {
        $ronly = false;
        $oldOrderId='';
        $temp='';
        $attributeValues='';
        $quoteId = false;
        $websiteId=$this->getStore()->getWebsiteId();
        
        $mainModel = Mage::getModel('checkoutoptions/checkoutoptions');
        $this->_form = new Varien_Data_Form();
        $storeId = $this->getStoreId();
        
        $mainModel->clearCheckoutSession('new_customer');
        
        $sWhereScope = '(additional_table.is_visible_in_advanced_search = 1 OR (find_in_set("' . $storeId . '", main_table.note) OR find_in_set("' . $storeId . '", additional_table.apply_to)))';
        
        //get attribute collection
        $collection = $mainModel->getAttributeCollecton();
        $collection
            ->getSelect()
            ->where('((additional_table.is_searchable > 0) OR (additional_table.is_comparable > 0)'. ( !$this->getCustomer()->getId() ? ' OR (additional_table.mmd_registration_page > 0))' : ')' ))
            ->where ($sWhereScope)
        ;

        $attributeValues = array();
        //get data from customer profile        
        $temp = $mainModel->getCustomerData($this->getCustomer()->getId(),$storeId,true);
        if($temp)
        {
            foreach($temp as $tmp)
            {
                if(in_array($tmp['type'],array('multiselect','checkbox')))
                {
                    $tmp['rawval']=explode(',',$tmp['rawval']);
                }
                $attributeValues[$tmp['code']]=$tmp['rawval'];
            }
        }
        //get data from old order if exists
        if( isset($_SESSION['adminhtml_quote']['order_id']) || isset($_SESSION['adminhtml_quote']['reordered']) )
        {
            $attributeValues = array();
            $oldOrderId=isset($_SESSION['adminhtml_quote']['order_id'])?$_SESSION['adminhtml_quote']['order_id']:$_SESSION['adminhtml_quote']['reordered'];
            $oldOrder = Mage::getModel('sales/order')->load($oldOrderId);
            $storeId = $oldOrder->getStoreId();
            $websiteId = $oldOrder->getStore()->getWebsiteId();
            
            $temp = $mainModel->getOrderCustomData($oldOrderId,$storeId,true);
            foreach($temp as $tmp)
            {
                if(in_array($tmp['type'],array('multiselect','checkbox')))
                {
                    $tmp['rawval']=explode(',',$tmp['rawval']);
                }
                $attributeValues[$tmp['code']]=$tmp['rawval'];
            }
        
            $groupId = $oldOrder->getCustomerGroupId();
            $quoteId = isset($_SESSION['adminhtml_quote']['quote_id'])?$_SESSION['adminhtml_quote']['quote_id']:false;
        }
        
				
        if($customerId = Mage::app()->getRequest()->getPost('customer_id'))
        {
            $groupId = Mage::getModel('customer/customer')->load($customerId)->getGroupId();
		}
        
        if(($groupIdTemp = Mage::app()->getRequest()->getPost('order')) && isset($groupIdTemp['account']['group_id']))
		{
            $groupId = $groupIdTemp['account']['group_id'];
		}
        
				
		if(!isset($groupId) && $this->getCustomerId())
		{
		    $groupId = Mage::getModel('customer/customer')->load($this->getCustomerId())->getGroupId();
		}
		
        if (!$this->getCustomer()->getId())
        {
            $_SESSION['mmd_checkout_used']['new_customer'] = true;
        }
        
    	/* {#MMD_COMMENT_END#}
        $performer = MMD_Mmdsys_Abstract_Service::get()->platform()->getModule('MMD_Checkoutoptions')->getLicense()->getPerformer();
        $ruler = $performer->getRuler();
        if ((!($ruler->checkRule('store',$storeId,'store') || $ruler->checkRule('store',$websiteId,'website')))&& (!$oldOrderId || !$temp))
        {
            return false;
        }
        elseif((!($ruler->checkRule('store',$storeId,'store') || $ruler->checkRule('store',$websiteId,'website')))&& $oldOrderId && $temp)
        {
            $ronly = true;
        }
        {#MMD_COMMENT_START#} */
        
        //get data from post
        if(Mage::getSingleton('adminhtml/session')->hasData('checkoutoptions_admin_post_data') && !$ronly)
        {
            $attributeValues = array();
            $curValues = Mage::getSingleton('adminhtml/session')->getData('checkoutoptions_admin_post_data');
            foreach($curValues as $curIndex => $curValue)
            {
                $attributeValues[$curIndex]=$curValue;
            }
            //Mage::getSingleton('adminhtml/session')->unsetData('checkoutoptions_admin_post_data');
        }
        
        if($collection->count())
        {
            if(isset($groupId ))
            {
                 foreach($collection as $key => $value)
                 {
                     if(in_array($groupId, Mage::getModel('checkoutoptions/attributecustomergroups')->getGroups($value->getAttributeId())))
                     {
                        $aTmpColl[] = $value;
                     }                         
                 }
            }
            else
            {
                //$aTmpColl = $collection;
				foreach($collection as $key => $value)
                 {
                    $aTmpColl[] = $value;
                 }
			}

            //form building
            $fieldset = $this->_form->addFieldset('main', array());
            if(!$ronly)
            {
                $collection = $aTmpColl;
				
				foreach($collection as $key => $attribute)
                {
                    if( $attribute->getData('mmd_product_category_dependant') )
                    {
                        $product_intersect = array_intersect(Mage::getModel('checkoutoptions/attributecatalogrefs')->getRefs($attribute->getId(), 'product'), Mage::helper('checkoutoptions')->getCartItems($quoteId,true));
                        $category_intersect = array_intersect(Mage::getModel('checkoutoptions/attributecatalogrefs')->getRefs($attribute->getId(), 'category'), Mage::helper('checkoutoptions')->getCartCategories($quoteId,true));
						if(empty($product_intersect) && empty($category_intersect))
                        {
                            unset($aTmpColl[$key]);
                        }
                     }
                }
                
            	$mainModel->prepareAdminForm($fieldset, /*$collection*/$aTmpColl, 'mmd_checkout_fields', $attributeValues);
            }
            else
            {
            	$aCustomAtrrList = $mainModel->getOrderCustomData($oldOrderId, $storeId, true);
            	foreach ($aCustomAtrrList as $attrN => $attr)
            	{
                    if($attr['value'])
                    {
                        $element = $fieldset->addField('note_'.$attrN, 'note',
                            array(
                                'label'		=> $attr['label'],
                                'text'		=> $attr['value'],
                            )
                        );
                    }
            	}
            }
        }
    }
}