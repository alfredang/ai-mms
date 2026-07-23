-- Disable retired courses (set status = 2 / Disabled):
--   C384 - AI Vibe Coding for React Native
--   C683 - AI Vibe Coding for Flutter Development
--
-- Sets the default-scope (store_id 0) status to Disabled and flips any
-- per-store override rows to Disabled too, so the products drop off the
-- storefront on every store. Idempotent. A catalog reindex + cache flush
-- after deploy makes the change visible on the storefront.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C384', 'C683')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well (a per-store status
-- override left at Enabled keeps the course live on that store even when
-- store_id 0 is Disabled).
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C384', 'C683');

-- Clear search-term redirects that pointed at these now-disabled course pages
-- (c384/c0384/c0683 course-code terms) so they fall back to normal search
-- results instead of 302-ing to a 404. Same rationale as migration 632, which
-- ran before these courses were disabled.
UPDATE catalogsearch_query
SET redirect = ''
WHERE redirect LIKE '%/ai-vibe-coding-for-react-native.html%'
   OR redirect LIKE '%/ai-vibe-coding-for-flutter-development.html%';
