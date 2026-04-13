/**
 * 
 */
$MMD_Simplifiedcheckout(function(){

	if(zip_load()){	
				var val_zipship_before=$MMD_Simplifiedcheckout('#shipping\\:postcode').val();
				$MMD_Simplifiedcheckout('#shipping\\:postcode').blur(function(event){
					val=this.value;
					if(val!="" && val_zipship_before!=val){					
						if($MMD_Simplifiedcheckout('#shipping\\:country_id').val())						
							updateShippingType();
					}
					val_zipship_before=val;
				});
			}
	
	if(region_load()){
		var val_regionship_before=$MMD_Simplifiedcheckout('#shipping\\:region').val();
		$MMD_Simplifiedcheckout('#shipping\\:region').blur(function(event){
			val=this.value;
			if(val!="" && val_regionship_before!=val){					
				if($MMD_Simplifiedcheckout('#shipping\\:country_id').val())						
					updateShippingType();
			}
			val_regionship_before=val;
		});
	}
	
	if(city_load()){
		var val_cityship_before=$MMD_Simplifiedcheckout('#shipping\\:city').val();
		$MMD_Simplifiedcheckout('#shipping\\:city').blur(function(event){
			val=this.value;
			if(val!="" && val_cityship_before!=val){					
				if($MMD_Simplifiedcheckout('#shipping\\:country_id').val())						
					updateShippingType();
			}
			val_cityship_before=val;
		});	
	}
	
	

});