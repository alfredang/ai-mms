-- 1793: TGS-2026064535 "CASL - AWS Certified Solutions Architect Associate Training"
--       -> "CASL - Agentic AI Solutions with ChatGPT Work and Codex"
--
-- REPURPOSE in place (entity 323). SKU unchanged, stays CASL: the CASL prefix,
-- the six funding tags (CASL / PSEA / UTAP / SFEC / Absentee Payroll / MCES),
-- price, duration (24h / 3 sessions), schedule options and the funding table
-- inside `prerequisite` are deliberately left alone.
--
-- PROBED on SG prod before writing. Stale AWS surfaces rewritten here:
--   * name, url_key, url_path, meta_title (plain -- MMD_Seotitle adds "WSQ funded"
--     + the brand at render time; the stored "WSQ AWS ... | Tertiary Courses
--     Singapore" produced the live "WSQ funded WSQ AWS ..." duplicate),
--     meta_description, meta_keyword
--   * short_description (About), description (5-topic outline + LSN_DATA marker),
--     whoshouldattend, the "Software: NIL" line in prerequisite
--   * course_TGS-2026064535_learning_outcomes cms_block (did NOT exist -> the
--     LO card never rendered; guarded INSERT then UPDATE)
--   * image/small_image/thumbnail labels + media-gallery label (alt text);
--     image PATHS untouched (filesystem paths)
--   * course_image_url -> new R2 cover, rendered with the existing badge set:
--       course-covers/TGS-2026064535-20261006-182539.png (191053 bytes)
--   * trainerprofile: the two "In this AWS program ... AWS Certified Solutions
--     Architect Associate exam" teaching paragraphs are removed (an exam promise
--     on a non-exam course). Career-history paragraphs are facts and stay.
--   * categories: OUT of 87 Cloud Computing, 183 AWS, 227 + 404 AWS Certification
--     Exam Prep (+ the anchor-inherited 182 Certification Exam Prep index row),
--     345 WSQ Certification, 426 WSQ Cloud Computing & Networking.
--     IN to 283 Codex AI Series (slot 2, after the WSQ Codex course, above the
--     C-block), 252 AI Courses and 325 WSQ AI Courses (sibling TGS-2023041081's
--     placements). Kept: 3, 15, 55, 292, 301.
--   * upsells / related: AWS links replaced with the Codex AI Series courses;
--     AWS courses' links pointing AT this course are removed.
--   * URL rewrites: old slug freed, 301s from every old path, existing 301s
--     flattened (dropped-category targets go to the bare new slug, else 301->404).
--   * search redirects: 17 AWS-intent terms pointed here (via the wsq- slug);
--     they go to the live AWS Solutions Architect Professional course, the
--     DevOps-on-AWS code to its own page, two unrelated terms are cleared.
--
-- Not touched: 33 learner reviews (genuine testimonials of the old course --
-- flagged to the admin), the brochure (Drive, regenerate separately), trainers.
--
-- SG only: keyed by SKU, no-ops where the SKU is absent. Idempotent.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064535' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- ---------------------------------------------------------------- varchar attrs
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'             AND entity_type_id=@et);
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'          AND entity_type_id=@et);
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path'         AND entity_type_id=@et);
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'       AND entity_type_id=@et);
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar SET value = 'CASL - Agentic AI Solutions with ChatGPT Work and Codex'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = 'casl-agentic-ai-solutions-with-chatgpt-work-and-codex'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = 'casl-agentic-ai-solutions-with-chatgpt-work-and-codex.html'
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = 'Agentic AI Solutions with ChatGPT Work and Codex'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- varchar(255): 226 chars.
UPDATE catalog_product_entity_varchar
   SET value = 'Learn Agentic AI Solutions with ChatGPT Work and Codex in Singapore. Design, build and test AI agents that automate business workflows, support software development and solve business problems. CASL course at Tertiary Courses.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   SET v.value = 'CASL - Agentic AI Solutions with ChatGPT Work and Codex'
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.entity_type_id = @et
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = 'CASL - Agentic AI Solutions with ChatGPT Work and Codex'
 WHERE m.entity_id = @e AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064535-20261006-182539.png'
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
   SET value = 'Agentic AI Solutions with ChatGPT Work and Codex, Agentic AI, AI Agents, ChatGPT Work, OpenAI Codex, AI Workflow Automation, AI-Assisted Software Development, Human-in-the-Loop, Responsible AI, CASL'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This course equips learners with practical skills to design, develop, and implement Agentic AI solutions using ChatGPT Work and Codex. Participants will explore how AI agents can go beyond conversational assistance to plan and execute multi-step tasks, work with files and information, use tools, generate and modify code, and automate complex business and technical workflows.</p>',
     '<p>Learners will gain hands-on experience using ChatGPT Work to perform knowledge-intensive tasks such as research, document analysis, data processing, content creation, and multi-step workflow execution. The course also introduces Codex for AI-assisted software development, enabling learners to understand codebases, generate and modify applications, troubleshoot technical issues, automate development tasks, and work with software repositories.</p>',
     '<p>Participants will learn how to design agentic workflows by defining objectives, providing appropriate context, configuring tools and skills, managing data, and establishing effective human-in-the-loop controls. The course also covers testing, troubleshooting, security, data governance, and responsible AI practices to support reliable AI implementation.</p>',
     '<p>By the end of the course, learners will be able to develop practical Agentic AI solutions that combine ChatGPT Work and Codex to automate workflows, support software development, solve business problems, and improve organisational productivity.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- LSN_DATA marker (admin Lesson editor) + the HTML the storefront renders,
-- regenerated together from the same five topics.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1: Agentic AI Solution Assessment with ChatGPT Work and Codex","subsecs":[',
         '{"title":"Agentic AI concepts: Chat, Work and Codex","links":[]},',
         '{"title":"Identify business requirements and agentic AI use cases","links":[]},',
         '{"title":"Assess agentic AI solution performance against expected outcomes","links":[]}]},',
       '{"title":"Topic 2: Agentic AI Architecture, Security and Solution Specifications","subsecs":[',
         '{"title":"Design agentic workflows: objectives, context, tools and skills","links":[]},',
         '{"title":"Specify usage, performance, security and data governance requirements","links":[]},',
         '{"title":"Analyse solution impact and human-in-the-loop controls","links":[]}]},',
       '{"title":"Topic 3: Agentic Workflow Integration, Implementation and Testing","subsecs":[',
         '{"title":"Execute multi-step research, document and data tasks with ChatGPT Work","links":[]},',
         '{"title":"Integrate files, tools and connected apps into agentic workflows","links":[]},',
         '{"title":"Plan implementation and test agentic AI solutions","links":[]}]},',
       '{"title":"Topic 4: AI Agent Automation, Deployment and Performance Monitoring","subsecs":[',
         '{"title":"Automate development tasks and work with repositories using Codex","links":[]},',
         '{"title":"Deploy agentic AI solutions and align them with existing systems","links":[]},',
         '{"title":"Review metrics and monitor AI agent performance","links":[]}]},',
       '{"title":"Topic 5: Agentic AI Troubleshooting, Coding and Issue Resolution","subsecs":[',
         '{"title":"Understand codebases and generate or modify applications with Codex","links":[]},',
         '{"title":"Troubleshoot technical issues and resolve escalated implementation issues","links":[]},',
         '{"title":"Apply responsible AI practices for reliable implementation","links":[]}]}] -->\n',
     '<p><strong>Topic 1: Agentic AI Solution Assessment with ChatGPT Work and Codex</strong></p>\n',
     '<p><em>Agentic AI concepts: Chat, Work and Codex</em></p>\n',
     '<p><em>Identify business requirements and agentic AI use cases</em></p>\n',
     '<p><em>Assess agentic AI solution performance against expected outcomes</em></p>\n',
     '<p><strong>Topic 2: Agentic AI Architecture, Security and Solution Specifications</strong></p>\n',
     '<p><em>Design agentic workflows: objectives, context, tools and skills</em></p>\n',
     '<p><em>Specify usage, performance, security and data governance requirements</em></p>\n',
     '<p><em>Analyse solution impact and human-in-the-loop controls</em></p>\n',
     '<p><strong>Topic 3: Agentic Workflow Integration, Implementation and Testing</strong></p>\n',
     '<p><em>Execute multi-step research, document and data tasks with ChatGPT Work</em></p>\n',
     '<p><em>Integrate files, tools and connected apps into agentic workflows</em></p>\n',
     '<p><em>Plan implementation and test agentic AI solutions</em></p>\n',
     '<p><strong>Topic 4: AI Agent Automation, Deployment and Performance Monitoring</strong></p>\n',
     '<p><em>Automate development tasks and work with repositories using Codex</em></p>\n',
     '<p><em>Deploy agentic AI solutions and align them with existing systems</em></p>\n',
     '<p><em>Review metrics and monitor AI agent performance</em></p>\n',
     '<p><strong>Topic 5: Agentic AI Troubleshooting, Coding and Issue Resolution</strong></p>\n',
     '<p><em>Understand codebases and generate or modify applications with Codex</em></p>\n',
     '<p><em>Troubleshoot technical issues and resolve escalated implementation issues</em></p>\n',
     '<p><em>Apply responsible AI practices for reliable implementation</em></p>\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<ul>',
     '<li>AI Solutions Architect</li>',
     '<li>AI Developer</li>',
     '<li>AI Agent Engineer</li>',
     '<li>AI Automation Consultant</li>',
     '<li>Software Developer</li>',
     '<li>Application Developer</li>',
     '<li>Solutions Architect</li>',
     '<li>Technical Consultant</li>',
     '<li>Business Analyst</li>',
     '<li>Systems Analyst</li>',
     '<li>Data Analyst</li>',
     '<li>Process Improvement Manager</li>',
     '<li>Digital Transformation Manager</li>',
     '<li>Operations Manager</li>',
     '<li>IT Manager</li>',
     '<li>Product Manager</li>',
     '<li>Project Manager</li>',
     '<li>Innovation Manager</li>',
     '<li>Knowledge Worker</li>',
     '<li>Business Owner</li>',
     '</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @e AND @e IS NOT NULL;

-- Only the Software line; the rest of the blob is house entry-requirement copy.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p><strong>Software:</strong></p><ul><li>NIL</li></ul>',
       '<p><strong>Software:</strong></p><ul><li>A paid ChatGPT plan with access to ChatGPT Work and <u><a href="https://openai.com/codex/" rel="noopener noreferrer" target="_blank">Codex</a></u></li></ul>')
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value,
       '<p>In this AWS program, Quah focuses on cloud solution architecture, AWS core services, and workload deployment strategies. His teaching emphasizes practical labs and scenario-based learning, preparing learners for the AWS Certified Solutions Architect Associate exam as well as workplace application.</p>', ''),
       '<p>For this WSQ course, Agus trains participants in designing resilient AWS architectures, implementing identity and access management (IAM), and securing workloads. His sessions are hands-on and application-oriented, ensuring learners gain both exam readiness and practical skills in AWS environments.</p>', '')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------- learning outcomes block
INSERT INTO cms_block (title, identifier, content, is_active)
SELECT 'TGS-2026064535 Learning Outcomes', 'course_TGS-2026064535_learning_outcomes', '', 1
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2026064535_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE identifier = 'course_TGS-2026064535_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Assess the performance of cloud solutions based on expected business requirements.</li>
<li>LO2: Draft specifications for cloud solutions addressing usage, performance, security, and analyze their impact.</li>
<li>LO3: Develop implementation plans incorporating cloud integration tools and installation tests for cloud solutions.</li>
<li>LO4: Develop processes for system alignment, automated software deployment, and reviewing metrics in cloud solution implementation.</li>
<li>LO5: Resolve escalated implementation issues by mastering impact analysis, scripting languages, big data tools, and cloud platforms.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2026064535_learning_outcomes' AND @e IS NOT NULL;

-- ---------------------------------------------------------------- categories
-- Out: AWS / AWS cert prep / cloud / certification listings (+ anchor-inherited 182).
DELETE FROM catalog_category_product
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (87, 183, 227, 345, 404, 426);
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (87, 182, 183, 227, 345, 404, 426);

-- In: 283 Codex AI Series at slot 2 (TGS- before C-). Shift the C-block down
-- only on the first run, i.e. while this course is not yet in the category.
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
  FROM (SELECT 283 AS cat, 2 AS pos
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
   AND TRIM(p.sku) IN ('TGS-2023041081', 'C989', 'C695', 'C427', 'C818');

INSERT IGNORE INTO catalog_product_link_attribute_int (product_link_attribute_id, link_id, value)
SELECT a.product_link_attribute_id, l.link_id,
       FIELD(TRIM(p.sku), 'TGS-2023041081', 'C989', 'C695', 'C427', 'C818')
  FROM catalog_product_link l
  JOIN catalog_product_entity p ON p.entity_id = l.linked_product_id
  JOIN catalog_product_link_attribute a
    ON a.link_type_id = l.link_type_id AND a.product_link_attribute_code = 'position'
 WHERE l.product_id = @e AND @e IS NOT NULL AND l.link_type_id IN (1, 4);

-- ---------------------------------------------------------------- URL rewrites
-- Free the OLD slug: its is_system rows hold the product id_paths, so a 301
-- INSERT IGNORE would no-op and refreshProductRewrite would mint a "-1" suffix.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND request_path LIKE '%casl-aws-certified-solutions-architect-associate-training.html';

DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%casl-agentic-ai-solutions-with-chatgpt-work-and-codex.html';

-- 301 old -> new. Kept categories keep their prefix; dropped ones go bare.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description, product_id)
SELECT @sid,
       CONCAT('tgs2026064535-agentic-', t.slot, '-', @e),
       CONCAT(t.old_prefix, 'casl-aws-certified-solutions-architect-associate-training.html'),
       CONCAT(t.new_prefix, 'casl-agentic-ai-solutions-with-chatgpt-work-and-codex.html'),
       0, 'RP', '1793: TGS-2026064535 repurposed to CASL - Agentic AI Solutions with ChatGPT Work and Codex', @e
  FROM (
        SELECT 'bare' AS slot, '' AS old_prefix, '' AS new_prefix
  UNION SELECT 'cat3',   'adult-training-courses/',                              'adult-training-courses/'
  UNION SELECT 'cat15',  'latest-courses/',                                      'latest-courses/'
  UNION SELECT 'cat55',  'computer-programming-and-infocomm-courses/',           'computer-programming-and-infocomm-courses/'
  UNION SELECT 'cat292', 'wsq-funded-courses/',                                  'wsq-funded-courses/'
  UNION SELECT 'cat301', 'wsq-it-security-courses/',                             'wsq-it-security-courses/'
  UNION SELECT 'cat87',  'cloud-computing-courses/',                             ''
  UNION SELECT 'cat183', 'aws-cloud-computing-courses-retired/',                 ''
  UNION SELECT 'cat227', 'aws-certification-exams-retired/',                     ''
  UNION SELECT 'cat345', 'wsq-certification-courses/',                           ''
  UNION SELECT 'cat404', 'aws-certification-preparation-exam-courses-retired/',  ''
  UNION SELECT 'cat426', 'wsq-cloud-computing-and-networking-courses/',          ''
  ) t
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten pre-existing 301s that target the old slug. Targets under a DROPPED
-- category would 404 after the reindex, so those go to the bare new slug.
UPDATE core_url_rewrite
   SET target_path = 'casl-agentic-ai-solutions-with-chatgpt-work-and-codex.html'
 WHERE is_system = 0
   AND target_path IN (
       'cloud-computing-courses/casl-aws-certified-solutions-architect-associate-training.html',
       'aws-cloud-computing-courses-retired/casl-aws-certified-solutions-architect-associate-training.html',
       'aws-certification-exams-retired/casl-aws-certified-solutions-architect-associate-training.html',
       'wsq-certification-courses/casl-aws-certified-solutions-architect-associate-training.html',
       'aws-certification-preparation-exam-courses-retired/casl-aws-certified-solutions-architect-associate-training.html',
       'wsq-cloud-computing-and-networking-courses/casl-aws-certified-solutions-architect-associate-training.html');

UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'casl-aws-certified-solutions-architect-associate-training.html',
                             'casl-agentic-ai-solutions-with-chatgpt-work-and-codex.html')
 WHERE is_system = 0
   AND target_path LIKE '%casl-aws-certified-solutions-architect-associate-training.html'
   AND id_path NOT LIKE 'tgs2026064535-agentic-%';

-- ---------------------------------------------------------------- search redirects
-- AWS-intent terms would now land on an agentic AI course: send them to the
-- live AWS Solutions Architect course instead.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-aws-certified-solutions-architect-professional-training.html'
 WHERE redirect IN ('https://www.tertiarycourses.com.sg/wsq-aws-certified-solutions-architect-associate-training.html',
                    'https://www.tertiarycourses.com.sg/casl-aws-certified-solutions-architect-associate-training.html')
   AND query_text NOT IN ('TGS-2023040474', 'TGS-2024048315', 'Microsoft Certified Solutions Associate')
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053926');

UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-devops-engineering-on-aws.html'
 WHERE query_text = 'TGS-2023040474'
   AND redirect IN ('https://www.tertiarycourses.com.sg/wsq-aws-certified-solutions-architect-associate-training.html',
                    'https://www.tertiarycourses.com.sg/casl-aws-certified-solutions-architect-associate-training.html')
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023040474');

UPDATE catalogsearch_query
   SET redirect = ''
 WHERE query_text IN ('TGS-2024048315', 'Microsoft Certified Solutions Associate')
   AND redirect IN ('https://www.tertiarycourses.com.sg/wsq-aws-certified-solutions-architect-associate-training.html',
                    'https://www.tertiarycourses.com.sg/casl-aws-certified-solutions-architect-associate-training.html');
