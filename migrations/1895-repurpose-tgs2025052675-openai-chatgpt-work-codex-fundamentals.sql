-- 1895: TGS-2025052675 "WSQ - AWS Certified Developer Associate Training"
--       -> "WSQ - OpenAI ChatGPT Work and Codex Fundamentals for Beginners"
--
-- REPURPOSE in place (entity 1315). SKU unchanged, stays WSQ: the seven funding
-- tags, price ($1,500), duration (24h / 3 sessions), schedule options, the
-- funding_and_grant / skills_framework / certification blocks and the funding
-- validity (news_from/to_date = 2025-02-03 -> 2027-02-02, already correct) are
-- deliberately left alone.
--
-- PROBED on SG prod before writing. Stale AWS surfaces rewritten here:
--   * name, url_key, url_path, meta_title (full rendered form per
--     .claude/rules/seo-meta.md), meta_description, meta_keyword
--     SEO targets: "ChatGPT training Singapore", "Codex training Singapore"
--   * short_description (About), description (4-topic outline + LSN_DATA),
--     whoshouldattend, the AWS-account line in prerequisite
--   * course_TGS-2025052675_learning_outcomes block -> supplied LO1-LO4
--   * image/small_image/thumbnail labels + media-gallery label (alt text);
--     image PATHS untouched (filesystem paths)
--   * course_image_url -> new R2 cover, rendered with the existing badge set:
--       course-covers/TGS-2025052675-20261103-025720.png (207402 bytes)
--   * trainerprofile: the two AWS course-teaching paragraphs are removed.
--     Career-history paragraphs are facts and stay.
--   * categories: OUT of 87 Cloud Computing, 182 Certification Exam Prep,
--     183 AWS, 227 + 404 AWS Certification Exam Prep, 345 WSQ Certification,
--     426 WSQ Cloud Computing & Networking.
--     IN to 283 Codex AI Series (slot 3, after the two funded Codex courses,
--     above the C-block), 252 AI Courses and 325 WSQ AI Courses (beside the
--     WSQ Codex course TGS-2023041081). Kept: 3, 15, 55, 292, 301.
--   * upsells / related: AWS links replaced with the Codex AI Series courses;
--     AWS courses' links pointing AT this course are removed.
--   * URL rewrites: system rows renamed in place (kept categories), dropped
--     categories' system rows deleted, 301s from every old path, existing
--     301s flattened (dropped-category targets go to the bare new slug).
--   * search redirects: the course code follows the course; AWS-developer
--     terms go to the Cloud Computing listing (no live AWS Developer course),
--     SysOps / architect / Android / UiPath terms to their own courses,
--     four unrelated terms are cleared.
--
-- Not touched: 13 learner reviews (genuine testimonials of the old course),
-- the brochure PDF (regenerate separately), the trainer pool.
--
-- SG only: keyed by SKU, no-ops where the SKU is absent. Idempotent.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025052675' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

SET @old := 'wsq-aws-certified-developer-associate-training.html';
SET @new := 'wsq-openai-chatgpt-work-and-codex-fundamentals-for-beginners.html';

-- ---------------------------------------------------------------- varchar attrs
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'             AND entity_type_id=@et);
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'          AND entity_type_id=@et);
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path'         AND entity_type_id=@et);
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'       AND entity_type_id=@et);
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar SET value = 'WSQ - OpenAI ChatGPT Work and Codex Fundamentals for Beginners'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = 'wsq-openai-chatgpt-work-and-codex-fundamentals-for-beginners'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = @new
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL;

-- Stored in full rendered form (seo-meta.md, SG funded): core wording 45 chars.
UPDATE catalog_product_entity_varchar
   SET value = 'Funded up to 70% WSQ ChatGPT Work and Codex Training for Beginners | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- 150 chars; funding line from the badges (WSQ + SkillsFuture Credit + UTAP).
UPDATE catalog_product_entity_varchar
   SET value = 'ChatGPT and Codex training for beginners: automate workflows, integrate apps, fix code. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   SET v.value = 'OpenAI ChatGPT Work and Codex Fundamentals for Beginners'
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.entity_type_id = @et
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = 'OpenAI ChatGPT Work and Codex Fundamentals for Beginners'
 WHERE m.entity_id = @e AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052675-20261103-025720.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- text attrs
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et);
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'       AND entity_type_id=@et);
SET @a_wsa  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend'   AND entity_type_id=@et);
SET @a_pre  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='prerequisite'      AND entity_type_id=@et);
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'    AND entity_type_id=@et);

UPDATE catalog_product_entity_text
   SET value = 'ChatGPT training Singapore, Codex training Singapore, ChatGPT Work and Codex course, OpenAI Codex course for beginners, AI workflow automation course, WSQ ChatGPT and Codex course, SkillsFuture Credit course, UTAP claimable course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This beginner-friendly <strong>ChatGPT and Codex training</strong> course introduces learners to <strong>OpenAI ChatGPT Work and Codex</strong>, with a practical focus on application integration and workflow automation. Learners will explore how ChatGPT Work can support everyday business tasks by working across documents, files, websites, and connected applications, while Codex can assist with developing, modifying, testing, and integrating software solutions.</p>\n',
     '<p>The course covers how to connect AI capabilities with common applications, APIs, data sources, and business workflows. Learners will gain hands-on experience using ChatGPT Work to retrieve information, coordinate tasks across applications, and automate multi-step processes. They will also learn how Codex can be used to generate integration code, work with APIs, troubleshoot application issues, and support the development of AI-enabled workflows.</p>\n',
     '<p>Designed for beginners with little or no prior AI development experience, the course introduces key concepts such as application connectors, APIs, authentication, structured data exchange, tool calling, and workflow orchestration. Emphasis is placed on practical use cases, secure integration practices, testing, and responsible AI usage.</p>\n',
     '<p>By the end of the course, learners will be able to use ChatGPT Work and Codex to integrate applications, automate routine processes, develop simple AI-assisted solutions, and improve productivity across business and technical workflows.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- LSN_DATA marker (admin Lesson editor) + the HTML the storefront renders,
-- same shape as the WSQ Codex course TGS-2023041081.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1: Application Integration and Workflow Automation with ChatGPT Work and Codex","subsecs":[]},',
       '{"title":"Topic 2: AI-Assisted Troubleshooting and Error Resolution for Integrated Applications","subsecs":[]},',
       '{"title":"Topic 3: Application Performance Evaluation, Testing and Optimisation","subsecs":[]},',
       '{"title":"Topic 4: Application Change Management and AI-Driven Solution Enhancement","subsecs":[]}] -->\n',
     '<p><strong>Topic 1: Application Integration and Workflow Automation with ChatGPT Work and Codex</strong></p>\n',
     '<p><strong>Topic 2: AI-Assisted Troubleshooting and Error Resolution for Integrated Applications</strong></p>\n',
     '<p><strong>Topic 3: Application Performance Evaluation, Testing and Optimisation</strong></p>\n',
     '<p><strong>Topic 4: Application Change Management and AI-Driven Solution Enhancement</strong></p>\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<ul>\n',
     '<li>Application Support Analyst</li>\n',
     '<li>Application Support Engineer</li>\n',
     '<li>IT Support Executive</li>\n',
     '<li>Junior Software Developer</li>\n',
     '<li>Systems Analyst</li>\n',
     '<li>Business Analyst</li>\n',
     '<li>Data Analyst</li>\n',
     '<li>Operations Executive</li>\n',
     '<li>Process Improvement Executive</li>\n',
     '<li>Digital Transformation Executive</li>\n',
     '<li>Project Coordinator</li>\n',
     '<li>Product Manager</li>\n',
     '<li>Administrative and Office Professional</li>\n',
     '<li>Knowledge Worker</li>\n',
     '<li>SME Business Owner</li>\n',
     '</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @e AND @e IS NOT NULL;

-- Only the Software line; the rest of the blob is house entry-requirement copy.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://aws.amazon.com/free/" target="_blank">An AWS account</a> &ndash; Free Tier available; a credit card is required to sign up</li>',
       '<li><a href="https://chatgpt.com/" target="_blank">A ChatGPT Plus (or higher) subscription</a> &ndash; required for ChatGPT Work and Codex</li>\n<li><a href="https://chatgpt.com/download" target="_blank">ChatGPT desktop app</a> &ndash; free download</li>')
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value,
       '<p data-start="999" data-end="1520">In the AWS Certified Developer &ndash; Associate Training course, Amin integrates his deep technical and governance expertise to help learners master cloud-native application development and deployment on AWS. His sessions focus on building resilient architectures, implementing DevSecOps practices, and optimizing code for scalability and performance. Learners benefit from his practical, industry-based approach, gaining the skills to design, develop, and maintain secure, high-performing applications in the AWS ecosystem.</p>', ''),
       '<p data-start="2268" data-end="2792">In this course, Mohan brings his real-world experience in cloud application development and deployment to guide learners through practical implementation of AWS developer tools and services. His sessions emphasize the use of CI/CD pipelines, serverless architectures, and containerized applications to create efficient and maintainable software systems. Learners gain a clear understanding of AWS best practices and the technical confidence to build, test, and optimize production-ready applications in cloud environments.</p>', '')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------- learning outcomes block
INSERT INTO cms_block (title, identifier, content, is_active)
SELECT 'Course TGS-2025052675 Learning Outcomes', 'course_TGS-2025052675_learning_outcomes', '', 1
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2025052675_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE identifier = 'course_TGS-2025052675_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Establish end-to-end processes to implement best practices in application support.</li>
<li>LO2: Develop and implement troubleshooting protocol using emerging techniques to resolve complex application issues effectively.</li>
<li>LO3: Evaluate application performance considering technical constraints.</li>
<li>LO4: Direct and collaborate on change requests to ensure effective application enhancements.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2025052675_learning_outcomes' AND @e IS NOT NULL;

-- ---------------------------------------------------------------- categories
-- Out: AWS / AWS cert prep / cloud / certification listings.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (87, 182, 183, 227, 345, 404, 426);
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (87, 182, 183, 227, 345, 404, 426);

-- In: 283 Codex AI Series at slot 3 (funded TGS- before C-). Shift the C-block
-- down only on the first run, i.e. while this course is not yet in the category.
SET @in283 := (SELECT COUNT(*) FROM catalog_category_product WHERE category_id = 283 AND product_id = @e);

UPDATE catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
   SET cp.position = cp.position + 1
 WHERE cp.category_id = 283 AND p.sku LIKE 'C%' AND @in283 = 0 AND @e IS NOT NULL;
UPDATE catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
   SET i.position = i.position + 1
 WHERE i.category_id = 283 AND p.sku LIKE 'C%' AND @in283 = 0 AND @e IS NOT NULL;

-- 252 / 325: sit next to the WSQ Codex course (TGS-2023041081) inside the TGS block.
SET @p252 := (SELECT cp.position FROM catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
               WHERE cp.category_id = 252 AND TRIM(p.sku) = 'TGS-2023041081');
SET @p325 := (SELECT cp.position FROM catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
               WHERE cp.category_id = 325 AND TRIM(p.sku) = 'TGS-2023041081');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.cat, @e, c.pos
  FROM (SELECT 283 AS cat, 3 AS pos
        UNION ALL SELECT 252, COALESCE(@p252, 1)
        UNION ALL SELECT 325, COALESCE(@p325, 1)) c
  JOIN catalog_category_entity ce ON ce.entity_id = c.cat
 WHERE @e IS NOT NULL;

INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, @sid, 4
  FROM catalog_category_product cp
 WHERE cp.product_id = @e AND cp.category_id IN (252, 283, 325) AND @e IS NOT NULL AND @sid IS NOT NULL
ON DUPLICATE KEY UPDATE position = VALUES(position), is_parent = 1;

-- ---------------------------------------------------------------- upsells / related
-- This course's own links (all AWS) -> the Codex AI Series courses.
DELETE FROM catalog_product_link
 WHERE product_id = @e AND @e IS NOT NULL AND link_type_id IN (1, 4);

-- AWS courses that recommended this course as an AWS course.
DELETE l FROM catalog_product_link l
  JOIN catalog_product_entity_varchar n
    ON n.entity_id = l.product_id AND n.store_id = 0 AND n.attribute_id = @a_name
 WHERE l.linked_product_id = @e AND @e IS NOT NULL AND l.link_type_id IN (1, 4)
   AND n.value LIKE '%AWS%';

INSERT IGNORE INTO catalog_product_link (product_id, linked_product_id, link_type_id)
SELECT @e, p.entity_id, t.link_type_id
  FROM catalog_product_entity p
  JOIN (SELECT 1 AS link_type_id UNION ALL SELECT 4) t
 WHERE @e IS NOT NULL
   AND TRIM(p.sku) IN ('TGS-2023041081', 'TGS-2026064535', 'C989', 'C695', 'C427', 'C818');

INSERT IGNORE INTO catalog_product_link_attribute_int (product_link_attribute_id, link_id, value)
SELECT a.product_link_attribute_id, l.link_id,
       FIELD(TRIM(p.sku), 'TGS-2023041081', 'TGS-2026064535', 'C989', 'C695', 'C427', 'C818')
  FROM catalog_product_link l
  JOIN catalog_product_entity p ON p.entity_id = l.linked_product_id
  JOIN catalog_product_link_attribute a
    ON a.link_type_id = l.link_type_id AND a.product_link_attribute_code = 'position'
 WHERE l.product_id = @e AND @e IS NOT NULL AND l.link_type_id IN (1, 4);

-- ---------------------------------------------------------------- URL rewrites
-- Dropped categories: their system rows go (the 301s below cover the old paths).
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND @e IS NOT NULL AND is_system = 1
   AND category_id IN (87, 182, 183, 227, 345, 404, 426);

-- Kept categories + bare: rename the system rows in place so the new URL
-- serves immediately and no "-1" suffix is minted on the next reindex.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, @old, @new)
 WHERE product_id = @e AND @e IS NOT NULL AND is_system = 1
   AND request_path LIKE CONCAT('%', @old);

-- New categories: product-in-category system rows.
INSERT IGNORE INTO core_url_rewrite
  (store_id, category_id, product_id, id_path, request_path, target_path, is_system)
SELECT @sid, c.cat, @e, CONCAT('product/', @e, '/', c.cat), CONCAT(c.prefix, @new),
       CONCAT('catalog/product/view/id/', @e, '/category/', c.cat), 1
  FROM (SELECT 252 AS cat, 'artificial-intelligence-courses/' AS prefix
        UNION ALL SELECT 283, 'codex-ai-series/'
        UNION ALL SELECT 325, 'wsq-ai-courses/') c
  JOIN catalog_category_entity ce ON ce.entity_id = c.cat
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- 301 old -> new. Kept categories keep their prefix; dropped ones go bare.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description, product_id)
SELECT @sid,
       CONCAT('tgs2025052675-chatgpt-codex-', t.slot, '-', @e),
       CONCAT(t.old_prefix, @old),
       CONCAT(t.new_prefix, @new),
       0, 'RP', '1895: TGS-2025052675 repurposed to WSQ - OpenAI ChatGPT Work and Codex Fundamentals for Beginners', @e
  FROM (
        SELECT 'bare' AS slot, '' AS old_prefix, '' AS new_prefix
  UNION SELECT 'cat3',   'adult-training-courses/',                              'adult-training-courses/'
  UNION SELECT 'cat15',  'latest-courses/',                                      'latest-courses/'
  UNION SELECT 'cat55',  'computer-programming-and-infocomm-courses/',           'computer-programming-and-infocomm-courses/'
  UNION SELECT 'cat292', 'wsq-funded-courses/',                                  'wsq-funded-courses/'
  UNION SELECT 'cat301', 'wsq-it-security-courses/',                             'wsq-it-security-courses/'
  UNION SELECT 'cat87',  'cloud-computing-courses/',                             ''
  UNION SELECT 'cat182', 'certification-exam-prep-courses/',                     ''
  UNION SELECT 'cat183', 'aws-cloud-computing-courses-retired/',                 ''
  UNION SELECT 'cat227', 'aws-certification-exams-retired/',                     ''
  UNION SELECT 'cat345', 'wsq-certification-courses/',                           ''
  UNION SELECT 'cat404', 'aws-certification-preparation-exam-courses-retired/',  ''
  UNION SELECT 'cat426', 'wsq-cloud-computing-and-networking-courses/',          ''
  ) t
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten pre-existing 301s that target the old slug. Targets under a DROPPED
-- category would 404, so those go to the bare new slug.
UPDATE core_url_rewrite
   SET target_path = @new
 WHERE is_system = 0
   AND target_path IN (
       'cloud-computing-courses/wsq-aws-certified-developer-associate-training.html',
       'certification-exam-prep-courses/wsq-aws-certified-developer-associate-training.html',
       'aws-cloud-computing-courses-retired/wsq-aws-certified-developer-associate-training.html',
       'aws-certification-exams-retired/wsq-aws-certified-developer-associate-training.html',
       'wsq-certification-courses/wsq-aws-certified-developer-associate-training.html',
       'aws-certification-preparation-exam-courses-retired/wsq-aws-certified-developer-associate-training.html',
       'wsq-cloud-computing-and-networking-courses/wsq-aws-certified-developer-associate-training.html');

UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, @old, @new)
 WHERE is_system = 0
   AND target_path LIKE CONCAT('%', @old)
   AND id_path NOT LIKE 'tgs2025052675-chatgpt-codex-%';

-- ---------------------------------------------------------------- search redirects
-- Only rows still pointing at the old AWS page (never overwrite other redirects).
UPDATE catalogsearch_query
   SET redirect = CASE
     WHEN query_text = 'TGS-2025052675'
       THEN CONCAT('https://www.tertiarycourses.com.sg/', @new)
     WHEN query_text IN ('AWS System associate', 'aws adminstrator associate')
       THEN 'https://www.tertiarycourses.com.sg/wsq-aws-certified-sysops-administrator-associate-training.html'
     WHEN query_text = 'Aws architecting associate'
       THEN 'https://www.tertiarycourses.com.sg/wsq-aws-certified-solutions-architect-professional-training.html'
     WHEN query_text = 'associate android developer'
       THEN 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-android-apps-development.html'
     WHEN query_text IN ('UiPath Certified Professional Automation Developer Associate',
                         'Certified Professional Automation Developer Associate')
       THEN 'https://www.tertiarycourses.com.sg/uipath-rpa-course.html'
     WHEN query_text IN ('Meta Certified Digital Marketing Associate Exam Prep', 'associate training',
                         'wsq developer', 'adminstrator associate exam prep')
       THEN ''
     ELSE 'https://www.tertiarycourses.com.sg/cloud-computing-courses.html'
   END
 WHERE redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old)
   AND @e IS NOT NULL;
