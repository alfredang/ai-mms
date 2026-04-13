
let isStatusReceived = false;
$jHitpay = jQuery.noConflict();
$jHitpay(document).ready(function(){
    
   checkHitpayPaymentStatus();
   
   function checkHitpayPaymentStatus() {

        function statusLoop() {
            if (isStatusReceived) {
                return;
            }

            if (typeof(status_ajax_url) !== "undefined") {
                $jHitpay.getJSON(status_ajax_url, {'payment_id' : hitpay_payment_id, 'order_id' : hitpay_order_id}, function (data) {
                    if (data.status == 'wait') {
                        setTimeout(statusLoop, 2000);
                    } else if (data.status == 'error') {
                        $jHitpay('.payment_pending').hide();
                        $jHitpay('.payment_error').show();
                        isStatusReceived = true;
                    } else if (data.status == 'pending') {
                        $jHitpay('.payment_pending').hide();
                        $jHitpay('.payment_status_pending').show();
                        isStatusReceived = true;
                        setTimeout(function(){window.location.href = data.redirect;}, 5000);
                    } else if (data.status == 'failed') {
                        $jHitpay('.payment_pending').hide();
                        $jHitpay('.payment_status_failed').show();
                        isStatusReceived = true;
                        setTimeout(function(){window.location.href = data.redirect;}, 5000);
                    } else if (data.status == 'completed') {
                        $jHitpay('.payment_pending').hide();
                        $jHitpay('.payment_status_complete').show();
                        isStatusReceived = true;
                        setTimeout(function(){window.location.href = data.redirect;}, 5000);
                    }
                });
            }
        }
        statusLoop();
    }
});
