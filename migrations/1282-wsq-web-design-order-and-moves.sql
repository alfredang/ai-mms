-- 1282: WSQ Web Design & Full Stack Courses (url_key 'wsq-web-design-cms-courses')
-- — move two courses out and pin the requested order for the remaining eight.
--
-- MOVED OUT of Web Design:
--   TGS-2023018988  WSQ - Google Workspace for SMEs -> WSQ Business
--                   (NOT yet in WSQ Business -> genuinely added there)
--   TGS-2021010366  WSQ - Application Integration with Docker and Kubernetes
--                   -> WSQ RPA & Automation (ALREADY a member at position 9 ->
--                   removal only; the INSERT IGNORE is a safety net)
--
-- "WSQ RPA & Automation" resolves to url_key 'wsq-rpa-automation-courses'
-- (cat 432) — note the catalog also has RPA (202 'rpa-api-it-automation-courses'
-- and 219 'rpa-courses') and n8n AI Automations (282); 432 is the WSQ one the
-- request links to.
--
-- No parent cleanup. Web Design (333) is a child of WSQ IT & Security (301), but
-- 301 carries 265 direct rows against a 77-product child union, so it is NOT a
-- 1265-style sub-categories-only parent like WSQ Media & Marketing (72). Both
-- courses keep their 301 rows deliberately — same call as 1280/1281.
--
-- Requested order:
--   1  TGS-2026064174  CASL - Vibe Coding for Basic Web Design
--   2  TGS-2021002504  WSQ - AI Vibe Coding for UI/UX
--   3  TGS-2020503531  WSQ - Building Professional Websites with WordPress
--   4  TGS-2021008635  WSQ - AI Vibe Coding for Full Stack Web Applications
--   5  TGS-2026064534  CASL - Build Full Stack React Web App with Vibe Coding
--   6  TGS-2021010365  WSQ - Create RESTful APIs and Web Apps with Python Flask
--   7  TGS-2026064472  CASL - AI Vibe Coding for REST API
--   8  TGS-2020505790  WSQ - SQL Fundamental for Beginners
--
-- All eight are TGS- and the category holds no C-prefix course, so the nightly
-- sweep has nothing to re-alphabetise and preserves TGS relative order — no
-- curated-allowlist entry needed. Business-key lookups only. Idempotent.

SET @wd := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-web-design-cms-courses' LIMIT 1);
SET @bz := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-business-courses' LIMIT 1);
SET @rpa := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-rpa-automation-courses' LIMIT 1);

-- 1. Ensure each mover exists in its destination ------------------------------

DROP TEMPORARY TABLE IF EXISTS tmp_wd_moves;
CREATE TEMPORARY TABLE tmp_wd_moves (sku VARCHAR(64) PRIMARY KEY, dest_id INT);
INSERT INTO tmp_wd_moves (sku, dest_id) VALUES
  ('TGS-2023018988', @bz),
  ('TGS-2021010366', @rpa);
DELETE FROM tmp_wd_moves WHERE dest_id IS NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT m.dest_id, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = m.dest_id)
FROM tmp_wd_moves m
JOIN catalog_product_entity p ON p.sku = m.sku;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT m.dest_id, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = m.dest_id),
       1, s.store_id, MAX(i.visibility)
FROM tmp_wd_moves m
JOIN catalog_product_entity p ON p.sku = m.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
GROUP BY m.dest_id, p.entity_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_wd_moves;

-- 2. Remove both from Web Design ----------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @wd AND @wd IS NOT NULL
  AND p.sku IN ('TGS-2023018988','TGS-2021010366');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @wd AND @wd IS NOT NULL
  AND p.sku IN ('TGS-2023018988','TGS-2021010366');

-- 3. Pin the requested order --------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064174' THEN -8
  WHEN 'TGS-2021002504' THEN -7
  WHEN 'TGS-2020503531' THEN -6
  WHEN 'TGS-2021008635' THEN -5
  WHEN 'TGS-2026064534' THEN -4
  WHEN 'TGS-2021010365' THEN -3
  WHEN 'TGS-2026064472' THEN -2
  WHEN 'TGS-2020505790' THEN -1
END
WHERE cp.category_id = @wd AND @wd IS NOT NULL
  AND p.sku IN ('TGS-2026064174','TGS-2021002504','TGS-2020503531','TGS-2021008635',
                'TGS-2026064534','TGS-2021010365','TGS-2026064472','TGS-2020505790');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064174' THEN -8
  WHEN 'TGS-2021002504' THEN -7
  WHEN 'TGS-2020503531' THEN -6
  WHEN 'TGS-2021008635' THEN -5
  WHEN 'TGS-2026064534' THEN -4
  WHEN 'TGS-2021010365' THEN -3
  WHEN 'TGS-2026064472' THEN -2
  WHEN 'TGS-2020505790' THEN -1
END
WHERE i.category_id = @wd AND @wd IS NOT NULL
  AND p.sku IN ('TGS-2026064174','TGS-2021002504','TGS-2020503531','TGS-2021008635',
                'TGS-2026064534','TGS-2021010365','TGS-2026064472','TGS-2020505790');
