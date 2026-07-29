<?php
/**
 * MailerLite column: a read-only checked box when the lead's email was
 * pushed to the site's subscriber group; otherwise a short REASON label
 * explaining why it can't be submitted:
 *   Unsubscribed — address previously opted out (never resurrected)
 *   Blocked      — MailerLite has the address as bounced / junk
 *   Excluded     — MailerLite not configured for this site / legacy skip
 * Transient states keep a checkbox: unchecked = not attempted, and a
 * 'failed' row stays an unchecked box (re-run the mass action to retry).
 * Shared by the Leads / Corporate / Customised / Franchise lead grids.
 */
class MMD_Leads_Block_Adminhtml_Leads_Grid_Renderer_Mailerlite
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $status = (string) $row->getData($this->getColumn()->getIndex());

        if ($status === MMD_Leads_Model_Lead::MAILERLITE_SENT) {
            return '<input type="checkbox" disabled checked="checked"'
                . ' title="Sent to MailerLite" onclick="return false;" />';
        }

        // Terminal "cannot submit" outcomes render as a reason label.
        $labels = array(
            MMD_Leads_Model_Lead::MAILERLITE_UNSUBSCRIBED
                => array('Unsubscribed', '#f59e0b', 'Previously unsubscribed — never re-added'),
            MMD_Leads_Model_Lead::MAILERLITE_BLOCKED
                => array('Blocked', '#f87171', 'MailerLite has this address as bounced / junk'),
            'bounced'
                => array('Blocked', '#f87171', 'MailerLite has this address as bounced'),
            'junk'
                => array('Blocked', '#f87171', 'MailerLite has this address as junk'),
            MMD_Leads_Model_Lead::MAILERLITE_SKIPPED
                => array('Excluded', '#64748b', 'Skipped — MailerLite not configured, or a pre-2026-07 skip; re-run Send to MailerLite to refresh the reason'),
        );
        if (isset($labels[$status])) {
            list($text, $color, $tip) = $labels[$status];
            return '<span style="color:' . $color . ';font-size:12px;" title="'
                . $this->escapeHtml($tip) . '">' . $text . '</span>';
        }

        // '' (never attempted) or 'failed' (transient API error) — an
        // unchecked box; both remain submittable via the mass action.
        $title = $status === MMD_Leads_Model_Lead::MAILERLITE_FAILED
            ? 'Failed (API error) — re-run Send to MailerLite to retry'
            : 'Not attempted';
        return '<input type="checkbox" disabled title="' . $this->escapeHtml($title)
            . '" onclick="return false;" />';
    }
}
