-- 271: Refund form redesign — add NRIC, course_code, net_amount_paid,
--      skillsfuture_claimed, refund_amount. Existing reused: course=Course Title,
--      order_ref=Order/Invoice No. Guarded so re-runs are no-ops.
SET @t := 'mmd_refund_lead';
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_refund_lead' AND COLUMN_NAME='nric');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_refund_lead` ADD COLUMN `nric` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `name`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_refund_lead' AND COLUMN_NAME='course_code');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_refund_lead` ADD COLUMN `course_code` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `course`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_refund_lead' AND COLUMN_NAME='net_amount_paid');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_refund_lead` ADD COLUMN `net_amount_paid` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `order_ref`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_refund_lead' AND COLUMN_NAME='skillsfuture_claimed');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_refund_lead` ADD COLUMN `skillsfuture_claimed` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `net_amount_paid`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_refund_lead' AND COLUMN_NAME='refund_amount');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_refund_lead` ADD COLUMN `refund_amount` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `skillsfuture_claimed`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
