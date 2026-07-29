-- 833: Re-sync course_runs.course_sku to the product's CURRENT sku.
--
-- course_sku is a display snapshot taken when the class was formed (run
-- matching uses product_id + course_start_date, never the sku). On SG,
-- ~3.4k historical runs still carried legacy SSG reference codes
-- (CRS-N-00xxxxx) from before those courses were renamed to the canonical
-- course-code convention: TGS-* (funded) / C* (non-funded). Backfill from
-- the live catalog so every surface reading course_sku (Classes grid,
-- Attendance, Certificates, agent/course APIs) shows the current code.
--
-- Partner-safe: joins this site's own catalog_product_entity, so MY/GH
-- M* codes just re-sync to their own current values. Idempotent: once
-- values match, re-runs update nothing. Runs whose product was deleted
-- keep their snapshot (no join hit).
UPDATE course_runs cr
INNER JOIN catalog_product_entity pe ON pe.entity_id = cr.product_id
SET cr.course_sku = TRIM(pe.sku)
WHERE TRIM(pe.sku) <> ''
  AND cr.course_sku <> TRIM(pe.sku);
