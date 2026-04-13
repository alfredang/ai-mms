var stripeExpress = {
    prButton: null,
    paymentRequest: null,
    canMakePaymentResult: null,

    /**
     * Place Order
     * @param result
     * @param callback
     */
    placeOrder: function (result, callback) {
        stripe.PRAPIEvent = result;
        stripe.closePaysheet('success');
        new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/place_order', {
                method: 'post',
                parameters: {
                    result: JSON.stringify(result)
                },
                onComplete: function (response)
                {
                    stripeExpress.processResponseWithPaymentIntent(response, function(err, response)
                    {
                        callback(err, response, result);
                    });
                }
            }
        );
    },

    /**
     * Add Item to Cart
     * @param request
     * @param shipping_id
     * @param callback
     */
    addToCart: function(request, shipping_id, callback) {
        new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/addtocart', {
                method: 'post',
                parameters: {
                    request: request,
                    shipping_id: shipping_id
                },
                onComplete: function (response)
                {
                    stripeExpress.processResponseWithPaymentIntent(response, callback);
                }
            }
        );
    },

    getShippingAddressFrom(prapiShippingAddress)
    {
        // For some countries like Japan, the PRAPI does not set the City, only the region
        if (prapiShippingAddress.city.length == 0 && prapiShippingAddress.region.length > 0)
            prapiShippingAddress.city = prapiShippingAddress.region;

        return prapiShippingAddress;
    },

    processResponseWithPaymentIntent: function(response, callback)
    {
        try
        {
            if (response.status != 200)
            {
                return callback("Sorry, an error has occurred. Please place your order through the checkout page.");
            }
            else if (response.responseJSON)
            {
                response = response.responseJSON;
            }
            else if (response.responseText)
            {
                response = JSON.parse(response.responseText);
            }

            if (response.message == "Authentication Required")
            {
                stripe.authenticateCustomer(function(err)
                {
                    if (err)
                        return callback(err, { message: err });

                    stripeExpress.placeOrder(stripe.PRAPIEvent, callback);
                });

                return;
            }

            if (typeof response.success != "undefined" && !response.success)
                return callback(response.message, response);

            if (typeof response.redirect != "undefined")
                return callback(null, response);

            if (response.paymentIntent)
                stripe.paymentIntent = response.paymentIntent;

            callback(null, response.results);
        }
        catch (e)
        {
            callback("Received invalid response from the Web API", response);
        }
    },

    /**
     * Estimate Shipping for Single Product
     * @param request
     * @param address
     * @param callback
     * @returns {*}
     */
    estimateShippingSingle: function (request, address, callback) {
        return new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/estimate_single', {
                method: 'post',
                parameters: {
                    request: JSON.stringify(request),
                    address: JSON.stringify(address)
                },
                onSuccess: function (response) {
                    stripeExpress.processResponseWithPaymentIntent(response, callback);
                }
            }
        );
    },

    /**
     * Estimate Shipping for Cart
     * @param address
     * @param callback
     * @returns {*}
     */
    estimateShippingCart: function (address, callback) {
        return new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/estimate_cart', {
                method: 'post',
                parameters: {
                    address: JSON.stringify(address)
                },
                onSuccess: function (response) {
                    stripeExpress.processResponseWithPaymentIntent(response, callback);
                }
            }
        );
    },

    setBillingAddress: function (data, callback) {
        return new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/set_billing_address', {
                method: 'post',
                parameters: {
                    data: JSON.stringify(data)
                },
                onComplete: function (response) {
                    stripeExpress.processResponseWithPaymentIntent(response, callback);
                }
            }
        );
    },

    /**
     * Apply Shipping and Return Totals
     * @param address
     * @param shipping_id
     * @param callback
     * @returns {*}
     */
    applyShipping: function(address, shipping_id, callback) {
        return new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/apply_shipping', {
                method: 'post',
                parameters: {
                    address: JSON.stringify(address),
                    shipping_id: shipping_id
                },
                onSuccess: function (response) {
                    stripeExpress.processResponseWithPaymentIntent(response, callback);
                }
            }
        );
    },

    /**
     * Apply Shipping and Return Totals (Single)
     * @param request
     * @param address
     * @param shipping_id
     * @param callback
     * @returns {*}
     */
    applyShippingSingle: function(request, address, shipping_id, callback) {
        return new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe/express/apply_shipping_single', {
                method: 'post',
                parameters: {
                    request: JSON.stringify(request),
                    address: JSON.stringify(address),
                    shipping_id: shipping_id
                },
                onSuccess: function (response) {
                    stripeExpress.processResponseWithPaymentIntent(response, callback);
                }
            }
        );
    },

    /**
     * Init Stripe Express
     * @param apiKey
     * @param params
     * @param settings
     * @param callback
     */
    initStripeExpress: function (apiKey, params, settings, callback)
    {
        stripe.securityMethod = 2;
        stripe.apiKey = apiKey;
        var self = this;

        if (stripe.stripeJsV3)
            this.onStripeJsLoaded(apiKey, params, settings, callback);
        else
        {
            stripe.loadStripeJsV3(function () {
                self.onStripeJsLoaded(apiKey, params, settings, callback);
            });
        }
    },

    onStripeJsLoaded: function(apiKey, params, settings, callback)
    {
        if (!stripe.stripeJsV3) {
            stripe.stripeJsV3 = Stripe(apiKey);
        }

        // Init Payment Request
        try {
            stripeExpress.paymentRequest = stripe.stripeJsV3.paymentRequest(params);
            var elements = stripe.stripeJsV3.elements();
            stripeExpress.prButton = elements.create('paymentRequestButton', {
                paymentRequest: stripeExpress.paymentRequest,
                style: {
                    paymentRequestButton: {
                        type: settings.type,
                        theme: settings.theme,
                        height: settings.height + 'px'
                    }
                }
            });
        } catch (e) {
            console.warn(e.message);
            return;
        }

        stripeExpress.paymentRequest.canMakePayment().then(function(result)
        {
            stripeExpress.canMakePaymentResult = result;
            if (result) {
                stripeExpress.prButton.mount('#payment-request-button');
                $$('.stripexpress-logo').invoke('show');
            } else {
                $('payment-request-button').hide();
                $$('.stripexpress-logo').invoke('hide');
            }
        });

        stripeExpress.prButton.on('ready', function () {
            callback(stripeExpress.paymentRequest, params, stripeExpress.prButton);
        });
    },

    /**
     * @param err - string
     * @param response - json-parsed object with the http response from Magento's place_order
     * @param result - object with the paymentRequest.on('token') result
     */
    onPlaceOrder: function(err, response, result)
    {
        if (err) {
            stripeExpress.showError(err);
        } else if (response.hasOwnProperty('redirect')) {
            window.location = response.redirect;
        }
    },

    // It seems that Magento does not have a working front-end validator for grouped products
    validateGroupedProduct: function(form)
    {
        var inputs = $$('#product_addtocart_form .input-text.qty')

        // Not a grouped product
        if (inputs.length < 2)
            return true;

        var qty = 0;
        for (var i = 0; i < inputs.length; i++)
        {
            var val = parseInt(inputs[i].value);
            if (!isNaN(val))
                qty += val;
        }

        return (qty > 0);
    },

    /**
     * Init Widget for Single Product Page
     * @param paymentRequest
     * @param params
     * @param prButton
     */
    initProductWidget: function (paymentRequest, params, prButton) {
        var request = [],
            shippingAddress = [],
            shippingMethod = null,
            self = this;

        prButton.on('click', function(ev) {
            var productAddToCartForm = new VarienForm('product_addtocart_form'),
                form = productAddToCartForm.form;

            if (!productAddToCartForm.validator.validate()) {
                ev.preventDefault();
                return;
            }

            if (!stripeExpress.validateGroupedProduct())
            {
                ev.preventDefault();
                alert("Please specify the quantity of product(s).");
                return;
            }

            // We don't want to preventDefault for applePay because we cannot use
            // paymentRequest.show() with applePay. Expecting Stripe to fix this.
            if (!stripeExpress.canMakePaymentResult.applePay)
                ev.preventDefault();

            request = form.serialize();

            $('payment-request-button').addClassName('disabled');

            stripeExpress.addToCart(request, shippingMethod, function (err, result) {
                $('payment-request-button').removeClassName('disabled');
                if (err) {
                    stripeExpress.showError(err);
                    return;
                }

                try
                {
                    stripeExpress.paymentRequest.update(result);
                    stripeExpress.paymentRequest.show();
                }
                catch (e)
                {
                    console.warn(e.message);
                }
            });
        });

        stripeExpress.paymentRequest.on('shippingaddresschange', function(ev) {
            var productAddToCartForm = new VarienForm('product_addtocart_form'),
                form = productAddToCartForm.form;

            if (!productAddToCartForm.validator.validate()) {
                return;
            }

            request = form.serialize(true);
            shippingAddress = stripeExpress.getShippingAddressFrom(ev.shippingAddress);
            stripeExpress.estimateShippingCart(shippingAddress, function (err, shippingOptions) {
                if (err) {
                    ev.updateWith({status: 'invalid_shipping_address'});
                    return;
                }

                if (shippingOptions.length < 1) {
                    ev.updateWith({status: 'invalid_shipping_address'});
                    return;
                }

                shippingMethod = null;
                if (shippingOptions.length > 0) {
                    // Apply first shipping method
                    var shippingOption = shippingOptions[0];
                    shippingMethod = shippingOption.hasOwnProperty('id') ? shippingOption.id : null;
                }

                stripeExpress.applyShipping(shippingAddress, shippingMethod, function (err, response) {
                    if (err) {
                        ev.updateWith({status: 'fail'});
                        return;
                    }

                    // Update order lines
                    var result = Object.assign({status: 'success', shippingOptions: shippingOptions}, response);
                    ev.updateWith(result);
                });
            });
        });

        stripeExpress.paymentRequest.on('shippingoptionchange', function(ev) {
            var productAddToCartForm = new VarienForm('product_addtocart_form'),
                form = productAddToCartForm.form;

            if (!productAddToCartForm.validator.validate()) {
                return;
            }

            request = form.serialize(true);
            shippingMethod = ev.shippingOption.hasOwnProperty('id') ? ev.shippingOption.id : null;
            stripeExpress.applyShipping(shippingAddress, shippingMethod, function (err, response) {
                if (err) {
                    ev.updateWith({status: 'fail'});
                    return;
                }

                // Update order lines
                var result = Object.assign({status: 'success'}, response);
                ev.updateWith(result);
            });
        });

        stripeExpress.paymentRequest.on('paymentmethod', function(result)
        {
            stripeExpress.onPaymentRequestPaymentMethod(result, prButton);
        });
    },

    onPaymentRequestPaymentMethod: function(result, paymentRequestButton)
    {
        stripe.PRAPIEvent = result;
        stripe.closePaysheet('success');

        $('payment-request-button').addClassName('disabled');
        stripeExpress.setBillingAddress(result.paymentMethod.billing_details, function(err, response)
        {
            $('payment-request-button').removeClassName('disabled');
            if (err) {
                stripeExpress.showError(err);
                return;
            }

            stripeExpress.onPaymentPlaced(result, paymentRequestButton);
        });
    },

    showError: function(message)
    {
        if (stripe.PRAPIEvent)
            stripe.closePaysheet('success'); // Simply hide the modal

        setTimeout(function(){
            alert(message);
        }, 300);
    },

    onPaymentPlaced: function(result, paymentRequestButton)
    {
        $('payment-request-button').addClassName('disabled');
        result.shippingAddress = stripeExpress.getShippingAddressFrom(result.shippingAddress);
        stripeExpress.placeOrder(result, function (err, response, result)
        {
            $('payment-request-button').removeClassName('disabled');
            stripe.closePaysheet('success');
            if (err)
                stripeExpress.showError(err);
            else if (response.hasOwnProperty('redirect'))
                window.location = response.redirect;
        });
    },

    /**
     * Init Widget for Cart Page
     * @param paymentRequest
     * @param params
     * @param prButton
     */
    initCartWidget: function (paymentRequest, params, prButton) {
        var shippingAddress = [],
            shippingMethod = null,
            self = this;

        stripeExpress.paymentRequest.on('shippingaddresschange', function(ev) {
            shippingAddress = stripeExpress.getShippingAddressFrom(ev.shippingAddress);
            stripeExpress.estimateShippingCart(shippingAddress, function (err, shippingOptions) {
                if (err) {
                    ev.updateWith({status: 'invalid_shipping_address'});
                    return;
                }

                if (shippingOptions.length < 1) {
                    ev.updateWith({status: 'invalid_shipping_address'});
                    return;
                }

                shippingMethod = null;
                if (shippingOptions.length > 0) {
                    // Apply first shipping method
                    var shippingOption = shippingOptions[0];
                    shippingMethod = shippingOption.hasOwnProperty('id') ? shippingOption.id : null;
                }

                stripeExpress.applyShipping(shippingAddress, shippingMethod, function (err, response) {
                    if (err) {
                        ev.updateWith({status: 'fail'});
                        return;
                    }

                    // Update order lines
                    var result = Object.assign({status: 'success', shippingOptions: shippingOptions}, response);
                    ev.updateWith(result);
                });
            });
        });

        stripeExpress.paymentRequest.on('shippingoptionchange', function(ev) {
            var shippingMethod = ev.shippingOption.hasOwnProperty('id') ? ev.shippingOption.id : null;
            stripeExpress.applyShipping(shippingAddress, shippingMethod, function (err, response) {
                if (err) {
                    ev.updateWith({status: 'fail'});
                    return;
                }

                // Update order lines
                var result = Object.assign({status: 'success'}, response);
                ev.updateWith(result);
            });
        });

        stripeExpress.paymentRequest.on('paymentmethod', function(result)
        {
            stripeExpress.onPaymentRequestPaymentMethod(result, prButton);
        });
    }
};
