<?php
class MMD_BankPayment_IndexController extends Mage_Core_Controller_Front_Action
{
   
	public function indexAction()
    { 	
		 $this->loadLayout();
        //$this->getLayout()->getBlock('confirmorderForm')
           // ->setFormAction( Mage::getUrl('*/*/post') );

        $this->_initLayoutMessages('customer/session');
        $this->_initLayoutMessages('catalog/session');
        $this->renderLayout();
    }
	
	function confirmorderAction()
	{
		$this->loadLayout();
        //$this->getLayout()->getBlock('confirmorderForm')
           // ->setFormAction( Mage::getUrl('*/*/post') );

        $this->_initLayoutMessages('customer/session');
        $this->_initLayoutMessages('catalog/session');
        $this->renderLayout();
	}
	
	public function postAction()
    {
        $post = $this->getRequest()->getPost();
		
		  if ( $post ) { 
		 
		 $fileUpload ="";
		
		 if (isset($_FILES['file_receipt']['name']) && $_FILES['file_receipt']['name'] != "") {
					$exten = pathinfo($_FILES['file_receipt']['name'], PATHINFO_EXTENSION);				
					$fileArr = array('jpg', 'jpeg', 'gif', 'png', 'pdf','doc','txt');
					
					if(in_array($exten,$fileArr))
					{
					$uploader = new Varien_File_Uploader("file_receipt");
					$uploader->setAllowedExtensions($fileArr);
					$uploader->setAllowRenameFiles(false);
					$uploader->setFilesDispersion(false);
					$path = Mage::getBaseDir("media") . DS . "bankpayment" . DS;
					$fileName = time() . "." . pathinfo($_FILES['file_receipt']['name'], PATHINFO_EXTENSION);     
					$uploader->save($path, $fileName);	
					$fileUpload = $path.$fileName;
					}
                }
		 
		 
            $translate = Mage::getSingleton('core/translate');
            /* @var $translate Mage_Core_Model_Translate */
            $translate->setTranslateInline(false);
            try {
                $postObject = new Varien_Object();
                $postObject->setData($post);

                $error = false;

                if (!Zend_Validate::is(trim($post['name']) , 'NotEmpty')) {
                    $error = true;
                }
				 if (!Zend_Validate::is(trim($post['transaction_id']) , 'NotEmpty')) {
                    $error = true;
                }
				 if (!Zend_Validate::is(trim($post['bank_paid_to']) , 'NotEmpty')) {
                    $error = true;
                }
				 if (!Zend_Validate::is(trim($post['order_id']) , 'NotEmpty')) {
                    $error = true;
                }
				 if (!Zend_Validate::is(trim($post['ib_nick']) , 'NotEmpty')) {
                    $error = true;
                }
				 if (!Zend_Validate::is(trim($post['transaction_date']) , 'NotEmpty')) {
                    $error = true;
                }
				 if (!Zend_Validate::is(trim($post['transaction_time']) , 'NotEmpty')) {
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
				
				//email send
				
				$body = '
<h4>Bank Payment Order Information</h4>
<hr>
<table cellspacing="0" cellpadding="0" border="0" style="width: 510px;">
        <tbody><tr id="ctl00_contentMain_uctlContact_countryRow">
			<td style="width:30%; padding: 0px 6px 12px 0px; text-align: right;color:#333;">
                Name: 
            </td>
			<td style="width: 70%; padding: 0px 6px 12px 0px;">'.$post['name'].'</td>
		</tr>
		<tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">Email: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['email'].'</td>
		</tr>
        <tr>
            <td style="width:30%; padding: 0px 6px 6px 0px; text-align: right;color:#333;">
                Transaction ID: 
            </td>
            <td style="width:70%; padding: 0px 0px 6px 0px;">'.$post['transaction_id'].'</td>
        </tr>
        
       <tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">Bank Account Paid To: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['bank_paid_to'].'</td>
		</tr>
		<tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">Order ID: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['order_id'].'</td>
		</tr>
		<tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">IB Nick: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['ib_nick'].'</td>
		</tr>
		
		<tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">Transaction Date: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['transaction_date'].'</td>
		</tr>
		
		<tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">Transaction Time: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['transaction_time'].'</td>
		</tr>
		
		<tr id="ctl00_contentMain_uctlContact_pnlCompany">
			<td style="width:30%; padding: 6px 6px 6px 0px; text-align: right;color:#333;">Comment: </td>
			<td style="width: 70%; padding: 6px 0px;">'.$post['comment'].'</td>
		</tr>
		
    </tbody></table>';
				
				
			$to = 	Mage::getStoreConfig('payment/bankpayment/recipient_email');
			$subject = 'Bank Payment Order Information:'.$post['order_id'];	
				
				$mail = new Zend_Mail();
				//$mail->setBodyText($rq_msg);
				$mail->setBodyHtml($body);
				$mail->setFrom($post['email'], $post['name']);
				$mail->addTo($to, 'Some Recipient');
				$mail->setSubject($subject);
				
				if($fileUpload!="") {
				$content = file_get_contents($fileUpload);
				$at = new Zend_Mime_Part($content); 
				$at->type        = 'application/'.$exten; // if u have PDF then it would like -> 'application/pdf'
				$at->disposition = Zend_Mime::DISPOSITION_INLINE;
				$at->encoding    = Zend_Mime::ENCODING_8BIT;
				$at->filename    = $fileName;
				$mail->addAttachment($at);
				}
				
				
				$mail->send(); 	
                Mage::getSingleton('customer/session')->addSuccess(Mage::helper('bankpayment')->__('Your Order Confirmation was submitted and will be responded to as soon as possible. Thank you for buying.'));
                $this->_redirect('*/*/');

                return;
            } catch (Exception $e) {			
                $translate->setTranslateInline(true);
                Mage::getSingleton('customer/session')->addError(Mage::helper('bankpayment')->__('Unable to submit your request. Please, try again later'));
                $this->_redirect('*/*/');
                return;
            }

        } else {
            $this->_redirect('*/*/');
        }
    }
}