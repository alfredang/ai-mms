-- Enable local-currency display for each country website.
-- Base (transaction) currency remains SGD; storefront converts at the rate
-- stored in directory_currency_rate. Update rates via System > Manage Currency > Rates.

-- 1. Add all local currencies to the global allowed list.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'currency/options/allow', 'SGD,MYR,GHS,NGN,BTN,INR')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 2. Set default display currency per website.
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
('websites', 2, 'currency/options/default', 'MYR'),
('websites', 3, 'currency/options/default', 'GHS'),
('websites', 4, 'currency/options/default', 'NGN'),
('websites', 5, 'currency/options/default', 'BTN'),
('websites', 6, 'currency/options/default', 'INR')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 3. Seed placeholder exchange rates from SGD.
--    UPDATE THESE via the admin before going live:
--    System > Manage Currency > Rates
INSERT INTO directory_currency_rate (currency_from, currency_to, rate) VALUES
('SGD', 'MYR',  3.40),
('SGD', 'GHS',  12.00),
('SGD', 'NGN',  1200.00),
('SGD', 'BTN',  63.00),
('SGD', 'INR',  63.00),
('MYR', 'SGD',  0.2941),
('GHS', 'SGD',  0.0833),
('NGN', 'SGD',  0.0008),
('BTN', 'SGD',  0.0159),
('INR', 'SGD',  0.0159)
ON DUPLICATE KEY UPDATE rate = VALUES(rate);
