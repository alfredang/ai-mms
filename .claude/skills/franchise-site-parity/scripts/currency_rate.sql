-- Currency switcher: the allow-list is usually already set (currency/options/allow=<LOCAL>,USD;
-- base/default=<LOCAL>). It's hidden ONLY because there's no exchange rate. Add it. PARTNER-DB-ONLY.
-- Replace <LOCAL> (e.g. GHS, MYR) and the two rates (APPROX ok; tell admin to refresh to live).
INSERT INTO directory_currency_rate (currency_from, currency_to, rate) VALUES
  ('<LOCAL>','<LOCAL>', 1.000000000000),
  ('<LOCAL>','USD',     <usd_per_local>),      -- e.g. GHS->USD 0.0667  (1 USD ~ 15 GHS)
  ('USD','USD',         1.000000000000),
  ('USD','<LOCAL>',     <local_per_usd>)        -- e.g. USD->GHS 15
ON DUPLICATE KEY UPDATE rate = VALUES(rate);
-- If allow-list is NOT set: also
--   INSERT INTO core_config_data (scope,scope_id,path,value) VALUES
--     ('stores',<storeId>,'currency/options/allow','<LOCAL>,USD') ON DUPLICATE KEY UPDATE value=VALUES(value);
-- Flush cache. Verify homepage HTML has a "currency-switcher" with both options.
