-- Rename C325 "Microsoft Project Training" -> "Microsoft Planner Masterclass"
--
--   url_key: microsoft-project-training -> microsoft-planner-masterclass
--   (301 from the old slug ships in 598, AFTER the catalog_url reindex)
--
-- Rebrand only: name, meta, image labels and the short_description intro. The
-- curriculum (description), price and duration are intentionally KEPT.
--
-- !! FOLLOW-UP REQUIRED — this rename differs from the 595 batch. Those were
-- AI-rebrands of the SAME subject. Microsoft Project and Microsoft Planner are
-- DIFFERENT products, so the retained curriculum (task allocation, resource
-- allocation, project sharing in MS Project) does NOT describe Planner. Two
-- open items for a content pass:
--   1. Rewrite the `description` (topics) for Planner.
--   2. Category 236 is literally named "Microsoft Project" — decide whether
--      C325 should stay in it, move to a Planner category, or the category
--      itself gets renamed. Left AS-IS here (rename-only scope).
--
-- Clears per-store overrides so partner store scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C325.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C325');

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
SELECT 4, @a_name, 0, @e, 'Microsoft Planner Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_uk, 0, @e, 'microsoft-planner-masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>The Microsoft Planner Masterclass is tailored for professionals who want to harness Microsoft Planner for everyday team and task management. Beginning with the foundational concepts, participants will be guided through creating plans and buckets, assigning tasks, and tracking progress across a team. The course provides a systematic approach, ensuring learners can use Planner to its fullest potential in collaborative work.</p>
<p>Progressing deeper, the masterclass covers managing and sharing plans across a team and connecting Planner with the wider Microsoft 365 toolset, which is paramount for collaborative ventures. With an emphasis on hands-on learning, participants will engage in real-world scenarios, enabling them to apply their knowledge immediately and effectively.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Microsoft Planner Masterclass | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Microsoft Planner in this hands-on masterclass — create plans and buckets, assign and track team tasks, and collaborate across Microsoft 365. Training in Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Microsoft Planner, Microsoft Planner Masterclass, Planner Training, Task Management, Team Collaboration, Microsoft 365, Project Management, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Microsoft Planner Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Microsoft Planner Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Microsoft Planner Masterclass' FROM DUAL WHERE @e IS NOT NULL
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
