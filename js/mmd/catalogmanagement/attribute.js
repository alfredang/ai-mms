/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.mmd.com)
* @package Amasty_Pgrid
*/

var amPattribute = new Class.create();

amPattribute.prototype = {
    initialize: function(title)
    {
        this.title = title;
    },
    
    showConfig: function()
    {
        attributeDialog = Dialog.info($('pAttribute_block').innerHTML, {
            draggable: true,
            resizable: true,
            closable: true,
            className: "magento",
            windowClassName: "popup-window",
            title: this.title,
            width: 700,
            height: 600,
            zIndex: 1000,
            recenterAuto: false,
            hideEffect: Element.hide,
            showEffect: Element.show,
            id: 'attributeDialog',
        });
    },
    
    closeConfig: function()
    {
        attributeDialog.close();
    }
};