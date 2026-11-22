-- Native apps (TC LMS SG / MY / GH): the trainer account angch@tertiaryinfotech.com
-- uses the Light appearance. Everyone else keeps the default, System.
-- Safe on every site: the row only matters where this account signs in.
-- The account can still change it from Account > Appearance in the app.

INSERT INTO `mmd_mobile_profile` (`email`, `theme`, `updated_at`)
VALUES ('angch@tertiaryinfotech.com', 'light', UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE `theme` = 'light', `updated_at` = UTC_TIMESTAMP();
