-- 1212: AI Vibe Coding Series — two conversions + curated non-WSQ order.
--
-- A) Convert two non-WSQ courses (SKUs unchanged), each with a new name, new
--    url_key + 301 from the old one, a freshly rendered branded R2 cover, new
--    overview/topics and new meta, then move them to their new series:
--      C141 AI Vibe Coding for iOS Ecommerce App
--             -> Claude Code for Digital Marketing   (-> Claude AI Series)
--      C818 AI Vibe Coding with Codex
--             -> Codex for Digital Marketing         (-> Codex AI Series)
--    Both leave the AI Vibe Coding Series.
--
-- B) Pin the requested 29-course non-WSQ order at positions 101..129, after
--    every WSQ/CASL/IBF course. Two members not in the requested list
--    (C819 Google Apps Script, C1074 Mobile Apps) sort after that block.
--    'ai-vibe-coding-series' is added to mmd/category_ordering/curated_url_keys
--    so the nightly sweep preserves the order.
--
-- SG-guarded; C-prefix SKUs and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_pdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_psdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);

-- ===== A: C141 -> Claude Code for Digital Marketing =====

SET @e_C141 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C141' LIMIT 1);
SET @t_C141 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C141, 'Claude Code for Digital Marketing' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C141 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C141 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C141, 'claude-code-for-digital-marketing' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C141 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C141 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C141, 'Claude Code for Digital Marketing | Tertiary Courses Singapore' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C141, 'Build and automate digital marketing workflows with Claude Code - campaign content, analytics scripts, SEO tooling and reporting, all driven from the terminal.' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e_C141, 'Master digital marketing delivery with Claude Code. This hands-on course shows marketers and developers how to use Claude Code as an agentic coding partner for real campaign work - generating and testing landing pages, automating content production, wiring up analytics and building reporting scripts without writing everything by hand.' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e_C141, '<h3 class="course-topic-h3">Topic 1 Getting Started with Claude Code</h3>
<ul>
<li>Installing and configuring Claude Code</li>
<li>Working with projects, files and context</li>
<li>Prompting patterns for marketing tasks</li>
<li>Safety, review and version control</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Content and Campaign Automation</h3>
<ul>
<li>Generating landing pages and email templates</li>
<li>Bulk content production and localisation</li>
<li>A/B test variants and copy iteration</li>
<li>Publishing workflows</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Marketing Analytics with Claude Code</h3>
<ul>
<li>Pulling and cleaning campaign data</li>
<li>Building analytics scripts</li>
<li>Attribution and funnel reporting</li>
<li>Dashboards and scheduled reports</li>
</ul>
<h3 class="course-topic-h3">Topic 4 SEO and Growth Tooling</h3>
<ul>
<li>Technical SEO audits</li>
<li>Schema and metadata generation</li>
<li>Competitor and keyword tooling</li>
<li>Automating recurring growth tasks</li>
</ul>' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e_C141 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e_C141 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C141, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C141-20260830-062958.png' FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'ios-app-swift-programming-training.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c141-301', 'ios-app-swift-programming-training.html', 'claude-code-for-digital-marketing.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C141) AND store_id = 1
  AND request_path <> 'claude-code-for-digital-marketing.html' AND @e_C141 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C141), 'claude-code-for-digital-marketing.html', CONCAT('catalog/product/view/id/', @e_C141), 1, @e_C141
FROM dual WHERE @e_C141 IS NOT NULL AND @is_sg > 0;

-- leave the AI Vibe Coding Series
DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e_C141 AND cp.category_id = @vibe AND @e_C141 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e_C141 AND i.category_id = @vibe AND @e_C141 IS NOT NULL AND @is_sg > 0;

-- join the target series, after its existing rows
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_C141, @e_C141,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_C141), 0) + 1
FROM dual WHERE @t_C141 IS NOT NULL AND @e_C141 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_C141, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_C141 AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C141' AND @t_C141 IS NOT NULL AND @is_sg > 0
GROUP BY p.entity_id, s.store_id;

-- ===== A: C818 -> Codex for Digital Marketing =====

SET @e_C818 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C818' LIMIT 1);
SET @t_C818 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'codex-ai-series' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C818, 'Codex for Digital Marketing' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C818 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C818 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C818, 'codex-for-digital-marketing' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C818 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C818 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C818, 'Codex for Digital Marketing | Tertiary Courses Singapore' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C818, 'Use OpenAI Codex to automate digital marketing engineering - campaign pages, content pipelines, analytics scripting and marketing integrations.' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e_C818, 'Apply OpenAI Codex to the engineering side of digital marketing. This practical course covers using Codex to build and maintain campaign assets, automate content and data pipelines, script analytics and connect the marketing stack, so marketing teams ship faster with less manual coding.' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e_C818, '<h3 class="course-topic-h3">Topic 1 Getting Started with Codex</h3>
<ul>
<li>Codex setup and workflow</li>
<li>Prompting and iterating on code</li>
<li>Reviewing and testing generated code</li>
<li>Working safely in a marketing codebase</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Campaign Assets with Codex</h3>
<ul>
<li>Landing pages and forms</li>
<li>Email and template automation</li>
<li>Tracking pixels and tag management</li>
<li>Rapid prototyping of campaign micro-sites</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Data and Analytics Pipelines</h3>
<ul>
<li>Extracting campaign and CRM data</li>
<li>Cleaning and transforming datasets</li>
<li>Automated reporting scripts</li>
<li>Alerting on campaign performance</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Integrating the Marketing Stack</h3>
<ul>
<li>Working with marketing APIs</li>
<li>Automating repetitive operations</li>
<li>Scheduling and monitoring jobs</li>
<li>Deploying and maintaining marketing tooling</li>
</ul>' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e_C818 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e_C818 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C818, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C818-20260830-062958.png' FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-with-codex.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c818-301', 'ai-vibe-coding-with-codex.html', 'codex-for-digital-marketing.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C818) AND store_id = 1
  AND request_path <> 'codex-for-digital-marketing.html' AND @e_C818 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C818), 'codex-for-digital-marketing.html', CONCAT('catalog/product/view/id/', @e_C818), 1, @e_C818
FROM dual WHERE @e_C818 IS NOT NULL AND @is_sg > 0;

-- leave the AI Vibe Coding Series
DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e_C818 AND cp.category_id = @vibe AND @e_C818 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e_C818 AND i.category_id = @vibe AND @e_C818 IS NOT NULL AND @is_sg > 0;

-- join the target series, after its existing rows
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_C818, @e_C818,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_C818), 0) + 1
FROM dual WHERE @t_C818 IS NOT NULL AND @e_C818 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_C818, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_C818 AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C818' AND @t_C818 IS NOT NULL AND @is_sg > 0
GROUP BY p.entity_id, s.store_id;

-- ===== B: curated non-WSQ order (101..129) =====

UPDATE core_config_data
SET value = CONCAT(value, ',ai-vibe-coding-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-vibe-coding-series%';

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C603' THEN 101
  WHEN 'C1800' THEN 102
  WHEN 'C1143' THEN 103
  WHEN 'C1154' THEN 104
  WHEN 'C879' THEN 105
  WHEN 'C139' THEN 106
  WHEN 'C138' THEN 107
  WHEN 'C136' THEN 108
  WHEN 'C28' THEN 109
  WHEN 'C356' THEN 110
  WHEN 'C169' THEN 111
  WHEN 'C178' THEN 112
  WHEN 'C357' THEN 113
  WHEN 'C674' THEN 114
  WHEN 'C841' THEN 115
  WHEN 'C485' THEN 116
  WHEN 'C193' THEN 117
  WHEN 'C188' THEN 118
  WHEN 'C430' THEN 119
  WHEN 'C539' THEN 120
  WHEN 'C592' THEN 121
  WHEN 'C143' THEN 122
  WHEN 'C349' THEN 123
  WHEN 'C1231' THEN 124
  WHEN 'C428' THEN 125
  WHEN 'C544' THEN 126
  WHEN 'C976' THEN 127
  WHEN 'C728' THEN 128
  WHEN 'C1319' THEN 129
END
WHERE cp.category_id = @vibe
  AND p.sku IN (
    'C603',
    'C1800',
    'C1143',
    'C1154',
    'C879',
    'C139',
    'C138',
    'C136',
    'C28',
    'C356',
    'C169',
    'C178',
    'C357',
    'C674',
    'C841',
    'C485',
    'C193',
    'C188',
    'C430',
    'C539',
    'C592',
    'C143',
    'C349',
    'C1231',
    'C428',
    'C544',
    'C976',
    'C728',
    'C1319'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C603' THEN 101
  WHEN 'C1800' THEN 102
  WHEN 'C1143' THEN 103
  WHEN 'C1154' THEN 104
  WHEN 'C879' THEN 105
  WHEN 'C139' THEN 106
  WHEN 'C138' THEN 107
  WHEN 'C136' THEN 108
  WHEN 'C28' THEN 109
  WHEN 'C356' THEN 110
  WHEN 'C169' THEN 111
  WHEN 'C178' THEN 112
  WHEN 'C357' THEN 113
  WHEN 'C674' THEN 114
  WHEN 'C841' THEN 115
  WHEN 'C485' THEN 116
  WHEN 'C193' THEN 117
  WHEN 'C188' THEN 118
  WHEN 'C430' THEN 119
  WHEN 'C539' THEN 120
  WHEN 'C592' THEN 121
  WHEN 'C143' THEN 122
  WHEN 'C349' THEN 123
  WHEN 'C1231' THEN 124
  WHEN 'C428' THEN 125
  WHEN 'C544' THEN 126
  WHEN 'C976' THEN 127
  WHEN 'C728' THEN 128
  WHEN 'C1319' THEN 129
END
WHERE i.category_id = @vibe
  AND p.sku IN (
    'C603',
    'C1800',
    'C1143',
    'C1154',
    'C879',
    'C139',
    'C138',
    'C136',
    'C28',
    'C356',
    'C169',
    'C178',
    'C357',
    'C674',
    'C841',
    'C485',
    'C193',
    'C188',
    'C430',
    'C539',
    'C592',
    'C143',
    'C349',
    'C1231',
    'C428',
    'C544',
    'C976',
    'C728',
    'C1319'
  );

-- the two members not in the requested list sort after the pinned block
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = 200 + cp.product_id
WHERE cp.category_id = @vibe AND p.sku IN ('C819', 'C1074');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = 200 + i.product_id
WHERE i.category_id = @vibe AND p.sku IN ('C819', 'C1074');

