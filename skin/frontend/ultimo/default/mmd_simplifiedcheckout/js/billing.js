$MMD_Simplifiedcheckout(function(){
	if(zip_load()){
			var val_zipbill_before=$MMD_Simplifiedcheckout('#billing\\:postcode').val();
			$MMD_Simplifiedcheckout('#billing\\:postcode').blur(function(event){ //$MMD_Simplifiedcheckout('#billing\\:postcode').live("blur", function(){//	$MMD_Simplifiedcheckout('#billing\\:postcode').blur(function(event){
				val=this.value;
				if(val!="" && val_zipbill_before!=val){					
					if($MMD_Simplifiedcheckout('#billing\\:country_id').val())						
						updateShippingType();
				}
				val_zipbill_before=val;
			});
	}
	
	
	if(region_load()){
	var val_regionbill_before=$MMD_Simplifiedcheckout('#billing\\:region').val();
	$MMD_Simplifiedcheckout('#billing\\:region').blur(function(event){ //$MMD_Simplifiedcheckout('#billing\\:region').live("blur", function(event) { //{$MMD_Simplifiedcheckout('#billing\\:region').blur(function(event){
		val=this.value;
		if(val!="" && val_regionbill_before!=val){					
			if($MMD_Simplifiedcheckout('#billing\\:country_id').val())						
				updateShippingType();
		}
		val_regionbill_before=val;
	});	
	}
	
	if(city_load()){
		var val_citybill_before=$MMD_Simplifiedcheckout('#billing\\:city').val();	
		//$MMD_Simplifiedcheckout('#billing\\:city').live("blur", function(event){
		$MMD_Simplifiedcheckout('#billing\\:city').blur(function(event){
			val=this.value;
			if(val!="" && val_citybill_before!=val){					
				if($MMD_Simplifiedcheckout('#billing\\:country_id').val())						
					updateShippingType();
			}
			//alert(val_citybill_before);
			val_citybill_before=val;
		});
	}
});