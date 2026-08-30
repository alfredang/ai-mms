-- 1220: Convert C903 "PL-7002 Create and Manage Automated Processes by using
-- Power Automate" into "Workplace Evaluation and Innovation for AI Adoption",
-- and move it from the Microsoft Copilot Series to the AI Applications Series
-- + its AI for HR subcategory.
--
-- ("Evaluaton" in the request is read as "Evaluation".)
--
-- SKU stays C903. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, a three-paragraph "What's This Course About"
-- (short_description) and a rewritten "What You'll Learn" (description
-- topics), new meta, plus a Funding Options block pointing at
-- WSQ - Agentic AI for HR (verified 200).
--
-- It also leaves the Power Platform / Power Automate / Microsoft Copilot /
-- Microsoft / Software Training trees, which no longer describe the course,
-- exactly as C811 did in 1210. It keeps All Courses (3) and Infocomm
-- Technology (55), and gains AI Courses (252).
--
-- Course is 7.5h / 1 day; the copy reflects that. Topic HTML uses the
-- LSN_DATA + <h3 class="course-topic-h3"> shape the product page expects.
-- cms_block is written with plain SQL + an explicit cms_block_store row —
-- never a model save, which wipes the store mapping.
--
-- SG-guarded; C-prefix SKU and these identifiers are SG-only (partner
-- no-op). Idempotent.

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

SET @e903 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C903' LIMIT 1);

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);
SET @copilot := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1);
SET @aicourses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-courses' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e903, 'Workplace Evaluation and Innovation for AI Adoption'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e903 AND attribute_id = @a_pname AND store_id <> 0
  AND @e903 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e903, 'workplace-evaluation-and-innovation-for-ai-adoption'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e903 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e903 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e903, 'Workplace Evaluation and Innovation for AI Adoption | Tertiary Courses Singapore'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e903, 'Evaluate your workplace for AI readiness and lead adoption - audit tasks and workflows, size the opportunity, redesign roles and run an innovation roadmap.'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e903, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C903-20260830-073432.png'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e903,
'<p>Most organisations do not fail at AI because the technology is hard &mdash; they fail because nobody looked closely at the work first. Tools get bought, pilots get run, and six months later the same people are doing the same tasks the same way. Workplace Evaluation and Innovation for AI Adoption starts from the opposite end: you learn to examine how work actually flows through your team, where the time and cost really go, and which of those tasks AI can genuinely take on today.</p><p>In this hands-on 1-day course, you will work through a structured evaluation of your own workplace &mdash; mapping processes task by task, scoring each one for AI feasibility and business impact, and separating the automation opportunities that pay back quickly from the ones that look impressive but stall. From that evidence you will build an innovation roadmap: which workflows to redesign, what changes for the people doing them, what skills the team needs next, and how you will measure whether it worked.</p><p>You will leave with a completed workplace evaluation, a prioritised AI adoption roadmap and a change plan you can put in front of management &mdash; the difference between "we should use more AI" and a costed, sequenced case for doing it. Ideal for HR and L&amp;D professionals, operations and department managers, business owners and transformation leads who are accountable for making AI adoption actually land.</p>'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e903,
'<!-- LSN_DATA: [{"title":"Topic 1 Understanding AI Adoption in the Workplace","subsecs":[{"title":"What AI can and cannot do in day-to-day work","links":[]},{"title":"Why AI initiatives stall after the pilot","links":[]},{"title":"Readiness factors: data, process, people and leadership","links":[]},{"title":"Case studies of successful and failed adoption","links":[]}]},{"title":"Topic 2 Evaluating Your Workplace","subsecs":[{"title":"Mapping processes and workflows task by task","links":[]},{"title":"Time, cost and pain-point analysis","links":[]},{"title":"Scoring tasks for AI feasibility and impact","links":[]},{"title":"Building your workplace evaluation report","links":[]}]},{"title":"Topic 3 Identifying Innovation Opportunities","subsecs":[{"title":"Prioritising quick wins against strategic bets","links":[]},{"title":"Redesigning workflows around AI","links":[]},{"title":"Role and job impact: what changes for your people","links":[]},{"title":"Risk, governance and responsible use","links":[]}]},{"title":"Topic 4 Building the Adoption Roadmap","subsecs":[{"title":"Sequencing initiatives over 90 days and beyond","links":[]},{"title":"Skills gaps and reskilling pathways","links":[]},{"title":"Change management and staff communication","links":[]},{"title":"Measuring adoption, ROI and course correction","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 Understanding AI Adoption in the Workplace</h3>
<ul>
<li>What AI can and cannot do in day-to-day work</li>
<li>Why AI initiatives stall after the pilot</li>
<li>Readiness factors: data, process, people and leadership</li>
<li>Case studies of successful and failed adoption</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Evaluating Your Workplace</h3>
<ul>
<li>Mapping processes and workflows task by task</li>
<li>Time, cost and pain-point analysis</li>
<li>Scoring tasks for AI feasibility and impact</li>
<li>Building your workplace evaluation report</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Identifying Innovation Opportunities</h3>
<ul>
<li>Prioritising quick wins against strategic bets</li>
<li>Redesigning workflows around AI</li>
<li>Role and job impact: what changes for your people</li>
<li>Risk, governance and responsible use</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building the Adoption Roadmap</h3>
<ul>
<li>Sequencing initiatives over 90 days and beyond</li>
<li>Skills gaps and reskilling pathways</li>
<li>Change management and staff communication</li>
<li>Measuring adoption, ROI and course correction</li>
</ul>'
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e903 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e903 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old URL, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'pl-7002-create-and-manage-automated-processes-by-using-power-automate.html'
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c903-301',
       'pl-7002-create-and-manage-automated-processes-by-using-power-automate.html',
       'workplace-evaluation-and-innovation-for-ai-adoption.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e903) AND store_id = 1
  AND request_path <> 'workplace-evaluation-and-innovation-for-ai-adoption.html'
  AND @e903 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e903), 'workplace-evaluation-and-innovation-for-ai-adoption.html',
       CONCAT('catalog/product/view/id/', @e903), 1, @e903
FROM dual WHERE @e903 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Leave the Copilot Series and the Power Platform trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e903
  AND cp.category_id IN (@copilot, 137, 218, 107, 11, 53)
  AND @e903 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e903
  AND i.category_id IN (@copilot, 137, 218, 107, 11, 53)
  AND @e903 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 6) Join AI Courses, the AI Applications Series and AI for HR.
--    HR order: C811 (101), C903 (102), C820 (103).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.id, @e903, 102
FROM (SELECT @aicourses AS id UNION ALL SELECT @apps UNION ALL SELECT @hr) c
WHERE c.id IS NOT NULL AND @e903 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.id, p.entity_id, 102, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN (SELECT @aicourses AS id UNION ALL SELECT @apps UNION ALL SELECT @hr) c ON c.id IS NOT NULL
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C903' AND @is_sg > 0
GROUP BY c.id, p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku WHEN 'C811' THEN 101 WHEN 'C903' THEN 102 WHEN 'C820' THEN 103 END
WHERE cp.category_id = @hr AND p.sku IN ('C811', 'C903', 'C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku WHEN 'C811' THEN 101 WHEN 'C903' THEN 102 WHEN 'C820' THEN 103 END
WHERE i.category_id = @hr AND p.sku IN ('C811', 'C903', 'C820');

-- Parent listing: the HR pair became a trio — C811 (120), C903 (121),
-- C820 (122); the Machine Learning group shifts down by one.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C811'  THEN 120
  WHEN 'C903'  THEN 121
  WHEN 'C820'  THEN 122
  WHEN 'C430'  THEN 123
  WHEN 'C592'  THEN 124
  WHEN 'C193'  THEN 125
  WHEN 'C188'  THEN 126
  WHEN 'C539'  THEN 127
  WHEN 'C1071' THEN 128
  WHEN 'C926'  THEN 129
  WHEN 'C1759' THEN 130
  WHEN 'C1762' THEN 131
  WHEN 'C19'   THEN 132
  WHEN 'C1330' THEN 133
  WHEN 'C279'  THEN 134
  WHEN 'C476'  THEN 135
  WHEN 'C1750' THEN 136
END
WHERE cp.category_id = @apps
  AND p.sku IN ('C811','C903','C820','C430','C592','C193','C188','C539','C1071',
                'C926','C1759','C1762','C19','C1330','C279','C476','C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C811'  THEN 120
  WHEN 'C903'  THEN 121
  WHEN 'C820'  THEN 122
  WHEN 'C430'  THEN 123
  WHEN 'C592'  THEN 124
  WHEN 'C193'  THEN 125
  WHEN 'C188'  THEN 126
  WHEN 'C539'  THEN 127
  WHEN 'C1071' THEN 128
  WHEN 'C926'  THEN 129
  WHEN 'C1759' THEN 130
  WHEN 'C1762' THEN 131
  WHEN 'C19'   THEN 132
  WHEN 'C1330' THEN 133
  WHEN 'C279'  THEN 134
  WHEN 'C476'  THEN 135
  WHEN 'C1750' THEN 136
END
WHERE i.category_id = @apps
  AND p.sku IN ('C811','C903','C820','C430','C592','C193','C188','C539','C1071',
                'C926','C1759','C1762','C19','C1330','C279','C476','C1750');

-- ---------------------------------------------------------------------------
-- 7) Funding Options block (C903 had none).
-- ---------------------------------------------------------------------------

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C903 Funding and Grant',
       'course_C903_funding_and_grant',
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html" title="WSQ - Agentic AI for HR">WSQ - Agentic AI for HR</a></span></p>',
       NOW(), NOW(), 1
FROM dual
WHERE @is_sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM cms_block) b
    WHERE b.identifier = 'course_C903_funding_and_grant'
  );

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html" title="WSQ - Agentic AI for HR">WSQ - Agentic AI for HR</a></span></p>',
    is_active = 1
WHERE identifier = 'course_C903_funding_and_grant'
  AND @is_sg > 0;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM (SELECT * FROM cms_block) b
WHERE b.identifier = 'course_C903_funding_and_grant'
  AND @is_sg > 0;
