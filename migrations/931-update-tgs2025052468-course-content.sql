-- 931: Refresh course content for TGS-2025052468
--   "WSQ - Agentic AI Applications with Claude Code" (name/SKU/URL unchanged)
-- New About This Course, Learning Outcomes and Course Outline supplied by the
-- admin (2026-08-12). Course pivoted off AWS Bedrock/LangChain to a pure
-- Claude Code curriculum (RAG, skills, sub-agents, hooks, MCP).
-- Surfaces: short_description, description (LSN_DATA JSON kept in sync),
-- learning_outcomes cms_block. Unchanged on purpose: name, url_key, SEO meta,
-- cover, funding/certification/brochure/skills_framework blocks, categories.
-- Partner-safe: TGS- SKUs exist only on SG => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052468' LIMIT 1);

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- --------------------------------------------- 1. About This Course (sdesc)
-- Post-885 block model: short_description is prose only (no section HTML,
-- no SKU deep links) => full replace is safe.
UPDATE catalog_product_entity_text SET value = '<p>Agentic AI Applications with Claude Code equips learners with practical skills to build intelligent, context-aware applications using Claude Code, Retrieval-Augmented Generation (RAG), reusable skills, and autonomous AI agents. The course emphasizes context engineering and RAG-based memory, enabling AI applications to retrieve relevant knowledge, maintain project context, and deliver more accurate and consistent outputs across complex workflows.</p>
<p>Learners will explore Claude Code fundamentals, including project initialization, operating modes, vibe coding workflows, and memory management. They will learn to structure persistent memory using project instructions, documentation, knowledge files, and external data sources so that Claude Code can understand application requirements, development standards, and domain-specific knowledge.</p>
<p>The course covers tools, custom slash commands, and Model Context Protocol (MCP) integrations for connecting Claude Code with external systems, APIs, databases, and development tools. Participants will also learn to create reusable skills that combine instructions, knowledge, tools, and workflows for specialized tasks.</p>
<p>Through hands-on activities, learners will implement RAG pipelines, develop skills and sub-agents, and use hooks to automate and control agentic workflows. They will learn how agents can retrieve knowledge, invoke tools, coordinate tasks, and execute multi-step processes with greater autonomy and reliability.</p>
<p>The course also addresses testing, debugging, optimization, and issue reporting for RAG and AI agent applications. By the end of the course, learners will be able to implement foundation-model applications, deploy agentic AI workflows, and identify issues affecting retrieval quality, memory accuracy, tool execution, and agent performance.</p>'
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0;

-- ------------------------------------- 2. Course Outline (description + JSON)
UPDATE catalog_product_entity_text SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Claude Code Fundamentals","subsecs":[{"title":"Vibe Coding with Claude Code","links":[]},{"title":"Initialise Claude Code","links":[]},{"title":"Operation Modes","links":[]},{"title":"Context Engineering and Memory Management","links":[]}]},{"title":"Topic 2: Tools and Commands","subsecs":[{"title":"Custom Slash Commands","links":[]},{"title":"Tools & MCP","links":[]}]},{"title":"Topic 3: RAG, Skills and Agents","subsecs":[{"title":"RAG and Skills","links":[]},{"title":"Sub Agents","links":[]},{"title":"Hooks","links":[]}]}] -->
<p><strong>Topic 1: Claude Code Fundamentals</strong></p>
<p><em>Vibe Coding with Claude Code</em></p>
<p><em>Initialise Claude Code</em></p>
<p><em>Operation Modes</em></p>
<p><em>Context Engineering and Memory Management</em></p>
<p><strong>Topic 2: Tools and Commands</strong></p>
<p><em>Custom Slash Commands</em></p>
<p><em>Tools &amp; MCP</em></p>
<p><strong>Topic 3: RAG, Skills and Agents</strong></p>
<p><em>RAG and Skills</em></p>
<p><em>Sub Agents</em></p>
<p><em>Hooks</em></p>'
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- --------------------------------- 3. Learning Outcomes (cms_block LO list)
UPDATE cms_block SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Implement AI applications and Foundation Models</li>
<li>LO2: Deploy AI workflows and machine learning techniques.</li>
<li>LO3: Identify and report issues in Retrieval-Augmented Generation (RAG) and AI Agents applications.</li>
</ul>'
  WHERE identifier = 'course_TGS-2025052468_learning_outcomes' AND @e IS NOT NULL;
