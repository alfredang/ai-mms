<?php

/**
 * Human-approval notice for the TMS availability sync.
 *
 * HARD RULE (user rule 2026-11-20): the sync cannot edit, hide or disable a
 * course. When SSG reports a different status for a course, the sync records it
 * and this helper emails the approver. Any change to the course itself is made
 * by a person in the admin, never by the sync.
 */
class MMD_Courses_Helper_Changenotice extends Mage_Core_Helper_Abstract
{
    const XML_APPROVER_EMAIL = 'courses/availability/approver_email';
    const DEFAULT_APPROVER   = 'angch@tertiaryinfotech.com';

    /** Config value "none" switches the email off (local development). */
    public function getApproverEmail()
    {
        $email = trim((string) Mage::getStoreConfig(self::XML_APPROVER_EMAIL));
        return $email !== '' ? $email : self::DEFAULT_APPROVER;
    }

    /**
     * @param array $changes rows of sku, name, url, old, new, reason, support_to
     * @return bool true when an email was sent
     */
    public function notify(array $changes)
    {
        if (!$changes) {
            return false;
        }
        $to = $this->getApproverEmail();
        if (strtolower($to) === 'none') {
            return false;
        }
        $subject = sprintf('Approval needed: SSG status changed for %d course(s), nothing was changed', count($changes));
        $body = $this->buildBody($changes);

        $gmail = Mage::helper('mmd_email/gmail');
        if ($gmail->isConfigured()) {
            $gmail->send($to, $subject, $body, 'Tertiary Courses');
            return true;
        }
        $mail = new Zend_Mail('UTF-8');
        $mail->addTo($to)
            ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'), 'Tertiary Courses')
            ->setSubject($subject)
            ->setBodyHtml($body)
            ->send();
        return true;
    }

    public function buildBody(array $changes)
    {
        $e = function ($v) {
            return htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8');
        };
        $td = 'style="padding:6px 10px;border:1px solid #d7dce5;font-size:13px;vertical-align:top;"';
        $rows = '';
        foreach ($changes as $c) {
            $rows .= '<tr>'
                . '<td ' . $td . '><a href="' . $e($c['url']) . '">' . $e($c['sku']) . '</a></td>'
                . '<td ' . $td . '>' . $e($c['name']) . '</td>'
                . '<td ' . $td . '>' . $e($c['old'] !== '' ? $c['old'] : 'not tracked') . '</td>'
                . '<td ' . $td . '><b>' . $e($c['new']) . '</b></td>'
                . '<td ' . $td . '>' . $e($c['reason']) . '</td>'
                . '<td ' . $td . '>' . $e($c['support_to'] !== '' ? $c['support_to'] : '-') . '</td>'
                . '</tr>';
        }
        return '<div style="font-family:Arial,Helvetica,sans-serif;color:#1f2937;font-size:14px;line-height:1.5;">'
            . '<p>The nightly TMS sync received a different SSG status for the course(s) below.</p>'
            . '<p><b>Nothing was changed on the website.</b> Every course is still enabled and visible. '
            . 'The sync cannot edit, hide or disable a course.</p>'
            . '<table style="border-collapse:collapse;">'
            . '<tr style="background:#eef2f8;"><th ' . $td . '>Course code</th><th ' . $td . '>Course</th>'
            . '<th ' . $td . '>Was</th><th ' . $td . '>Now</th><th ' . $td . '>SSG reason</th><th ' . $td . '>Support to</th></tr>'
            . $rows . '</table>'
            . '<p>If a course should change (for example, disable a course whose funding will not be renewed), '
            . 'reply to approve it or make the change in the admin: Courses, Edit Course. No action is needed to keep it as it is.</p>'
            . '<p style="color:#6b7280;font-size:12px;">Sent by ' . $e(Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB)) . ' (/courses/api_availability).</p>'
            . '</div>';
    }
}
