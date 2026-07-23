-- 567: Repair the 301s that migration 566 failed to create.
--
-- BUG IN 566: the INSERT was guarded with
--   NOT EXISTS (SELECT 1 FROM core_url_rewrite x
--               WHERE x.store_id = r.store_id AND x.request_path = old||'.html')
-- intended to make the migration idempotent. But Magento's own is_system=1
-- rewrite row for the category ALREADY has request_path = old||'.html' (it maps
-- the slug to catalog/category/view/id/N). So the guard matched on the very
-- first run and suppressed every 301 insert. 566 renamed the url_keys but left
-- no redirects behind.
--
-- Current state after 566: the old URL still resolves, but only via that stale
-- is_system=1 row, which the Catalog URL Rewrites reindex will delete or
-- re-point — at which point every old link 404s. This must land before that
-- reindex runs.
--
-- FIX: for each renamed category, convert the stale is_system row whose
-- request_path is the OLD slug into a proper is_system=0 / options='RP' 301
-- pointing at the new slug. That is exactly the shape Magento itself writes for
-- a url_key change, and it survives reindex (is_system=0 rows are preserved).
-- The stock is_system=1 row for the NEW slug is (re)created by the reindexer.
--
-- Guarded per category so it is a no-op if 566 was never applied or if the
-- repair already ran. Idempotent.
-- After deploy: reindex Catalog URL Rewrites + Category Flat Data, flush cache.

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

-- Convert stale is_system row (old slug) -> 301 to the new slug.
-- @old = the slug 566 renamed away from, @new = the slug now on the category.

-- ---------------------------------------------------------------- 81 --------
SET @old := 'life-science-courses-training';
SET @new := 'healthcare-and-wsh-courses';
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html'), is_system = 0, options = 'RP', description = 'slug 301 (567)'
WHERE product_id IS NULL AND request_path = CONCAT(@old, '.html')
  AND target_path <> CONCAT(@new, '.html')
  AND EXISTS (SELECT 1 FROM catalog_category_entity_varchar uk
              WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @new);

-- ---------------------------------------------------------------- 126 -------
SET @old := 'business-analytics-training-courses';
SET @new := 'marketing-analytics-courses';
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html'), is_system = 0, options = 'RP', description = 'slug 301 (567)'
WHERE product_id IS NULL AND request_path = CONCAT(@old, '.html')
  AND target_path <> CONCAT(@new, '.html')
  AND EXISTS (SELECT 1 FROM catalog_category_entity_varchar uk
              WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @new);

-- ---------------------------------------------------------------- 139 -------
SET @old := 'machine-learning-courses';
SET @new := 'ai-applications-series-courses';
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html'), is_system = 0, options = 'RP', description = 'slug 301 (567)'
WHERE product_id IS NULL AND request_path = CONCAT(@old, '.html')
  AND target_path <> CONCAT(@new, '.html')
  AND EXISTS (SELECT 1 FROM catalog_category_entity_varchar uk
              WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @new);

-- ---------------------------------------------------------------- 250 -------
SET @old := 'voice-agents-and-video-agents-coures';
SET @new := 'ai-devops-series-courses';
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html'), is_system = 0, options = 'RP', description = 'slug 301 (567)'
WHERE product_id IS NULL AND request_path = CONCAT(@old, '.html')
  AND target_path <> CONCAT(@new, '.html')
  AND EXISTS (SELECT 1 FROM catalog_category_entity_varchar uk
              WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @new);

-- ---------------------------------------------------------------- 314 -------
SET @old := 'ethereum-skillsfuture-courses-in';
SET @new := 'ethereum-blockchain-courses';
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html'), is_system = 0, options = 'RP', description = 'slug 301 (567)'
WHERE product_id IS NULL AND request_path = CONCAT(@old, '.html')
  AND target_path <> CONCAT(@new, '.html')
  AND EXISTS (SELECT 1 FROM catalog_category_entity_varchar uk
              WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @new);

-- Deep-path variants: FlatCategoryUrl means categories live at /<url_key>.html,
-- but legacy nested request_paths ending in /<old-slug>.html still exist from
-- before the flat-URL change. Re-point those at the new flat URL too.
UPDATE core_url_rewrite SET target_path = 'healthcare-and-wsh-courses.html', options = 'RP', is_system = 0
WHERE product_id IS NULL AND options = 'RP' AND target_path = 'life-science-courses-training.html';
UPDATE core_url_rewrite SET target_path = 'marketing-analytics-courses.html', options = 'RP', is_system = 0
WHERE product_id IS NULL AND options = 'RP' AND target_path = 'business-analytics-training-courses.html';
UPDATE core_url_rewrite SET target_path = 'ai-applications-series-courses.html', options = 'RP', is_system = 0
WHERE product_id IS NULL AND options = 'RP' AND target_path = 'machine-learning-courses.html';
UPDATE core_url_rewrite SET target_path = 'ai-devops-series-courses.html', options = 'RP', is_system = 0
WHERE product_id IS NULL AND options = 'RP' AND target_path = 'voice-agents-and-video-agents-coures.html';
UPDATE core_url_rewrite SET target_path = 'ethereum-blockchain-courses.html', options = 'RP', is_system = 0
WHERE product_id IS NULL AND options = 'RP' AND target_path = 'ethereum-skillsfuture-courses-in.html';
