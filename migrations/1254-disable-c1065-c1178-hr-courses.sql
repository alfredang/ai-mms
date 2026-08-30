-- 1254: Disable two retired courses (status = 2):
--   C1065 - AI for Performance Management
--   C1178 - AI for Talent Management
--
-- Same pattern as migrations 833-842 and 1253: set the default-scope
-- (store_id 0) status to Disabled and flip any per-store override rows too —
-- an Enabled override keeps the course live on that store even when store 0
-- says Disabled.
--
-- Note: 1252 added both of these to the AI for HR subcategory. Disabling them
-- removes them from that listing (and from Business & Soft Skills, HR
-- Management, Soft Skills, Leadership and Coaching & Mentoring), leaving
-- AI for HR with its other seven courses. The category rows are left in place
-- so re-enabling later restores the memberships and their pinned positions;
-- a disabled product simply does not render.
--
-- No category is emptied by this: the smallest affected category
-- (Coaching & Mentoring) keeps another enabled course, so no category needs
-- deactivating the way 1253's Rhino category did.
--
-- A catalog reindex + cache flush after apply makes the change visible.
--
-- SG-guarded; C-prefix SKUs are SG-only (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C1065', 'C1178')
  AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well.
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr
  AND e.sku IN ('C1065', 'C1178')
  AND @is_sg > 0;
