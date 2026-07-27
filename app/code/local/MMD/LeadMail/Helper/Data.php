<?php
/**
 * Shared lead-notification mailer. Every MMD lead form (enquiry, franchise,
 * trainer, corporate, customised, hiring, appeal, refund, reschedule, course
 * feedback) routes its admin notification through here so they all share one
 * branded HTML layout, one recipient (Tertiary Courses Singapore
 * <sales@tertiarycourses.com.sg>) and the same CC list.
 */
class MMD_LeadMail_Helper_Data extends Mage_Core_Helper_Abstract
{
    const TEMPLATE_CODE = 'MMD Lead Notification';

    /**
     * @param string $leadType  e.g. "Trainer Application", "Franchise Enquiry"
     * @param array  $rows      list of array($label, $value) extra fields
     * @param array  $extraTo   additional To: recipients beyond the configured one
     */
    public function notify($leadType, $name, $email, $telephone, array $rows = array(), $message = '', array $extraTo = array(), $ccOverride = null)
    {
        try {
            $details = '';
            foreach ($rows as $r) {
                $label = isset($r[0]) ? (string) $r[0] : '';
                $value = isset($r[1]) ? (string) $r[1] : '';
                if (trim($value) === '') {
                    continue;
                }
                $details .= '<tr><td style="padding:8px 0;width:170px;color:#64748b;border-bottom:1px solid #eef2f7;vertical-align:top;">'
                    . $this->escapeHtml($label)
                    . '</td><td style="padding:8px 0;border-bottom:1px solid #eef2f7;color:#0f172a;">'
                    . nl2br($this->escapeHtml($value)) . '</td></tr>';
            }

            $id = Mage::getModel('core/email_template')->loadByCode(self::TEMPLATE_CODE)->getId();
            if (!$id) {
                Mage::log('MMD_LeadMail: template "' . self::TEMPLATE_CODE . '" not found', null, 'mmd_leadmail.log');
                return false;
            }

            $toEmail = Mage::getStoreConfig('mmd_leadmail/notify/to_email');
            $toName  = Mage::getStoreConfig('mmd_leadmail/notify/to_name');
            $cc      = ($ccOverride !== null)
                ? array_values(array_filter(array_map('trim', (array) $ccOverride)))
                : array_filter(array_map('trim', explode(',', (string) Mage::getStoreConfig('mmd_leadmail/notify/cc'))));
            $sender  = Mage::getStoreConfig('contacts/email/sender_email_identity') ?: 'general';

            $tpl = Mage::getModel('core/email_template');
            $tpl->setDesignConfig(array('area' => 'frontend', 'store' => Mage::app()->getStore()->getId()));
            // Pre-create the Zend_Mail so CC / extra-To survive sendTransactional().
            foreach ($cc as $ccAddr) {
                $tpl->getMail()->addCc($ccAddr);
            }
            foreach ($extraTo as $toAddr) {
                $toAddr = trim((string) $toAddr);
                if ($toAddr !== '') {
                    $tpl->getMail()->addTo($toAddr);
                }
            }
            if ($email) {
                $tpl->setReplyTo($email);
            }
            // NOTE: never name these vars 'name'/'email' — core send() overwrites
            // those two keys with the RECIPIENT's name/email (Template.php:389),
            // which made every notification show the sales mailbox as the lead.
            $tpl->sendTransactional($id, $sender, $toEmail, $toName, array(
                'lead_type'    => $this->escapeHtml($leadType),
                'lead_name'    => $this->escapeHtml($name),
                'lead_email'   => $this->escapeHtml($email),
                'telephone'    => $this->escapeHtml(trim((string) $telephone) !== '' ? $telephone : '-'),
                'details_html' => $details,
                'message'      => $this->escapeHtml(trim((string) $message) !== '' ? $message : '-'),
            ));
            return (bool) $tpl->getSentSuccess();
        } catch (Exception $e) {
            Mage::logException($e);
            return false;
        }
    }
}
