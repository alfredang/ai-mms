-- 1312: Curate the "WSQ Digital Marketing Courses" listing
-- (/wsq-digital-marketing-courses.html, url_key wsq-digital-marketing-courses).
--
-- Three changes, all listing-membership / ordering only - no product data:
--
--   1. ADD two video courses that belong in the funded digital-marketing
--      listing but were never assigned:
--        TGS-2024043855  WSQ - Creating Engaging Videos with Generative AI (GenAI)
--        TGS-2023036088  WSQ - Agentic AI for Video Creation
--
--   2. REMOVE three courses that belong in other listings. Each is ALREADY
--      assigned to its destination category (verified on SG prod 2026-09-02),
--      so the "move" is a removal from this category only:
--        TGS-2023037472  WSQ - Business Innovation with Agentic AI and AI Agents
--                        -> already in wsq-business-courses
--        TGS-2025052342  WSQ - Closing Sales with Empathy-Driven People-Focused Selling
--                        -> already in wsq-soft-skills-courses
--        TGS-2025053924  WSQ - Service Branding Strategies to Elevate Your Business
--                        -> already in wsq-soft-skills-courses
--
--   3. PIN the remaining 16 courses to the owner-specified order (1..16).
--
-- ORDERING SAFETY: this category is TGS--ONLY, so the funded-first rule
-- (category-ordering skill) is satisfied trivially. The nightly sweep
-- MMD_RoleManager_Model_Cron_CategoryOrdering sorts TGS- rows by their
-- EXISTING position ("WSQ keep relative order"), so a dense 1..16 curated TGS
-- order is stable under it - no curated_url_keys exemption is needed (that
-- config only protects non-WSQ/C- blocks from re-alphabetisation).
--
-- Both tables are written: catalog_category_product (admin source of truth)
-- and catalog_category_product_index (what the storefront listing reads; no
-- reindex runs at deploy). Cat 308 has no anchor-inherited rows - every index
-- row has a matching base row - so a straight per-product write is complete.
--
-- Business-key lookups only (SKU + category url_key). Partner-safe: on MY/GH
-- neither the TGS- SKUs nor this category exist, so @cat/@pid resolve NULL and
-- every statement no-ops. Idempotent: re-running rewrites the same positions.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
             WHERE store_id = 0 AND attribute_id = @uk
               AND value = 'wsq-digital-marketing-courses' LIMIT 1);

-- ===========================================================================
-- STEP 1 - remove the three courses that moved to other listings.
-- Guarded on the destination actually holding the course, so this can never
-- orphan a course out of every listing.
-- ===========================================================================

SET @c_biz  := (SELECT entity_id FROM catalog_category_entity_varchar
                WHERE store_id = 0 AND attribute_id = @uk
                  AND value = 'wsq-business-courses' LIMIT 1);
SET @c_soft := (SELECT entity_id FROM catalog_category_entity_varchar
                WHERE store_id = 0 AND attribute_id = @uk
                  AND value = 'wsq-soft-skills-courses' LIMIT 1);

-- TGS-2023037472 -> WSQ Business Courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037472' LIMIT 1);
SET @ok  := (SELECT COUNT(*) FROM catalog_category_product
             WHERE category_id = @c_biz AND product_id = @pid);
DELETE FROM catalog_category_product
 WHERE category_id = @cat AND product_id = @pid AND @cat IS NOT NULL AND @pid IS NOT NULL AND @ok > 0;
DELETE FROM catalog_category_product_index
 WHERE category_id = @cat AND product_id = @pid AND @cat IS NOT NULL AND @pid IS NOT NULL AND @ok > 0;

-- TGS-2025052342 -> WSQ Soft Skills Courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052342' LIMIT 1);
SET @ok  := (SELECT COUNT(*) FROM catalog_category_product
             WHERE category_id = @c_soft AND product_id = @pid);
DELETE FROM catalog_category_product
 WHERE category_id = @cat AND product_id = @pid AND @cat IS NOT NULL AND @pid IS NOT NULL AND @ok > 0;
DELETE FROM catalog_category_product_index
 WHERE category_id = @cat AND product_id = @pid AND @cat IS NOT NULL AND @pid IS NOT NULL AND @ok > 0;

-- TGS-2025053924 -> WSQ Soft Skills Courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053924' LIMIT 1);
SET @ok  := (SELECT COUNT(*) FROM catalog_category_product
             WHERE category_id = @c_soft AND product_id = @pid);
DELETE FROM catalog_category_product
 WHERE category_id = @cat AND product_id = @pid AND @cat IS NOT NULL AND @pid IS NOT NULL AND @ok > 0;
DELETE FROM catalog_category_product_index
 WHERE category_id = @cat AND product_id = @pid AND @cat IS NOT NULL AND @pid IS NOT NULL AND @ok > 0;

-- ===========================================================================
-- STEP 2 + 3 - assign every member (adding the two video courses) and pin it
-- to its curated slot. INSERT ... ON DUPLICATE KEY UPDATE covers both the
-- "already assigned, reposition" and "not assigned, add" cases in one shape.
--
-- The index insert derives store_id/visibility from the product's OWN index
-- rows in other categories, so it only writes stores where the product is
-- actually visible on this instance.
-- ===========================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_dm_order;
CREATE TEMPORARY TABLE tmp_dm_order (sku VARCHAR(64) PRIMARY KEY, pos INT NOT NULL);
INSERT INTO tmp_dm_order (sku, pos) VALUES
  ('TGS-2025056988',  1),  -- WSQ - Agentic AI for Digital Marketing
  ('TGS-2023018659',  2),  -- WSQ - Claude Cowork for Digital Marketing
  ('TGS-2021003023',  3),  -- WSQ - Generative AI for Social Media Marketing
  ('TGS-2020505996',  4),  -- WSQ - Agentic AI for Social Media Marketing
  ('TGS-2019503343',  5),  -- WSQ - Enhancing Online Presence with AI Powered SEO
  ('TGS-2020503501',  6),  -- WSQ - Generative AI for Search Engine Optimization (SEO)
  ('TGS-2022017520',  7),  -- WSQ - Agentic AI for Market Research
  ('TGS-2023037589',  8),  -- WSQ - Generative AI for Content Creation
  ('TGS-2023036153',  9),  -- WSQ - Multi AI Agents Workflow for Content Creation
  ('TGS-2020503109', 10),  -- WSQ - Claude Cowork for Email Marketing
  ('TGS-2026064473', 11),  -- CASL - Agentic AI for Email Marketing Campaign
  ('TGS-2024043855', 12),  -- WSQ - Creating Engaging Videos with Generative AI (GenAI)  [ADD]
  ('TGS-2023036088', 13),  -- WSQ - Agentic AI for Video Creation                        [ADD]
  ('TGS-2023036657', 14),  -- WSQ - Agentic AI for TikTok Marketing
  ('TGS-2025060552', 15),  -- WSQ - Agentic AI for Affiliate Marketing
  ('TGS-2021009337', 16);  -- WSQ - Pay Per Click (PPC) Campaign Optimization

-- Base table (admin-facing source of truth).
INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, e.entity_id, t.pos
FROM tmp_dm_order t
JOIN catalog_product_entity e ON e.sku = t.sku
WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- Storefront-facing index, per store the product is visible in.
INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, e.entity_id, t.pos, 1, i.store_id, MAX(i.visibility)
FROM tmp_dm_order t
JOIN catalog_product_entity e ON e.sku = t.sku
JOIN catalog_category_product_index i ON i.product_id = e.entity_id AND i.store_id > 0
WHERE @cat IS NOT NULL
GROUP BY e.entity_id, t.pos, i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

DROP TEMPORARY TABLE IF EXISTS tmp_dm_order;
