-- C776: "Digital Transformation for Small and Medium Enterprises" -> "AI Transformation with Microsoft
-- Copilot", the 2-day non-WSQ twin of TGS-2024044051 (WSQ - AI Transformation with Microsoft Copilot).
--
-- 1. name, url_key/url_path (digital-transformation-sme -> ai-transformation-with-microsoft-copilot),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. Fee / Duration / Sessions: $350 / 7.5 hrs / 1 day -> $700 / 15 hrs / 2 days.
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 4 About paragraphs and
--    4 topics). ASCII literals, not a parent join: "three-day WSQ course" -> "two-day course" and the
--    parent's curly apostrophe in "organisation's" is written as ASCII.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block: "No funding" pointing at the WSQ twin.
-- 6. Listed in the Microsoft Copilot Series (357, curated order) at the tail of the non-WSQ block,
--    after C012 (already a member at 19). Mirrored into catalog_category_product_index.
-- 7. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it. "wsq sme" / "SME courses" no longer describe this course -> redirect cleared.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template A03 (gid 175) -> B03 (gid 142, counterpart of the parent's WSQ-C03) is switched on
-- prod via the code path, not here.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C776' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024044051' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'AI Transformation with Microsoft Copilot';
SET @old_slug  := 'digital-transformation-sme';
SET @new_slug  := 'ai-transformation-with-microsoft-copilot';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

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

-- ------------------------------------------- fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Lead AI transformation with Microsoft 365 Copilot: use Copilot in everyday work, design safe Copilot Workflows, build and test Copilot agents and measure adoption value. Course at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI Transformation with Microsoft Copilot, Microsoft 365 Copilot, Copilot Training, Copilot Workflows, Copilot Agent Builder, Copilot Agents, AI Adoption, AI Transformation, AI for Executives, AI for Managers, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p><strong>AI Transformation with Microsoft Copilot</strong> is a practical two-day course for executives and senior managers. Use Microsoft 365 Copilot in everyday business work, design a no-code Copilot Workflow and build a focused Copilot agent. The emphasis is better decisions, safe handoffs and measurable outcomes.</p><p>In Copilot Chat, Word, PowerPoint, Excel, Outlook and Teams, participants turn a synthetic service case into sourced briefs, analysis, meeting actions and leadership messages. They check claims and keep a human owner for consequential decisions.</p><p>Participants describe a repeatable service process to Copilot Workflows, map its trigger, steps, approval and exception path, then test normal and failure cases. They use Copilot Agent Builder to define a bounded purpose, instructions, approved knowledge and starter prompts, and test the agent before any sharing. Feature availability depends on the organisation''s Microsoft 365 tenant; an offline design and test path is provided.</p><p>Leaders finish with a pilot cohort, adoption plan, quality and value scorecard, and a board-ready go, hold or stop recommendation. No coding is required. The course is informed by Microsoft AB-730 and AB-731 themes; it is not Microsoft exam preparation.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Use Microsoft 365 Copilot for everyday business work","subsecs":[]},{"title":"Topic 2: Design safe Copilot Workflows and human controls","subsecs":[]},{"title":"Topic 3: Create and test bounded Copilot agents","subsecs":[]},{"title":"Topic 4: Lead adoption, measure value and scale outcomes","subsecs":[]}] -->\n<p><strong>Topic 1: Use Microsoft 365 Copilot for everyday business work</strong></p>\n<p><strong>Topic 2: Design safe Copilot Workflows and human controls</strong></p>\n<p><strong>Topic 3: Create and test bounded Copilot agents</strong></p>\n<p><strong>Topic 4: Lead adoption, measure value and scale outcomes</strong></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C776-20261001-083729.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C776 - Funding and Grant', 'course_C776_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C776_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C776_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C776_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-transformation-with-microsoft-copilot.html" title="WSQ - AI Transformation with Microsoft Copilot">WSQ - AI Transformation with Microsoft Copilot</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C776_funding_and_grant';

-- ------------------------------------------ Microsoft Copilot Series -----
-- Curated category: append after the current last member (C012 at 19), base + index.
SET @copilot := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
                    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
                  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1);
SET @cpos := (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = @copilot);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @copilot, @pid, @cpos
  FROM DUAL WHERE @ok AND @copilot IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @copilot, @pid, cp.position, 1, i.store_id, MAX(i.visibility)
  FROM catalog_category_product cp
  JOIN catalog_category_product_index i ON i.product_id = cp.product_id AND i.store_id > 0
 WHERE @ok AND @copilot IS NOT NULL AND cp.category_id = @copilot AND cp.product_id = @pid
 GROUP BY cp.position, i.store_id;

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c776_old;
CREATE TEMPORARY TABLE tmp_c776_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c776_old
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
  FROM tmp_c776_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c776_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html')
   AND query_text IN ('wsq sme', 'SME courses');

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
