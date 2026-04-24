-- Remove "Dr. Alfred Ang" from the trainers multiselect on every course
-- except C1434 (Mastering OpenClaw). Requested by angch@tertiaryinfotech.com —
-- courses had him bulk-assigned as a legacy placeholder trainer.
--
-- trainers is attribute_id 170 (multiselect), stored as a comma-separated CSV
-- of option_ids in catalog_product_entity_text.value. This migration rewrites
-- that CSV with the Alfred-Ang option_id stripped out for every product
-- except entity_id 1434, and NULLs the value if he was the only trainer.

SET @alfred_opt_id := (
    SELECT o.option_id
    FROM eav_attribute_option o
    JOIN eav_attribute_option_value v
      ON v.option_id = o.option_id AND v.store_id = 0
    WHERE o.attribute_id = 170 AND v.value = 'Dr. Alfred Ang'
    LIMIT 1
);

-- Strip the option_id from every CSV value. The REPLACE chain:
--   1. Normalize: remove spaces ("1, 2, 3" -> "1,2,3")
--   2. Wrap: ",1,2,3," so every id is bounded by commas
--   3. Remove ",ID,": matches the id anywhere in the list
--   4. Unwrap: strip leading/trailing commas
UPDATE catalog_product_entity_text
SET value = TRIM(BOTH ',' FROM
    REPLACE(
        CONCAT(',', REPLACE(value, ' ', ''), ','),
        CONCAT(',', @alfred_opt_id, ','),
        ','
    )
)
WHERE attribute_id = 170
  AND entity_id != 1434
  AND value IS NOT NULL
  AND value != ''
  AND FIND_IN_SET(@alfred_opt_id, REPLACE(value, ' ', '')) > 0;

-- Any row that became an empty string after removal: NULL it so the dashboard
-- doesn't treat "" as a meaningful trainer assignment.
UPDATE catalog_product_entity_text
SET value = NULL
WHERE attribute_id = 170
  AND entity_id != 1434
  AND value = '';
