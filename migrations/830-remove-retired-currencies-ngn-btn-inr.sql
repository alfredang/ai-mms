-- 830: Remove retired-store currencies (NGN, BTN, INR) from the allowed-currency list.
-- Nigeria, Bhutan and India stores are retired; only SGD, MYR, GHS remain.
-- Partner-safe: strips only the retired tokens from whatever each site's
-- current allow list is — never overwrites the list wholesale, so MY/GH
-- (whose base/default currencies differ) keep their own configuration.
-- Idempotent: re-running is a no-op once the tokens are gone.

UPDATE core_config_data
SET value = TRIM(BOTH ',' FROM
        REPLACE(
        REPLACE(
        REPLACE(
            CONCAT(',', value, ','),
            ',NGN,', ','),
            ',BTN,', ','),
            ',INR,', ','))
WHERE path = 'currency/options/allow'
  AND (
        FIND_IN_SET('NGN', value) > 0
     OR FIND_IN_SET('BTN', value) > 0
     OR FIND_IN_SET('INR', value) > 0
  );
