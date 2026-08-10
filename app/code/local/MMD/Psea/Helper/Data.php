<?php
/**
 * PSEA submission mailer. Sends the learner's filled PSEA withdrawal form to
 * the ops mailboxes with the uploaded file attached. No lead/DB record is
 * created — the email IS the submission.
 *
 * Transport mirrors MMD_Certificate: prefer the Gmail OAuth helper (SG), fall
 * back to Zend_Mail (Aschroder SMTPPro transport applies automatically).
 *
 * Email HTML follows the dark-mode-safe pattern of the "MMD Lead
 * Notification" template: SOLID background colours only — never a CSS
 * gradient behind text. Gmail's dark theme inverts solid bg + text colours
 * coherently (contrast survives), but keeps gradients/background-images
 * while still inverting the text, which produced dark-on-dark headers.
 */
class MMD_Psea_Helper_Data extends Mage_Core_Helper_Abstract
{
    const TO_EMAIL = 'enquiry@tertiaryinfotech.com';
    const CC_EMAIL = 'sales@tertiarycourses.com.sg';

    /**
     * @param array $data  name, email, telephone, course_code, message
     * @param array $file  bytes, name, mime
     * @return bool
     */
    public function sendSubmission(array $data, array $file)
    {
        $subject = 'PSEA Form Submission — ' . $data['name']
            . ($data['course_code'] !== '' ? ' (' . $data['course_code'] . ')' : '');
        $body = $this->buildEmailHtml($data, $file['name']);

        // Prefer Gmail OAuth (SG). If it is configured but errors (expired /
        // revoked token), fall THROUGH to Zend_Mail instead of failing the
        // learner's submission — a transport problem must not lose the form.
        try {
            $gmail = Mage::helper('mmd_email/gmail');
            if ($gmail->isConfigured()) {
                $gmail->sendWithAttachment(
                    self::TO_EMAIL, $subject, $body,
                    $file['bytes'], $file['name'], $file['mime'],
                    'Tertiary Courses PSEA Submission',
                    array(self::CC_EMAIL),
                    $data['email']
                );
                return true;
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }

        try {
            $mail = new Zend_Mail('UTF-8');
            $mail->addTo(self::TO_EMAIL)
                 ->addCc(self::CC_EMAIL)
                 ->setFrom(
                     Mage::getStoreConfig('trans_email/ident_general/email') ?: self::CC_EMAIL,
                     'Tertiary Courses PSEA Submission'
                 )
                 ->setReplyTo($data['email'], $data['name'])
                 ->setSubject($subject)
                 ->setBodyHtml($body)
                 ->createAttachment(
                     $file['bytes'], $file['mime'],
                     Zend_Mime::DISPOSITION_ATTACHMENT, Zend_Mime::ENCODING_BASE64, $file['name']
                 );
            // Bare Zend_Mail::send() falls back to sendmail (absent in the
            // container) — route through the store's configured SMTPPro
            // transport, like every other transactional email on this site.
            $transport = null;
            try {
                $transport = Mage::helper('smtppro')->getTransport(Mage::app()->getStore()->getId());
            } catch (Exception $e) {
                Mage::logException($e);
            }
            $mail->send($transport);
            return true;
        } catch (Exception $e) {
            Mage::logException($e);
            return false;
        }
    }

    /**
     * Dark-mode-safe branded notification body (solid colours only).
     */
    public function buildEmailHtml(array $data, $attachName)
    {
        $e = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };
        $row = function ($label, $value) use ($e) {
            if (trim((string) $value) === '') {
                return '';
            }
            return '<tr><td style="padding:8px 0;width:170px;color:#64748b;border-bottom:1px solid #eef2f7;vertical-align:top;">'
                . $e($label)
                . '</td><td style="padding:8px 0;border-bottom:1px solid #eef2f7;color:#0f172a;">'
                . nl2br($e($value)) . '</td></tr>';
        };

        return '<div style="font-family:Arial,Helvetica,sans-serif;background:#f1f5f9;padding:24px 0;margin:0;">'
            . '<table align="center" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:12px;overflow:hidden;border:1px solid #e2e8f0;">'
            . '<tr><td style="background:#0f172a;padding:22px 28px;">'
            . '<div style="color:#ffffff;font-size:18px;font-weight:bold;">Tertiary Courses Singapore</div>'
            . '<div style="color:#4ade80;font-size:12px;letter-spacing:1px;text-transform:uppercase;margin-top:4px;">PSEA Form Submission</div>'
            . '</td></tr>'
            . '<tr><td style="padding:24px 28px;">'
            . '<p style="margin:0 0 16px;color:#0f172a;font-size:15px;line-height:1.5;">A learner submitted their filled <strong>PSEA Withdrawal Form</strong> (attached).</p>'
            . '<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;font-size:14px;">'
            . $row('Name', $data['name'])
            . '<tr><td style="padding:8px 0;width:170px;color:#64748b;border-bottom:1px solid #eef2f7;vertical-align:top;">Email</td>'
            . '<td style="padding:8px 0;border-bottom:1px solid #eef2f7;"><a href="mailto:' . $e($data['email']) . '" style="color:#0d9488;text-decoration:none;">' . $e($data['email']) . '</a></td></tr>'
            . $row('Phone', $data['telephone'])
            . $row('Course Code', $data['course_code'])
            . $row('Attached File', $attachName)
            . '</table>'
            . '<p style="margin:20px 0 6px;color:#64748b;font-size:12px;text-transform:uppercase;letter-spacing:1px;">Message</p>'
            . '<div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:14px 16px;color:#334155;font-size:14px;line-height:1.55;">'
            . (trim((string) $data['message']) !== '' ? nl2br($e($data['message'])) : '-')
            . '</div>'
            . '</td></tr>'
            . '<tr><td style="background:#f8fafc;padding:16px 28px;border-top:1px solid #e2e8f0;color:#94a3b8;font-size:12px;line-height:1.5;">'
            . 'Submitted via the PSEA submission form on tertiarycourses.com.sg. Reply to this email to respond directly to the learner.'
            . '</td></tr>'
            . '</table></div>';
    }
}
