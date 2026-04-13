
var cardTypes = {
    visa: new RegExp('^4'),
    mastercard: new RegExp('^5[1-5]'),
    amex: new RegExp('^3[47]'),
    discover: new RegExp('^6(?:011|5[0-9]{2})'),
    jcb: new RegExp('^(?:2131|1800|35[0-9]{3})'),
    diners: new RegExp('^3(?:0[0-5]|[68][0-9])')
};

function getCardType(cardNumber)
{
    for (var type in cardTypes)
        if (cardTypes.hasOwnProperty(type))
            if (cardTypes[type].test(cardNumber))
                return type;
}

var iconsContainer;

function resetIconsFade()
{
    iconsContainer.className = 'input-box';
    var children = iconsContainer.getElementsByTagName('img');
    for (var i = 0; i < children.length; i++)
        children[i].className = '';
}

var onCardNumberChangedFade = function(input)
{
    if (!iconsContainer) iconsContainer = document.getElementById('stripe-payments-accepted-cards');
    if (!iconsContainer) return;

    resetIconsFade();

    var cardNumber = input.value;
    if (!cardNumber || cardNumber.length === 0) return;

    var cardType = getCardType(cardNumber);
    if (!cardType) return;

    var img = document.getElementById('stripe_payments_' + cardType + '_type');
    if (!img) return;

    img.className = 'active';
    iconsContainer.className = 'input-box stripe-payments-detected';
};

function resetIconsSlide(input)
{
    input.className = input.className.replace(/ ?cctype-detected cctype-[a-z]+/, '');
}

var onCardNumberChangedSlide = function(input)
{
    var cardNumber = input.value;
    if (!cardNumber || cardNumber.length === 0) return resetIconsSlide(input);

    var cardType = getCardType(cardNumber);
    if (!cardType) return resetIconsSlide(input);

    var ccTypeClass = 'cctype-detected cctype-' + cardType;
    if (input.className.indexOf(ccTypeClass) > 0) return;

    resetIconsSlide(input);
    input.className = input.className + ' ' + ccTypeClass;
};
