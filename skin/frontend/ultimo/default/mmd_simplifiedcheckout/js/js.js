function timeoutProcess()
	{	
		val=$MMD_Simplifiedcheckout("#shipping-address-select").val();
		if(val)	
		updateShippingType(add('shipping')); // line 101 in skin.../mmd_simplifiedcheckout/js.js 
	}

 function isInt(x) {
   var y=parseInt(x);
   if (isNaN(y)) return false;
   return x==y && x.toString()==y.toString();
 } 
 
 typeof(id3) == "undefined"
	 
 function add(str){
	var str_val="";
	str_val=str_val+((typeof($MMD_Simplifiedcheckout("#"+str+"-address-select option:selected").val())=='undefined')?'':$MMD_Simplifiedcheckout("#"+str+"-address-select option:selected").val())+",";
	str_val=str_val+((typeof($MMD_Simplifiedcheckout("#"+str+"\\:country_id").val())=='undefined')?'':$MMD_Simplifiedcheckout("#"+str+"\\:country_id").val())+",";
	str_val=str_val+((typeof($MMD_Simplifiedcheckout("#"+str+"\\:postcode").val())=='undefined')?'':$MMD_Simplifiedcheckout("#"+str+"\\:postcode").val())+",";
	if($MMD_Simplifiedcheckout("#"+str+"\\:region_id").attr('display')=='block')
	str_val=str_val+((typeof($MMD_Simplifiedcheckout("#"+str+"\\:region_id").val())=='undefined' && $MMD_Simplifiedcheckout("#"+str+"\\:region_id").val()==null)?"":$MMD_Simplifiedcheckout("#"+str+"\\:region_id").val())+",";
	else
	str_val=str_val+',';
	if($MMD_Simplifiedcheckout("#"+str+"\\:region").attr('display')=='block')
	str_val=str_val+((typeof($MMD_Simplifiedcheckout("#"+str+"\\:region").val())=='undefined' && $MMD_Simplifiedcheckout("#"+str+"\\:region").val()==null)?"":$MMD_Simplifiedcheckout("#"+str+"\\:region").val())+",";
	else
	str_val=str_val+',';
	str_val=str_val+((typeof($MMD_Simplifiedcheckout("#"+str+"\\:city").val())=='undefined')?'':$MMD_Simplifiedcheckout("#"+str+"\\:city").val());
	
	return str_val;
 }
 
$MMD_Simplifiedcheckout(function(){
		
		var flag=1;	//kiem tra checkbox shiptosameaddress co duoc check hay uncheck, =1 la duoc check va default = checked
		var i=1;		

		//////////CONFIGURATION
		var shipaddselect=$MMD_Simplifiedcheckout("#shipping-address-select");// line 104 co the bi empty
		
		////////
		var change=0;		//cho biet tag select -coutryid cua billing va shipping co bi change hay ko,=1 la bi change
		var change_select=0; //cho biet tag select #billing-address-select(khi acc login va` co address) co bi change hay ko
		var timer;
		var islogin = logined();	//cho biet customer login hay chua
		var hasadd = hasaddress();	//cho biet customer co day du thong tin address hay chua
		
		// khi thay doi gia tri trong address customer o phan billing
		$MMD_Simplifiedcheckout("#billing-address-select").change(function(){			
			if(flag==1){	//  ship the same billing
					change_select=0;
					if(this.value==""){	// new address						
						countryid=$MMD_Simplifiedcheckout("#billing\\:country_id option:selected").val();	
						updateBillingForm(this.value,flag);
					}
					else{	
						updateBillingForm(this.value,flag); // update lai form address va load lai cac phuong thuc
					}								
				}				
				else{
					// chi cap nhat lai form thoi, khong cap nhat lai shipping type
					updateBillingForm(this.value,flag);
					change_select=1;
				}
			
		});
		
		// khi thay doi gia tri trong address customer o phan shipping
		$MMD_Simplifiedcheckout("#shipping-address-select").change(function(){
			
				if(flag==0){	//no check ship the same billing
					change_select=1;		
					if(this.value==""){		// new address				
						countryid=$MMD_Simplifiedcheckout("#shipping\\:country_id option:selected").val();						
						if(countryid){		
						//neu select shipping ton tai. option hop le^ hay value khac rong~, khu? truong hop. option="" khi bi clearForm() khi click 	#ship_to_same_address	
						updateShippingForm(this.value); // value = shipping_address_id selected
						}
					}
					else{						
						val=$MMD_Simplifiedcheckout("#shipping-address-select").val();
						if(val)
						updateShippingForm(this.value);	// value = shipping_address_id selected				
					}
				}
		});
		
		$MMD_Simplifiedcheckout('#shipping\\:same_as_billing').click(function()
		{			
			if(hasadd)
			{
				address_id =  $MMD_Simplifiedcheckout("#shipping-address-select").val();				
				updateShippingForm(address_id) ;
			}
			else
			{
				if(flag==0)
					{						
						if(this.checked==false)
							{		
								//xoa form shipping address chi? voi lan dau tien khi click vao shiptosameaddress
								if(!islogin)
									{
										$MMD_Simplifiedcheckout('#shipping-new-address-form').clearForm();
									}
							}
							else
							{
								if(change==1)
								{	
									//kiem tra xem countryid cua? shipping co bi change hay ko,neu bi thay doi thi thuc hien refresh lai shippingmethod
									ctid=$MMD_Simplifiedcheckout('#shipping\\:country_id');	
									updateShippingType();
									change=0;
								}
								if(change_select==0){	//kiem tra xem address select co bi change hay ko								
									if(!shipaddselect){
										countryid=$MMD_Simplifiedcheckout("#shipping\\:country_id option:selected").val();
										if(countryid!="")									
										updateShippingType();
									}
									change_select=1;
							}
								//if(hasadd){								
									//updateShippingType();
								//}							
							}
					}
				}
		});
		
		$MMD_Simplifiedcheckout("#ship_to_same_address").click(function(){
			 shipaddselect=$MMD_Simplifiedcheckout("#shipping-address-select");
			 billaddselect=$MMD_Simplifiedcheckout("#billing-address-select");
			if(this.checked==false){// calculate according to shipping
			// change step order
				$MMD_Simplifiedcheckout("#mmd-osc-p2").removeClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-2').addClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-3');
				$MMD_Simplifiedcheckout("#mmd-osc-p3").removeClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-3').addClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-4');
				$MMD_Simplifiedcheckout("#mmd-osc-p4").removeClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-4').addClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-5');
				
				flag=0;
					if(i==1)
					{
					//xoa form shipping address chi? voi lan dau tien khi click vao shiptosameaddress
						if(!islogin)
							{
						$MMD_Simplifiedcheckout('#shipping-new-address-form').clearForm();  //fix cho th bi mat country_id doi voi shipping
							}
					i=0;
					}
					
					$MMD_Simplifiedcheckout("#shipping_show").css('display','block');
					this.value=0;		//thuoc tinh' value =0 =>checkbox co checked dang trong
					if(islogin){

						change_select=1;

						if(change_select==0 || change==0){	//kiem tra xem address select co bi change hay ko							
							if(shipaddselect.val()==""){
								if(change==0){//kiem tra xem countryid cua? shipping co bi change hay ko,neu bi thay doi thi thuc hien refresh lai shippingmethod
									countryid=$MMD_Simplifiedcheckout("#shipping\\:country_id option:selected").val();
									if(countryid){									
									updateShippingType();
									change=1;
									}
								}
							}
							else{								
							countryid=$MMD_Simplifiedcheckout("#shipping\\:country_id option:selected").val();							
							if(countryid)							
							updateShippingType();
							}
							change_select=1;
						}
					}
					else{
						if(change==0){//kiem tra xem countryid cua? shipping co bi change hay ko,neu bi thay doi thi thuc hien refresh lai shippingmethod
							countryid=$MMD_Simplifiedcheckout("#shipping\\:country_id option:selected").val();
							if(countryid){							
							updateShippingType();
							change=1;
							}
						}			
					}
			}
			else{
				// change step order
				$MMD_Simplifiedcheckout("#mmd-osc-p2").removeClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-3').addClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-2');
				$MMD_Simplifiedcheckout("#mmd-osc-p3").removeClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-4').addClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-3');
				$MMD_Simplifiedcheckout("#mmd-osc-p4").removeClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-5').addClass('simplifiedcheckout-numbers simplifiedcheckout-numbers-4');
				
					 flag=1;
					 shipping.setSameAsBilling(true);
					 $('shipping:same_as_billing').checked = false;
					 $MMD_Simplifiedcheckout('#shipping_show').css('display','none');
					 this.value=1;	
					
					if(islogin){
						countryid=$MMD_Simplifiedcheckout("#billing\\:country_id option:selected").val();
						if(countryid){						
						updateShippingType();
						change_select=0;
						}
						if(change_select!=0 ||change==1){	//kiem tra xem address select co bi change hay ko
							if(billaddselect.val()==""){
									if(change==1){//kiem tra xem countryid cua? shipping co bi change hay ko,neu bi thay doi thi thuc hien refresh lai shippingmethod
										countryid=$MMD_Simplifiedcheckout("#billing\\:country_id option:selected").val();
										if(countryid){										
										updateShippingType();
										change=0;
										}
									}
								}
								else{
								countryid=$MMD_Simplifiedcheckout("#billing\\:country_id option:selected").val();
								if(countryid)								
								updateShippingType();
								}
								change_select=0;
						}
					}
					else{
						if(change==1){//kiem tra xem countryid cua? shipping co bi change hay ko,neu bi thay doi thi thuc hien refresh lai shippingmethod
							countryid=$MMD_Simplifiedcheckout("#billing\\:country_id option:selected").val();
							if(countryid){							
							updateShippingType();
							change=0;
							}
						}
					}
			}
		});
		
		
		$MMD_Simplifiedcheckout('#register_new_account').click(function(){				
				if(this.checked==true){
					$MMD_Simplifiedcheckout('#register-customer-password').css('display','block');
					this.value = 1;
					}
				else{
					this.value = 0;
					$MMD_Simplifiedcheckout('#register-customer-password').css('display','none');
					$MMD_Simplifiedcheckout('#register-customer-password').clearForm();
					}
				});
		
		$MMD_Simplifiedcheckout('#subscribe_newsletter').click(function(){				
				if(this.checked==true){
					this.value = 1;
				}
				else{
					this.value = 0;
				}
		});	
		
		$MMD_Simplifiedcheckout.fn.clearForm=function(){			
			$MMD_Simplifiedcheckout(':input', this).each(function() {					
					var type = $MMD_Simplifiedcheckout(this).get(0).type;	//.type can replate : .name .class .
					var tag = $MMD_Simplifiedcheckout(this).get(0).tagName.toLowerCase();					
					if (type == 'text' || type == 'password' || tag == 'textarea'){
						if((this.id =='billing:postcode' || this.id =='shipping:postcode') && this.value =='.')
							{
							this.value = '';
							}
						if(this.id!='billing:city' && this.id!='billing:taxvat' && this.id!='billing:day' && this.id!='billing:month' && this.id!='billing:year' && this.id!='billing:postcode' && this.id !='billing:region' && this.id!='shipping:city' && this.id!='shipping:postcode' && this.id !='shipping:region' && (islogin && this.id!='billing:email')){
							this.value = '';
						}
						else if(this.value=='n/a'){							
							this.value= '';
						}
					}
					else if ((type == 'checkbox' || type == 'radio') && this.id != 'register_new_account' ){
						
						this.checked = false;
					}
					else if (tag == 'select'){
						if(this.id!='billing:country_id' && this.id!='shipping:country_id' && this.id!='billing:region_id' && this.id!='shipping:region_id'){
							this.selectedIndex = -1;
						}
					}
			});
		};
		
		$MMD_Simplifiedcheckout('#allow_gift_messages').click(function(){
			if (this.checked==true){
				$MMD_Simplifiedcheckout('#allow-gift-message-container').css('display','block');
					if(!islogin)
					{
						$MMD_Simplifiedcheckout('input[id^="gift-message"]').val('');
					}
					else if(!hasadd)
					{
						$MMD_Simplifiedcheckout('input[id^="gift-message-whole-to"]').val('');
						$MMD_Simplifiedcheckout('input[id^="gift-message-"][id$="to"]').val('');
					}
				}
			else
				$MMD_Simplifiedcheckout('#allow-gift-message-container').css('display','none');
		});
	
///////// load ajax khi change country
		if(country_load()){		
			$MMD_Simplifiedcheckout('#billing\\:country_id').live("change", function(){
				if(flag==1){						
					updateShippingType();
					change=0;	//change=0 khi flag=1
					}
				else{
					change=1;		//khi #billing\\:country_id change trong luc flag=0 tuc' box shipping showing, de khi #ship_to_same_address dc click voi flag=1 tro lai thi` update shippingmethod
				}				//change=1 khi flag=0
			});
			
			$MMD_Simplifiedcheckout('#shipping\\:country_id').live("change", function(){			
					if(flag==0){
					change=1;					
					updateShippingType();
					}
			});
		}
		
		
////////load khi change zip postcode
		if(zip_load()){
//			var val_zipbill_before=$MMD_Simplifiedcheckout('#billing\\:postcode').val();
//			$MMD_Simplifiedcheckout('#billing\\:postcode').live("blur", function(){//	$MMD_Simplifiedcheckout('#billing\\:postcode').blur(function(event){
//				val=this.value;
//				if(val!="" && val_zipbill_before!=val){					
//					if($MMD_Simplifiedcheckout('#billing\\:country_id').val())						
//						updateShippingType();
//				}
//				val_zipbill_before=val;
//			});
			
//			var val_zipship_before=$MMD_Simplifiedcheckout('#shipping\\:postcode').val();
//			$MMD_Simplifiedcheckout('#shipping\\:postcode').blur(function(event){
//				val=this.value;
//				if(val!="" && val_zipship_before!=val){					
//					if($MMD_Simplifiedcheckout('#shipping\\:country_id').val())						
//						updateShippingType();
//				}
//				val_zipship_before=val;
//			});
		}
		
//////////load khi change state/province bien select 
		if(region_load()){
			$MMD_Simplifiedcheckout('#billing\\:region_id').live("change", function(){ //$MMD_Simplifiedcheckout('#billing\\:region_id').change(function(){
						if(flag==1){							
							updateShippingType();
							change=0;	//change=0 khi flag=1
							}
						else{
							change=1;		//khi #billing\\:country_id change trong luc flag=0 tuc' box shipping showing, de khi #ship_to_same_address dc click voi flag=1 tro lai thi` update shippingmethod
						}				
				});
				$MMD_Simplifiedcheckout('#shipping\\:region_id').live("change",function(){
						if(flag==0){
						change=1;						
						updateShippingType();
						}
				});
			
//////////load khi change state/province bien text
//			var val_regionbill_before=$MMD_Simplifiedcheckout('#billing\\:region').val();
//			$MMD_Simplifiedcheckout('#billing\\:region').live("blur", function(event) { //{$MMD_Simplifiedcheckout('#billing\\:region').blur(function(event){
//				val=this.value;
//				if(val!="" && val_regionbill_before!=val){					
//					if($MMD_Simplifiedcheckout('#billing\\:country_id').val())						
//						updateShippingType();
//				}
//				val_regionbill_before=val;
//			});
			
//			var val_regionship_before=$MMD_Simplifiedcheckout('#shipping\\:region').val();
//			$MMD_Simplifiedcheckout('#shipping\\:region').blur(function(event){
//				val=this.value;
//				if(val!="" && val_regionship_before!=val){					
//					if($MMD_Simplifiedcheckout('#shipping\\:country_id').val())						
//						updateShippingType();
//				}
//				val_regionship_before=val;
//			});
		}

//////////load khi change city 
		//if(city_load()){
//			var val_citybill_before=$MMD_Simplifiedcheckout('#billing\\:city').val();
//		
//			$MMD_Simplifiedcheckout('#billing\\:city').live("blur", function(event){
//			//$MMD_Simplifiedcheckout('#billing\\:city').blur(function(event){
//				val=this.value;
//				if(val!="" && val_citybill_before!=val){					
//					if($MMD_Simplifiedcheckout('#billing\\:country_id').val())						
//						updateShippingType();
//				}
//				alert(val_citybill_before);
//				val_citybill_before=val;
//			});
			
//			var val_cityship_before=$MMD_Simplifiedcheckout('#shipping\\:city').val();
//			$MMD_Simplifiedcheckout('#shipping\\:city').blur(function(event){
//				val=this.value;
//				if(val!="" && val_cityship_before!=val){					
//					if($MMD_Simplifiedcheckout('#shipping\\:country_id').val())						
//						updateShippingType();
//				}
//				val_cityship_before=val;
//			});		
		//}
});

