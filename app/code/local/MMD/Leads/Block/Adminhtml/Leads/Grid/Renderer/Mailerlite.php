<?php
/**
 * Read-only checkbox indicating whether the lead's email was pushed to the
 * site's MailerLite subscriber group. Checked = sent; unchecked otherwise,
 * with the exact outcome (skipped / failed / never attempted) in the
 * tooltip. Styling comes from the global minimalist checkbox rules in
 * dark-theme.css — no per-column CSS.
 */
class MMD_Leads_Block_Adminhtml_Leads_Grid_Renderer_Mailerlite
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $status = (string) $row->getData($this->getColumn()->getIndex());
        $sent   = ($status === MMD_Leads_Model_Lead::MAILERLITE_SENT);
        $title  = $sent ? 'Sent to MailerLite' : ($status !== '' ? ucfirst($status) : 'Not attempted');
        return '<input type="checkbox" disabled'
            . ($sent ? ' checked="checked"' : '')
            . ' title="' . $this->escapeHtml($title) . '" onclick="return false;" />';
    }
}
