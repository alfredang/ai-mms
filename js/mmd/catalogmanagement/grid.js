/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.mmd.com)
* @package Amasty_Pgrid
*/ 

pointerX = 0;
pointerY = 0;

Object.extend(Prototype.Browser, {
    IE9: (/MSIE (\d+\.\d+);/.test(navigator.userAgent)) ? (Number(RegExp.$1) == 9 ? true : false) : false
});

var mmdCatalogmanagement = new Class.create();

mmdCatalogmanagement.prototype = {
    initialize: function(properties, saveUrl, saveAllUrl, storeId, dateFormat, calendarUrl, options)
    {
        this.saveUrl       = saveUrl;
        this.saveAllUrl    = saveAllUrl;
        this.properties    = properties;
        this.storeId       = storeId;
        this.dateFormat    = dateFormat;
        this.calendarUrl   = calendarUrl;
        this.options       = options;
        
        this.saveAllButtonId = 'catalogmanagement_saveall_button';
        
        this.dataToSave    = new Hash();
        
        this.init();
    },
    
    init: function()
    {
        this.values     = new Array();
        this.productIds = new Array();
        this.table = $('productGrid_table');
        if (!this.table)
        {
            return false;
        }
        this.colnames = new Array();
        // attaching listeners to grid td-s
        $$('#productGrid_table tr.headings th').each(function(th){
            this.colnames[this.colnames.length] = '';
            th.getElementsBySelector('a').each(function(a){
                this.colnames[this.colnames.length-1] = a.name; // -1 because we already saved empty, and if element found, we should replace
            }.bind(this));
        }.bind(this));
        
        $$('#productGrid_table tbody tr').each(function(row){
            row.childElements().each(function(td, i){
                if (0 == i)
                {
                    productId = 0;
                    if (td.select('.massaction-checkbox').length > 0)
                    {
                        productId = td.select('.massaction-checkbox')[0].value; // This is massaction checkbox. It's value = product_id
                    }
                }
                this.productIds[td.identify()] = productId;
                if (field = this.properties[this.colnames[i]])
                {
                    td.observe('click', this.cellClick.bindAsEventListener(this, field, td)); // attaching onClick event to each TD, need to pass current field and td into the listener scope
                    td.observe('mouseover', this.cellMouseOver.bindAsEventListener(this, td)); // will change cursor
                    td.observe('mouseout', this.cellMouseOut.bindAsEventListener(this, td)); // will change cursor
                }
            }.bind(this));
        }.bind(this));
    },
    
    cellMouseOver: function(event)
    {
        var args  = $A(arguments);
        var td    = args[1];
        td.style.cursor = 'text';
        
        if (!td.hasClassName('clicked'))
        {
            pointerX = event.pointerX();
            pointerY = event.pointerY();
            notifyTimeout = setTimeout(peditGrid.notifyEdit, 400);
            setTimeout("$('catalogmanagement_edit_note').style.display = 'none';", 2000);
        }
    },
    
    cellMouseOut: function(event)
    {
        if ('undefined' != typeof(notifyTimeout))
        {
            clearTimeout(notifyTimeout);
        }
    },
    
    cellClick: function(event)
    {
        var args  = $A(arguments);
        var field = args[1];
        var td    = args[2];
        if (!td.hasClassName('clicked'))
        {
            td.addClassName('clicked');
            var value = td.innerHTML.strip();
            this.values[td.identify()] = value;
            if ('&nbsp;' == value)
            {
                value = "";
            }
            value = value.replace('&nbsp;',' ');
            switch (field.type)
            {
                case 'text':
                case 'price':
                    input = document.createElement('input');
                    input.type = 'text';
                    input.value = value;
                    if ("qty" == field.col && this.options.quantity_math)
                    {
                    	input.value += '+';
                    }
                    if (Prototype.Browser.IE && !Prototype.Browser.IE9) {
                        input.setAttribute('class', "catalogmanagement_input_text editable");
                    } else 
                    {
                        input.addClassName('catalogmanagement_input_text');
                        input.addClassName('editable');
                    }
                    td.innerHTML = '';
                    td.appendChild(input);
                    var element = input;
                    element.style.position = 'relative';
                    element.style.top = '-1px';
                    element.style.left = '-2px';
                    $(element).observe('keypress', this.cellKeyPress.bindAsEventListener(this, field, td));
                    $(element).observe('blur',     this.cellSave.bindAsEventListener(this, field, td));
                    element.focus();
                    if ("qty" == field.col && this.options.quantity_math)
                    {
	                    if (this.setSelectionRange)
	                    {
		                    var len = $(this).val().length * 2;
		                    this.setSelectionRange(len, len);
	                    }
	                    else
	                    {
		                    $(element).value = $(element).value;
	                    }
                    }
                break;
                case 'textarea':
                	area = document.createElement('textarea');
                    value=value.replace(new RegExp('&lt;','g'), '<');
                    value=value.replace(new RegExp('&gt;','g'), '>');  
                                      
                	area.value = value;
                    if (Prototype.Browser.IE && !Prototype.Browser.IE9) {
                    	area.setAttribute('class', "catalogmanagement_input_text editable");
                    } else 
                    {
                    	area.addClassName('catalogmanagement_input_text');
                    	area.addClassName('editable');
                    }
                    td.innerHTML = '';
                    td.appendChild(area);
                    var element = area;
                    element.style.position = 'relative';
                    element.style.top = '-1px';
                    element.style.left = '-2px';
                    element.style.height = '300px';
                    $(element).observe('keypress', this.cellKeyPress.bindAsEventListener(this, field, td));
                    $(element).observe('blur',     this.cellSave.bindAsEventListener(this, field, td));
                    element.focus();
                break;
                case 'select':
                    sel = document.createElement('select');
                    if (Prototype.Browser.IE && !Prototype.Browser.IE9) {
                        sel.setAttribute('class', "catalogmanagement_input_select editable");
                    } else 
                    {
                        sel.addClassName('catalogmanagement_input_select');
                        sel.addClassName('editable');
                    }
                    var h = $H(field.options);
                    h.each(function(optionItem){
                        var val   = optionItem[0];
                        var label = optionItem[1];
                        if ('string' == typeof(label))
                        {
	                        option    = document.createElement('option');
	                        option.value = val;
	                        option.text  = label;
	                        option.innerText  = label;
	                        if (value == label)
	                        {
	                            option.selected = true;
	                        }
	                        sel.appendChild(option);
                        }
                    });
                    td.innerHTML = '';
                    td.appendChild(sel);
                    var element = sel;
                    $(element).observe('change',   this.cellSave.bindAsEventListener(this, field, td));
                    $(element).observe('blur',     this.cellSave.bindAsEventListener(this, field, td));
                    element.focus();
                break;
                case 'multiselect':
                    sel = document.createElement('select');
                    sel.multiple = true;
                    if (Prototype.Browser.IE && !Prototype.Browser.IE9) {
                        sel.setAttribute('class', "catalogmanagement_input_select editable");
                    } else 
                    {
                        sel.addClassName('catalogmanagement_input_select');
                        sel.addClassName('editable');
                    }
                    var h = $H(field.options);
                    value = explode(',', value);
                    for (var i = 0; i < value.length; i++)
                    {
                        value[i] = trim(value[i]);
                    }
                    h.each(function(optionItem){
                        var val   = optionItem[0];
                        var label = optionItem[1];
                        if ('string' == typeof(label))
                        {
                            option    = document.createElement('option');
                            option.value = val;
                            option.text  = label;
                            option.innerText  = label;
                            if (in_array(label, value))
                            {
                                option.selected = true;
                            }
                            sel.appendChild(option);
                        }
                    });
                    td.innerHTML = '';
                    td.appendChild(sel);
                    var element = sel;
                    $(element).observe('blur',     this.cellSave.bindAsEventListener(this, field, td));
                    element.focus();
                break;
                case 'date':
                    input = document.createElement('input');
                    input.type = 'text';
                    input.value = value;
                    if (Prototype.Browser.IE && !Prototype.Browser.IE9) {
                        input.setAttribute('class', "catalogmanagement_input_text catalogmanagement_input_date editable");
                    } else 
                    {
                        input.addClassName('catalogmanagement_input_text');
                        input.addClassName('catalogmanagement_input_date');
                        input.addClassName('editable');
                    }
                    td.innerHTML = '';
                    td.appendChild(input);
                    var element = input;
                    element.style.position = 'relative';
                    element.style.top = '-1px';
                    element.style.left = '-2px';
                    element.readOnly = true;
                    
                    // creating calendar button
                    calendarBtn = document.createElement('img');
                    calendarBtn.src = this.calendarUrl;
                    calendarBtn.alt = "";
                    calendarBtn.style.cursor = 'pointer';
                    td.appendChild(calendarBtn);
                    calendarBtn.style.position = 'relative';
                    calendarBtn.style.top = '2px';
                    calendarBtn.style.left = '1px';
                    
                    Calendar.setup({
                        inputField : element.identify(),
                        ifFormat : this.dateFormat,
                        button : calendarBtn.identify(),
                        align : "Bl",
                        singleClick : true,
                        onClose : function(cal) {
                            cal.hide();
                            this.cellSave(this, field, td);
                        }.bind(this)
                    });
                    
                    calendarBtn.click();
                    
                break;
            }
        }
        Event.stop(event);
    },
    
    cellSave: function(event)
    {
        var args = $A(arguments);
        var field = args[1];
        var td    = args[2];
        
        var element = td.select('.editable')[0];
        
        if (!element)
        {
            return;
        }
        
        element.addClassName('progressing');
        element.removeClassName('editable');
        
        switch (element.type)
        {
            case 'select-one':
                var newValue = element.options[element.selectedIndex].text;
            break;
            case 'select-multiple':
                var selectedValues = '';
                for (i=0; i < element.options.length; i++) {
                    if (element.options[i].selected) {
                        selectedValues += element.options[i].text + ', ';
                    }
                }
                if (selectedValues)
                {
                    selectedValues = selectedValues.substr(0, selectedValues.length - 2);
                }
                var newValue = selectedValues;
            break;
            default:
                var newValue = element.value;
            break;
        }

        if (newValue != this.values[td.identify()])
        {
            productId     = this.productIds[td.identify()];
            var saveValue = element.value;
            
    	    if ('select-multiple' == element.type)
	        {
	            saveValue = '';
	            for (i=0; i < element.options.length; i++) {
	                if (element.options[i].selected) {
	                    saveValue += element.options[i].value + ',';
	                }
	            }
	            if (saveValue)
	            {
	                saveValue = saveValue.substr(0, saveValue.length - 1);
	            }
            }

            if ('single' == this.options.mode)
            {
                /* single edit mode */

                postData  = 'form_key=' + FORM_KEY + '&product_id=' + productId + '&store=' + this.storeId + '&field=' + field.col + '&value=' + encodeURIComponent(saveValue);
                
                new Ajax.Request(this.saveUrl, {
                    method: 'post',
                    postBody : postData,
                    onSuccess: function(transport) {
                        var element = td.select('.progressing')[0];
                        if (transport.responseText.isJSON()) {
                            var response = transport.responseText.evalJSON();
                            if (response.error) {
                                alert(response.message);
                                element.addClassName('editable');
                                element.removeClassName('progressing');
                            }
                            if (response.success) {
                                td.innerHTML = response.value;
                                td.removeClassName('clicked');
                            }
                        }
                    },
                    onFailure: function()
                    {
                        var element = td.select('.progressing')[0];
                        alert('Request failed. Please retry.');
                        element.addClassName('editable');
                        element.removeClassName('progressing');
                    }    
                });
            } else 
            {
                /* multiple edit mode: first store internally, then will send by ajax all at once */
                
                var displayValue = saveValue;
                
                if ('select-multiple' == element.type)
                {
                    displayValue = '';
                    for (i=0; i < element.options.length; i++) {
                        if (element.options[i].selected) {
                            displayValue += element.options[i].innerHTML + ', ';
                        }
                    }
                    if (displayValue)
                    {
                        displayValue = displayValue.substr(0, displayValue.length - 2);
                    }
                }
                
                if ('select-one' == element.type)
                {
                    displayValue = element.options[element.selectedIndex].innerHTML;
                }
                
                this.dataToSave.set( td.identify(), {productId: productId, field: field.col, value: encodeURIComponent(saveValue)} );

                if ($(this.saveAllButtonId).hasClassName('disabled'))
                {
                    $(this.saveAllButtonId).removeClassName('disabled');
                }
                
                td.innerHTML = displayValue;
                td.removeClassName('clicked');
            }
        } else 
        {
            td.innerHTML = this.values[td.identify()];
            td.removeClassName('clicked');
        }
        
    },
    
    saveAll: function()
    {
        $(this.saveAllButtonId).addClassName('disabled');

        if (this.dataToSave.keys().length < 1)
        {
            return false;
        }
        
        var postData  = 'form_key=' + FORM_KEY + '&store=' + this.storeId;
        
        var i = 0;
        this.dataToSave.each(function(rec){
            postData += '&productId[' + i + ']=' + rec.value.productId + '&field[' + i + ']=' + rec.value.field + '&value[' + i + ']=' + rec.value.value + '&tdkey[' + i + ']=' + rec.key;
            i++;
        });
        
        new Ajax.Request(this.saveAllUrl, {
            method: 'post',
            evalJS: 'force',
            postBody : postData,
            onSuccess: function(transport) {
                this.dataToSave = new Hash();
            }.bind(this),
            onFailure: function()
            {
                alert('Request failed. Please retry.');
                $(this.saveAllButtonId).removeClassName('disabled');
            }.bind(this)
        });
    },
    
    cellKeyPress: function(event)
    {
        if (event.keyCode == 13) // ENTER key
        {
            var args = $A(arguments);
            var field = args[1];
            var td    = args[2];
            this.cellSave(event, field, td);
        }
    },
    
    notifyEdit: function()
    {
        $('catalogmanagement_edit_note').style.left = 45 + pointerX + 'px';
        $('catalogmanagement_edit_note').style.top = -60 + pointerY + 'px';
        $('catalogmanagement_edit_note').style.display = 'block';
    }
};

Event.observe(window, 'load', function(){
    
    productGridJsObject.initGridAjaxReloaded = productGridJsObject.initGridAjax;

    productGridJsObject.initGridAjax = function()
    {
        this.initGridAjaxReloaded();
        peditGrid.init();
    }
    
});


function explode (delimiter, string, limit) {
    if ( arguments.length < 2 || typeof delimiter == 'undefined' || typeof string == 'undefined' ) return null;
    if ( delimiter === '' || delimiter === false || delimiter === null) return false;
    if ( typeof delimiter == 'function' || typeof delimiter == 'object' || typeof string == 'function' || typeof string == 'object'){
        return { 0: '' };
    }
    if ( delimiter === true ) delimiter = '1';
    delimiter += '';
    string += '';
    var s = string.split( delimiter );
    if ( typeof limit === 'undefined' ) return s;
    if ( limit === 0 ) limit = 1;
    if ( limit > 0 ){
        if ( limit >= s.length ) return s;
        return s.slice( 0, limit - 1 ).concat( [ s.slice( limit - 1 ).join( delimiter ) ] );
    }
    if ( -limit >= s.length ) return [];
    s.splice( s.length + limit );
    return s;
}

function in_array (needle, haystack, argStrict) {
    var key = '',
        strict = !! argStrict;
    if (strict) {
        for (key in haystack) {
            if (haystack[key] === needle) {
                return true;
            }
        }
    } else {
        for (key in haystack) {
            if (haystack[key] == needle) {
                return true;
            }
        }
    }
    return false;
}

function trim (str, charlist) {
    var whitespace, l = 0,
        i = 0;
    str += '';
    if (!charlist) {
        // default list
        whitespace = " \n\r\t\f\x0b\xa0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000";
    } else {
        // preg_quote custom list
        charlist += '';
        whitespace = charlist.replace(/([\[\]\(\)\.\?\/\*\{\}\+\$\^\:])/g, '$1');
    }
    l = str.length;
    for (i = 0; i < l; i++) {
        if (whitespace.indexOf(str.charAt(i)) === -1) {
            str = str.substring(i);
            break;
        }
    }
    l = str.length;
    for (i = l - 1; i >= 0; i--) {
        if (whitespace.indexOf(str.charAt(i)) === -1) {
            str = str.substring(0, i + 1);
            break;
        }
    }
    return whitespace.indexOf(str.charAt(0)) === -1 ? str : '';
}
