-- Disable retired course (set status = 2 / Disabled):
--   C742 - Deploy Kubernetes with AI
--
-- Same pattern as migration 1665: default-scope (store_id 0) status set to
-- Disabled plus any per-store override rows flipped too. Idempotent. A catalog
-- reindex + cache flush after deploy makes the change visible on the storefront.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE TRIM(e.sku) = 'C742'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well (an Enabled override
-- keeps the course live on that store even when store_id 0 is Disabled).
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND TRIM(e.sku) = 'C742';

-- Clear search-term redirects that pointed at the now-disabled course page so
-- they fall back to normal search results instead of 302-ing to a 404.
UPDATE catalogsearch_query
SET redirect = ''
WHERE redirect LIKE '%/deploy-kubernetes-with-ai.html%'
   OR redirect LIKE '%/ai-devops-with-kubernetes.html%';
