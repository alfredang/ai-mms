-- 1560: C818 "Codex for Digital Marketing" -> "ChatGPT WORK for Digital Marketing"
--
-- Naming surfaces only, as requested: name, url_key/url_path (+ permanent 301
-- from every old path), meta_title, the cover-alt labels, and the re-rendered
-- cover PNG (the title is baked into the image). Overview, topics, meta
-- description/keywords, categories and trainers are deliberately NOT touched.
--
-- Keyed by SKU. The cover update is guarded on SG's old R2 URL, so partner
-- sites (own SKU-named covers) keep their image. Idempotent.
--
-- Post-deploy on prod: refreshProductRewrite(818) + flush, or the new slug
-- 404s (the indexer, not this SQL, mints the canonical is_system=1 row).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C818' LIMIT 1);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------- name / meta_title / url_key / url_path ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'name'       THEN 'ChatGPT WORK for Digital Marketing'
      WHEN 'meta_title' THEN 'ChatGPT WORK for Digital Marketing'
      WHEN 'url_key'    THEN 'chatgpt-work-for-digital-marketing'
      WHEN 'url_path'   THEN 'chatgpt-work-for-digital-marketing.html'
      ELSE 'ChatGPT WORK for Digital Marketing'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('name','meta_title','url_key','url_path',
                           'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'ChatGPT WORK for Digital Marketing'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- cover (SG render only) ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C818-20260926-002132.png'
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code = 'course_image_url'
  AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C818-20260830-062958.png';

-- ---------- 301s ----------
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug, under its OWN id_path. The system rows are deleted first: an
-- upsert onto them would be reclaimed by the next rewrite reindex, and a 301
-- left on id_path product/818 blocks the indexer from minting the new row.
DROP TEMPORARY TABLE IF EXISTS tmp_c818_old;
CREATE TEMPORARY TABLE tmp_c818_old AS
SELECT store_id, request_path FROM core_url_rewrite
WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
  AND (request_path = 'codex-for-digital-marketing.html'
       OR request_path LIKE '%/codex-for-digital-marketing.html');

DELETE r FROM core_url_rewrite r
JOIN tmp_c818_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/c818-codex-for-digital-marketing-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'chatgpt-work-for-digital-marketing.html', 0, 'RP',
       '1560: C818 renamed to ChatGPT WORK for Digital Marketing'
FROM tmp_c818_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_c818_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one
-- hop — including the earlier ai-vibe-coding-with-codex.html hop, which the
-- old Vue.js slugs were still chaining through
UPDATE core_url_rewrite
SET target_path = 'chatgpt-work-for-digital-marketing.html', options = 'RP'
WHERE is_system = 0
  AND (target_path IN ('codex-for-digital-marketing.html', 'ai-vibe-coding-with-codex.html')
       OR target_path LIKE '%/codex-for-digital-marketing.html'
       OR target_path LIKE '%/ai-vibe-coding-with-codex.html');

-- on-site search redirects (if any) — path swap keeps each site's own domain
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/codex-for-digital-marketing.html', '/chatgpt-work-for-digital-marketing.html')
WHERE redirect LIKE '%/codex-for-digital-marketing.html';
