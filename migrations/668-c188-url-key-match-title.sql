-- C188 was repurposed to "AI Vibe Coding for Python Financial Analysis"
-- (migration 641, url_key intentionally left unchanged then). This brings the
-- URL in line with the title:
--   python-machine-learning-scikit-learn -> ai-vibe-coding-for-python-financial-analysis
--
-- Market-neutral (keys off SKU, store 0), same pattern as migration 354.
-- The 301 from the OLD slug to the new one is written by the catalog_url
-- reindex AFTER this runs (catalog/seo/save_rewrites_history = 1) — run the
-- reindex API (/reindex/api/run?token=...&flush=1) on each site after deploy.
--
-- Also retargets the pre-existing legacy RP rewrites and catalogsearch_query
-- redirects that point at the old slug, so nothing 301-chains. REPLACE keeps
-- each site's own domain intact. Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=4);

UPDATE catalog_product_entity_varchar v
JOIN catalog_product_entity e ON e.entity_id = v.entity_id
SET v.value = 'ai-vibe-coding-for-python-financial-analysis'
WHERE v.attribute_id = @uk AND v.store_id = 0
  AND e.sku = 'C188';

-- Legacy custom 301s that still target the old slug -> point straight at the new one
UPDATE core_url_rewrite
SET target_path = 'ai-vibe-coding-for-python-financial-analysis.html'
WHERE target_path = 'python-machine-learning-scikit-learn.html'
  AND options = 'RP';

-- Search-term redirects: swap the path, keep each site's own domain
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/python-machine-learning-scikit-learn.html', '/ai-vibe-coding-for-python-financial-analysis.html')
WHERE redirect LIKE '%/python-machine-learning-scikit-learn.html';
