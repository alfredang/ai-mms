-- Move "Blockchain" from Financial Services to Logistics & Supply Chain,
-- carrying its whole subtree.
--
-- Before: Financial Services (165) > Blockchain (166)   path 1/2/3/165/166
-- After:  Logistics & Supply Chain (132) > Blockchain   path 1/2/3/132/166
--
-- SUBTREE MOVE — unlike the 3D Printing move (564) this node is NOT a leaf. It
-- carries 6 descendants across two levels:
--   Metaverse, CryptoCurrencies, Smart Contract & DApp, NFT, DeFi   (level 5)
--   Smart Contract & DApp > Ethereum                                (level 6)
-- Every descendant's `path` must have its prefix rewritten, or the tree breaks
-- (orphaned nodes, wrong breadcrumbs, menu gaps). Handled by the REPLACE() on
-- the old path prefix below, which rewrites the node and all descendants in one
-- statement.
--
-- LEVELS ARE UNCHANGED: both the old parent (165) and the new parent (132) are
-- level 3, so the subtree keeps its existing levels (166 stays 4, its children
-- stay 5, Ethereum stays 6). No level arithmetic is needed. If this migration is
-- ever adapted to a target at a DIFFERENT depth, the level column must be
-- shifted by the depth delta as well.
--
-- URL IMPACT: NONE. MMD_FlatCategoryUrl resolves every category at
-- /<url_key>.html regardless of parent, so every node in this subtree keeps its
-- existing URL. No 301s, and deliberately NO url_key/url_path writes.
--
-- Product assignments are untouched (19 on Blockchain itself, plus each
-- descendant's own).
--
-- Resolved by NAME rather than hardcoded ids so it lands on every site.
-- Idempotent: once moved, @node resolves NULL under the old parent and every
-- statement no-ops. Mirrored into catalog_category_flat_store_{1,2,3} behind
-- information_schema guards.
-- After deploy: reindex catalog_category_flat + catalog_url, flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @src := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Financial Services' AND e.level = 3 LIMIT 1);

SET @dst := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Logistics & Supply Chain' AND e.level = 3 LIMIT 1);

SET @node := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Blockchain' AND e.parent_id = @src LIMIT 1) r);

-- Capture the old/new path prefixes BEFORE anything is modified.
SET @old_path := (SELECT path FROM (SELECT path FROM catalog_category_entity WHERE entity_id = @node) a);
SET @new_path := (SELECT CONCAT(path, '/', @node) FROM (SELECT path FROM catalog_category_entity WHERE entity_id = @dst) b);

-- Re-path the node AND every descendant in one pass (prefix swap).
UPDATE catalog_category_entity
SET path = CONCAT(@new_path, SUBSTRING(path, CHAR_LENGTH(@old_path) + 1))
WHERE @node IS NOT NULL AND @old_path IS NOT NULL AND @new_path IS NOT NULL
  AND (entity_id = @node OR path LIKE CONCAT(@old_path, '/%'));

-- Reparent the node itself (level unchanged — both parents are level 3).
UPDATE catalog_category_entity
SET parent_id = @dst
WHERE entity_id = @node AND @dst IS NOT NULL;

-- Place Blockchain last under its new parent.
UPDATE catalog_category_entity
SET position = (SELECT m FROM (SELECT IFNULL(MAX(position), 0) + 1 m FROM catalog_category_entity WHERE parent_id = @dst AND entity_id <> @node) c)
WHERE entity_id = @node AND @dst IS NOT NULL;

-- Keep both parents' children_count honest.
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @src) d) WHERE entity_id = @src;
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @dst) e) WHERE entity_id = @dst;

SET @flat_path := " SET path = CONCAT(@new_path, SUBSTRING(path, CHAR_LENGTH(@old_path) + 1)) WHERE @node IS NOT NULL AND (entity_id = @node OR path LIKE CONCAT(@old_path, '/%'))";
SET @flat_move := " SET parent_id = @dst WHERE entity_id = @node";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_path), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_path), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_path), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
