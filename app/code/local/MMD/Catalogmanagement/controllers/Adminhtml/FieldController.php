<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Adminhtml_FieldController extends Mage_Adminhtml_Controller_Action
{
    protected $_product = null;
    protected $_colProp = null;
    
    protected function _initProduct($productId, $field)
    {
        $productId = $productId;
        if ('name' == $field)
        {
            // name field should always be saved with no store loaded
            $product        = Mage::getModel('catalog/product')->load($productId);
        } else 
        {
            $product        = Mage::getModel('catalog/product')->setStoreId($this->_getStore()->getId())->load($productId);
        }
        $this->_product = $product;
    }
    
    protected function _getStore()
    {
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
    }
    
    protected function _getObject($field)
    {
        $obj = $this->_product;
                
        if (isset($field['obj']))
        {
            $obj = $this->_product->getData($field['obj']); // for example, stock_item
        }
        
        return $obj;
    }
    
    protected function _getColumnProperties()
    {
        if (!$this->_colProp)
        {
            $this->_colProp = Mage::helper('catalogmanagement')->getColumnsProperties(false, true);
        }
        return $this->_colProp;
    }
    
    /**
    * this method returns javascript code
    */
    public function saveallAction()
    {
        $productIds = $this->getRequest()->getPost('productId');
        $fields     = $this->getRequest()->getPost('field');
        $values     = $this->getRequest()->getPost('value');
        $tdKeys     = $this->getRequest()->getPost('tdkey');
        $responce   = '';
        $errors     = array();
        if (is_array($productIds) && !empty($productIds) && is_array($fields) && is_array($values))
        {
            foreach ($productIds as $i => $productId)
            {
                $result = $this->_updateProductData($productId, $fields[$i], $values[$i]);
                if (isset($result['success']))
                {
                    $responce .= "$('" . $tdKeys[$i] . "').innerHTML = '" . $result['value'] . "';";
                } elseif (isset($result['error']))
                {
                    $errors[] = $result['message'];
                }
            }
            if ($errors)
            {
                $responce .= 'alert("' . implode("\r\n", $errors) . '");';
            }
        }
        
        $this->getResponse()->setBody(
            $responce
        );
    }
    
    public function saveAction()
    {
        $result = $this->_updateProductData($this->getRequest()->getPost('product_id'), Mage::app()->getRequest()->getParam('field'), Mage::app()->getRequest()->getParam('value'));
        
        $this->getResponse()->setBody(
            Mage::helper('core')->jsonEncode($result)
        );
    }
    
    protected function _updateProductData($productId, $field, $value)
    {
        $this->_initProduct($productId, $field);
        if ($this->_product)
        {
            $result  = array();
            
            if ('custom_name' == $field)
            {
                $field = 'name';
            }
            
            $store   = $this->_getStore();
            
            $columnProps = $this->_getColumnProperties();
            $obj         = $this->_product;

            if (isset($columnProps[$field]))
            {
                /* will save value. first need to check where to save (product itself, stock item, etc.)
                 * @see MMD_Catalogmanagement_Helper_Data
                 */
                
                $obj = $this->_getObject($columnProps[$field]);

                if (isset($columnProps[$field]['format']))
                {
                    switch ($columnProps[$field]['format'])
                    {
                        case 'numeric':
                           
                            $lastNumber = 0;
                            if(false !== strpos($value, ','))$value = str_replace(',', '.', $value);

                            if(false !== strpos($value, '.'))
                            {
                                $value_1=$value;
                                $pieces=explode('.', $value_1);
                                foreach($pieces as $val)
                                {
                                    if(!next($pieces))
                                    {
                                        $lastNumber = $val;
                                    }                              
                                }
                                array_pop($pieces);
                                $union=implode(',',$pieces);
                                $value=$union.'.'.$lastNumber;
                            }

                            $value = str_replace(',', '', $value); 
                          
                                                           
                            if (false !== strpos($value, '+') || false !== strpos($value, '-'))
                            {
                                if (   strpos($value, '+') != (strlen($value) - 1)  &&  strpos($value, '-') != (strlen($value) - 1)  )
                                {
                                    $value = preg_replace('@[^0-9\.+-]@', '', $value);
                                    try {
                                        $toEval = '$value = ' . $value . ';';
                                        eval($toEval);
                                    } catch (Exception $e) {}
                                }
                            }
                            $value = preg_replace('@[^-0-9\.]@', '', $value);
                        break;
                    }
                }
                
                if ('multiselect' == $columnProps[$field]['type'])
                {
                    $value = explode(',', $value);
                }
                
                if ('price' == $columnProps[$field]['type'])
                {
                    $value = str_replace('$', '', $value);
                }

                $obj->setData($columnProps[$field]['col'], $value);

                try
                {
                    if (method_exists($obj, 'validate'))
                    {
                        $obj->validate(); // this will validate necessary unique values
                    }
                } catch (Exception $e)
                {
                    $result = array(
                        'error'   => 1,
                        'message' => 'ID ' . $productId . ': ' . $e->getMessage() , "\r\n",
                    );
                }
                
                if (!isset($result['error']))
                {
                    if (Mage::getStoreConfig('catalogmanagement/cond/availability'))
                    {
                        if ('qty' == $columnProps[$field]['col'])
                        {
                            if ($obj->getOrigData('qty') > 0 && $obj->getData('qty') <= 0)
                            {
                                $obj->setData('is_in_stock', 0);
                            }
                            if ($obj->getOrigData('qty') <= 0 && $obj->getData('qty') > 0)
                            {
                                $obj->setData('is_in_stock', 1);
                            }
                        }
                    }
                    $obj->save();
                    
                    $this->_initProduct($productId, $field);
                    $obj = $this->_getObject($columnProps[$field]);
                }
            }
            
            if (!isset($result['error']))
            {
                $outputValue  = $obj->getData($columnProps[$field]['col']);

                if (isset($columnProps[$field]))
                {
                    switch ($columnProps[$field]['type'])
                    {
                        case 'price':
                            $currencyCode = $store->getBaseCurrency()->getCode();
                            $outputValue  = sprintf("%f", $outputValue);
                            $outputValue  = Mage::app()->getLocale()->currency($currencyCode)->toCurrency($outputValue);
                        break;
                        case 'select':
                            if (isset($columnProps[$field]['options'][$outputValue]))
                            {
                                $outputValue = $columnProps[$field]['options'][$outputValue];
                            }
                        break;
                        case 'multiselect':
                            $outputValues = explode(',', $outputValue);
                            if (is_array($outputValues) && !empty($outputValues))
                            {
                                foreach ($outputValues as &$value)
                                {
                                    if (isset($columnProps[$field]['options'][$value]))
                                    {
                                        $value = $columnProps[$field]['options'][$value];
                                    }
                                }
                                $outputValue = implode(', ', $outputValues);
                            }
                        break;
                        case 'date':
                            $outputValue = Mage::getSingleton('core/locale')->date($outputValue, Zend_Date::ISO_8601, null, false)->toString(Mage::app()->getLocale()->getDateFormat(Mage_Core_Model_Locale::FORMAT_TYPE_MEDIUM));
                        break;
                        default:
                            $outputValue = htmlentities($outputValue);
                        break;
                    }
                }
                $result       = array('success' => 1, 'value' => $outputValue);
            }
            
        } else 
        {
            $result = array(
                'error'   => 1,
                'message' => $this->__('Unable to load product with ID %d', $productId) . "\r\n",
            );
        }
        
        return $result;
    }

    public function savesortingAction()
    {
        $orderedFields = Mage::app()->getRequest()->getParam('fields', array());

        $extraKey = '';
        if (Mage::getStoreConfig('catalogmanagement/attr/byadmin'))
        {
            $extraKey = Mage::getSingleton('admin/session')->getUser()->getId();
        }

        $config = Mage::getModel('core/config');
        $config->saveConfig('catalogmanagement/attributes/sorting' . $extraKey, implode(',', $orderedFields));
        $config->cleanCache();

        $result = array('success' => 1);

        $this->getResponse()->setBody(
            Mage::helper('core')->jsonEncode($result)
        );
    }
}