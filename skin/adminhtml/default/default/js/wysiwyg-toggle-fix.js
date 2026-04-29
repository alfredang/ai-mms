/**
 * Fix for the WYSIWYG "Show / Hide Editor" toggle on CMS Pages, CMS Blocks,
 * Categories, and any other admin page using Mage_Adminhtml_Block_Catalog_
 * Helper_Form_Wysiwyg.
 *
 * Symptom: clicking "Show / Hide Editor" hides the iframe but the underlying
 * textarea also stays hidden, leaving an empty space. Clicking again does
 * nothing because tinyMCE.get(id) still finds no editor (it was removed)
 * and turnOn() then has no visible target to attach to in some browsers.
 *
 * Cause: tinyMCE 3's mceAddControl sets `display:none` on the original
 * textarea; mceRemoveControl is supposed to restore it but doesn't always
 * (depends on TinyMCE state, plugin order, and whether the textarea was
 * wrapped in a container). The Magento `tinyMceWysiwygSetup.turnOff` does
 * not defensively reset the textarea's style.
 *
 * Fix: monkey-patch the prototype methods so we always explicitly
 * show / hide the textarea ourselves. Idempotent — safe to run multiple
 * times (e.g. after PJAX swaps).
 */
(function () {
    function applyPatch() {
        if (typeof tinyMceWysiwygSetup === 'undefined') return false;
        if (tinyMceWysiwygSetup.prototype.__togglePatched) return true;

        var origTurnOff = tinyMceWysiwygSetup.prototype.turnOff;
        tinyMceWysiwygSetup.prototype.turnOff = function () {
            origTurnOff.apply(this, arguments);
            var ta = document.getElementById(this.id);
            if (ta) {
                ta.style.setProperty('display', 'block', 'important');
                ta.style.setProperty('visibility', 'visible', 'important');
            }
        };

        var origTurnOn = tinyMceWysiwygSetup.prototype.turnOn;
        tinyMceWysiwygSetup.prototype.turnOn = function () {
            // Make sure the textarea is visible before TinyMCE tries to
            // attach — TinyMCE 3.x bails out silently if the target node
            // is hidden via display:none.
            var ta = document.getElementById(this.id);
            if (ta) {
                ta.style.removeProperty('display');
                ta.style.removeProperty('visibility');
            }
            // Defensive: if a previous editor instance is still registered
            // for this id, drop it before re-attaching. mceAddControl is
            // a no-op when an editor with the same id already exists.
            if (typeof tinyMCE !== 'undefined' && tinyMCE.get && tinyMCE.get(this.id)) {
                try { tinyMCE.execCommand('mceRemoveControl', false, this.id); } catch (e) {}
            }
            origTurnOn.apply(this, arguments);
        };

        tinyMceWysiwygSetup.prototype.__togglePatched = true;
        return true;
    }

    if (!applyPatch()) {
        var attempts = 0;
        var iv = setInterval(function () {
            if (applyPatch() || ++attempts > 30) clearInterval(iv);
        }, 100);
    }
})();
