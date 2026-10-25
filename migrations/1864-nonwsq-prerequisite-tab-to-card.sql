-- Non-WSQ Course Info tabs, round 2 (user, 2026-10-25): the Course Info accordion carries
-- Minimum Entry Requirement | Minimum Software/Hardware Requirement (+ exam-info extras) only;
-- the Prerequisite moves out of the tab into the Prerequisite card (cms/block
-- course_<SKU>_prerequisite, rendered above Certification on C-prefix courses). Every non-WSQ
-- course gets a card: its stated prerequisite, or the beginners line 1862 wrote.
--   * an existing non-empty card (1858 C177, 1861 C437/C1098/C740) is kept as is;
--   * a Prerequisite section that actually holds entry requirements (C728: Knowledge and
--     Skills / Attitude / Experience, from 1851) becomes the Minimum Entry Requirement tab, and
--     its lead sentence goes on the card after the beginners line.
-- Works on the 1862 layout only (value starts with the Prerequisite heading) -> idempotent.
-- SG-only (store guard); MY/GH get the same change DB-only.

SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @a := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @h1 := '<h2>Prerequisite</h2>\n';
SET @h2 := '\n<h2>Minimum Entry Requirement</h2>';
SET @hs := '\n<h2>Minimum Software/Hardware Requirement</h2>';
SET @ks := '<p>Knowledge and Skills</p>';
SET @beg := '<p>This course is for beginners. No prerequisite is required.</p>';

DROP TEMPORARY TABLE IF EXISTS tmp_prereq_card;
CREATE TEMPORARY TABLE tmp_prereq_card (value_id INT NOT NULL PRIMARY KEY, sku VARCHAR(64) NOT NULL,
  pre MEDIUMTEXT NOT NULL, rest MEDIUMTEXT NOT NULL) DEFAULT CHARSET = utf8;
INSERT INTO tmp_prereq_card (value_id, sku, pre, rest)
SELECT t.value_id, TRIM(e.sku),
       SUBSTRING(t.value, CHAR_LENGTH(@h1) + 1, LOCATE(@h2, t.value) - CHAR_LENGTH(@h1) - 1),
       SUBSTRING(t.value, LOCATE(@h2, t.value) + 1)
  FROM catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
 WHERE @ok AND t.attribute_id = @a AND t.store_id = 0
   AND TRIM(e.sku) REGEXP '^C[0-9]'
   AND LEFT(t.value, CHAR_LENGTH(@h1)) = @h1 AND LOCATE(@h2, t.value) > 0;

-- entry requirements filed under Prerequisite: they become the Entry tab, the lead sentence goes on the card
UPDATE tmp_prereq_card
   SET rest = CONCAT('<h2>Minimum Entry Requirement</h2>\n', SUBSTRING(pre, LOCATE(@ks, pre)),
                     SUBSTRING(rest, LOCATE(@hs, rest))),
       pre  = TRIM(CONCAT(@beg, '\n', TRIM(LEFT(pre, LOCATE(@ks, pre) - 1))))
 WHERE LOCATE(@ks, pre) > 0 AND LOCATE(@hs, rest) > 0;

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', p.sku, ' - Prerequisite'), CONCAT('course_', p.sku, '_prerequisite'), TRIM(p.pre), NOW(), NOW(), 1
  FROM tmp_prereq_card p
 WHERE TRIM(p.pre) <> ''
   AND NOT EXISTS (SELECT 1 FROM cms_block b
                    WHERE b.identifier = CONCAT('course_', p.sku, '_prerequisite') COLLATE utf8_general_ci);

UPDATE cms_block b
  JOIN tmp_prereq_card p ON b.identifier = CONCAT('course_', p.sku, '_prerequisite') COLLATE utf8_general_ci
   SET b.content = TRIM(p.pre), b.is_active = 1, b.update_time = NOW()
 WHERE TRIM(IFNULL(b.content, '')) = '' AND TRIM(p.pre) <> '';

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
  FROM cms_block b
  JOIN tmp_prereq_card p ON b.identifier = CONCAT('course_', p.sku, '_prerequisite') COLLATE utf8_general_ci;

UPDATE catalog_product_entity_text t
  JOIN tmp_prereq_card p ON p.value_id = t.value_id
   SET t.value = p.rest;

DROP TEMPORARY TABLE IF EXISTS tmp_prereq_card;
