-- Disable every EMPTY category on each instance — a category whose storefront
-- index (catalog_category_product_index) holds ZERO products on THIS site.
-- Sets is_active=0 + include_in_menu=0 at store 0 so the page 404s and it drops
-- off the mega-menu.
--
-- CATALOG PARITY MODEL (per the franchise rules): non-WSQ (C-prefix) courses and
-- the category tree are the SAME across SG/MY/GH; SG additionally carries WSQ +
-- IBF (TGS-prefix). So:
--   * A category empty on SG is empty on MY/GH too (same C-catalog) — disable everywhere.
--   * MY/GH have NO WSQ courses, so categories populated on SG ONLY by WSQ
--     courses are empty on MY/GH — this same migration disables those extra
--     empties there automatically, because the guard is per-instance index count.
--   * SG should not carry HRDF/Malaysia-only categories (e.g.
--     "recommended-hrdf-courses-malaysia") — empty on SG, so disabled here.
--
-- PARTNER-SAFE BY CONSTRUCTION: the disable is CONDITIONAL on this instance's
-- own storefront-index emptiness, evaluated per category. A category with a live
-- product on a given site keeps its index rows and is skipped there. No SKU list,
-- no hardcoded ids — categories resolved by url_key. M-prefix products carry
-- status=1 at store 0 but are excluded from a store's index unless assigned to
-- that store's website, so the index is the correct emptiness test (a store-0
-- status count would falsely read non-empty). Idempotent. Re-runnable.
--
-- NOTE: this deliberately does NOT touch the many empty mega-menu LANDING-PAGE
-- categories (Enquiry, Refund Request, Assessment Appeal Form, Pearson Vue Exams,
-- Associate Trainer, etc.) — those are functional form/CMS menu links with no
-- products by design. Only categories that are meant to LIST courses are named
-- here, so a landing page is never disabled by accident.

SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');
SET @a_ckey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');

-- Course-listing categories to disable IF empty on this instance (by url_key).
DROP TEMPORARY TABLE IF EXISTS tmp_empty_cat_targets;
CREATE TEMPORARY TABLE tmp_empty_cat_targets (url_key VARCHAR(255) PRIMARY KEY);
INSERT INTO tmp_empty_cat_targets (url_key) VALUES
  ('autodesk-navisworks-training'),
  ('flutter-courses'),
  ('learning-management-system-lms-courses'),
  ('microsoft-access-training'),
  ('microsoft-onedrive-software-training'),
  ('recommended-hrdf-courses-malaysia');

-- Resolve to entity ids present on this instance, restricted to those with an
-- EMPTY storefront index (no products in any store's index on this site).
DROP TEMPORARY TABLE IF EXISTS tmp_empty_cat_ids;
CREATE TEMPORARY TABLE tmp_empty_cat_ids (entity_id INT PRIMARY KEY);
INSERT INTO tmp_empty_cat_ids (entity_id)
SELECT c.entity_id
FROM catalog_category_entity c
JOIN catalog_category_entity_varchar uk
  ON uk.entity_id=c.entity_id AND uk.store_id=0 AND uk.attribute_id=@a_ckey
JOIN tmp_empty_cat_targets t ON t.url_key = uk.value
WHERE (SELECT COUNT(*) FROM catalog_category_product_index x WHERE x.category_id=c.entity_id) = 0;

-- Disable: is_active=0.
UPDATE catalog_category_entity_int ci
JOIN tmp_empty_cat_ids ids ON ids.entity_id=ci.entity_id
SET ci.value=0
WHERE ci.store_id=0 AND ci.attribute_id=@a_active;

-- Drop from menu: include_in_menu=0 (insert the row if the category never had one).
UPDATE catalog_category_entity_int ci
JOIN tmp_empty_cat_ids ids ON ids.entity_id=ci.entity_id
SET ci.value=0
WHERE ci.store_id=0 AND ci.attribute_id=@a_menu;
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, ids.entity_id, 0
FROM tmp_empty_cat_ids ids
WHERE NOT EXISTS (
  SELECT 1 FROM catalog_category_entity_int ci
  WHERE ci.entity_id=ids.entity_id AND ci.store_id=0 AND ci.attribute_id=@a_menu);

DROP TEMPORARY TABLE IF EXISTS tmp_empty_cat_targets;
DROP TEMPORARY TABLE IF EXISTS tmp_empty_cat_ids;
