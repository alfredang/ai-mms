<?php class MMD_MagentoCaptcha_IndexController extends Mage_Core_Controller_Front_Action
{
      const XML_PATH_EMAIL_RECIPIENT  = 'contacts/email/recipient_email';
    const XML_PATH_EMAIL_SENDER     = 'contacts/email/sender_email_identity';
    const XML_PATH_EMAIL_TEMPLATE   = 'contacts/email/email_template';
    const XML_PATH_ENABLED          = 'contacts/contacts/enabled';

    public function preDispatch()
    {
        parent::preDispatch();

        if( !Mage::getStoreConfigFlag(self::XML_PATH_ENABLED) ) {
            $this->norouteAction();
        }
    }
	 public function indexAction()
    {
	
        $this->loadLayout();
        $this->getLayout()->getBlock('contactForm')
            ->setFormAction( Mage::getUrl('*/*/post') );

        $this->_initLayoutMessages('customer/session');
        $this->_initLayoutMessages('catalog/session');
        $this->renderLayout();
		

    }
    
      
   public function postAction()
    {
       
       
        $secretKey     = Mage::getStoreConfig('magentocaptcha/general/secret_key') ?: getenv('RECAPTCHA_SECRET_KEY') ?: 'CHANGE_ME'; 
        if (!$this->_validateFormKey()) {
           // $this->_redirect('*/*/index');
           // return;
        }
        if(isset($_SERVER['HTTP_REFERER']) && strpos($_SERVER['HTTP_REFERER'],$_SERVER['HTTP_HOST'])!==false)
		{
        
            
            
       // Mage::log($_SERVER['REMOTE_ADDR']."-".$_SERVER['REMOTE_ADDR'], null, 'contact.log', true);
            
        $post = $this->getRequest()->getPost();
            
        // echo '<pre>'; print_r($post);
         //   die;   
           
        if ( $post ) {
            $translate = Mage::getSingleton('core/translate');
            /* @var $translate Mage_Core_Model_Translate */
            $translate->setTranslateInline(false);
            try {
                
                
           if(!empty($_POST['g-recaptcha-response'])){ 
               
               
          $api_url = 'https://www.google.com/recaptcha/api/siteverify'; 
            $resq_data = array( 
                'secret' => $secretKey, 
                'response' => $_POST['g-recaptcha-response'], 
                'remoteip' => $_SERVER['REMOTE_ADDR'] 
            ); 
 
            $curlConfig = array( 
                CURLOPT_URL => $api_url, 
                CURLOPT_POST => true, 
                CURLOPT_RETURNTRANSFER => true, 
                CURLOPT_POSTFIELDS => $resq_data, 
                CURLOPT_SSL_VERIFYPEER => false 
            ); 
 
            $ch = curl_init(); 
            curl_setopt_array($ch, $curlConfig); 
            $response = curl_exec($ch); 
            if (curl_errno($ch)) { 
                $api_error = curl_error($ch); 
            } 
            curl_close($ch); 
 
            // Decode JSON data of API response in array 
            $responseData = json_decode($response); 
 //echo '<pre>';
        //    print_r($responseData);   die;
               
            // If the reCAPTCHA API response is valid 
            if(!empty($responseData) && $responseData->success){ 
                
              
                $postObject = new Varien_Object();
                $postObject->setData($post);

                $error = false;

                if (!Zend_Validate::is(trim($post['name']) , 'NotEmpty')) {
                    $error = true;
                }

                if (!Zend_Validate::is(trim($post['comment']) , 'NotEmpty')) {
                    $error = true;
                }

                if (!Zend_Validate::is(trim($post['email']), 'EmailAddress')) {
                    $error = true;
                }

                if (Zend_Validate::is(trim($post['hideit']), 'NotEmpty')) {
                    $error = true;
                }

                if ($error) {
                    throw new Exception();
                }
                
                
                if (preg_match('/[\'^:£$%&*()}{@#~?><>,|=_+¬-]/', $post['comment']))
                {
                    $this->_redirect('*/*/');
                }
                if (preg_match('/[\'^:£$%&*()}{@#~?><>,|=_+¬-]/', $post['name']))
                {
                    $this->_redirect('*/*/');
                }
                
                
                $mailTemplate = Mage::getModel('core/email_template');
                /* @var $mailTemplate Mage_Core_Model_Email_Template */
                $mailTemplate->setDesignConfig(array('area' => 'frontend'))
                    ->setReplyTo($post['email'])
                    ->sendTransactional(
                        Mage::getStoreConfig(self::XML_PATH_EMAIL_TEMPLATE),
                        Mage::getStoreConfig(self::XML_PATH_EMAIL_SENDER),
                        Mage::getStoreConfig(self::XML_PATH_EMAIL_RECIPIENT),
                        null,
                        array('data' => $postObject)
                    );

                if (!$mailTemplate->getSentSuccess()) {
                    throw new Exception();
                }

                $translate->setTranslateInline(true);

                Mage::getSingleton('customer/session')->addSuccess(Mage::helper('contacts')->__('Your inquiry was submitted and will be responded to as soon as possible. Thank you for contacting us.'));
                $this->_redirect('*/*/');

                return;
                
            } else
                {
                $this->_redirect('*/*/');
                return;
                }
                } else { $this->_redirect('*/*/');
                return;}
                
            } catch (Exception $e) {					
				
                $translate->setTranslateInline(true);
                //Mage::getSingleton('customer/session')->addError(Mage::helper('contacts')->__('Unable to submit your request. Please, try again later'));
                  Mage::getSingleton('customer/session')->addSuccess(Mage::helper('contacts')->__('Your inquiry was submitted and will be responded to as soon as possible. Thank you for contacting us.'));
                $this->_redirect('*/*/');
                return;
            }

        } else {
            $this->_redirect('*/*/');
        }
        }
        else {
            $this->_redirect('*/*/');
        }
    }     
    
	public function postAction_old()
    {
       
        if (!$this->_validateFormKey()) {
            $this->_redirect('*/*/index');
            return;
        }
        if(isset($_SERVER['HTTP_REFERER']) && strpos($_SERVER['HTTP_REFERER'],$_SERVER['HTTP_HOST'])!==false)
		{
        
            
            
        Mage::log($_SERVER['REMOTE_ADDR']."-".$_SERVER['REMOTE_ADDR'], null, 'contact.log', true);
            
        $post = $this->getRequest()->getPost();
        if ( $post ) {
            $translate = Mage::getSingleton('core/translate');
            /* @var $translate Mage_Core_Model_Translate */
            $translate->setTranslateInline(false);
            try {
			
			 $formId = 'contact_form';
           $captchaModel = Mage::helper('captcha')->getCaptcha($formId);
           if ($captchaModel->isRequired()) {
            if (!$captchaModel->isCorrect($this->_getCaptchaString($this->getRequest(), $formId))) {
                Mage::getSingleton('customer/session')->addError(Mage::helper('captcha')->__('Incorrect CAPTCHA.'));
                $this->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
                Mage::getSingleton('customer/session')->setCustomerFormData($this->getRequest()->getPost());
                $this->getResponse()->setRedirect(Mage::getUrl('*/*/'));
                return;
            }
           } 
          
			
			
                $postObject = new Varien_Object();
                $postObject->setData($post);

                $error = false;

                if (!Zend_Validate::is(trim($post['name']) , 'NotEmpty')) {
                    $error = true;
                }

                if (!Zend_Validate::is(trim($post['comment']) , 'NotEmpty')) {
                    $error = true;
                }

                if (!Zend_Validate::is(trim($post['email']), 'EmailAddress')) {
                    $error = true;
                }

                if (Zend_Validate::is(trim($post['hideit']), 'NotEmpty')) {
                    $error = true;
                }

                if ($error) {
                    throw new Exception();
                }
                
                
                if (preg_match('/[\'^:£$%&*()}{@#~?><>,|=_+¬-]/', $post['comment']))
                {
                    $this->_redirect('*/*/');
                }
                if (preg_match('/[\'^:£$%&*()}{@#~?><>,|=_+¬-]/', $post['name']))
                {
                    $this->_redirect('*/*/');
                }
                
                
                $mailTemplate = Mage::getModel('core/email_template');
                /* @var $mailTemplate Mage_Core_Model_Email_Template */
                $mailTemplate->setDesignConfig(array('area' => 'frontend'))
                    ->setReplyTo($post['email'])
                    ->sendTransactional(
                        Mage::getStoreConfig(self::XML_PATH_EMAIL_TEMPLATE),
                        Mage::getStoreConfig(self::XML_PATH_EMAIL_SENDER),
                        Mage::getStoreConfig(self::XML_PATH_EMAIL_RECIPIENT),
                        null,
                        array('data' => $postObject)
                    );

                if (!$mailTemplate->getSentSuccess()) {
                    throw new Exception();
                }

                $translate->setTranslateInline(true);

                Mage::getSingleton('customer/session')->addSuccess(Mage::helper('contacts')->__('Your inquiry was submitted and will be responded to as soon as possible. Thank you for contacting us.'));
                $this->_redirect('*/*/');

                return;
            } catch (Exception $e) {					
				
                $translate->setTranslateInline(true);
                //Mage::getSingleton('customer/session')->addError(Mage::helper('contacts')->__('Unable to submit your request. Please, try again later'));
                  Mage::getSingleton('customer/session')->addSuccess(Mage::helper('contacts')->__('Your inquiry was submitted and will be responded to as soon as possible. Thank you for contacting us.'));
                $this->_redirect('*/*/');
                return;
            }

        } else {
            $this->_redirect('*/*/');
        }
        }
        else {
            $this->_redirect('*/*/');
        }
    }
	
	 protected function _getCaptchaString($request, $formId)
    {
        $captchaParams = $request->getPost(Mage_Captcha_Helper_Data::INPUT_NAME_FIELD_VALUE);
        return $captchaParams[$formId];
    } 
}
