var stripeTokens = {};

var initStripe = function(apiKey, securityMethod, callback)
{
    if (typeof callback == "undefined")
        callback = function() {};

    stripe.securityMethod = securityMethod;
    stripe.apiKey = apiKey;
    stripe.onStripeInitCallback = callback;

    if (stripe.securityMethod == 1)
        stripe.loadStripeJsV2(stripe.onLoadStripeJsV2);

    // We always load v3 so that we use Payment Intents
    stripe.loadStripeJsV3(stripe.onLoadStripeJsV3);

    // Disable server side card validation when Stripe.js is enabled
    if (typeof AdminOrder != 'undefined' && AdminOrder.prototype.loadArea && typeof AdminOrder.prototype._loadArea == 'undefined')
    {
        AdminOrder.prototype._loadArea = AdminOrder.prototype.loadArea;
        AdminOrder.prototype.loadArea = function(area, indicator, params)
        {
            if (typeof area == "object" && area.indexOf('card_validation') >= 0)
                area = area.splice(area.indexOf('card_validation'), 0);

            if (area.length > 0)
                this._loadArea(area, indicator, params);
        };
    }

    // Integrate Stripe.js with various One Step Checkout modules
    initOSCModules();
    stripe.onWindowLoaded(initOSCModules); // Run it again after the page has loaded in case we missed an ajax based OSC module

    // Integrate Stripe.js with the multi-shipping payment form
    stripe.onWindowLoaded(initMultiShippingForm);

    // Errors at the checkout review step should send the customer back to the payment section
    stripe.initReviewStepErrors();
    stripe.onWindowLoaded(stripe.initReviewStepErrors); // For OSC modules

    // Integrate Stripe.js with the admin area
    stripe.onWindowLoaded(initAdmin); // Needed when refreshing the browser
    initAdmin(); // Needed when the payment method is loaded through an ajax call after adding the shipping address
};

var stripe = {
    version: '1.1.7',

    // Properties
    billingInfo: null,
    multiShippingFormInitialized: false,
    oscInitialized: false,
    applePayButton: null,
    applePaySuccess: false,
    applePayResponse: null,
    securityMethod: 0,
    card: null,
    paymentFormValidator: null,
    stripeJsV2: null,
    stripeJsV3: null,
    apiKey: null,
    sourceId: null,
    iconsContainer: null,
    paymentIntent: null,
    paymentIntents: [],
    isAdmin: false,
    PRAPIEvent: null,
    isDynamicCustomerAuthenticationInitialized: false,
    isAlertProxyInitialized: false,
    is3DSecureOpen: false,
    onStripeInitCallback: function() {},

    // Methods
    placeOrder: function() {}, // Will be overwritten dynamically
    shouldLoadStripeJsV2: function()
    {
        return (stripe.securityMethod == 1 || (stripe.securityMethod == 2 && stripe.isApplePayEnabled()));
    },
    loadStripeJsV2: function(callback)
    {
        if (!stripe.shouldLoadStripeJsV2())
            return callback();

        var script = document.getElementsByTagName('script')[0];
        var stripeJsV2 = document.createElement('script');
        stripeJsV2.src = "https://js.stripe.com/v2/";
        stripeJsV2.onload = function()
        {
            stripe.onLoadStripeJsV2();
            callback();
        };
        stripeJsV2.onerror = function(evt) {
            console.warn("Stripe.js v2 could not be loaded");
            console.error(evt);
            callback();
        };
        script.parentNode.insertBefore(stripeJsV2, script);
    },
    loadStripeJsV3: function(callback)
    {
        var script = document.getElementsByTagName('script')[0];
        var stripeJsV3 = document.createElement('script');
        stripeJsV3.src = "https://js.stripe.com/v3/";
        stripeJsV3.onload = function()
        {
            stripe.onLoadStripeJsV3();
            if (typeof callback === 'function') {
                callback();
            }
        };
        stripeJsV3.onerror = function(evt) {
            console.warn("Stripe.js v3 could not be loaded");
            console.error(evt);
        };
        // Do this on the next cycle so that stripe.onLoadStripeJsV2() finishes first
        script.parentNode.insertBefore(stripeJsV3, script);
    },
    onLoadStripeJsV2: function()
    {
        if (!stripe.stripeJsV2)
        {
            Stripe.setPublishableKey(stripe.apiKey);
            stripe.stripeJsV2 = Stripe;
        }
    },
    onLoadStripeJsV3: function()
    {
        if (!stripe.stripeJsV3)
        {
            var params = {
                betas: ['payment_intent_beta_3']
            };
            stripe.stripeJsV3 = Stripe(stripe.apiKey, params);
        }

        stripe.initLoadedStripeJsV3();
    },
    initLoadedStripeJsV3: function()
    {
        stripe.initStripeElements();
        stripe.onWindowLoaded(stripe.initStripeElements);

        stripe.initPaymentRequestButton();
        stripe.onWindowLoaded(stripe.initPaymentRequestButton);

        stripe.onStripeInitCallback();
    },
    onWindowLoaded: function(callback)
    {
        if (window.attachEvent)
            window.attachEvent("onload", callback); // IE
        else
            window.addEventListener("load", callback); // Other browsers
    },
    initReviewStepErrors: function()
    {
        if (typeof Review == 'undefined' || typeof Review.prototype.nextStep == 'undefined')
            return;

        Review.prototype._nextStep = Review.prototype.nextStep;

        var nextStep = Review.prototype.nextStep;
        Review.prototype.nextStep = function(transport)
        {
            if (stripe.oscInitialized)
                return this._nextStep(transport);

            if (transport) {
                var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};

                if (response.redirect) {
                    this.isSuccess = true;
                    location.href = encodeURI(response.redirect);
                    return;
                }
                if (response.success) {
                    this.isSuccess = true;
                    location.href = encodeURI(this.successUrl);
                }
                else{
                    var msg = response.error_messages;
                    if (Object.isArray(msg)) {
                        msg = msg.join("\n").stripTags().toString();
                    }
                    if (msg) {
                        stripe.displayReviewStepError(msg);
                    }
                }

                if (response.update_section) {
                    $('checkout-'+response.update_section.name+'-load').update(response.update_section.html);
                }

                if (response.goto_section) {
                    checkout.gotoSection(response.goto_section, true);
                }
            }
        };
        if (typeof review != 'undefined')
        {
            review.nextStep = Review.prototype.nextStep;
            review._nextStep = Review.prototype._nextStep;
        }
    },
    displayReviewStepError: function(msg)
    {
        if (msg.indexOf("reusable source you provided is consumed") >= 0)
        {
            alert("Your card was declined");
            stripe.displayCardError("Your card was declined", true);
            deleteStripeToken();
        }
        else if (msg.indexOf("card was declined") >= 0)
        {
            alert(msg);
            stripe.displayCardError(msg, true);
            deleteStripeToken();
        }
        else
            alert(msg);
    },
    validatePaymentForm: function(callback)
    {
        if (!this.paymentFormValidator)
            this.paymentFormValidator = new Validation('payment_form_stripe_payments');

        if (!this.paymentFormValidator.form)
            this.paymentFormValidator = new Validation('new-card');

        if (!this.paymentFormValidator.form)
            return true;

        this.paymentFormValidator.reset();

        result = this.paymentFormValidator.validate();

        // The Magento validator will try to pass over injected Stripe Elements, so to exclude those,
        // check if any of the form elements have a validation-failed class
        if (!result)
        {
            var failedElements = Form.getElements('payment_form_stripe_payments').findAll(function(elm){
                return $(elm).hasClassName('validation-failed');
            });
            if (failedElements.length === 0)
                return true;
        }

        return result;
    },
    placeAdminOrder: function(e)
    {
        var radioButton = document.getElementById('p_method_stripe_payments');
        if (radioButton && !radioButton.checked)
            return order.submit();

        createStripeToken(function(err)
        {
            if (err)
                alert(err);
            else
                order.submit();
        });
    },
    addAVSFieldsTo: function(cardDetails)
    {
        var owner = stripe.getSourceOwner();
        cardDetails.name = owner.name;
        cardDetails.address_line1 = owner.address.line1;
        cardDetails.address_line2 = owner.address.line2;
        cardDetails.address_zip = owner.address.postal_code;
        cardDetails.address_city = owner.address.city;
        cardDetails.address_state = owner.address.state;
        cardDetails.address_country = owner.address.country;
        return cardDetails;
    },
    getSourceOwner: function()
    {
        // Format is
        var owner = {
            name: null,
            email: null,
            phone: null,
            address: {
                city: null,
                country: null,
                line1: null,
                line2: null,
                postal_code: null,
                state: null
            }
        };

        // If there is an address select dropdown, don't read the address from the input fields in case
        // the customer changes the address from the dropdown. Dropdown value changes do not update the
        // plain input fields
        if (!document.getElementById('billing-address-select'))
        {
            // Scenario 1: We are in the admin area creating an order for a guest who has no saved address yet
            var line1 = document.getElementById('order-billing_address_street0');
            var postcode = document.getElementById('order-billing_address_postcode');
            var email = document.getElementById('order-billing_address_email');

            // Scenario 2: Checkout page with an OSC module and a guest customer
            if (!line1)
                line1 = document.getElementById('billing:street1');

            if (!postcode)
                postcode = document.getElementById('billing:postcode');

            if (!email)
                email = document.getElementById('billing:email');

            if (line1)
                owner.address.line1 = line1.value;

            if (postcode)
                owner.address.postal_code = postcode.value;

            if (email)
                owner.email = email.value;

            // New fields
            if (document.getElementById('billing:firstname'))
                owner.name = document.getElementById('billing:firstname').value + ' ' + document.getElementById('billing:lastname').value;

            if (document.getElementById('billing:telephone'))
                owner.phone = document.getElementById('billing:telephone').value;

            if (document.getElementById('billing:city'))
                owner.address.city = document.getElementById('billing:city').value;

            if (document.getElementById('billing:country_id'))
                owner.address.country = document.getElementById('billing:country_id').value;

            if (document.getElementById('billing:street2'))
                owner.address.line2 = document.getElementById('billing:street2').value;

            if (document.getElementById('billing:region'))
                owner.address.state = document.getElementById('billing:region').value;
        }

        // Scenario 3: Checkout or admin area and a registered customer already has a pre-loaded billing address
        if (stripe.billingInfo !== null)
        {
            if (owner.email === null && stripe.billingInfo.email !== null)
                owner.email = stripe.billingInfo.email;

            if (owner.address.line1 === null && stripe.billingInfo.line1 !== null)
                owner.address.line1 = stripe.billingInfo.line1;

            if (owner.address.postal_code === null && stripe.billingInfo.postcode !== null)
                owner.address.postal_code = stripe.billingInfo.postcode;

            // New fields
            if (owner.name === null && stripe.billingInfo.name !== null)
                owner.name = stripe.billingInfo.name;

            if (owner.phone === null && stripe.billingInfo.phone !== null)
                owner.phone = stripe.billingInfo.phone;

            if (owner.address.city === null && stripe.billingInfo.city !== null)
                owner.address.city = stripe.billingInfo.city;

            if (owner.address.country === null && stripe.billingInfo.country !== null)
                owner.address.country = stripe.billingInfo.country;

            if (owner.address.line2 === null && stripe.billingInfo.line2 !== null)
                owner.address.line2 = stripe.billingInfo.line2;

            if (owner.address.state === null && stripe.billingInfo.state !== null)
                owner.address.state = stripe.billingInfo.state;
        }

        if (!owner.phone)
            delete owner.phone;

        return owner;
    },
    displayCardError: function(message, inline)
    {
        // Some OSC modules have the Place Order button away from the payment form
        if (stripe.oscInitialized && typeof inline == 'undefined')
        {
            alert(message);
            return;
        }

        // When we use a saved card, display the message as an alert
        var newCardRadio = document.getElementById('new_card');
        if (newCardRadio && !newCardRadio.checked)
        {
            alert(message);
            return;
        }

        var box = $('stripe-payments-card-errors');

        if (box)
        {
            try
            {
                checkout.gotoSection("payment");
            }
            catch (e) {}

            box.update(message);
            box.addClassName('populated');
        }
        else
            alert(message);
    },
    clearCardErrors: function()
    {
        var box = $('stripe-payments-card-errors');

        if (box)
        {
            box.update("");
            box.removeClassName('populated');
        }
    },
    isApplePayEnabled: function()
    {
        // Some OSC modules will refuse to reload the payment method when the billing address is changed for a customer.
        // We can't use Apple Pay without a billing address
        if (typeof paramsApplePay == "undefined" || !paramsApplePay)
            return false;

        return true;
    },
    hasNoCountryCode: function()
    {
        return (typeof paramsApplePay.country == "undefined" || !paramsApplePay.country || paramsApplePay.country.length === 0);
    },
    getCountryElement: function()
    {
        var element = document.getElementById('billing:country_id');

        if (!element)
            element = document.getElementById('billing_country_id');

        if (!element)
        {
            var selects = document.getElementsByName('billing[country_id]');
            if (selects.length > 0)
                element = selects[0];
        }

        return element;
    },
    getCountryCode: function()
    {
        var element = stripe.getCountryElement();

        if (!element)
            return null;

        if (element.value && element.value.length > 0)
            return element.value;

        return null;
    },
    initResetButton: function()
    {
        var resetButton = document.getElementById('apple-pay-reset');
        resetButton.addEventListener('click', resetApplePayToken);
        resetButton.disabled = false;
    },
    getStripeElementsStyle: function()
    {
        // Custom styling can be passed to options when creating an Element.
        return {
            base: {
                // Add your base input styles here. For example:
                fontSize: '16px',
                lineHeight: '24px'
                // iconColor: '#c4f0ff',
                // color: '#31325F'
        //         fontWeight: 300,
        //         fontFamily: '"Helvetica Neue", Helvetica, sans-serif',

        //         '::placeholder': {
        //             color: '#CFD7E0'
        //         }
            }
        };
    },
    getStripeElementCardNumberOptions: function()
    {
        return {
            // iconStyle: 'solid',
            // hideIcon: false,
            style: stripe.getStripeElementsStyle()
        };
    },
    getStripeElementCardExpiryOptions: function()
    {
        return {
            style: stripe.getStripeElementsStyle()
        };
    },
    getStripeElementCardCvcOptions: function()
    {
        return {
            style: stripe.getStripeElementsStyle()
        };
    },
    getStripeElementsOptions: function()
    {
        return {
            locale: 'auto'
        };
    },
    initStripeElements: function()
    {
        if (stripe.securityMethod != 2)
            return;

        if (document.getElementById('stripe-payments-card-number') === null)
            return;

        var elements = stripe.stripeJsV3.elements(stripe.getStripeElementsOptions());

        var cardNumber = stripe.card = elements.create('cardNumber', stripe.getStripeElementCardNumberOptions());
        cardNumber.mount('#stripe-payments-card-number');
        cardNumber.addEventListener('change', stripe.stripeElementsOnChange);

        var cardExpiry = elements.create('cardExpiry', stripe.getStripeElementCardExpiryOptions());
        cardExpiry.mount('#stripe-payments-card-expiry');
        cardExpiry.addEventListener('change', stripe.stripeElementsOnChange);

        var cardCvc = elements.create('cardCvc', stripe.getStripeElementCardCvcOptions());
        cardCvc.mount('#stripe-payments-card-cvc');
        cardCvc.addEventListener('change', stripe.stripeElementsOnChange);
    },
    stripeElementsOnChange: function(event)
    {
        if (typeof event.brand != 'undefined')
            stripe.onCardNumberChanged(event.brand);

        if (event.error)
            stripe.displayCardError(event.error.message, true);
        else
            stripe.clearCardErrors();
    },
    onCardNumberChanged: function(cardType)
    {
        stripe.onCardNumberChangedFade(cardType);
        stripe.onCardNumberChangedSwapIcon(cardType);
    },
    resetIconsFade: function()
    {
        stripe.iconsContainer.className = 'input-box';
        var children = stripe.iconsContainer.getElementsByTagName('img');
        for (var i = 0; i < children.length; i++)
            children[i].className = '';
    },
    onCardNumberChangedFade: function(cardType)
    {
        if (!stripe.iconsContainer)
            stripe.iconsContainer = document.getElementById('stripe-payments-accepted-cards');

        if (!stripe.iconsContainer)
            return;

        stripe.resetIconsFade();

        if (!cardType || cardType == "unknown") return;

        var img = document.getElementById('stripe_payments_' + cardType + '_type');
        if (!img) return;

        img.className = 'active';
        stripe.iconsContainer.className = 'input-box stripe-payments-detected';
    },
    cardBrandToPfClass: {
        'visa': 'pf-visa',
        'mastercard': 'pf-mastercard',
        'amex': 'pf-american-express',
        'discover': 'pf-discover',
        'diners': 'pf-diners',
        'jcb': 'pf-jcb',
        'unknown': 'pf-credit-card',
    },
    onCardNumberChangedSwapIcon: function(cardType)
    {
        var brandIconElement = document.getElementById('stripe-payments-brand-icon');
        var pfClass = 'pf-credit-card';
        if (cardType in stripe.cardBrandToPfClass)
            pfClass = stripe.cardBrandToPfClass[cardType];

        for (var i = brandIconElement.classList.length - 1; i >= 0; i--)
            brandIconElement.classList.remove(brandIconElement.classList[i]);

        brandIconElement.classList.add('pf');
        brandIconElement.classList.add(pfClass);
    },
    initPaymentRequestButton: function()
    {
        if (!stripe.isApplePayEnabled())
            return;

        if (stripe.hasNoCountryCode())
            paramsApplePay.country = stripe.getCountryCode();

        if (stripe.hasNoCountryCode())
            return;

        var paymentRequest;
        try
        {
            paymentRequest = stripe.stripeJsV3.paymentRequest(paramsApplePay);
            var elements = stripe.stripeJsV3.elements();
            var prButton = elements.create('paymentRequestButton', {
                paymentRequest: paymentRequest,
            });
        }
        catch (e)
        {
            console.warn(e.message);
            return;
        }

        // Check the availability of the Payment Request API first.
        paymentRequest.canMakePayment().then(function(result)
        {
            if (result)
            {
                if (!document.getElementById('payment-request-button'))
                    return;

                prButton.mount('#payment-request-button');
                $('payment_form_stripe_payments').addClassName('payment-request-api-supported');
                if ($('co-payment-form'))
                    $('co-payment-form').addClassName('payment-request-api-supported');
                stripe.initResetButton();
            }
        });

        paymentRequest.on('paymentmethod', function(result)
        {
            try
            {
                stripe.PRAPIEvent = result;
                setStripeToken(result.paymentMethod.id + ':' + result.paymentMethod.card.brand + ':' + result.paymentMethod.card.last4);
                setApplePayToken(result.paymentMethod);
                stripe.closePaysheet('success');
            }
            catch (e)
            {
                stripe.closePaysheet('fail');
                console.error(e);
            }
        });
    },
    isPaymentMethodSelected: function()
    {
        if (typeof payment != 'undefined' && typeof payment.currentMethod != 'undefined' && payment.currentMethod.length > 0)
            return (payment.currentMethod == 'stripe_payments');
        else
        {
            var radioButton = document.getElementById('p_method_stripe_payments');
            if (!radioButton || !radioButton.checked)
                return false;

            return true;
        }
    },
    selectMandate: function()
    {
        document.getElementById('stripe_payments_sepa_iban').classList.remove("required-entry");
    },
    selectNewIBAN: function()
    {
        document.getElementById('new_mandate').checked = 1;
        document.getElementById('stripe_payments_sepa_iban').classList.add("required-entry");
    },
    setLoadWaiting: function(section)
    {
        // Check if defined first in case of an OSC module rewriting the whole thing
        if (typeof checkout != 'undefined' && checkout && checkout.setLoadWaiting)
        {
            try
            {
                // OSC modules may also cause crashes if they have stripped away the html elements
                checkout.setLoadWaiting(section);
            }
            catch (e) {}
        }
        else
            stripe.toggleAdminSave(section);
    },
    // Triggered when the user clicks a saved card radio button
    useCard: function()
    {
        var token = stripe.getSelectedSavedCard();

        // User wants to use a new card
        if (token == null)
        {
            enablePaymentFormValidation();
            deleteStripeToken();
            stripe.sourceId = null;
        }
        // User wants to use a saved card
        else
        {
            disablePaymentFormValidation();
            setStripeToken(token);
            stripe.sourceId = stripe.cleanToken(token);
        }
    },
    getSelectedSavedCard: function()
    {
        var elements = document.getElementsByName("payment[cc_saved]");
        if (elements.length == 0)
            return null;
        var selected = null;
        for (var i = 0; i < elements.length; i++)
            if (elements[i].checked)
                selected = elements[i];
        if (!selected)
            return null;
        if (selected.value == 'new_card')
            return null;
        return selected.value;
    },
    // Converts tokens in the form "src_1E8UX32WmagXEVq4SpUlSuoa:Visa:4242" into src_1E8UX32WmagXEVq4SpUlSuoa
    cleanToken: function(token)
    {
        if (token.indexOf(":") >= 0)
            return token.substring(0, token.indexOf(":"));
        return token;
    },
    shouldSaveCard: function()
    {
        var saveCardInput = document.getElementById('stripe_payments_cc_save');
        if (!saveCardInput)
            return false;
        return saveCardInput.checked;
    },
    getPaymentIntent: function(callback)
    {
        new Ajax.Request(
            MAGENTO_BASE_URL + 'stripe_payments/api/get_payment_intent', {
                method: 'post',
                onComplete: function (response)
                {
                    try
                    {
                        callback(null, response.responseJSON.paymentIntent);
                    }
                    catch (e)
                    {
                        callback("Could not retrieve payment details, please contact us for help");
                        console.error(response);
                    }
                }
            }
        );
    },
    handleCardPayment: function(done)
    {
        try
        {
            stripe.closePaysheet('success');

            stripe.stripeJsV3.handleCardPayment(stripe.paymentIntent).then(function(result)
            {
                if (result.error)
                    return done(result.error.message);

                return done();
            });
        }
        catch (e)
        {
            done(e.message);
        }
    },
    handleCardAction: function(done)
    {
        try
        {
            stripe.closePaysheet('success');

            stripe.stripeJsV3.handleCardAction(stripe.paymentIntent).then(function(result)
            {
                if (result.error)
                    return done(result.error.message);

                return done();
            });
        }
        catch (e)
        {
            done(e.message);
        }
    },
    processNextAuthentication: function(done)
    {
        if (stripe.paymentIntents.length > 0)
        {
            stripe.paymentIntent = stripe.paymentIntents.pop();
            stripe.authenticateCustomer(function(err)
            {
                if (err)
                    done(err);
                else
                    stripe.processNextAuthentication(done);
            });
        }
        else
        {
            stripe.paymentIntent = null;
            return done();
        }
    },
    authenticateCustomer: function(done)
    {
        try
        {
            stripe.stripeJsV3.retrievePaymentIntent(stripe.paymentIntent).then(function(result)
            {
                if (result.error)
                    return done(result.error);

                if (result.paymentIntent.status == "requires_action"
                    || result.paymentIntent.status == "requires_source_action")
                {
                    if (result.paymentIntent.confirmation_method == "manual")
                        return stripe.handleCardAction(done);
                    else
                        return stripe.handleCardPayment(done);
                }

                return done();
            });
        }
        catch (e)
        {
            done(e.message);
        }
    },
    isNextAction3DSecureRedirect: function(result)
    {
        if (!result)
            return false;

        if (typeof result.paymentIntent == 'undefined' || !result.paymentIntent)
            return false;

        if (typeof result.paymentIntent.next_action == 'undefined' || !result.paymentIntent.next_action)
            return false;

        if (typeof result.paymentIntent.next_action.use_stripe_sdk == 'undefined' || !result.paymentIntent.next_action.use_stripe_sdk)
            return false;

        if (typeof result.paymentIntent.next_action.use_stripe_sdk.type == 'undefined' || !result.paymentIntent.next_action.use_stripe_sdk.type)
            return false;

        return (result.paymentIntent.next_action.use_stripe_sdk.type == 'three_d_secure_redirect');
    },
    paymentIntentCanBeConfirmed: function()
    {
        // If stripe.sourceId exists, it means that we are using a saved card source, which is not going to be a 3DS card
        // (because those are hidden from the admin saved cards section)
        return !stripe.sourceId;
    },
    maskError: function(err)
    {
        var errLowercase = err.toLowerCase();
        var pos1 = errLowercase.indexOf("Invalid API key provided".toLowerCase());
        var pos2 = errLowercase.indexOf("No API key provided".toLowerCase());
        if (pos1 === 0 || pos2 === 0)
            return 'Invalid Stripe API key provided.';

        return err;
    },
    closePaysheet: function(withResult)
    {
        try
        {
            if (!stripe.PRAPIEvent)
                return;

            stripe.PRAPIEvent.complete(withResult);
        }
        catch (e)
        {
            // Will get here if we already closed it
        }
    },
    isApplePayInsideForm: function()
    {
        return stripe.applePayLocation == 2;
    },
    triggerCustomerAuthentication: function()
    {
        if (stripe.is3DSecureOpen)
            return;

        stripe.agreeToTerms();
        stripe.is3DSecureOpen = true;
        stripe.authenticateCustomer(function(err)
        {
            stripe.is3DSecureOpen = false;

            if (err)
                return stripe.displayCardError(err);

            stripe.placeOrder();
        });
    },
    agreeToTerms: function()
    {
        // Some OSC modules such as LotusBreath and Idev OSC reload the page when customer authentication is required
        // causing the terms and agreements checkboxes to lose their value. We re-agree here so that we can resubmit the form.
        var agreements = $$(".checkout-agreements input[type=checkbox]");
        for (var i = 0; i < agreements.length; i++)
            agreements[i].checked = true;
    },
    parseErrorMessage: function(msg)
    {
        stripe.paymentIntent = null;

        if (msg == "Authentication Required")
            return true;

        // Case of subscriptions
        if (msg.indexOf("Authentication Required: ") === 0)
        {
            stripe.paymentIntent = msg.substring("Authentication Required: ".length);
            return true;
        }
        // FME QuickCheckout prefers to inform us that this is a core exception...
        else if (msg.indexOf("Core Exception: Authentication Required: ") === 0)
        {
            stripe.paymentIntent = msg.substring("Core Exception: Authentication Required: ".length);
            return true;
        }

        return false;
    },
    isAuthenticationRequired: function(msgs)
    {
        if (typeof msgs == "undefined")
            return false;

        if (typeof msgs[0] == "string")
        {
            var multipleMsgs = msgs[0].split(/\n/);
            if (multipleMsgs.length > 0)
            {
                for (var i = 0; i < multipleMsgs.length; i++)
                    if (stripe.parseErrorMessage(multipleMsgs[i]))
                        return true;
            }
        }

        return false;
    },
    initAlertProxy: function(authenticationMethod)
    {
        if (stripe.isAlertProxyInitialized)
            return;

        stripe.isAlertProxyInitialized = true;

        (function(proxied)
        {
            window.alert = function()
            {
                if (stripe.isAuthenticationRequired(arguments))
                {
                    authenticationMethod();
                }
                else
                    return proxied.apply(this, arguments);
            };
        })
        (window.alert);
    },
    searchForAuthenticationRequiredError: function(authenticationMethod)
    {
        // Some OSC modules will not alert the error, they will instead redirect to the same page and add the error in a DOM element.
        // Here we handle those cases
        var errors = $$('.onestepcheckout-error')
            .concat($$('.error-msg li'))
            .concat($$('.error-msg span'))
            .concat($$('.opc-message-container'))
            .concat($$('#saveOder-error'));

        for (var i = 0; i < errors.length; i++)
        {
            if (!errors[i])
                continue;

            if (stripe.parseErrorMessage(errors[i].innerText))
            {
                errors.each(Element.hide);
                $$('ul.messages').each(Element.hide);
                authenticationMethod();
                break;
            }
        }
    },
    toggleAdminSave: function(disable)
    {
        if (typeof disableElements != 'undefined' && typeof enableElements != 'undefined')
        {
            if (disable)
                disableElements('save');
            else
                enableElements('save');
        }
    },
    ach:
    {
        token: null,
        verificationError: 'Could not verify bank account details!',

        getParams: function()
        {
            var routingNumber = $('stripe-ach-routing_number').value;
            var accountNumber = $('stripe-ach-account_number').value;
            var accountHolderName = $('stripe-ach-account_holder_name').value;
            var accountHolderType = $('stripe-ach-account_holder_type').value;
            var country = $('stripe-ach-country').value;
            var currency = $('stripe-ach-currency').value;

            if (routingNumber.length === 0 ||
                accountNumber.length === 0 ||
                accountHolderName.length === 0 ||
                accountHolderType.length === 0)
            {
                stripe.ach.verificationError = 'Please enter your account details';
                return false;
            }

            if (country.length === 0 ||
                currency.length === 0)
            {
                stripe.ach.verificationError = 'Your country or currency could not be determined';
                return false;
            }

            return {
              country: country,
              currency: currency,
              routing_number: routingNumber,
              account_number: accountNumber,
              account_holder_name: accountHolderName,
              account_holder_type: accountHolderType,
            };
        },
        generateToken: function()
        {
            var params = stripe.ach.getParams();

            if (!params)
                return;

            if (params.routing_number.length < 9)
                return;

            if (params.account_number.length < 4)
                return;

            if (!stripe.stripeJsV3)
            {
                stripe.ach.verificationError = 'Could not verify bank details because the Stripe.js v3 security method has not been enabled';
                return;
            }

            stripe.ach.hideErrors();

            stripe.stripeJsV3.createToken('bank_account', params).then(function(result)
            {
                if (result.token)
                    stripe.ach.setToken(result.token.id, result.token.bank_account);
                else
                {
                    if (result.error)
                        stripe.ach.verificationError = result.error.message;
                    else
                        stripe.ach.verificationError = 'Your bank account details could not be used to verify your account';

                    stripe.ach.showErrors();
                }
            });
        },
        validateForm: function(value)
        {
            stripe.ach.generateToken();

            if (stripe.ach.token)
                return true;

            stripe.ach.showErrors();

            return false;
        },
        resetToken: function()
        {
            stripe.ach.token = null;
            $('stripe-ach-token').value = "";

            stripe.ach.hideSuccessMessage();
            stripe.ach.hideErrors();
            stripe.ach.generateToken();
        },
        setToken: function(token, bank_account)
        {
            stripe.ach.token = token;
            $('stripe-ach-token').value = token;

            stripe.ach.showSuccessMessage();
            stripe.ach.hideErrors();
        },
        setVerificationError: function()
        {
            setTimeout(function(){
                var el = $('advice-stripe-payments-ach-generate-token-stripe-ach-token');
                if (el)
                    el.innerText = stripe.ach.verificationError;
            }, 10);
        },
        hideErrors: function()
        {
            $('ach-bank-account-details').removeClassName("showVerificationError");
            stripe.ach.verificationError = 'Could not verify bank account details!';
            stripe.ach.setVerificationError();
        },
        showErrors: function()
        {
            $('ach-bank-account-details').addClassName("showVerificationError");
            stripe.ach.setVerificationError();
        },
        hideSuccessMessage: function()
        {
            $('stripe-ach-account-verified').style.display = "none";
        },
        showSuccessMessage: function()
        {
            $('stripe-ach-account-verified').style.display = "block";
        }
    }
};

var initAdmin = function()
{
    var btn = document.getElementById('order-totals');
    if (btn) btn = btn.getElementsByTagName('button');
    if (btn && btn[0]) btn = btn[0];
    if (btn) btn.onclick = stripe.placeAdminOrder;

    var topBtns = document.getElementsByClassName('save');
    for (var i = 0; i < topBtns.length; i++)
    {
        topBtns[i].onclick = stripe.placeAdminOrder;
    }
};

var beginApplePay = function()
{
    var paymentRequest = paramsApplePay;

    var countryCode = stripe.getCountryCode();
    if (countryCode && countryCode != paymentRequest.countryCode)
    {
        // In some cases with OSC modules, the country may change without having the payment form reloaded
        paymentRequest.countryCode = countryCode;
    }

    var ession = Stripe.applePay.buildSession(paymentRequest, function(result, completion)
    {
        setStripeToken(result.token.id);

        completion(ApplePaySession.STATUS_SUCCESS);

        setApplePayToken(result.token);
    },
    function(error)
    {
        alert(error.message);
    });

    session.begin();
};

var setApplePayToken = function(token)
{
    if (!stripe.isApplePayEnabled())
        return;

    var radio = document.querySelector('input[name="payment[cc_saved]"]:checked');
    if (!radio || (radio && radio.value == 'new_card'))
        disablePaymentFormValidation();

    if ($('new_card'))
        $('new_card').removeClassName('validate-one-required-by-name');

    $('apple-pay-result-brand').update(token.card.brand);
    $('apple-pay-result-last4').update(token.card.last4);
    $('payment_form_stripe_payments').addClassName('apple-pay-success');

    if (!stripe.isApplePayInsideForm() && $('co-payment-form'))
        $('co-payment-form').addClassName('apple-pay-success');

    $('apple-pay-result-brand').className = "type " + token.card.brand;
    stripe.applePaySuccess = true;
    stripe.applePayToken = token;
    stripe.sourceId = token.id;

    // Ensure that a payment method is selected if Apple Pay is used outside the payment form
    var el = document.getElementById("p_method_stripe_payments");
    if (el) el.checked = true;
};

var resetApplePayToken = function()
{
    if (!stripe.isApplePayEnabled())
        return;

    var radio = document.querySelector('input[name="payment[cc_saved]"]:checked');
    if (!radio || (radio && radio.value == 'new_card'))
        enablePaymentFormValidation();

    if ($('new_card'))
        $('new_card').addClassName('validate-one-required-by-name');

    $('payment_form_stripe_payments').removeClassName('apple-pay-success');

    if (!stripe.isApplePayInsideForm() && $('co-payment-form'))
        $('co-payment-form').removeClassName('apple-pay-success');

    if ($('apple-pay-result-brand'))
    {
        $('apple-pay-result-brand').update();
        $('apple-pay-result-last4').update();
        $('apple-pay-result-brand').className = "";
    }
    deleteStripeToken();
    stripe.applePaySuccess = false;
    stripe.applePayToken = null;
};

var getCardDetails = function()
{
    // Validate the card
    var cardName = document.getElementById('stripe_payments_cc_owner');
    var cardNumber = document.getElementById('stripe_payments_cc_number');
    var cardCvc = document.getElementById('stripe_payments_cc_cid');
    var cardExpMonth = document.getElementById('stripe_payments_expiration');
    var cardExpYear = document.getElementById('stripe_payments_expiration_yr');

    var isValid = cardName && cardName.value && cardNumber && cardNumber.value && cardCvc && cardCvc.value && cardExpMonth && cardExpMonth.value && cardExpYear && cardExpYear.value;

    if (!isValid) return null;

    var cardDetails = {
        name: cardName.value,
        number: cardNumber.value,
        cvc: cardCvc.value,
        exp_month: cardExpMonth.value,
        exp_year: cardExpYear.value
    };

    cardDetails = stripe.addAVSFieldsTo(cardDetails);

    return cardDetails;
};

var createStripeToken = function(callback)
{
    stripe.clearCardErrors();

    // Card validation, displays the error at the payment form section
    if (!stripe.validatePaymentForm())
        return;

    // Terms and Agreements validation, shows as an alert
    var terms = $$('#checkout-agreements input[type=checkbox]');
    for (var i = 0; i < terms.length; i++)
    {
        if (!terms[i].checked)
        {
            alert("Please agree to all the terms and conditions before placing the order.");
            return;
        }
    }

    stripe.setLoadWaiting('review');
    var done = function(err)
    {
        stripe.setLoadWaiting(false);

        if (err)
        {
            resetApplePayToken();
            err = stripe.maskError(err);
        }

        return callback(err);
    };

    if (stripe.applePaySuccess)
    {
        return done();
    }

    // First check if the "Use new card" radio is selected, return if not
    var cardDetails, newCardRadio = document.getElementById('new_card');
    if (newCardRadio && !newCardRadio.checked)
    {
        if (stripe.sourceId)
            setStripeToken(stripe.sourceId);
        else
            return done("No card specified");

        return done(); // We are using a saved card token for the payment
    }

    try
    {
        var data = {
            billing_details: stripe.getSourceOwner()
        };

        stripe.stripeJsV3.createPaymentMethod('card', stripe.card, data).then(function(result)
        {
            if (result.error)
                return done(result.error.message);

            var cardKey = result.paymentMethod.id;
            var token = result.paymentMethod.id + ':' + result.paymentMethod.card.brand + ':' + result.paymentMethod.card.last4;
            stripeTokens[cardKey] = token;
            setStripeToken(token);

            return done();
        });
    }
    catch (e)
    {
        return done(e.message);
    }
};

function setStripeToken(token)
{
    try
    {
        var input, inputs = document.getElementsByClassName('stripejs-token');
        if (inputs && inputs[0]) input = inputs[0];
        else input = document.createElement("input");
        input.setAttribute("type", "hidden");
        input.setAttribute("name", "payment[cc_stripejs_token]");
        input.setAttribute("class", 'stripejs-token');
        input.setAttribute("value", token);
        input.disabled = false; // Gets disabled when the user navigates back to shipping method
        var form = document.getElementById('payment_form_stripe_payments');
        if (!form) form = document.getElementById('co-payment-form');
        if (!form) form = document.getElementById('order-billing_method_form');
        if (!form) form = document.getElementById('onestepcheckout-form');
        if (!form && typeof payment != 'undefined') form = document.getElementById(payment.formId);
        if (!form)
        {
            form = document.getElementById('new-card');
            input.setAttribute("name", "newcard[cc_stripejs_token]");
        }
        form.appendChild(input);
    } catch (e) {}
}

function deleteStripeToken()
{
    var input, inputs = document.getElementsByClassName('stripejs-token');
    if (inputs && inputs[0]) input = inputs[0];
    if (input && input.parentNode) input.parentNode.removeChild(input);
}

// Multi-shipping form support for Stripe.js
var multiShippingForm = null, multiShippingFormSubmitButton = null;

function submitMultiShippingForm(e)
{
    if (!stripe.isPaymentMethodSelected())
        return true;

    if (e.preventDefault) e.preventDefault();

    if (!multiShippingFormSubmitButton) multiShippingFormSubmitButton = document.getElementById('payment-continue');
    if (multiShippingFormSubmitButton) multiShippingFormSubmitButton.disabled = true;

    createStripeToken(function(err)
    {
        if (multiShippingFormSubmitButton) multiShippingFormSubmitButton.disabled = false;

        if (err)
            stripe.displayCardError(err);
        else
            multiShippingForm.submit();
    });

    return false;
}

// Multi-shipping form
var initMultiShippingForm = function()
{
    if (typeof payment == 'undefined' ||
        payment.formId != 'multishipping-billing-form' ||
        stripe.multiShippingFormInitialized)
        return;

    multiShippingForm = document.getElementById(payment.formId);
    if (!multiShippingForm) return;

    if (multiShippingForm.attachEvent)
        multiShippingForm.attachEvent("submit", submitMultiShippingForm);
    else
        multiShippingForm.addEventListener("submit", submitMultiShippingForm);

    stripe.multiShippingFormInitialized = true;
};

var isCheckbox = function(input)
{
    return input.attributes && input.attributes.length > 0 &&
        (input.type === "checkbox" || input.attributes[0].value === "checkbox" || input.attributes[0].nodeValue === "checkbox");
};

var disablePaymentFormValidation = function()
{
    var i, inputs = document.querySelectorAll(".stripe-input");
    var parentId = 'payment_form_stripe_payments';

    $(parentId).removeClassName("stripe-new");
    for (i = 0; i < inputs.length; i++)
    {
        if (isCheckbox(inputs[i])) continue;
        $(inputs[i]).removeClassName('required-entry');
    }
};

var enablePaymentFormValidation = function()
{
    var i, inputs = document.querySelectorAll(".stripe-input");
    var parentId = 'payment_form_stripe_payments';

    $(parentId).addClassName("stripe-new");
    for (i = 0; i < inputs.length; i++)
    {
        if (isCheckbox(inputs[i])) continue;
        $(inputs[i]).addClassName('required-entry');
    }
};

var toggleValidation = function(evt)
{
    $('new_card').removeClassName('validate-one-required-by-name');
    if (evt.target.value == 'stripe_payments')
        $('new_card').addClassName('validate-one-required-by-name');
};

var initSavedCards = function(isAdmin)
{
    if (isAdmin)
    {
        // Adjust validation if necessary
        var newCardRadio = document.getElementById('new_card');
        if (newCardRadio)
        {
            var methods = document.getElementsByName('payment[method]');
            for (var j = 0; j < methods.length; j++)
                methods[j].addEventListener("click", toggleValidation);
        }
    }
};

var saveNewCard = function()
{
    var saveButton = document.getElementById('stripe-savecard-button');
    var wait = document.getElementById('stripe-savecard-please-wait');
    saveButton.style.display = "none";
    wait.style.display = "block";

    if (typeof Stripe != 'undefined')
    {
        createStripeToken(function(err)
        {
            saveButton.style.display = "block";
            wait.style.display = "none";

            if (err)
                stripe.displayCardError(err);
            else
                document.getElementById("new-card").submit();

        });
        return false;
    }

    return true;
};

var initOSCModules = function()
{
    if (stripe.oscInitialized) return;

    // Front end bindings
    if (typeof IWD != "undefined" && typeof IWD.OPC != "undefined")
    {
        IWD.OPC.isAuthenticationInProgress = false;

        // IWD OnePage Checkout override, which is a tad of a mess
        var proceed = function()
        {
            if (typeof $j == 'undefined') // IWD 4.0.4
                $j = $j_opc; // IWD 4.0.8

            var form = $j('#co-payment-form').serializeArray();
            IWD.OPC.Checkout.xhr = $j.post(IWD.OPC.Checkout.config.baseUrl + 'onepage/json/savePayment',form, IWD.OPC.preparePaymentResponse,'json');
        };

        stripe.placeOrder = function()
        {
            proceed();
        };

        IWD.OPC.savePayment = function()
        {
            if (!IWD.OPC.saveOrderStatus)
                return;

            if (IWD.OPC.Checkout.xhr !== null)
                IWD.OPC.Checkout.xhr.abort();

            IWD.OPC.Checkout.lockPlaceOrder();

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            if (IWD.OPC.isAuthenticationInProgress && typeof IWD.OPC.saveOrder != "undefined") // IWD 4.3.4
            {
                IWD.OPC.isAuthenticationInProgress = false; // Turn it off on the second order submission
                IWD.OPC.saveOrder();
                return;
            }

            createStripeToken(function(err)
            {
                IWD.OPC.Checkout.xhr = null;
                IWD.OPC.Checkout.unlockPlaceOrder();

                if (err)
                {
                    IWD.OPC.Checkout.hideLoader();
                    stripe.displayCardError(err);
                }
                else
                    stripe.placeOrder();
            });
        };

        stripe.onWindowLoaded(function()
        {
            var msgs = $$('.opc-message-container');
            if (msgs.length > 0)
            {
                msgs[0].addEventListener('DOMNodeInserted', function(evt) {
                    stripe.searchForAuthenticationRequiredError(function()
                    {
                        setTimeout(function()
                        {
                            $$('.opc-messages-action button')[0].click();
                        });
                        setTimeout(function()
                        {
                            IWD.OPC.isAuthenticationInProgress = true;

                            stripe.authenticateCustomer(function(err)
                            {
                                if (err)
                                    return stripe.displayCardError(err);

                                // We cannot use stripe.placeOrder with IWD
                                // stripe.placeOrder();
                                $$('#checkout-review-submit button')[0].click();
                            });
                        }, 10);
                    });
                }, false);
            }
        });

        stripe.oscInitialized = true;
    }
    // Magik OneStepCheckout v1.0.1
    else if (typeof MGKOSC != "undefined")
    {
        window.addEventListener("load", function()
        {
            var proceed = checkout.save.bind(checkout);

            stripe.placeOrder = function()
            {
                proceed();
            };

            checkout.save = function(element)
            {
                if (!stripe.isPaymentMethodSelected())
                    return stripe.placeOrder();

                createStripeToken(function(err)
                {
                    if (err)
                        stripe.displayCardError(err);
                    else
                        stripe.placeOrder();
                });
            };
            stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
            stripe.oscInitialized = true;
        });
    }
    // MageCloud Clarion OSC v1.0.2
    else if ($('onestepcheckout_orderform') && $$('.btn-checkout').length > 0)
    {
        var checkoutButton = $$('.btn-checkout').pop();
        stripe.placeOrder = function()
        {
            checkout.save();
        };
        checkoutButton.onclick = function(e)
        {
            e.preventDefault();

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };
        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    else if ($('onestep_form'))
    {
        // MageWorld OneStepCheckoutPro v3.4.4
        var initOSC = function()
        {
            OneStep.Views.Init.prototype._updateOrder = OneStep.Views.Init.prototype.updateOrder;
            OneStep.Views.Init.prototype.updateOrder = function()
            {
                var proceed = this._updateOrder.bind(this);

                stripe.placeOrder = function()
                {
                    proceed();
                };

                if (!stripe.isPaymentMethodSelected())
                    return stripe.placeOrder();

                var self = this;

                this.$el.find("#review-please-wait").show();
                window.OneStep.$('.btn-checkout').attr('disabled','disabled');

                createStripeToken(function(err)
                {
                    if (err)
                    {
                        self.$el.find("#review-please-wait").hide();
                        window.OneStep.$('.btn-checkout').removeAttr('disabled');
                        stripe.displayCardError(err);
                    }
                    else
                        stripe.placeOrder();
                });

            };
        };

        window.addEventListener("load", initOSC);
        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    // FancyCheckout 1.2.6
    else if ($('fancycheckout_orderform'))
    {
        var placeOrderButton = $$('button.btn-checkout')[0];
        if (!placeOrderButton)
            return;

        stripe.placeOrder = function()
        {
            billingForm.submit();
        };

        placeOrderButton.onclick = function(e)
        {
            if(!billingForm.validator.validate())
                return;

            jQuery('#control_overlay').show();
            jQuery('.opc_wrapper').css('opacity','0.5');

            e.preventDefault();

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                {
                    stripe.displayCardError(err);
                    jQuery('#control_overlay').hide();
                    jQuery('.opc_wrapper').css('opacity','1');
                }
                else
                    stripe.placeOrder();
            });
        };

        stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    else if ($('onestepcheckout-form') && !$('quickcheckout-ajax-loader'))
    {
        // MageBay OneStepCheckout 1.1.5
        // Idev OneStepCheckout 4.5.4
        var setLoading = function(flag)
        {
            if (typeof jQuery == 'undefined')
                return;

            var placeOrderButton = $('onestepcheckout-place-order');
            if (!placeOrderButton)
                return;

            var loading = jQuery('.onestepcheckout-place-order-loading');

            if (flag == true)
            {
                if (loading.length > 0)
                    loading.remove();

                /* Disable button to avoid multiple clicks */
                placeOrderButton.removeClassName('orange').addClassName('grey');
                placeOrderButton.disabled = true;

                var loaderelement = new Element('span').
                    addClassName('onestepcheckout-place-order-loading').
                    update('Please wait, processing your order...');

                placeOrderButton.parentNode.appendChild(loaderelement);
            }
            else
            {
                location.reload();

                if (loading.length > 0)
                    loading.remove();

                placeOrderButton.disabled = false;
            }
        }

        var initIdevOSC = function()
        {
            if (typeof $('onestepcheckout-form').proceed != 'undefined')
                return;

            stripe.placeOrder = function()
            {
                $('onestepcheckout-form').proceed();
            };

            $('onestepcheckout-form').proceed = $('onestepcheckout-form').submit;
            $('onestepcheckout-form').submit = function(e)
            {
                if (!stripe.isPaymentMethodSelected())
                    return stripe.placeOrder();

                setLoading(true);

                createStripeToken(function(err)
                {
                    if (err)
                    {
                        stripe.displayCardError(err);
                        setLoading(false);
                    }
                    else
                        stripe.placeOrder();
                });
            };

            // Idev OneStepCheckout 4.1.0
            if (typeof submitOsc != 'undefined' && typeof $('onestepcheckout-form')._submitOsc == 'undefined')
            {
                $('onestepcheckout-form')._submitOsc = submitOsc;
                submitOsc = function(form, url, message, image)
                {
                    stripe.placeOrder = function()
                    {
                        $('onestepcheckout-form')._submitOsc(form, url, message, image);
                    };

                    if (!stripe.isPaymentMethodSelected())
                        return stripe.placeOrder();

                    setLoading(true);

                    createStripeToken(function(err)
                    {
                        if (err)
                        {
                            stripe.displayCardError(err);
                            setLoading(false);
                        }
                        else
                            stripe.placeOrder();
                    });
                };
            }
        };

        // This is triggered when the billing address changes and the payment method is refreshed
        window.addEventListener("load", initIdevOSC);

        stripe.onWindowLoaded(function()
        {
            stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);
        });

        stripe.oscInitialized = true;
    }
    else if (typeof AWOnestepcheckoutForm != 'undefined')
    {
        // AheadWorks OneStepCheckout 1.3.5
        AWOnestepcheckoutForm.prototype.__sendPlaceOrderRequest = AWOnestepcheckoutForm.prototype._sendPlaceOrderRequest;
        AWOnestepcheckoutForm.prototype._sendPlaceOrderRequest = function()
        {
            var self = this;

            stripe.placeOrder = function()
            {
                self.__sendPlaceOrderRequest();
            };

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                {
                    stripe.displayCardError(err);
                    try
                    {
                        self.enablePlaceOrderButton();
                        self.hidePleaseWaitNotice();
                        self.hideOverlay();
                    }
                    catch (e) {}
                }
                else
                    stripe.placeOrder();
            });
        };
        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    // NextBits OneStepCheckout 1.0.3
    else if (typeof checkoutnext != 'undefined' && typeof Review.prototype.proceed == 'undefined')
    {
        Review.prototype.proceed = Review.prototype.save;
        Review.prototype.save = function()
        {
            var self = this;

            stripe.placeOrder = function()
            {
                self.proceed();
            };

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        if (typeof review != 'undefined')
            review.save = Review.prototype.save;

        stripe.oscInitialized = true;
    }
    // Magecheckout OSC 2.2.1
    else if (typeof MagecheckoutSecuredCheckoutPaymentMethod != 'undefined')
    {
        MagecheckoutSecuredCheckoutForm.prototype._placeOrderProcess = MagecheckoutSecuredCheckoutForm.prototype.placeOrderProcess;
        MagecheckoutSecuredCheckoutForm.prototype.placeOrderProcess = function ()
        {
            var self = this;

            stripe.placeOrder = function()
            {
                self._placeOrderProcess();
            };

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        if (typeof securedCheckoutForm != 'undefined')
        {
            securedCheckoutForm._placeOrderProcess = MagecheckoutSecuredCheckoutForm.prototype._placeOrderProcess;
            securedCheckoutForm.placeOrderProcess = MagecheckoutSecuredCheckoutForm.prototype.placeOrderProcess;
        }
        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    // Lotusbreath OneStepCheckout 4.2.0
    else if (typeof oscObserver != 'undefined' && typeof oscObserver.register != 'undefined')
    {
        window.validToken = false;

        stripe.placeOrder = function()
        {
            $('lbonepage-place-order-btn').click();
        };

        oscObserver.register('beforeSubmitOrder', function()
        {
            if (!stripe.isPaymentMethodSelected())
                return;

            if (window.validToken)
                return;

            oscObserver.stopSubmittingOrder = true;

            createStripeToken(function(err)
            {
                oscObserver.stopSubmittingOrder = false;

                if (err)
                {
                    window.validToken = false;
                    stripe.displayCardError(err, true);
                }
                else
                {
                    window.validToken = true;
                    stripe.placeOrder();
                }
            });

        });

        stripe.onWindowLoaded(function()
        {
            oscObserver.register('afterLoadingNewContent', function()
            {
                // afterLoadingNewContent is called prematurely, allow some time for the DOM to update and the ajax requests to finish
                setTimeout(function(){
                    stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);
                }, 600);
            });
        });

        stripe.oscInitialized = true;
    }
    // FireCheckout 3.2.0
    else if ($('firecheckout-form'))
    {
        var fireCheckoutPlaceOrder = function()
        {
            var self = this;

            if (!stripe.isPaymentMethodSelected())
                return self.proceed();

            if (typeof checkout != "undefined" && typeof checkout.validate != "undefined" && !checkout.validate())
                return;

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err, true);
                else
                    self.proceed();
            });
        };

        window.addEventListener("load", function()
        {
            var btnCheckout = document.getElementsByClassName('btn-checkout');
            if (btnCheckout && btnCheckout.length)
            {
                for (var i = 0; i < btnCheckout.length; i++)
                {
                    var button = btnCheckout[i];
                    button.proceed = button.onclick;
                    button.onclick = fireCheckoutPlaceOrder;

                    stripe.placeOrder = function()
                    {
                        button.proceed();
                    };
                }
            }
        });

        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);

        stripe.oscInitialized = true;
    }
    else if (typeof MagegiantOneStepCheckoutForm != 'undefined')
    {
        // MageGiant OneStepCheckout 4.0.0
        MagegiantOneStepCheckoutForm.prototype.__placeOrderRequest = MagegiantOneStepCheckoutForm.prototype._placeOrderRequest;
        MagegiantOneStepCheckoutForm.prototype._placeOrderRequest = function()
        {
            var self = this;

            stripe.placeOrder = function()
            {
                self.__placeOrderRequest();
            };

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        stripe.oscInitialized = true;
    }
    else if (typeof oscPlaceOrder != 'undefined')
    {
        // Magestore OneStepCheckout 3.5.0
        var proceed = oscPlaceOrder;

        oscPlaceOrder = function(element)
        {
            var form = $('one-step-checkout-form');
            var payment_method = $RF(form, 'payment[method]');
            if (payment_method != 'stripe_payments')
                return stripe.placeOrder();

            var validator = new Validation('one-step-checkout-form');

            if (validator.validate())
            {
                createStripeToken(function(err)
                {
                    if (err)
                        stripe.displayCardError(err);
                    else
                        stripe.placeOrder();
                });
            }
        };

        stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);

        stripe.placeOrder = function()
        {
            proceed(document.getElementById('onestepcheckout-button-place-order'));
        };

        stripe.oscInitialized = true;
    }
    // GoMage LightCheckout 5.9
    else if (typeof checkout != 'undefined' && typeof checkout.LightcheckoutSubmit != 'undefined')
    {
        checkout._LightcheckoutSubmit = checkout.LightcheckoutSubmit;

        stripe.placeOrder = function()
        {
            checkout._LightcheckoutSubmit();
        };

        checkout.LightcheckoutSubmit = function()
        {

            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                {
                    stripe.displayCardError(err);
                    checkout.showLoadinfo();
                    location.reload();
                }
                else
                    stripe.placeOrder();
            });
        };

        var triggerModal = null;

        document.getElementsByTagName("BODY")[0].addEventListener('DOMNodeInserted', function(evt)
        {
            if (triggerModal)
                clearTimeout(triggerModal);

            triggerModal = setTimeout(function()
            {
                stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);
            }, 100);

        }, false);

        stripe.oscInitialized = true;
    }
    // Amasty OneStepCheckout 3.0.5
    else if ($('amscheckout-submit') && typeof completeCheckout != 'undefined')
    {
        stripe.placeOrder = function()
        {
            completeCheckout();
        };

        $('amscheckout-submit').onclick = function(el)
        {
            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            showLoading();
            createStripeToken(function(err)
            {
                hideLoading();
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        document.getElementById('amasty-scheckout-messagebox').addEventListener('DOMNodeInserted', function(evt) {
            stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);
        }, false);

        stripe.oscInitialized = true;
    }
    else if ((typeof Review != 'undefined' && typeof Review.prototype.proceed == 'undefined') && (
        // Magesolution Athlete Ultimate Magento Theme v1.1.2
        $('oscheckout-form') ||
        // PlumRocket OneStepCheckout 1.3.4
        ($('submit-chackout') && $('submit-chackout-top')) ||
        // Apptha 1StepCheckout v1.9
        (typeof closeLink1 != 'undefined')
    ))
    {
        Review.prototype.proceed = Review.prototype.save;

        stripe.placeOrder = function()
        {
            review.proceed();
        };

        Review.prototype.save = function()
        {
            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        if (typeof review != 'undefined')
            review.save = Review.prototype.save;

        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
    }
    else if (typeof OSCheckout != 'undefined' && typeof OSCheckout.prototype.proceed == 'undefined')
    {
        // AdvancedCheckout OSC 2.5.0
        OSCheckout.prototype.proceed = OSCheckout.prototype.placeOrder;
        OSCheckout.prototype.placeOrder = function()
        {
            var self = this;

            stripe.placeOrder = function()
            {
                self.proceed();
            };

            // Payment is not defined
            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        if (typeof oscheckout != 'undefined')
        {
            oscheckout.proceed = OSCheckout.prototype.proceed;
            oscheckout.placeOrder = OSCheckout.prototype.placeOrder;
        }
        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    // Aitoc OnePageCheckout v1.4.17
    else if ($('aitcheckout-place-order') && typeof AitMagentoReview != "undefined" && typeof AitMagentoReview.prototype.proceed != "undefined")
    {
        AitMagentoReview.prototype.proceed = AitMagentoReview.prototype.save;

        stripe.placeOrder = function()
        {
            review.proceed();
        };

        AitMagentoReview.prototype.save = function()
        {
            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            var validator = new Validation(aitCheckout.getForm());
            if (validator && validator.validate())
            {
                createStripeToken(function(err)
                {
                    if (err)
                        stripe.displayCardError(err);
                    else
                        stripe.placeOrder();
                });
            }
            else
            {
                if (0 < Ajax.activeRequestCount)
                {
                    aitCheckout.valid = false;
                }
            }
        };

        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    // Magebees One Page Checkout v1.1.1
    else if ($$('.magebeesOscFull').length > 0 && typeof Review != 'undefined' && typeof Review.prototype.proceed == 'undefined')
    {
        Review.prototype.proceed = Review.prototype.submit;

        stripe.placeOrder = function()
        {
            review.proceed();
        };

        Review.prototype.submit = function()
        {
            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            if (!checkout || !checkout.validateReview(true))
                return;

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        Event.stopObserving($('order_submit_button'));
        review.firsttimeinitialize();
    }
    // EcommerceTeam Tcheckout 1.0
    else if ($('tcheckout-form') && $('tcheckout-save-btn'))
    {
        $('tcheckout-form').proceed = $('tcheckout-form').submit;

        stripe.placeOrder = function()
        {
            $('tcheckout-form').proceed();
        };

        $('tcheckout-form').onsubmit = function(e)
        {
            if (!stripe.isPaymentMethodSelected())
                return true;

            e.preventDefault();

            createStripeToken(function(err)
            {
                if (err)
                {
                    $('tcheckout-please-wait').style.display = 'none';
                    $('tcheckout-save-btn').disabled = '';
                    $('tcheckout-save-btn').removeClassName('disabled');
                    stripe.displayCardError(err);
                }
                else
                    stripe.placeOrder();
            });
        };

        stripe.searchForAuthenticationRequiredError(stripe.triggerCustomerAuthentication);
        stripe.oscInitialized = true;
    }
    else if (typeof Review != 'undefined' && typeof Review.prototype.proceed == 'undefined')
    {
        // Default Magento Onepage checkout
        // Awesome Checkout 1.5.0
        // PlumRocket OSC 1.3.4
        // Other OSC modules

        /* The Awesome Checkout 1.5.0 configuration whitelist files are:
         *   stripe_payments/js/stripe_payments.js
         *   stripe_payments/js/cctype.js
         *   stripe_payments/css/styles.css
         *   prototype/window.js
         *   prototype/windows/themes/default.css
        */

        Review.prototype.proceed = Review.prototype.save;

        stripe.placeOrder = function()
        {
            // Awesome Checkout && PlumRocket
            checkout.loadWaiting = false;

            // Others
            review.proceed();
        };

        Review.prototype.save = function()
        {
            if (!stripe.isPaymentMethodSelected())
                return stripe.placeOrder();

            createStripeToken(function(err)
            {
                if (err)
                    stripe.displayCardError(err);
                else
                    stripe.placeOrder();
            });
        };

        if (typeof review != 'undefined')
            review.save = Review.prototype.save;

        stripe.initAlertProxy(stripe.triggerCustomerAuthentication);
    }
};

