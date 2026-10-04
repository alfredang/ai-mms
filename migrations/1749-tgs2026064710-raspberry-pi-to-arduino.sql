-- 1749: TGS-2026064710 "CASL - IoT with Arduino" belongs on the Arduino page
-- ('arduino-courses-in'), not Raspberry Pi ('raspberry-pi-courses-in').
--
-- 1. Add it to Arduino right after the existing TGS- block (WSQ/CASL first,
--    then C- courses): it takes MAX(TGS- position)+1 and every non-TGS row at
--    or after that slot shifts down by one. A plain MAX(position)+1 append
--    would land it below the C- courses (see 1269 -> 1273).
-- 2. Remove it from Raspberry Pi. Parent-anchor check: Robotics & IoT keeps
--    its direct row on purpose — the course is still in Arduino / IoT there.
--
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites
-- (no TGS- courses). Idempotent: the shift runs only while the course is not
-- yet in Arduino.

SET @ard := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='arduino-courses-in' LIMIT 1);
SET @rpi := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='raspberry-pi-courses-in' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026064710' LIMIT 1);

SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product
  WHERE category_id = @ard AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @ard AND TRIM(p.sku) LIKE 'TGS-%');

-- 1. Make room after the TGS- block, then insert ----------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @ard IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @ard AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @ard IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @ard AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ard, @pid, @slot
FROM DUAL WHERE @ard IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ard, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @ard IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;

-- 2. Remove from Raspberry Pi --------------------------------------------------

DELETE FROM catalog_category_product
WHERE category_id = @rpi AND product_id = @pid AND @rpi IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id = @rpi AND product_id = @pid AND @rpi IS NOT NULL;
