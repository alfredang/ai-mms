-- Course Info "Prerequisite" tab follows the Prerequisite card (user, 2026-10-25). 1862 gave every
-- non-WSQ course without a stated prerequisite the beginners line; where an active per-course
-- cms/block course_<SKU>_prerequisite exists (1858 C177, 1861 C437/C1098/C740), the tab now carries
-- the card's text instead, so the tab and the card never contradict each other.
-- Only replaces the exact beginners line written by 1862 -> a hand-written tab is left alone.
-- SG-only (store guard; the cards are SG-only) -> no-op on MY/GH. Idempotent.

SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @a := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @beg := '<h2>Prerequisite</h2>\n<p>This course is for beginners. No prerequisite is required.</p>\n';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
  JOIN cms_block b ON b.identifier = CONCAT('course_', TRIM(e.sku), '_prerequisite') COLLATE utf8_general_ci
   SET t.value = CONCAT('<h2>Prerequisite</h2>\n', TRIM(b.content), '\n', SUBSTRING(t.value, CHAR_LENGTH(@beg) + 1))
 WHERE @ok AND t.attribute_id = @a AND t.store_id = 0
   AND TRIM(e.sku) REGEXP '^C[0-9]'
   AND b.is_active = 1 AND TRIM(b.content) <> ''
   AND LEFT(t.value, CHAR_LENGTH(@beg)) = @beg;
