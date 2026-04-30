<?php
/**
 * Override the standard Orphaned Role Resources page so it actually
 * exposes a Delete control. The base block relies on the grid's
 * mass-action bar (Delete option), but sidebar-nav.css globally hides
 * `.admin-main .massaction` because the project replaces it with per-row
 * Actions dropdowns — and the per-row injection isn't running on this
 * tiny housekeeping grid. Result: the user lands on the page with no
 * way to actually delete anything.
 *
 * Add a top-right "Delete All Orphaned Resources" button that ticks
 * every checkbox, sets the (hidden) mass-action select to `delete`,
 * and submits the existing mass-action form. Bypasses the broken UX
 * without re-styling the whole mass-action subsystem.
 */
class MMD_Adminhtml_Block_Permissions_OrphanedResource extends Mage_Adminhtml_Block_Permissions_OrphanedResource
{
    public function __construct()
    {
        parent::__construct();

        $confirm = Mage::helper('core')->jsQuoteEscape(
            Mage::helper('adminhtml')->__('Delete all orphaned role resources?')
        );
        $onclick =
            "if (!confirm('{$confirm}')) return;"
            . "var grid = document.querySelector('.grid table.data');"
            . "if (!grid) return;"
            . "grid.querySelectorAll('input[type=\"checkbox\"]').forEach(function(c){ c.checked = true; });"
            . "var sel = document.querySelector('.massaction select');"
            . "if (sel) sel.value = 'delete';"
            . "var form = document.querySelector('form[id\$=\"_massaction-form\"]') "
            .   "|| document.querySelector('.massaction form');"
            . "if (form) { form.submit(); return; }"
            . "var btn = document.querySelector('.massaction button.scalable') "
            .   "|| document.querySelector('.massaction button');"
            . "if (btn) btn.click();";

        $this->_addButton('delete_all_orphans', array(
            'label'   => Mage::helper('adminhtml')->__('Delete All Orphaned Resources'),
            'class'   => 'delete',
            'onclick' => $onclick,
        ));
    }
}
