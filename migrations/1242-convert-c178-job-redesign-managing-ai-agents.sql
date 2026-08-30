-- 1242: Convert C178 "AI Vibe Coding for C++" into "Job Redesign for
-- Managing AI Agents", and move it from the AI Vibe Coding Series to
-- AI for HR.
--
-- SKU stays C178. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta, plus a written-from-scratch
-- "What's This Course About" (three paragraphs) and "What You'll Learn"
-- (four topics) — no donor course was named for this one, and the subject is
-- distinct from the existing HR courses:
--   C811 Job Assessment and Redesign for AI Adoption  — assessing jobs for AI
--   C903 Workplace Evaluation and Innovation          — org-wide readiness
--   C178 (this)                                       — redesigning roles for
--        people who now SUPERVISE AI agents day to day
--
-- It also leaves the Programming / C-C++-C# trees, which no longer describe
-- the course. It keeps All Courses (3), Infocomm Technology (55) and AI
-- Courses (252).
--
-- Placed after the three existing non-WSQ HR courses (1241 order), so the
-- listing reads: two WSQ, then AI for HR, Generative AI for Interviewing,
-- Job Assessment and Redesign, Workplace Evaluation, then this. Every
-- non-WSQ member is covered by the CASE so none drifts.
--
-- Its funding card (created by 1226 with the AI Vibe Coding target) is
-- repointed at WSQ - Agentic AI for HR to match the new subject.
--
-- Course is 7.5h / 1 day; the copy reflects that. Topic HTML uses the
-- LSN_DATA + <h3 class="course-topic-h3"> shape the product page expects.
-- The 301 uses a slug-derived id_path so a future rename cannot collide.
--
-- SG-guarded; C-prefix SKU and these url_keys are SG-only (partner no-op).
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

SET @e178 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C178' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e178, 'Job Redesign for Managing AI Agents'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e178 AND attribute_id = @a_pname AND store_id <> 0
  AND @e178 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e178, 'job-redesign-for-managing-ai-agents'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e178 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e178 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e178, 'Job Redesign for Managing AI Agents | Tertiary Courses Singapore'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e178, 'Redesign roles for a workforce that supervises AI agents - task allocation between people and agents, oversight and escalation, new skills, and performance management.'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e178, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C178-20260830-121753.png'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e178,
'<p>When AI agents start doing real work &mdash; drafting, researching, reconciling, responding &mdash; the job that changes most is not the agent''s, it is your team''s. People who used to produce the work now review it, direct it and decide when to overrule it. That is a genuinely different role, and most organisations hand it to staff without redesigning the job, the workload expectations or the performance measures around it.</p><p>In this hands-on 1-day course, you will learn to redesign roles for a workforce that supervises AI agents. You will map which tasks move to agents and which stay human, define the oversight each workflow needs, write the escalation rules that tell people when to step in, and rebalance workloads once the routine work has shifted. You will also work through the harder questions: who is accountable when an agent gets it wrong, what supervision looks like at scale, and how to keep judgement sharp when the first draft always arrives finished.</p><p>You will leave with redesigned role profiles, an oversight and escalation model, and a skills plan for moving your team from doing the work to directing it &mdash; the practical groundwork for adopting agents without hollowing out capability. Ideal for HR and L&amp;D professionals, team leaders, operations managers and transformation leads planning for an agent-assisted workforce.</p>'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e178,
'<!-- LSN_DATA: [{"title":"Topic 1 How AI Agents Change the Job","subsecs":[{"title":"What AI agents can and cannot take over","links":[]},{"title":"From producing work to directing and reviewing it","links":[]},{"title":"Roles most and least affected by agent adoption","links":[]},{"title":"Case examples of agent-assisted teams","links":[]}]},{"title":"Topic 2 Splitting Work Between People and Agents","subsecs":[{"title":"Task-level analysis of existing roles","links":[]},{"title":"Deciding what to delegate to an agent","links":[]},{"title":"Rebalancing workloads after the routine work shifts","links":[]},{"title":"Writing the redesigned role profile","links":[]}]},{"title":"Topic 3 Oversight, Escalation and Accountability","subsecs":[{"title":"Designing review and approval checkpoints","links":[]},{"title":"Escalation rules: when a human must step in","links":[]},{"title":"Accountability when an agent gets it wrong","links":[]},{"title":"Supervising agents at scale without rubber-stamping","links":[]}]},{"title":"Topic 4 Skills, Performance and Transition","subsecs":[{"title":"New skills for agent supervisors","links":[]},{"title":"Keeping human judgement sharp","links":[]},{"title":"Performance measures for agent-assisted roles","links":[]},{"title":"Communicating the change and planning the transition","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 How AI Agents Change the Job</h3>
<ul>
<li>What AI agents can and cannot take over</li>
<li>From producing work to directing and reviewing it</li>
<li>Roles most and least affected by agent adoption</li>
<li>Case examples of agent-assisted teams</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Splitting Work Between People and Agents</h3>
<ul>
<li>Task-level analysis of existing roles</li>
<li>Deciding what to delegate to an agent</li>
<li>Rebalancing workloads after the routine work shifts</li>
<li>Writing the redesigned role profile</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Oversight, Escalation and Accountability</h3>
<ul>
<li>Designing review and approval checkpoints</li>
<li>Escalation rules: when a human must step in</li>
<li>Accountability when an agent gets it wrong</li>
<li>Supervising agents at scale without rubber-stamping</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Skills, Performance and Transition</h3>
<ul>
<li>New skills for agent supervisors</li>
<li>Keeping human judgement sharp</li>
<li>Performance measures for agent-assisted roles</li>
<li>Communicating the change and planning the transition</li>
</ul>'
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e178 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e178 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-for-cpp.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-vibe-coding-for-cpp-301',
       'ai-vibe-coding-for-cpp.html', 'job-redesign-for-managing-ai-agents.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e178) AND store_id = 1
  AND request_path <> 'job-redesign-for-managing-ai-agents.html'
  AND @e178 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e178), 'job-redesign-for-managing-ai-agents.html',
       CONCAT('catalog/product/view/id/', @e178), 1, @e178
FROM dual WHERE @e178 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Leave the AI Vibe Coding Series and the Programming / C trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e178
  AND cp.category_id IN (@vibe, 31, 80)
  AND @e178 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e178
  AND i.category_id IN (@vibe, 31, 80)
  AND @e178 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 6) Join AI for HR, after the three existing non-WSQ courses.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @hr, p.entity_id, 105
FROM catalog_product_entity p
WHERE @hr IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C178';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @hr, p.entity_id, 105, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @hr IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C178'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C820' THEN 101
  WHEN 'C169' THEN 102
  WHEN 'C811' THEN 103
  WHEN 'C903' THEN 104
  WHEN 'C178' THEN 105
END
WHERE cp.category_id = @hr
  AND p.sku IN ('C820', 'C169', 'C811', 'C903', 'C178');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C820' THEN 101
  WHEN 'C169' THEN 102
  WHEN 'C811' THEN 103
  WHEN 'C903' THEN 104
  WHEN 'C178' THEN 105
END
WHERE i.category_id = @hr
  AND p.sku IN ('C820', 'C169', 'C811', 'C903', 'C178');

-- ---------------------------------------------------------------------------
-- 7) Repoint the funding card at the HR-relevant WSQ course.
-- ---------------------------------------------------------------------------

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html" title="WSQ - Agentic AI for HR">WSQ - Agentic AI for HR</a></span></p>'
WHERE identifier = 'course_C178_funding_and_grant'
  AND @is_sg > 0;
