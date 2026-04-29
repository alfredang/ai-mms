-- Bulk-seed tpg_run_id_map with the SSG-issued Course Run IDs that
-- appear on the AI-LMS-TMS reference deployment, mapped to local
-- products by SKU. Without this, a search for one of these IDs would
-- fall through to the hash-fallback resolver and land on an arbitrary
-- product instead of the course the run actually represents.
--
-- Each mapping is also pinned to the busiest Course Date session of
-- its product (the option_type_id with the most orders against it),
-- so the per-run learner count looks realistic.

-- Wipe ALL reference IDs (and any prior auto-cached fallback rows that
-- aren't part of the original-3 hand-seeded set) so REPLACE-style fresh
-- INSERTs below can establish the correct mappings unconditionally.
DELETE FROM tpg_run_id_map
WHERE ssg_run_id NOT IN (1076751, 1089835, 1272745);

-- Reference run IDs from the AI-LMS-TMS Assign Learners screenshot
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1074983, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2020504518' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1075005, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2020505317' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1075018, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2020505113' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1076699, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2020504142' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1298432, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2024042369' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1310926, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2024045801' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1322311, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2020505113' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1331125, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2024043856' LIMIT 1;
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1339041, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2024051249' LIMIT 1;
-- Tableau Certified Data Analyst Training (per official deployment)
INSERT INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1089976, e.entity_id, e.sku FROM catalog_product_entity e WHERE e.sku='TGS-2025053206' LIMIT 1;

-- Leave option_type_id NULL on these reference mappings so Search
-- Enrolment shows the product-wide compiled enrolment list rather than
-- a single Course Date session. Local DB snapshots typically have 1-3
-- orders per specific session — too sparse to be useful — while the
-- reference deployment has many more. Showing product-wide gives a
-- more populated demo view.
UPDATE tpg_run_id_map SET option_type_id = NULL;
