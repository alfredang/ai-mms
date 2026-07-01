-- 296-currency-rate-cleanup.sql
--
-- SG instance:    add SGD->USD if not present; keep all existing rates.
-- Country instances (MY/GH/NG/BT/IN): prune rates where currency_from =
--   local base currency, keeping only local->local (1.0), local->SGD,
--   local->USD. Rows from other source currencies are left untouched.
--
-- Detects which instance this is running on from core_config_data:
--   website-scoped currency/options/base takes precedence over default scope.

-- -----------------------------------------------------------------------
-- 1. Resolve the instance's effective base currency.
-- -----------------------------------------------------------------------
SET @base_currency = COALESCE(
    (SELECT value FROM core_config_data
     WHERE path = 'currency/options/base' AND scope = 'websites'
     ORDER BY scope_id ASC LIMIT 1),
    (SELECT value FROM core_config_data
     WHERE path = 'currency/options/base' AND scope = 'default'
     LIMIT 1)
);

-- -----------------------------------------------------------------------
-- 2. Country instances only: remove ALL rates except the three allowed
--    pairs {local->local, local->SGD, local->USD}.
--    This covers both local-currency rows with wrong targets AND rows
--    from other source currencies (e.g. GHS->* or INR->* on the MY DB).
-- -----------------------------------------------------------------------
DELETE FROM directory_currency_rate
WHERE @base_currency IS NOT NULL
  AND @base_currency != 'SGD'
  AND NOT (
      currency_from = @base_currency
      AND currency_to IN (@base_currency, 'SGD', 'USD')
  );

-- -----------------------------------------------------------------------
-- 3. Country instances only: ensure local->local (identity rate) exists.
-- -----------------------------------------------------------------------
INSERT IGNORE INTO directory_currency_rate (currency_from, currency_to, rate)
SELECT @base_currency, @base_currency, 1.0000
FROM DUAL
WHERE @base_currency IS NOT NULL
  AND @base_currency != 'SGD';

-- -----------------------------------------------------------------------
-- 4. All instances: add SGD->USD if not already present.
--    Rate is a placeholder (0.7400 ≈ current); update via
--    Admin > System > Manage Currency > Rates after deploy.
-- -----------------------------------------------------------------------
INSERT IGNORE INTO directory_currency_rate (currency_from, currency_to, rate)
VALUES ('SGD', 'USD', 0.7400);
