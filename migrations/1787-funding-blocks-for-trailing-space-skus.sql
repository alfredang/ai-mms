-- C8, C16 and C22 are stored with a TRAILING SPACE in catalog_product_entity.sku ('C8 ', 'C16 ',
-- 'C22 '). view.phtml builds the block id from the raw SKU, so these pages read
-- 'course_C16 _funding_and_grant' (space before the underscore) - not the trimmed identifier that
-- the admin, 1784 and every audit script use. Result on prod (2026-10-05): C8 and C22 rendered NO
-- funding card at all, and C16 rendered a stale space-named block linking an old WSQ slug while
-- 1784's corrected block sat unread under the trimmed name.
--
-- Fix (content-only, SKU untouched - the space-named brochure/certification blocks depend on it):
-- copy the trimmed block's content to the space-named identifier, creating it (+ store 0 row) when
-- absent. Trimmed blocks stay the editable source. SG-only. Idempotent.
-- Post-deploy: cache flush.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- C16: space-named block exists -> overwrite with the trimmed (1784) content.
UPDATE cms_block sp
  JOIN (SELECT content FROM cms_block WHERE identifier = 'course_C16_funding_and_grant' LIMIT 1) src
   SET sp.content = src.content, sp.update_time = NOW()
 WHERE @sg = 1 AND sp.identifier = 'course_C16 _funding_and_grant';

-- C8 / C22: create the space-named block from the trimmed one.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C8 - Funding and Grant', 'course_C8 _funding_and_grant', b.content, NOW(), NOW(), 1
  FROM cms_block b
 WHERE @sg = 1 AND b.identifier = 'course_C8_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) x WHERE x.identifier = 'course_C8 _funding_and_grant')
 LIMIT 1;

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C22 - Funding and Grant', 'course_C22 _funding_and_grant', b.content, NOW(), NOW(), 1
  FROM cms_block b
 WHERE @sg = 1 AND b.identifier = 'course_C22_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) x WHERE x.identifier = 'course_C22 _funding_and_grant')
 LIMIT 1;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE @sg = 1 AND b.identifier IN ('course_C8 _funding_and_grant', 'course_C22 _funding_and_grant', 'course_C16 _funding_and_grant');
