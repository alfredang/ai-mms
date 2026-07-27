-- 821: Fix lead-notification emails showing the sales mailbox as the applicant.
--      Mage_Core_Model_Email_Template::send() overwrites template vars 'name' and
--      'email' with the RECIPIENT's identity (Tertiary Courses Singapore
--      <sales@tertiarycourses.com.sg>), so {{var name}}/{{var email}} in the
--      "MMD Lead Notification" template never showed the actual lead. Rename the
--      vars to lead_name/lead_email (MMD_LeadMail_Helper_Data now passes these).
--      Idempotent: REPLACE() finds nothing on re-run. No-op where the template
--      row does not exist (partner instances are guarded by the WHERE clause).

UPDATE core_email_template
SET template_text = REPLACE(REPLACE(template_text, '{{var name}}', '{{var lead_name}}'), '{{var email}}', '{{var lead_email}}'),
    template_subject = REPLACE(REPLACE(template_subject, '{{var name}}', '{{var lead_name}}'), '{{var email}}', '{{var lead_email}}'),
    modified_at = NOW()
WHERE template_code = 'MMD Lead Notification';
