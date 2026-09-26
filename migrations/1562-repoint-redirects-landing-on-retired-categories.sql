-- 1562: re-point 301s that land on a RETIRED category (301 -> 404) at the
-- successor the owner already recorded for that category.
--
-- WHY: after 1561 flattened the redirect chains, 3,704 RP rows on SG prod still
-- ended on a rewrite of a category with is_active=0 (e.g. the AWS collision-suffix
-- ladders aws-certification-exams-5 -> ... -> aws-certification-exams-106.html,
-- whose row targets catalog/category/view/id/227, disabled). Googlebot follows
-- one 301 and gets a 404 -- the GSC "Not found (404)" / failed "Page with
-- redirect" validation classes.
--
-- Five of those categories (183 AWS, 227 + 404 AWS Certification Exam Prep,
-- 126 Marketing Analytics, 98 ERP & CRM) carry an `mmd_retire/<category_id>`
-- rewrite whose target_path IS the successor chosen when the category was
-- retired (certification-exam-prep-courses.html, digital-marketing-courses-in.html,
-- logistics-and-manufacturing-courses.html). 2,904 rows are fixable from that
-- record; the other 35 retired categories (282 rows) have no recorded successor
-- and are deliberately left alone (restore vs retire is an owner decision).
--
-- Rules (no hardcoded ids -- everything is derived from the mmd_retire rows, so
-- this is a silent no-op on a partner DB without them):
--   1. target is <retired-cat>/<product>.html and the product is ENABLED with a
--      live flat rewrite (id_path product/<id>, store 1)  -> the product's flat URL
--   2. target is <retired-cat>/<product>.html and the product is disabled/gone -> successor
--   3. target is the retired category itself                                  -> successor
-- Never writes a self-loop; idempotent; applied live on SG prod first (2026-09-26).

-- Rule 1: product still on sale -> its own flat URL.
UPDATE core_url_rewrite a
JOIN (
    SELECT t.request_path AS dead_target, p.request_path AS new_target
      FROM core_url_rewrite t
      JOIN core_url_rewrite r    ON r.id_path = CONCAT('mmd_retire/', t.category_id) AND r.store_id = 1 AND r.options IN ('R','RP')
      JOIN core_url_rewrite succ ON succ.request_path = r.target_path AND succ.options IS NULL AND succ.store_id = 1
      JOIN core_url_rewrite p    ON p.id_path = CONCAT('product/', t.product_id) AND p.store_id = 1 AND p.options IS NULL
      JOIN catalog_product_entity_int st ON st.entity_id = t.product_id AND st.store_id = 0 AND st.value = 1
       AND st.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'status' AND entity_type_id = 4)
     WHERE t.options IS NULL AND t.category_id IS NOT NULL AND t.product_id IS NOT NULL
     GROUP BY t.request_path, p.request_path
) m ON m.dead_target = a.target_path
SET a.target_path = m.new_target
WHERE a.options IN ('R','RP')
  AND m.new_target <> a.request_path;

-- Rules 2 + 3: retired product-in-category path, or the category itself -> successor.
UPDATE core_url_rewrite a
JOIN (
    SELECT t.request_path AS dead_target, r.target_path AS new_target
      FROM core_url_rewrite t
      JOIN core_url_rewrite r    ON r.id_path = CONCAT('mmd_retire/', t.category_id) AND r.store_id = 1 AND r.options IN ('R','RP')
      JOIN core_url_rewrite succ ON succ.request_path = r.target_path AND succ.options IS NULL AND succ.store_id = 1
      JOIN catalog_category_entity_int ia ON ia.entity_id = t.category_id AND ia.store_id = 0 AND ia.value = 0
       AND ia.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'is_active' AND entity_type_id = 3)
     WHERE t.options IS NULL AND t.category_id IS NOT NULL
     GROUP BY t.request_path, r.target_path
) m ON m.dead_target = a.target_path
SET a.target_path = m.new_target
WHERE a.options IN ('R','RP')
  AND m.new_target <> a.request_path;

-- Settle the chains this re-point creates (X -> <cat>-106.html -> successor):
-- the boot after 1561 added one more ladder rung per retired category, so the
-- rows pointing at the previous rung now sit two hops from the successor.
-- Same pass as 1561; two passes suffice for one rung, no-op once flat.
SET SESSION group_concat_max_len = 65535;

UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

