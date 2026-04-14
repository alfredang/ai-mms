-- Disable MMD CustomOptions per-option inventory tracking.
-- When enabled, every course session (radio/select option) needed a linked
-- product SKU with stock data, otherwise the option renders disabled and
-- customers cannot click "Register Your Interest".

UPDATE core_config_data SET value='0' WHERE path='mmd_catalog/customoptions/inventory_enabled';
UPDATE core_config_data SET value='0' WHERE path='mageworx_catalog/customoptions/inventory_enabled';
