-- The two SG non-WSQ courses 1862/1864 could not reach (user, 2026-10-25):
--   C525  Finance for Non-Finance Managers - Course Info value was NULL -> standard Entry tab (the
--         site default, copied from C012) + laptop/browser Software tab; beginners Prerequisite card.
--   C1235 Building Mobile UI with Flutter (disabled) - still the old Prerequisite | Software
--         Requirement layout -> Entry + Minimum Software/Hardware tabs; its prerequisite moves to the card.
-- Each step only fires on the exact old state -> idempotent. SG-only (store guard).

SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @a := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @hs := '\n<h2>Minimum Software/Hardware Requirement</h2>';
SET @entry := (SELECT SUBSTRING(t.value, 1, LOCATE(@hs, t.value))
                 FROM catalog_product_entity_text t JOIN catalog_product_entity e ON e.entity_id = t.entity_id
                WHERE t.attribute_id = @a AND t.store_id = 0 AND TRIM(e.sku) = 'C012'
                  AND t.value LIKE '<h2>Minimum Entry Requirement</h2>%' AND LOCATE(@hs, t.value) > 0);
SET @beg := '<p>This course is for beginners. No prerequisite is required.</p>';

-- C525
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
   SET t.value = CONCAT(@entry, '<h2>Minimum Software/Hardware Requirement</h2>\n',
       '<p><strong>Software:</strong></p>\n<p>You will need the following for this course:</p>\n<ul>\n',
       '<li>A web browser such as Google Chrome, Microsoft Edge or Safari &ndash; free</li>\n',
       '<li>Access to the course materials provided in class</li>\n</ul>\n',
       '<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>\n')
 WHERE @ok AND @entry IS NOT NULL AND t.attribute_id = @a AND t.store_id = 0 AND TRIM(e.sku) = 'C525'
   AND TRIM(IFNULL(t.value, '')) = '';

-- C1235: card first (from the old Prerequisite section), then the tab rewrite
SET @c1235 := (SELECT t.value FROM catalog_product_entity_text t JOIN catalog_product_entity e ON e.entity_id = t.entity_id
                WHERE @ok AND @entry IS NOT NULL AND t.attribute_id = @a AND t.store_id = 0 AND TRIM(e.sku) = 'C1235'
                  AND t.value LIKE '<h2>Prerequisite</h2>%' AND LOCATE('<h2>Software Requirement</h2>', t.value) > 0);
SET @pre := TRIM(SUBSTRING(@c1235, CHAR_LENGTH('<h2>Prerequisite</h2>') + 1,
                           LOCATE('<h2>Software Requirement</h2>', @c1235) - CHAR_LENGTH('<h2>Prerequisite</h2>') - 1));
SET @sw := TRIM(SUBSTRING(@c1235, LOCATE('<h2>Software Requirement</h2>', @c1235) + CHAR_LENGTH('<h2>Software Requirement</h2>')));

DROP TEMPORARY TABLE IF EXISTS tmp_card_fix;
CREATE TEMPORARY TABLE tmp_card_fix (sku VARCHAR(16) NOT NULL PRIMARY KEY, content TEXT NOT NULL) DEFAULT CHARSET = utf8;
INSERT INTO tmp_card_fix (sku, content)
SELECT 'C525', @beg FROM DUAL WHERE @ok AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'C525')
UNION ALL
SELECT 'C1235', @pre FROM DUAL WHERE @ok AND @c1235 IS NOT NULL AND @pre <> '';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', f.sku, ' - Prerequisite'), CONCAT('course_', f.sku, '_prerequisite'), f.content, NOW(), NOW(), 1
  FROM tmp_card_fix f
 WHERE NOT EXISTS (SELECT 1 FROM cms_block b WHERE b.identifier = CONCAT('course_', f.sku, '_prerequisite') COLLATE utf8_general_ci);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
  JOIN tmp_card_fix f ON b.identifier = CONCAT('course_', f.sku, '_prerequisite') COLLATE utf8_general_ci;

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
   SET t.value = CONCAT(@entry, '<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n', @sw,
                        '\n<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>\n')
 WHERE @ok AND @c1235 IS NOT NULL AND t.attribute_id = @a AND t.store_id = 0 AND TRIM(e.sku) = 'C1235'
   AND t.value = @c1235;

DROP TEMPORARY TABLE IF EXISTS tmp_card_fix;
