-- 1310: Add the 7 WSQ/CASL courses that appear in "Digital Marketing Courses"
-- (/digital-marketing-courses-in.html, cat 8) but were missing from the funded
-- listing "WSQ Digital Marketing Courses" (/wsq-digital-marketing-courses.html,
-- cat 308).
--
-- Cat 8 carries 17 funded (TGS-) courses; cat 308 had only 10. The other 7 were
-- never assigned. All 7 are enabled TGS- SKUs, so they belong in the funded
-- listing.
--
-- ORDERING: cat 308 is a TGS--ONLY listing whose existing 1..10 order is
-- CURATED (not alphabetical), so that order is left untouched and the 7 new
-- courses are APPENDED after it, alphabetical by course name among themselves.
-- Funded-first is preserved trivially - every member is TGS-.
--
-- The index mirror (catalog_category_product_index) is written directly; the
-- storefront reads it and no reindex runs at deploy.
--
-- Business-key lookups only (SKU + category url_key). Partner-safe: on MY/GH
-- neither the TGS- SKUs nor cat 308 exist, so @cat/@pid are NULL and every
-- statement no-ops. Idempotent: re-running finds @have = 1 and the position is
-- recomputed to the same slot via ON DUPLICATE KEY UPDATE / INSERT IGNORE.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
             WHERE store_id = 0 AND attribute_id = @uk
               AND value = 'wsq-digital-marketing-courses' LIMIT 1);

-- ---------------------------------------------------------------------------
-- TGS-2025056988 - WSQ - Agentic AI for Digital Marketing

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2025056988' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------------------
-- TGS-2020505996 - WSQ - Agentic AI for Social Media Marketing

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2020505996' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------------------
-- TGS-2023036657 - WSQ - Agentic AI for TikTok Marketing

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2023036657' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------------------
-- TGS-2023037472 - WSQ - Business Innovation with Agentic AI and AI Agents

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2023037472' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------------------
-- TGS-2025052342 - WSQ - Closing Sales with Empathy-Driven People-Focused Selling

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2025052342' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------------------
-- TGS-2023037589 - WSQ - Generative AI for Content Creation

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2023037589' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------------------
-- TGS-2025053924 - WSQ - Service Branding Strategies to Elevate Your Business

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2025053924' LIMIT 1);

-- Append one past the current last member (skip on re-run: keep existing slot).
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT CASE WHEN @have > 0
                  THEN (SELECT position FROM catalog_category_product
                        WHERE category_id = @cat AND product_id = @pid)
                  ELSE COALESCE(MAX(cp.position), 0) + 1 END
                FROM catalog_category_product cp
                WHERE cp.category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);
