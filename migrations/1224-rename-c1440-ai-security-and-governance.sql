-- 1224: Rename C1440 "AI Security and Governance for AI Agents" to
-- "AI Security and Governance", with a new url_key + 301, a freshly rendered
-- branded R2 cover, and rewritten "What's This Course About"
-- (short_description) and "What You'll Learn" (description topics).
--
-- SKU stays C1440. The old copy was scoped to securing AI agents; the new
-- name is broader, so the content widens to cover AI security and governance
-- across the organisation — risk and threat landscape, governance frameworks
-- and policy, securing models/data/agents, and assurance/compliance — while
-- keeping agent-specific risks as one topic rather than the whole course.
--
-- Course is 7.5h / 1 day; the copy reflects that. Topic HTML uses the
-- LSN_DATA + <h3 class="course-topic-h3"> shape the product page expects.
-- Category memberships (AI Security Series, AI Agents Series) are unchanged.
--
-- SG-guarded; C-prefix SKU and this url_key are SG-only (partner no-op).
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

SET @e1440 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1440' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e1440, 'AI Security and Governance'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e1440 AND attribute_id = @a_pname AND store_id <> 0
  AND @e1440 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e1440, 'ai-security-and-governance'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e1440 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e1440 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e1440, 'AI Security and Governance | Tertiary Courses Singapore'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e1440, 'Secure and govern AI across your organisation - risk and threat landscape, governance frameworks and policy, securing models, data and agents, and assurance.'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e1440, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1440-20260830-075515.png'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e1440,
'<p>AI is now embedded in everyday business systems &mdash; chatbots answering customers, models scoring decisions, agents acting on live data &mdash; and each of those creates exposure that traditional security controls were never designed for. Prompt injection, data leakage through model inputs, unsafe tool access, unclear accountability when a model gets it wrong: these are governance problems as much as technical ones, and organisations that treat them as an afterthought find out the hard way.</p><p>In this hands-on 1-day course, you will work through the AI security and governance landscape end to end &mdash; the threats specific to AI and machine learning systems, how to secure models, data pipelines and autonomous agents, and how to build the governance layer around them: policies, approval gates, human oversight, audit trails and incident response. You will apply recognised frameworks and map them to the regulatory expectations that apply in Singapore and beyond.</p><p>You will leave with a practical AI risk assessment, a governance checklist and a control set you can take back to your own organisation &mdash; enough to answer "is our AI use safe, compliant and accountable?" with evidence rather than hope. Ideal for IT and security professionals, risk and compliance officers, data and AI practitioners, and managers responsible for AI adoption.</p>'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e1440,
'<!-- LSN_DATA: [{"title":"Topic 1 The AI Risk and Threat Landscape","subsecs":[{"title":"How AI systems fail: technical, data and human factors","links":[]},{"title":"Attacks on AI: prompt injection, data poisoning, model extraction","links":[]},{"title":"Data leakage, privacy and confidentiality risks","links":[]},{"title":"Real-world AI security incidents and lessons learned","links":[]}]},{"title":"Topic 2 AI Governance Frameworks and Policy","subsecs":[{"title":"Principles of responsible and trustworthy AI","links":[]},{"title":"Governance frameworks and standards","links":[]},{"title":"Regulatory expectations and compliance obligations","links":[]},{"title":"Writing AI usage policies that people follow","links":[]}]},{"title":"Topic 3 Securing Models, Data and Agents","subsecs":[{"title":"Securing data pipelines and training data","links":[]},{"title":"Access control, identity and least privilege for AI systems","links":[]},{"title":"Guardrails for autonomous agents and tool use","links":[]},{"title":"Testing, red-teaming and evaluating AI systems","links":[]}]},{"title":"Topic 4 Assurance, Oversight and Response","subsecs":[{"title":"Running an AI risk assessment","links":[]},{"title":"Human oversight and approval gates","links":[]},{"title":"Monitoring, logging and audit trails","links":[]},{"title":"Incident response and continuous improvement","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 The AI Risk and Threat Landscape</h3>
<ul>
<li>How AI systems fail: technical, data and human factors</li>
<li>Attacks on AI: prompt injection, data poisoning, model extraction</li>
<li>Data leakage, privacy and confidentiality risks</li>
<li>Real-world AI security incidents and lessons learned</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI Governance Frameworks and Policy</h3>
<ul>
<li>Principles of responsible and trustworthy AI</li>
<li>Governance frameworks and standards</li>
<li>Regulatory expectations and compliance obligations</li>
<li>Writing AI usage policies that people follow</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Securing Models, Data and Agents</h3>
<ul>
<li>Securing data pipelines and training data</li>
<li>Access control, identity and least privilege for AI systems</li>
<li>Guardrails for autonomous agents and tool use</li>
<li>Testing, red-teaming and evaluating AI systems</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Assurance, Oversight and Response</h3>
<ul>
<li>Running an AI risk assessment</li>
<li>Human oversight and approval gates</li>
<li>Monitoring, logging and audit trails</li>
<li>Incident response and continuous improvement</li>
</ul>'
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e1440 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e1440 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old URL, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-security-and-governance-for-ai-agents.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c1440-301', 'ai-security-and-governance-for-ai-agents.html',
       'ai-security-and-governance.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e1440) AND store_id = 1
  AND request_path <> 'ai-security-and-governance.html'
  AND @e1440 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e1440), 'ai-security-and-governance.html',
       CONCAT('catalog/product/view/id/', @e1440), 1, @e1440
FROM dual WHERE @e1440 IS NOT NULL AND @is_sg > 0;
