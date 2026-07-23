-- Rename C1148 "Project Management For Small & Medium Enterprises"
--             -> "Generative AI for Strategic Planning"
--
--   url_key: project-management-sme-training-singapore
--         -> generative-ai-for-strategic-planning
--   (301 from the old slug ships in 600, AFTER the catalog_url reindex)
--
-- Rebrand only: name, meta, image labels and the short_description intro. The
-- curriculum (description), price and duration are intentionally KEPT.
--
-- !! FOLLOW-UP REQUIRED — like C325/597, this is a SUBJECT change, not just an
-- AI rebrand of the same topic. The retained curriculum covers SME project
-- management (methodologies, project execution, SME hurdles) and does NOT
-- describe generative AI for strategic planning. Open items for a content pass:
--   1. Rewrite the `description` (topics) for generative AI / strategic planning.
--   2. C1148 remains in "Project Management" (125) — the new title is a strategy
--      /AI course, so revisit whether that category (and possibly an AI category)
--      is the right home. Left AS-IS here (rename-only scope).
--
-- Clears per-store overrides so partner store scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1148.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1148');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Generative AI for Strategic Planning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_uk, 0, @e, 'generative-ai-for-strategic-planning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Embark on a transformative journey with our Generative AI for Strategic Planning course, designed to show leaders and managers how generative AI can strengthen the way they plan and make decisions. This course equips participants with practical skills to apply generative AI to environmental scanning, scenario building, option analysis and strategy communication. With a focus on practical application, participants will learn where these tools genuinely add value and where human judgement must remain in charge.</p>
<p>Through a blend of interactive lectures, real-world case studies and hands-on exercises, participants will gain a working understanding of generative AI tools, effective prompting for strategy work, and the limits and risks involved, including hallucination, bias and confidentiality. By the end of the course, participants will be able to bring generative AI into their own planning cycle with confidence.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for Strategic Planning | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn to apply generative AI to strategic planning — scenario building, option analysis, effective prompting and the limits of AI in decision-making. Training in Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI for Strategic Planning, Generative AI, AI Strategy, Strategic Planning, Scenario Planning, AI for Managers, Decision Making, Business Strategy, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Generative AI for Strategic Planning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Generative AI for Strategic Planning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Generative AI for Strategic Planning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so partner store scopes can't shadow store 0.
DELETE v FROM catalog_product_entity_varchar v
WHERE v.entity_id = @e AND v.store_id <> 0
  AND v.attribute_id IN (@a_name, @a_uk, @a_mt, @a_il, @a_sil, @a_til);

DELETE v FROM catalog_product_entity_text v
WHERE v.entity_id = @e AND v.store_id <> 0
  AND v.attribute_id IN (@a_short, @a_md, @a_mk);

-- Drop stale url_path so the catalog_url reindex rebuilds from the new url_key.
DELETE v FROM catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4 AND a.attribute_code = 'url_path'
WHERE v.entity_id = @e;
