-- 1085: Fix GSC "Page with redirect" — flatten 301 chains + drop 301->404 redirects.
--
-- WHY: Google Search Console flagged 1,063 pages under "Page with redirect"
-- (2026-08-24 coverage export). Root cause found on live SG:
--   (a) 143 two-hop chains  A -> B -> C  created by the accumulated WSQ->CASL /
--       AI-course renames: an older rename pointed A->B, a later rename pointed
--       B->C, and nothing ever re-pointed A. Google reports every hop.
--   (b) 12 rewrites whose target is `catalog/category/view/id/N` where category N
--       is is_active=0 (disabled). Those serve 301 -> 404, the worst shape:
--       the old URL keeps its redirect but lands on a dead page.
--
-- FIX: (a) re-point the first hop straight at the final target (single 301);
--      (b) delete the redirect rows that can only ever land on a 404, so the old
--          URL returns a clean 404 instead of 301->404.
--
-- Verified before writing: 0 three-hop chains, 0 self-loops, and all 25 distinct
-- final targets return HTTP 200 on https://www.tertiarycourses.com.sg/.
--
-- Set-based and idempotent: re-running is a no-op once no chain remains.
-- Partner-safe: operates only on rows that are themselves chained/dead on THIS
-- database, so a partner DB without these rows is untouched. No SKU/ID lists.

-- (a) Flatten A -> B -> C into A -> C. Repeated as a JOIN so it fixes every
--     chained row in one statement; the NOT LIKE guard keeps dead-category
--     targets out of here (they are handled by (b) below).
UPDATE core_url_rewrite a
JOIN core_url_rewrite b
  ON  b.request_path = a.target_path
  AND b.store_id     = a.store_id
  AND b.options IN ('R','RP')
SET a.target_path = b.target_path
WHERE a.options IN ('R','RP')
  AND b.target_path NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> b.target_path;

-- (b) Remove redirects that point at a DISABLED category (301 -> 404).
--     Deleting the rewrite lets the URL 404 directly, which is what Google
--     should see for a retired category page.
DELETE r FROM core_url_rewrite r
WHERE r.options IN ('R','RP')
  AND r.target_path LIKE 'catalog/category/view/id/%'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_category_entity_int cei
        JOIN eav_attribute ea
          ON ea.attribute_id = cei.attribute_id
         AND ea.attribute_code = 'is_active'
         AND ea.entity_type_id = (
               SELECT entity_type_id FROM eav_entity_type
               WHERE entity_type_code = 'catalog_category')
       WHERE cei.entity_id = CAST(SUBSTRING_INDEX(r.target_path,'/',-1) AS UNSIGNED)
         AND cei.store_id = 0
         AND cei.value = 1
      );

-- (c) Second flattening pass: a chain whose middle hop was deleted by (b) —
--     or whose target was itself rewritten by (a) — can leave one more level.
--     Cheap to run, no-op when clean.
UPDATE core_url_rewrite a
JOIN core_url_rewrite b
  ON  b.request_path = a.target_path
  AND b.store_id     = a.store_id
  AND b.options IN ('R','RP')
SET a.target_path = b.target_path
WHERE a.options IN ('R','RP')
  AND b.target_path NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> b.target_path;
