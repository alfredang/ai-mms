-- 1033: TGS-2020505550 (Data Storytelling with Tableau) — move the Learning
-- Outcomes out of the course description and into the per-course
-- `course_TGS-2020505550_learning_outcomes` cms/block, so they render in the
-- Learning Outcomes card instead of inside "What's This Course About".
--
-- Why this course was wrong on BOTH paths (nothing rendered in the card):
--   * it has NO `_learning_outcomes` cms_block at all (predates the 885-891
--     extraction) -> the block path yields nothing; and
--   * its inline heading reads "<h2>Course Learning Outcomes</h2>", while
--     view.phtml::$_extractSection anchors the title immediately after the
--     <h[1-6]> (inline wrappers aside). The leading "Course " means the
--     'Learning\s+Outcomes' pattern never matches -> the regex fallback also
--     yields nothing, and the LOs stay in the About narrative.
-- So BOTH halves are required: seed the block AND strip the section.
--
-- Data-only (view.phtml already reads block-first with regex fallback).
-- Block content is the section BODY only, with no <h2> — matching all 298
-- existing *_learning_outcomes blocks; the card supplies its own heading.
-- The section is the TAIL of short_description, so the strip is an exact-byte
-- REPLACE of the trailing chunk (no following wrapper <div> to preserve).
-- Byte-exact literals verified identical local vs prod (md5 93077e55..., 1559 B).
-- Idempotent: guarded INSERT, and the REPLACE no-ops once applied or on any
-- partner row whose bytes diverge.

SET @sku := 'TGS-2020505550';
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = @sku LIMIT 1);
SET @a_sd := (SELECT attribute_id FROM eav_attribute
              WHERE entity_type_id = 4 AND attribute_code = 'short_description' LIMIT 1);
SET @ident := CONCAT('course_', @sku, '_learning_outcomes');
SET @lo_body := UNHEX('3C703E42792074686520656E64206F662074686520636F757273652C206C6561726E6572732077696C6C2062652061626C6520746F266E6273703B3C2F703E0D0A3C756C3E0D0A3C6C693E4C4F313A205574696C697A65205461626C65617520666F7220646174612076697375616C697A6174696F6E266E6273703B3C2F6C693E0D0A3C6C693E4C4F323A266E6273703B4964656E74696679207472656E647320616E64207061747465726E732066726F6D20646174613C2F6C693E0D0A3C6C693E4C4F333A266E6273703B446576656C6F702064617368626F6172647320616E642073746F7269657320666F7220646174612073746F727974656C6C696E673C2F6C693E0D0A3C6C693E4C4F343A266E6273703B50726573656E742073746F7269657320746F207374616B65686F6C6465727320616E64207265766965772077697468207375626A656374206D617474657220657870657274733C2F6C693E0D0A3C6C693E4C4F353A266E6273703B44657369676E20696E7465726163746976652076697375616C697A6174696F6E7320666F7220646174612073746F727974656C6C696E673C2F6C693E0D0A3C2F756C3E');
SET @lo_section := UNHEX('0D0A3C68323E436F75727365204C6561726E696E67204F7574636F6D65733C2F68323E0D0A3C703E42792074686520656E64206F662074686520636F757273652C206C6561726E6572732077696C6C2062652061626C6520746F266E6273703B3C2F703E0D0A3C756C3E0D0A3C6C693E4C4F313A205574696C697A65205461626C65617520666F7220646174612076697375616C697A6174696F6E266E6273703B3C2F6C693E0D0A3C6C693E4C4F323A266E6273703B4964656E74696679207472656E647320616E64207061747465726E732066726F6D20646174613C2F6C693E0D0A3C6C693E4C4F333A266E6273703B446576656C6F702064617368626F6172647320616E642073746F7269657320666F7220646174612073746F727974656C6C696E673C2F6C693E0D0A3C6C693E4C4F343A266E6273703B50726573656E742073746F7269657320746F207374616B65686F6C6465727320616E64207265766965772077697468207375626A656374206D617474657220657870657274733C2F6C693E0D0A3C6C693E4C4F353A266E6273703B44657369676E20696E7465726163746976652076697375616C697A6174696F6E7320666F7220646174612073746F727974656C6C696E673C2F6C693E0D0A3C2F756C3E');

-- 1) Seed the cms/block (only if this course doesn't already have one).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', @sku, ' Learning Outcomes'), @ident, @lo_body, NOW(), NOW(), 1
FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b WHERE b.identifier = @ident);

-- Map to the "All Store Views" scope (store 0), like every other course block.
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b WHERE b.identifier = @ident;

-- 2) Strip the section from short_description (all stores that carry the bytes).
UPDATE catalog_product_entity_text v
SET v.value = REPLACE(v.value, @lo_section, '')
WHERE v.entity_id = @e
  AND v.attribute_id = @a_sd
  AND @e IS NOT NULL
  AND LOCATE(@lo_section, v.value) > 0;
