-- 931: Repurpose WSQ course TGS-2020503395 (SKU unchanged)
--   "WSQ - Business Innovation with OpenClaw and Blockchain"
--   -> "WSQ - Business Innovation with AI Agents"
-- New About / Learning Outcomes / Course Outline supplied by the admin.
-- Surfaces: name, labels (+ media-gallery label), cover, url_key (+ url_path
-- purge at every scope + 301 from the old slug + legacy alias repoint), SEO
-- meta (title + keyword + description), short_description, description
-- (LSN_DATA JSON kept in sync), whoshouldattend (Job Roles card),
-- learning_outcomes cms_block, trainerprofile (blockchain teaching claims
-- retargeted to AI agents; career facts — CBP cert, Hyperledger delivery
-- history — kept), categories (drop Blockchain + WSQ Blockchain & Fintech;
-- already in the WSQ Agentic AI / AI Agents Series cats), search-term
-- redirects (course-lineage + TGS-code terms follow the course; pure
-- blockchain-intent terms retargeted to the live blockchain offering,
-- AI Vibe Coding for Smart Contract, verified 200 no-chain 2026-08-12).
-- Unchanged on purpose: SKU + funding block/validity (same TGS code),
-- skills_framework (Business Innovation ICT-SNA-4003-1 TSC still correct),
-- certification block, brochure block (SKU-keyed; PDF regenerated
-- out-of-band).
-- Partner-safe: TGS- SKUs exist only on SG => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503395' LIMIT 1);

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_wsa   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');

-- ------------------------------------------------------------ 1. name + labels
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Business Innovation with AI Agents'
  WHERE entity_id = @e AND attribute_id = @a_name AND store_id = 0;

-- Labels are alt text on the cover, which strips the WSQ prefix itself.
UPDATE catalog_product_entity_varchar SET value = 'Business Innovation with AI Agents'
  WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_til) AND store_id = 0;

-- Fresh cover rendered 2026-08-12 with the WSQ/funding badge chips
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503395-20260812-151639.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (renders as the zoom-gallery img title/alt)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'Business Innovation with AI Agents'
  WHERE g.entity_id = @e;

-- --------------------------------------------------------------------- 2. URL
UPDATE catalog_product_entity_varchar SET value = 'wsq-business-innovation-with-ai-agents'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
-- url_path at EVERY scope (store 0 + 1 rows exist) — the URL indexer regenerates
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- 301 from the old bare slug. Drop any non-system squatter first (647: INSERT
-- IGNORE silently no-ops against a stale row). The guarded INSERT lands only
-- once the reindex has moved the system row off the old path; SG's URL indexer
-- also saves rewrite history, so one of the two paths always yields the 301.
DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path = 'wsq-business-innovation-with-openclaw-and-blockchain.html'
  AND @e IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2020503395_openclaw_', s.store_id),
       'wsq-business-innovation-with-openclaw-and-blockchain.html',
       'wsq-business-innovation-with-ai-agents.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'wsq-business-innovation-with-openclaw-and-blockchain.html'
      AND c.is_system = 1);

-- Legacy alias 301s that still target the old slug (bare + category-path
-- forms, e.g. wsq-seo-ecommerce-course-singapore-1057.html) — repoint the
-- filename so they don't become a 301 chain through the old path.
UPDATE core_url_rewrite
  SET target_path = REPLACE(target_path,
    'wsq-business-innovation-with-openclaw-and-blockchain.html',
    'wsq-business-innovation-with-ai-agents.html')
  WHERE is_system = 0
    AND target_path LIKE '%wsq-business-innovation-with-openclaw-and-blockchain.html'
    AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 3. SEO meta
-- Plain title only: MMD_Seotitle prepends "WSQ funded" and appends the brand
-- postfix at render time (the old row had both baked in — that was the bug).
UPDATE catalog_product_entity_varchar SET value = 'Business Innovation with AI Agents'
  WHERE entity_id = @e AND attribute_id = @a_mt;

-- meta_description is a VARCHAR attr (not covered by the meta_title/keyword
-- pair) and rendered into <meta name="description">, og:description,
-- twitter:description AND the JSON-LD Course node — one row, four surfaces.
UPDATE catalog_product_entity_varchar SET value = 'Learn business innovation with AI agents. Explore use cases, opportunities, and implementation strategies for digital transformation. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md;

UPDATE catalog_product_entity_text SET value = 'WSQ business innovation course, AI agents training Singapore, business innovation with AI agents, Hermes Agent for business, AI agent business use cases, business process automation with AI agents, WSQ funded course Singapore, agentic AI course, AI workflow automation, Tertiary Infotech Academy'
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- --------------------------------------------- 4. About This Course (sdesc)
-- Post-strip block model: short_description is prose only (no section HTML,
-- no SKU deep links — verified LOCATE(Course Brochure)=0) => full replace.
UPDATE catalog_product_entity_text SET value = '<p>Business Innovation with AI Agents equips participants with practical skills to identify, design, and implement AI-powered opportunities that improve business processes, customer experiences, and organizational performance. Learners will explore how Hermes Agent can understand objectives, plan and execute tasks, retrieve information, use digital tools, automate workflows, and collaborate with employees.</p>
<p>Through hands-on activities, participants will analyze existing business processes, identify operational challenges, and determine where Hermes Agent can create measurable value. They will configure and apply agents to business functions such as customer service, sales, marketing, administration, research, reporting, and knowledge management. The course covers task design, prompt and context engineering, tool and API integration, Retrieval-Augmented Generation, memory, workflow automation, and human-in-the-loop approvals.</p>
<p>Participants will also develop business cases, evaluate technical and operational feasibility, conduct cost-benefit analyses, and plan pilot implementations. Emphasis is placed on responsible deployment through data protection, access controls, security guardrails, governance, performance measurement, and continuous improvement. By the end of the course, learners will be able to use Hermes Agent to develop practical business innovations aligned with organizational needs and strategic goals.</p>'
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0;

-- ------------------------------------- 5. Course Outline (description + JSON)
UPDATE catalog_product_entity_text SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI Agents, Emerging Technologies and Business Model Transformation","subsecs":[]},{"title":"Topic 2: Identifying AI Agent Opportunities for Business Innovation","subsecs":[]},{"title":"Topic 3: Digitalizing Business Processes with AI Agents","subsecs":[]},{"title":"Topic 4: Feasibility and Cost-Benefit Analysis of AI Agent Solutions","subsecs":[]},{"title":"Topic 5: Implementing and Evaluating AI-Driven Business Innovation Processes","subsecs":[]}] -->
<p><strong>Topic 1: AI Agents, Emerging Technologies and Business Model Transformation</strong></p>
<p><strong>Topic 2: Identifying AI Agent Opportunities for Business Innovation</strong></p>
<p><strong>Topic 3: Digitalizing Business Processes with AI Agents</strong></p>
<p><strong>Topic 4: Feasibility and Cost-Benefit Analysis of AI Agent Solutions</strong></p>
<p><strong>Topic 5: Implementing and Evaluating AI-Driven Business Innovation Processes</strong></p>'
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- --------------------------------- 6. What You'll Learn (cms_block LO list)
UPDATE cms_block SET content = '<p>By the end of the class, learners will be able to</p>
<ul>
<li>LO1: Understand technology and compare current business model for the organisation with emerging business model in the industry</li>
<li>LO2:&nbsp;Explore potential opportunities for business innovation technology within the organisation</li>
<li>LO3:&nbsp;Identify ways in which digitalization can be applied to the business</li>
<li>LO4:&nbsp;Conduct feasibility analysis and weigh the costs-benefits of potential business innovation opportunities.</li>
<li>LO5:&nbsp;Implement business innovation processes</li>
</ul>'
  WHERE identifier = 'course_TGS-2020503395_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------- 7. Trainer bios (course mentions)
-- Byte-probed on SG prod 2026-08-12: every target LOCATEs exactly once.
-- Career facts stay (Truman's CBP cert + "blockchain (Hyperledger)" delivery
-- history are facts, not course claims) — only teaching claims retarget.
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'including blockchain applications in business innovation',
  'including AI agent applications in business innovation')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'His teaching emphasizes the strategic use of blockchain for process optimization, transparency, and secure transactions',
  'His teaching emphasizes the strategic use of AI agents for process optimization, workflow automation, and data-driven decision-making')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'confidently explore blockchain as a tool to drive organizational change',
  'confidently explore AI agents as a tool to drive organizational change')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'well-positioned to guide learners in blockchain applications',
  'well-positioned to guide learners in AI agent applications')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'In his blockchain training, Alfred focuses on practical, learner-centered approaches, helping participants understand the fundamentals of distributed ledger technology and its potential to transform industries',
  'In his AI agent training, Alfred focuses on practical, learner-centered approaches, helping participants understand the fundamentals of agentic AI and its potential to transform industries')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'the ability to identify opportunities for blockchain adoption in real-world business contexts',
  'the ability to identify opportunities for AI agent adoption in real-world business contexts')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'leverage blockchain for innovation and sustainable growth',
  'leverage AI agents for innovation and sustainable growth')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'As a trainer, Truman emphasizes the practical application of blockchain technology in solving business challenges. He has delivered blockchain-focused courses covering both technical implementation and strategic use cases, enabling participants to understand smart contracts, decentralized applications, and blockchain integration with existing systems',
  'As a trainer, Truman emphasizes the practical application of AI agent technology in solving business challenges. He has delivered technology-focused courses covering both technical implementation and strategic use cases, enabling participants to understand autonomous agents, workflow automation, and AI integration with existing systems')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'confidently explore blockchain as a driver of innovation, efficiency, and trust in the digital economy',
  'confidently explore AI agents as a driver of innovation, efficiency, and trust in the digital economy')
  WHERE entity_id = @e AND attribute_id = @a_tp;

-- -------------------------------------------------------------- 8. Categories
-- Resolve BY NAME (ids differ per instance). Drop the blockchain placements;
-- the course already sits in WSQ Agentic AI Courses / AI Agents Series /
-- AI Courses / WSQ AI Courses, so nothing to add.
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.store_id = 0
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE cp.product_id = @e AND v.value IN ('Blockchain', 'WSQ Blockchain & Fintech');

-- ------------------------------------ 9. Job Roles (whoshouldattend attr)
-- Renders as the "Job Roles" accordion card. 6 of the 20 roles were
-- blockchain-specific; retargeted to AI-agent equivalents. The 14
-- technology-neutral roles (Business Innovation Manager, Digital
-- Transformation Lead, ...) stay untouched — each REPLACE is a distinct
-- <li> so re-running is a no-op once applied.
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  '<li>Blockchain Strategy Consultant</li>', '<li>AI Strategy Consultant</li>')
  WHERE entity_id = @e AND attribute_id = @a_wsa;
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  '<li>Blockchain Solutions Architect</li>', '<li>AI Solutions Architect</li>')
  WHERE entity_id = @e AND attribute_id = @a_wsa;
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  '<li>Enterprise Blockchain Consultant</li>', '<li>Enterprise AI Consultant</li>')
  WHERE entity_id = @e AND attribute_id = @a_wsa;
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  '<li>Blockchain Project Manager</li>', '<li>AI Project Manager</li>')
  WHERE entity_id = @e AND attribute_id = @a_wsa;
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  '<li>Blockchain Business Analyst</li>', '<li>AI Business Analyst</li>')
  WHERE entity_id = @e AND attribute_id = @a_wsa;
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  '<li>Blockchain Implementation Consultant</li>', '<li>AI Agent Implementation Consultant</li>')
  WHERE entity_id = @e AND attribute_id = @a_wsa;

-- --------------------------------------------------- 10. Search-term redirects
-- 21 live rows point at the old slug. Course-lineage terms (any "business
-- innovation" variant, incl. the "buiness" typo, plus the bare TGS code)
-- follow the course to its new slug — same TGS reference, same funded course.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/wsq-business-innovation-with-ai-agents.html'
  WHERE redirect LIKE '%tertiarycourses.com.sg/wsq-business-innovation-with-openclaw-and-blockchain.html%'
    AND (query_text LIKE '%business innovation%'
         OR query_text LIKE '%buiness innovation%'
         OR query_text = 'TGS-2020503395');

-- Pure blockchain-intent terms (blockchain for SME, NICF blockchain, typos,
-- business technology with blockchain) go to the live blockchain offering
-- instead of an AI-agents page (target verified 200, no redirect chain).
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/ai-vibe-coding-for-smart-contract.html'
  WHERE redirect LIKE '%tertiarycourses.com.sg/wsq-business-innovation-with-openclaw-and-blockchain.html%';
