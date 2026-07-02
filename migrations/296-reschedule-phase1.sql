-- Phase 1 WSQ reschedule automation (2026-07)
-- Adds: OTP table for email verification, structured fields on lead table,
--       transactional email template for the OTP code.

CREATE TABLE IF NOT EXISTS `mmd_reschedule_otp` (
  `otp_id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email`      VARCHAR(255) NOT NULL,
  `code`       CHAR(6)     NOT NULL,
  `expires_at` DATETIME    NOT NULL,
  `used`       TINYINT(1)  NOT NULL DEFAULT 0,
  `created_at` DATETIME    NOT NULL,
  PRIMARY KEY (`otp_id`),
  KEY `IDX_OTP_EMAIL`   (`email`),
  KEY `IDX_OTP_EXPIRES` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `mmd_reschedule_lead`
  ADD COLUMN `run_id`        VARCHAR(64) NULL DEFAULT NULL COMMENT 'LMS current course_run UUID or MMS run_id',
  ADD COLUMN `target_run_id` VARCHAR(64) NULL DEFAULT NULL COMMENT 'LMS target course_run UUID',
  ADD COLUMN `is_wsq`        TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '1 = WSQ (TGS- SKU)',
  ADD COLUMN `lms_status`    VARCHAR(32) NULL DEFAULT NULL COMMENT 'pending_push / pushed / failed',
  ADD COLUMN `lms_response`  TEXT        NULL DEFAULT NULL COMMENT 'JSON blob from LMS';

INSERT IGNORE INTO `core_email_template`
    (`template_code`, `template_text`, `template_type`, `template_subject`,
     `template_sender_name`, `template_sender_email`, `added_at`, `modified_at`)
VALUES (
    'MMD Reschedule OTP',
    '<p style="font-family:sans-serif;color:#374151;margin:0 0 12px;">Hi,</p>
<p style="font-family:sans-serif;color:#374151;margin:0 0 16px;">Your verification code for the <strong>TIA Class Reschedule</strong> form is:</p>
<p style="font-family:monospace;font-size:2rem;letter-spacing:0.4rem;font-weight:bold;color:#0d9488;margin:0 0 16px;">{{var code}}</p>
<p style="font-family:sans-serif;color:#374151;margin:0 0 8px;">This code expires in <strong>15 minutes</strong>.</p>
<p style="font-family:sans-serif;color:#6b7280;font-size:0.85rem;margin:0;">If you did not request this, you can safely ignore this email.</p>',
    2,
    'Your TIA Class Reschedule Verification Code',
    '{{config path="trans_email/ident_general/name"}}',
    '{{config path="trans_email/ident_general/email"}}',
    NOW(), NOW()
);
