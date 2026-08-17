-- 1050: Re-assert the C688 slug claim from 1047 (repair migration).
--
-- WHY THIS EXISTS
-- 1047 renamed C924 -> "Generative AI for Agile Design Thinking", freeing the
-- slug 'generative-ai-for-design-thinking', and handed it to C688 (whose title
-- already is exactly that). Section 3 of 1047 deliberately DELETES C924's
-- old-bare-slug 301 so the path can resolve to C688's own canonical page.
--
-- On SG that half did not stick. Cause: a `catalog_url` reindex was run against
-- production BEFORE the 1047 build had deployed. The indexer regenerates a
-- product's old-slug 301s from its own rewrite history, so it re-created
--     generative-ai-for-design-thinking.html -> generative-ai-for-agile-...html
-- AFTER 1047 had cleared it. That row then squats the path, so C688 never gets
-- it and the URL 301s to the agile course instead of serving C688.
-- (Local replay against a prod-shaped state confirms 1047 itself is correct:
-- with the squatter present at apply time, 1047 clears it and C688 claims the
-- slug. The squatter here is purely reindex-regenerated, post-1047.)
--
-- Net effect on the storefront once this runs + catalog_url is reindexed:
--   generative-ai-for-agile-design-thinking.html -> 200 (C924)          [already OK]
--   generative-ai-for-design-thinking.html       -> 200 (C688)          [fixed here]
--   design-thinking-with-gen-ai.html             -> 301 -> C688's page  [fixed here]
--
-- Idempotent: every write is guarded; a re-run converges. Safe to run even if
-- 1047 already produced the correct end state (all statements become no-ops).
-- Partner-safe: C-prefix SKUs may exist on MY/GH but the slug/rewrite rows are
-- per-store; @e IS NULL guards make this a no-op where the SKU is absent.

SET @e924 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C924' LIMIT 1);
SET @e688 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C688' LIMIT 1);

SET @a_urlk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

SET @slug     := 'generative-ai-for-design-thinking';
SET @old_c688 := 'design-thinking-with-gen-ai';

-- 1. Remove the reindex-regenerated squatter on the shared path.
--    Scoped to is_system = 0 AND product_id = C924 so we only drop the stale
--    redirect, never C688's own (is_system = 1) canonical rewrite.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@slug, '.html')
   AND product_id = @e924
   AND is_system = 0
   AND @e924 IS NOT NULL;

-- 2. Re-assert C688's url_key (no-op if 1047 already set it).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_urlk, 0, @e688, @slug
 WHERE @e688 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e688 AND attribute_id = @a_urlk AND store_id <> 0 AND @e688 IS NOT NULL;

-- 3. Drop C688's url_path at EVERY scope so the indexer regenerates it from
--    url_key. Also clears any '-688' suffixed value a prior reindex wrote while
--    the path was squatted (the collision-suffix trap).
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e688 AND attribute_id = @a_urlp AND @e688 IS NOT NULL;

-- 4. Drop any suffixed system rewrite from a squatted reindex, so the indexer
--    is free to grant C688 the clean path on the next run.
DELETE FROM core_url_rewrite
 WHERE product_id = @e688
   AND request_path LIKE CONCAT(@slug, '-%')
   AND @e688 IS NOT NULL;

-- 5. C688's OWN old slug keeps a real 301 (options = 'RP'; an empty options
--    column is a 302 and transfers no ranking), at BOTH scopes.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@slug, '.html'), options = 'RP', is_system = 0
 WHERE request_path = CONCAT(@old_c688, '.html')
   AND store_id IN (0, 1)
   AND @e688 IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, @e688,
       CONCAT('manual-301-', MD5(CONCAT(@old_c688, '.html')), '-', s.store_id),
       CONCAT(@old_c688, '.html'), CONCAT(@slug, '.html'), 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @e688 IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@old_c688, '.html') AND x.store_id = s.store_id);
