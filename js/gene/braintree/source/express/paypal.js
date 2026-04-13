var BraintreePayPalExpress = Class.create(BraintreeExpressAbstract, {
    vzeroPayPal: false,

    /**
     * Init the PayPal button class
     *
     * @private
     */
    _init: function () {
        this.vzeroPayPal = new vZeroPayPalButton(
            false,
            '',
            false, /* Vault flow forced as the final amount can change */
            this.config.locale,
            false,
            false,
            this.urls.clientTokenUrl
        );
    },

    /**
     * Attach the PayPal instance to the buttons
     *
     * @param buttons
     */
    attachToButtons: function (buttons) {
        var options = {
            validate: this.validateForm,
            onSuccess: function (payload) {

                var params = {
                    paypal: JSON.stringify(payload)
                };
                if (typeof this.config.productId !== 'undefined') {
                    params.product_id = this.config.productId;
                    params.form_data = $('product_addtocart_form') ? $('product_addtocart_form').serialize() : $('pp_express_form').serialize();
                }

                this.initModal(params);
            }.bind(this),
            tokenizeRequest: {
                enableShippingAddress: true /* Request shipping address from customer */
            }
        };

        // Add a class to the parents of the buttons
        buttons.each(function (button) {
            button.up().addClassName('braintree-paypal-express-container');
        });

        // Initialize the PayPal button logic on any valid buttons on the page
        this.vzeroPayPal.attachPayPalButtonEvent(buttons, options);
    }

});