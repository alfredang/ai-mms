-- C976: "AI Vibe Coding for Smart Contract" -> "AI Vibe Coding for Blockchain dApps",
-- the 2-day non-WSQ twin of TGS-2021009338 (WSQ - Develop Blockchain and Web3 App with
-- Vibe Coding).
--
-- 1. name, url_key/url_path (ai-vibe-coding-for-smart-contract -> ai-vibe-coding-for-blockchain-dapps),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. 1 day -> 2 days to match the parent: fee $350 -> $700, Duration 7.5 -> 15 hrs,
--    Sessions 1 -> 2.
-- 3. "What's This Course About" and course topics follow the WSQ parent (two typos in the
--    parent's Topic 2 fixed: "Vibe Codig", "Vibe COding"). Written as literals.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block re-pointed at the WSQ twin (it linked WSQ - AI Vibe Coding for Multi
--    Agents System, an unrelated course).
-- 6. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug. Search terms redirecting to the old slug follow.
-- Stays in the AI Vibe Coding Series (badge + categories unchanged).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): switch the schedule template A05 (gid 184) -> B19
-- (gid 108) to match the parent's (SG) WSQ-B19, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C976' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021009338' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'AI Vibe Coding for Blockchain dApps';
SET @old_slug  := 'ai-vibe-coding-for-smart-contract';
SET @new_slug  := 'ai-vibe-coding-for-blockchain-dapps';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

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

-- --------------------------------------------------------- meta data -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mtitle;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build Web3 dApps with AI vibe coding. Develop, test and deploy Solidity smart contracts on Ethereum with AI coding assistants, from token standards to wallet integration, at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI Vibe Coding, Blockchain, dApps, Web3, Smart Contract, Solidity, Ethereum, NFT, ERC-20, ERC-721, Python Web3, AI Coding, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- 2 days / 15 hrs / $700 -----
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '15'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '2'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Unlock the power of Blockchain and Web3 development through a modern, AI-driven approach with our hands-on course on building decentralized applications using Vibe Coding. In today&rsquo;s rapidly evolving digital landscape, blockchain technology is transforming industries&mdash;from finance and supply chain to digital identity and AI integration. This course equips you with the practical skills to design, build, and deploy Web3 applications efficiently using prompt-driven development workflows.</p>\n<p>Throughout this program, you will explore the Ethereum ecosystem, learn how to develop smart contracts using Solidity, and apply Vibe Coding techniques to accelerate full-stack Web3 development. You will gain hands-on experience in building secure and scalable decentralized applications (DApps), integrating wallets, interacting with smart contracts, and deploying your solutions to live blockchain networks.</p>\n<p>Beyond coding, the course emphasizes the end-to-end development lifecycle&mdash;from ideation and architecture design to testing, deployment, and continuous integration. You will also learn how AI-assisted development tools can enhance productivity, reduce development time, and enable rapid prototyping of innovative Web3 solutions.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1 Blockchain, Cryptocurrency, Smart Contract and Token Economics</h3>\n<ul>\n<li>Introduction of Blockchain and Cryptocurrency</li>\n<li>Use Cases of Blockchain and Cryptocurrency</li>\n<li>Introduction to Smart Contract and Non Fungible Token (NFT)</li>\n<li>Use Cases of Smart Contract and NFT</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2 Develop DApp with Vibe Coding</h3>\n<ul>\n<li>Overview of Ethereum DApp Platform</li>\n<li>Create Smart Contract using Vibe Coding</li>\n<li>Solidity Coding Syntax</li>\n<li>Best Practices on Vibe Coding</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3 Smart Contract Testing</h3>\n<ul>\n<li>Test Smart Contract and Monitor Outputs</li>\n<li>Manage Ether and Gas Fee</li>\n<li>Monitor Ethereum Blockchain Transactions</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4 Smart Contract Deployment</h3>\n<ul>\n<li>Deploy Smart Contract</li>\n<li>Token Standards</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C976-20261002-184739.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C976 - Funding and Grant', 'course_C976_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C976_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C976_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C976_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-develop-blockchain-and-web3-app-with-vibe-coding.html" title="WSQ - Develop Blockchain and Web3 App with Vibe Coding">WSQ - Develop Blockchain and Web3 App with Vibe Coding</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C976_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c976_old;
CREATE TEMPORARY TABLE tmp_c976_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c976_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c976_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c976_old;

-- ---------------------------------------------- search-term redirects -----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
