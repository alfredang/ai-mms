-- C544: "AI Vibe Coding for Blockchain" -> "Blockchain Fundamentals Masterclass", the 2-day non-WSQ
-- twin of TGS-2021009338 (WSQ - Develop Blockchain and Web3 App with Vibe Coding).
--
-- 1. name, url_key/url_path (ai-vibe-coding-for-blockchain -> blockchain-fundamentals-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. Length + fee: 1 day / 7.5 hrs / $350 -> 2 days (sessions) / 15 hrs (duration) / $700.
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 3 About paragraphs and
--    its 4 topics), with the parent's "Vibe Codig" / "Vibe COding" typos corrected. ASCII literals.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Leaves the AI Vibe Coding Series: removed from that category (ai-vibe-coding-series) and its
--    red "AI Vibe Coding Series" badge (course_series_badge) is cleared. It stays in Blockchain
--    (blockchain-courses), where the non-WSQ block is re-sorted alphabetically for the new name.
-- 6. Funding block: "No funding" now points at the WSQ twin (it named an unrelated vibe-coding
--    course, WSQ - AI Vibe Coding for Multi-Agents System).
-- 7. 301s: the product's system rows are renamed in place to the new slug (so the new URL resolves
--    without a rewrite refresh); every old path, bare or category-prefixed, 301s one hop to the new
--    BARE slug, legacy RP rows and search redirects are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template switch A01 -> B19 (gid 108, the counterpart of
-- the parent's (SG) WSQ-B19) via the admin Switch Template code path; flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C544' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021009338' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Blockchain Fundamentals Masterclass';
SET @old_slug  := 'ai-vibe-coding-for-blockchain';
SET @new_slug  := 'blockchain-fundamentals-masterclass';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_badge   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');
SET @a_cname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @cat_vibe  := (SELECT entity_id FROM catalog_category_entity_varchar
                    WHERE attribute_id = @a_curlkey AND store_id = 0 AND value = 'ai-vibe-coding-series' LIMIT 1);
SET @cat_bc    := (SELECT entity_id FROM catalog_category_entity_varchar
                    WHERE attribute_id = @a_curlkey AND store_id = 0 AND value = 'blockchain-courses' LIMIT 1);

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- ------------------------------------------------- length + course fee -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700.0000 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- Price index, so listings show the new fee before the next price reindex.
UPDATE catalog_product_index_price
   SET price = 700.0000,
       final_price = IF(final_price > 0, 700.0000, final_price),
       min_price   = IF(min_price   > 0, 700.0000, min_price),
       max_price   = IF(max_price   > 0, 700.0000, max_price)
 WHERE @ok AND entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn blockchain, smart contracts, NFTs and Ethereum DApps in this 2-day Blockchain Fundamentals Masterclass, building and deploying Web3 apps with AI-assisted vibe coding at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Blockchain Fundamentals Masterclass, Blockchain Course, Blockchain Training, Web3 Development, Smart Contract, Solidity, Ethereum DApp, NFT, Cryptocurrency, Token Economics, Vibe Coding, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Unlock the power of Blockchain and Web3 development through a modern, AI-driven approach with our hands-on course on building decentralized applications using Vibe Coding. In today&rsquo;s rapidly evolving digital landscape, blockchain technology is transforming industries&mdash;from finance and supply chain to digital identity and AI integration. This course equips you with the practical skills to design, build, and deploy Web3 applications efficiently using prompt-driven development workflows.</p>\n<p>Throughout this program, you will explore the Ethereum ecosystem, learn how to develop smart contracts using Solidity, and apply Vibe Coding techniques to accelerate full-stack Web3 development. You will gain hands-on experience in building secure and scalable decentralized applications (DApps), integrating wallets, interacting with smart contracts, and deploying your solutions to live blockchain networks.</p>\n<p>Beyond coding, the course emphasizes the end-to-end development lifecycle&mdash;from ideation and architecture design to testing, deployment, and continuous integration. You will also learn how AI-assisted development tools can enhance productivity, reduce development time, and enable rapid prototyping of innovative Web3 solutions.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1 Blockchain, Cryptocurrency, Smart Contract and Token Economics</h3>\n<ul>\n<li>Introduction of Blockchain and Cryptocurrency</li>\n<li>Use Cases of Blockchain and Cryptocurrency</li>\n<li>Introduction to Smart Contract and Non Fungible Token (NFT)</li>\n<li>Use Cases of Smart Contract and NFT</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2 Develop DApp with Vibe Coding</h3>\n<ul>\n<li>Overview of Ethereum DApp Platform</li>\n<li>Create Smart Contract using Vibe Coding</li>\n<li>Solidity Coding Syntax</li>\n<li>Best Practices on Vibe Coding</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3 Smart Contract Testing</h3>\n<ul>\n<li>Test Smart Contract and Monitor Outputs</li>\n<li>Manage Ether and Gas Fee</li>\n<li>Monitor Ethereum Blockchain Transactions</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4 Smart Contract Deployment</h3>\n<ul>\n<li>Deploy Smart Contract</li>\n<li>Token Standards</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover, @a_dur, @a_sess) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C544-20261001-050819.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- leave AI Vibe Coding Series -----
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_badge;

DELETE FROM catalog_category_product
 WHERE @ok AND @cat_vibe IS NOT NULL AND category_id = @cat_vibe AND product_id = @pid;

DELETE FROM catalog_category_product_index
 WHERE @ok AND @cat_vibe IS NOT NULL AND category_id = @cat_vibe AND product_id = @pid;

-- ----------------------------------------------- Blockchain category -----
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat_bc, @pid, 9999 FROM DUAL WHERE @ok AND @cat_bc IS NOT NULL;

-- Re-sort the direct members: funded (TGS-) keep their relative order, then C- alphabetical by
-- name, then the rest. AUTO_INCREMENT temp table, not @rn (5.7 ignores ORDER BY with @rn).
DROP TEMPORARY TABLE IF EXISTS tmp_c544_bc_order;
CREATE TEMPORARY TABLE tmp_c544_bc_order (
  pos INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL
);
INSERT INTO tmp_c544_bc_order (product_id)
SELECT cp.product_id
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  LEFT JOIN catalog_product_entity_varchar nv
    ON nv.entity_id = e.entity_id AND nv.store_id = 0 AND nv.attribute_id = @a_name
 WHERE @ok AND @cat_bc IS NOT NULL AND cp.category_id = @cat_bc
 ORDER BY CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END,
          CASE WHEN e.sku LIKE 'TGS-%' THEN cp.position END,
          CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END,
          cp.product_id;

UPDATE catalog_category_product cp
  JOIN tmp_c544_bc_order t ON t.product_id = cp.product_id
   SET cp.position = t.pos
 WHERE cp.category_id = @cat_bc;

UPDATE catalog_category_product_index i
  JOIN tmp_c544_bc_order t ON t.product_id = i.product_id
   SET i.position = t.pos
 WHERE i.category_id = @cat_bc AND i.is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_c544_bc_order;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C544 - Funding and Grant', 'course_C544_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C544_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C544_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C544_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-develop-blockchain-and-web3-app-with-vibe-coding.html" title="WSQ - Develop Blockchain and Web3 App with Vibe Coding">WSQ - Develop Blockchain and Web3 App with Vibe Coding</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C544_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c544_old;
CREATE TEMPORARY TABLE tmp_c544_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c544_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2b) The product left the AI Vibe Coding Series: drop its category-scoped system row there.
DELETE FROM core_url_rewrite
 WHERE @ok AND @cat_vibe IS NOT NULL AND product_id = @pid AND is_system = 1 AND category_id = @cat_vibe;

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c544_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c544_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
