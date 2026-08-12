-- 933: Rename TGS-2025054471
--        "WSQ - Pearson Vue Certified IT Specialist - Artificial Intelligence"
--      -> "WSQ - Autonomous AI Agents"
--
-- Course code (SKU) is UNCHANGED — TGS-2025054471 stays, so the per-SKU
-- cms_block identifiers, brochure PDF path, funding deep links and the
-- funding validity window all stay put. Follows the 929/930/931 shape.
--
-- Scope of this file:
--   1. name -> "WSQ - Autonomous AI Agents"; image/gallery labels -> plain
--      title (alt text mirrors the cover, which strips the WSQ prefix)
--   2. course_image_url -> fresh cover rendered on SG prod 2026-08-12
--      (new title; badges unchanged)
--   3. meta_title / meta_description / meta_keyword refreshed. meta_title omits
--      BOTH the "WSQ" token and the brand suffix — MMD_Seotitle composes the
--      <title> at render time (prepends "WSQ funded" for SG TGS- SKUs and
--      appends "| Tertiary Courses Singapore"). The CURRENT value bakes in
--      both, which renders as "WSQ funded WSQ Pearson ... | Tertiary Courses
--      Singapore | Tertiary Courses Singapore" — the 853 anti-pattern; this
--      migration cleans it up.
--   4. url_key -> autonomous-ai-agents; url_path deleted at every scope so the
--      Catalog URL Rewrites indexer regenerates it
--   5. 301 from the old bare slug; the 33 legacy alias rewrites that 301 into
--      the old slug are repointed straight at the new one (no 301 chains)
--   6. short_description -> the new "About This Course" copy (3 paragraphs;
--      full replace — sections live in per-SKU cms_blocks since 885-890)
--   7. description (Course Outline) -> the 3 new topics, replacing the 5
--      Pearson-VUE-exam-domain topics, keeping the existing <p><strong> shape
--   8. search-term redirects retargeted off the old slug (2 SG rows)
--
-- NOT touched (verified against SG prod 2026-08-12):
--   - learning_outcomes cms_block (1786) — LO1-LO3 already match the requested
--     text byte-for-byte; the requested LOs are unchanged by this rename
--   - skills_framework block (2864) — the accredited TSC (AER-TEM-3026-1.1
--     "Artificial Intelligence Application") still describes the new content
--     and is unchanged by a title rename
--   - certification / funding_and_grant / brochure blocks — SKU unchanged
--   - trainerprofile — LOCATE('Pearson') = 0 at BOTH scopes (store 0 and 1);
--     the old course title never appears, so there is nothing to splice
--   - whoshouldattend / prerequisite — the AI job roles and entry requirements
--     remain accurate for the new agent-focused content
--   - the sibling live Pearson VUE courses (Networking / Cybersecurity /
--     Cloud Computing / the separate "-training" AI product id 798) and their
--     ~60 search redirects — deliberately left pointing where they are
--
-- Partner-safe: TGS- SKUs only exist on SG; on MY/GH @e IS NULL and the file
-- no-ops (rewrite/search statements additionally guarded on the SG store /
-- full SG domain). Idempotent — re-runnable.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025054471' LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------------------------- 1. name + labels
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Autonomous AI Agents'
  WHERE entity_id = @e AND attribute_id = @a_name AND store_id = 0;

-- Labels carry the plain title (no "WSQ - " prefix): they are alt text on the
-- course cover, which itself renders without the prefix.
UPDATE catalog_product_entity_varchar SET value = 'Autonomous AI Agents'
  WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_til) AND store_id = 0;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'Autonomous AI Agents'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. fresh cover (R2)
-- Re-rendered on SG prod 2026-08-12 with the new title (the old PNG baked
-- "Pearson Vue Certified IT Specialist - Artificial Intelligence" into the
-- image). Badges unchanged: WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC,
-- Absentee Payroll, MCES.
UPDATE catalog_product_entity_varchar
  SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054471-20260812-152009.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu;

-- ------------------------------------------------------------------ 3. SEO meta
-- Plain title only — MMD_Seotitle prepends the funding token and appends the
-- brand postfix at render time; baking either is the 853 anti-pattern.
UPDATE catalog_product_entity_varchar SET value = 'Autonomous AI Agents Course'
  WHERE entity_id = @e AND attribute_id = @a_mt;

UPDATE catalog_product_entity_varchar SET value = 'Master Autonomous AI Agents in Singapore. Learn to design, build, deploy and monitor AI agents with memory, tools, RAG and multi-agent workflows. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md;

UPDATE catalog_product_entity_text SET value = 'Autonomous AI Agents, AI Agent Development, Agentic AI, Large Language Models, Retrieval-Augmented Generation, Agent Memory, Tool Integration, Multi-Agent Systems, Prompt Engineering, Context Engineering, Human-in-the-Loop, AI Agent Security, Prompt Injection Defence, AI Agent Monitoring, AI Training Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- ------------------------------------------------------- 4. url_key + url_path
UPDATE catalog_product_entity_varchar SET value = 'autonomous-ai-agents'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 5. 301s off the old slug
-- Repoint the existing bare-slug rewrite row (the system row still holds the
-- old request_path until reindex) and force it permanent + manual; create the
-- row where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'autonomous-ai-agents.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html'
    AND store_id IN (0, 1);
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html'), '-', s.store_id),
       'wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html',
       'autonomous-ai-agents.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug (33 rows: historical bare
-- and category-prefixed paths) — repoint straight at the new slug so inbound
-- links take one hop, not a chain. REPLACE also fixes the category-prefixed
-- targets. Anchored with a leading '%' + full old filename so the sibling
-- Pearson VUE courses (networking / cybersecurity / cloud-computing / the
-- separate "-training" AI product) are never matched.
UPDATE core_url_rewrite
  SET target_path = REPLACE(target_path,
      'wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html',
      'autonomous-ai-agents.html')
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html'
    AND request_path <> 'wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html';

-- ---------------------------------------- 6. short_description (About This Course)
-- Full replace: since the 885-890 extraction this course's short_description
-- holds only the intro prose (Brochure / Certification / Skills Framework /
-- Funding sections live in per-SKU cms_blocks).
UPDATE catalog_product_entity_text SET value = '<p>Autonomous AI Agents equips participants with practical skills to design, build, deploy, and manage AI agents capable of performing tasks with minimal human intervention. Learners will explore how autonomous agents use large language models, tools, memory, context, reasoning, and structured workflows to understand goals, plan actions, make decisions, and interact with digital systems.</p>
<p>Through hands-on activities, participants will build agents that retrieve information, process documents, call APIs, automate workflows, generate outputs, and collaborate with other specialized agents. The course covers agent architecture, prompt and context engineering, tool integration, Retrieval-Augmented Generation, persistent memory, multi-agent coordination, task delegation, and human-in-the-loop approvals.</p>
<p>Participants will also learn to evaluate agent performance, monitor actions, manage permissions, control operating costs, and troubleshoot unreliable behaviour. Strong emphasis is placed on responsible deployment through sandboxing, least-privilege access, security guardrails, audit trails, data protection, and defence against prompt injection. By the end of the course, learners will be able to develop secure, reliable, and goal-driven autonomous AI agents for practical business and operational applications.</p>'
  WHERE entity_id = @e AND attribute_id = @a_sd;

-- ------------------------------------------------ 7. description (Course Outline)
-- Same markup shape as the current value (<p><strong>Topic N: ...</strong></p>).
-- The requested outline carries topic titles only — the five Pearson VUE exam
-- domains and their sub-bullets are retired with the certification content.
UPDATE catalog_product_entity_text SET value = '<p><strong>Topic 1: Building Autonomous AI Agents with Data, Memory and Tools</strong></p>
<p><strong>Topic 2: Deploying and Optimizing Autonomous AI Agent Workflows</strong></p>
<p><strong>Topic 3: Monitoring, Evaluating and Troubleshooting AI Agent Applications</strong></p>'
  WHERE entity_id = @e AND attribute_id = @a_desc;

-- --------------------------------------- 8. retarget search-term redirects
-- Exactly 2 live SG rows point at this course's slug (query_id 63949 = the bare
-- course code, 65096 = the full old title). Anchored on the FULL SG-domain URL
-- ending in this course's filename so the ~60 sibling Pearson VUE redirects
-- (networking / cybersecurity / cloud computing / the "-training" AI product)
-- are untouched. Search redirects are DATA — this file is ALSO applied live on
-- prod (see memory feedback_search_redirects_always_apply_live).
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/autonomous-ai-agents.html'
  WHERE redirect = 'https://www.tertiarycourses.com.sg/wsq-pearson-vue-certified-it-specialist-artificial-intelligence.html';
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/autonomous-ai-agents.html'
  WHERE @sg = 1 AND query_text = 'TGS-2025054471';
