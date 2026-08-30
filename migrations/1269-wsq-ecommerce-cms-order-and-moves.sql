-- 1269: WSQ e-Commerce & CMS Courses (url_key 'wsq-e-commerce-cms-courses') —
-- remove three unrelated courses, pin the requested order for the remaining six,
-- and add three courses to other series categories.
--
-- Requested order for e-Commerce & CMS:
--   1  TGS-2026064474  CASL - AI for eCommerce
--   2  TGS-2026064175  CASL - Build Your Own eCommerce Store with AI Vibe Coding
--   3  TGS-2026061330  WSQ - Managing E-Commerce Operations To Grow Sales
--   4  TGS-2020503531  WSQ - Building Professional Websites with WordPress
--   5  TGS-2023018262  WSQ - Build Your Online Presence and Website with Wix for Beginners
--   6  TGS-2023041080  WSQ - Mastering Notion for Content, Project, and Database Management
--
-- REMOVED from e-Commerce & CMS:
--   TGS-2022017524  WSQ - Business Process Automation with Power Automate and Copilot Studio Agents
--   TGS-2023040481  WSQ - Microsoft Dynamics 365 Fundamentals (CRM) (MB-910)
--   TGS-2024044051  WSQ - Microsoft 365 Copilot for Teams
-- e-Commerce & CMS is a child of WSQ Media & Marketing (cat 72), which per
-- migration 1265 lists ONLY courses reachable through its sub-categories. None
-- of these three sits in any OTHER child of 72, so their leftover direct rows on
-- 72 are dropped too — otherwise they would keep showing on the parent page.
--
-- ADDED elsewhere (all three are genuinely new members of their destination):
--   TGS-2026064175  -> AI Vibe Coding Series      ('ai-vibe-coding-series')
--   TGS-2026064474  -> AI for Retail              ('ai-for-retail-courses', child of AI Applications Series)
--   TGS-2024044051  -> Microsoft Copilot Series   ('microsoft-copilot-series')
-- Those three destinations contain non-TGS (C-prefix) courses AND are already in
-- mmd/category_ordering/curated_url_keys, so the nightly sweep keeps their
-- curated order; the new TGS- rows sort into the WSQ block ahead of it.
--
-- Negative positions keep the pinned block ahead of anything unpinned; the daily
-- ordering sweep preserves TGS relative order. Business-key lookups only.
-- Idempotent.

SET @ec := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-e-commerce-cms-courses' LIMIT 1);
SET @mm := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-media-marketing-courses' LIMIT 1);

-- 1. Add the three courses to their new series categories --------------------

DROP TEMPORARY TABLE IF EXISTS tmp_ec_adds;
CREATE TEMPORARY TABLE tmp_ec_adds (sku VARCHAR(64) PRIMARY KEY, dest_id INT);
INSERT INTO tmp_ec_adds (sku, dest_id)
SELECT 'TGS-2026064175', v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-vibe-coding-series' LIMIT 1;
INSERT INTO tmp_ec_adds (sku, dest_id)
SELECT 'TGS-2026064474', v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-for-retail-courses' LIMIT 1;
INSERT INTO tmp_ec_adds (sku, dest_id)
SELECT 'TGS-2024044051', v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='microsoft-copilot-series' LIMIT 1;
DELETE FROM tmp_ec_adds WHERE dest_id IS NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT m.dest_id, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = m.dest_id)
FROM tmp_ec_adds m
JOIN catalog_product_entity p ON p.sku = m.sku;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT m.dest_id, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = m.dest_id),
       1, s.store_id, MAX(i.visibility)
FROM tmp_ec_adds m
JOIN catalog_product_entity p ON p.sku = m.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
GROUP BY m.dest_id, p.entity_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_ec_adds;

-- 2. Remove the three courses from e-Commerce & CMS --------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @ec AND @ec IS NOT NULL
  AND p.sku IN ('TGS-2022017524','TGS-2023040481','TGS-2024044051');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @ec AND @ec IS NOT NULL
  AND p.sku IN ('TGS-2022017524','TGS-2023040481','TGS-2024044051');

-- 3. Drop their leftover rows on the Media & Marketing parent -----------------
-- Only where the product is no longer reachable through ANY child of 72.
-- Materialised first: MySQL cannot read the table it is deleting from (1093).

DROP TEMPORARY TABLE IF EXISTS tmp_ec_still_child;
CREATE TEMPORARY TABLE tmp_ec_still_child (product_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_ec_still_child (product_id)
SELECT c2.product_id
FROM catalog_category_product c2
JOIN catalog_category_entity ce ON ce.entity_id = c2.category_id AND ce.parent_id = @mm
JOIN catalog_product_entity p ON p.entity_id = c2.product_id
WHERE @mm IS NOT NULL
  AND p.sku IN ('TGS-2022017524','TGS-2023040481','TGS-2024044051');

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @mm AND @mm IS NOT NULL
  AND p.sku IN ('TGS-2022017524','TGS-2023040481','TGS-2024044051')
  AND cp.product_id NOT IN (SELECT product_id FROM tmp_ec_still_child);

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @mm AND @mm IS NOT NULL
  AND p.sku IN ('TGS-2022017524','TGS-2023040481','TGS-2024044051')
  AND i.product_id NOT IN (SELECT product_id FROM tmp_ec_still_child);

DROP TEMPORARY TABLE IF EXISTS tmp_ec_still_child;

-- 4. Pin the requested e-Commerce & CMS order --------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064474' THEN -6
  WHEN 'TGS-2026064175' THEN -5
  WHEN 'TGS-2026061330' THEN -4
  WHEN 'TGS-2020503531' THEN -3
  WHEN 'TGS-2023018262' THEN -2
  WHEN 'TGS-2023041080' THEN -1
END
WHERE cp.category_id = @ec AND @ec IS NOT NULL
  AND p.sku IN ('TGS-2026064474','TGS-2026064175','TGS-2026061330',
                'TGS-2020503531','TGS-2023018262','TGS-2023041080');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064474' THEN -6
  WHEN 'TGS-2026064175' THEN -5
  WHEN 'TGS-2026061330' THEN -4
  WHEN 'TGS-2020503531' THEN -3
  WHEN 'TGS-2023018262' THEN -2
  WHEN 'TGS-2023041080' THEN -1
END
WHERE i.category_id = @ec AND @ec IS NOT NULL
  AND p.sku IN ('TGS-2026064474','TGS-2026064175','TGS-2026061330',
                'TGS-2020503531','TGS-2023018262','TGS-2023041080');
