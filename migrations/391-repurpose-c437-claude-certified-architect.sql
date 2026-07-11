-- Repurpose course C437 to "Claude Certified Architect - Foundations
-- Certification" (Anthropic Claude cert prep, exam code CCAR-F). Course details
-- show the 5 exam domains from the exam guide; registration link points to the
-- Anthropic Partner Academy (Skilljar). NOT an AI Vibe Coding course (no badge).
-- Store scope 0. Idempotent. meta_description kept under varchar(255).
-- No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C437');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Claude Certified Architect - Foundations Certification') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Prepare for and earn the Claude Certified Architect - Foundations certification (exam code CCAR-F). This certification validates that you can make informed decisions about tradeoffs when implementing real-world, production-grade solutions with Claude. It tests foundational knowledge across Claude Code, the Claude Agent SDK, the Claude API and the Model Context Protocol (MCP) &mdash; the core technologies used to build production applications with Claude. It is intended for solution architects and developers who design and implement production applications with Claude.</p>
<p>This 2-day course prepares you for all five exam domains through hands-on practice building agentic loops and multi-agent systems, designing MCP tools, configuring Claude Code workflows, engineering prompts for structured output, and managing context and reliability in production. The scenario-based exam has 60 multiple-choice and multiple-response items across 4 scenarios (drawn from a bank of 6), a 120-minute time limit and a passing scaled score of 720 (100-1,000). Register on the Anthropic Partner Academy: <a href="https://anthropic-partners.skilljar.com/claude-certified-architect-foundations-certification" target="_blank">Claude Certified Architect - Foundations</a>.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Domain 1 Agentic Architecture and Orchestration (27%)</h3>
<ul>
<li>Design and implement agentic loops for autonomous task execution (stop_reason handling, tool-result feedback)</li>
<li>Orchestrate multi-agent systems with coordinator-subagent patterns</li>
<li>Configure subagent invocation, context passing and spawning (Task tool, isolated context, parallel subagents)</li>
<li>Avoid agentic anti-patterns and design for observability and controlled information flow</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Tool Design and MCP Integration (18%)</h3>
<ul>
<li>Design Model Context Protocol (MCP) tool and resource interfaces for backend integration</li>
<li>Define clear tool schemas, inputs and outputs for reliable tool use</li>
<li>Integrate Claude with custom backend systems and APIs via MCP</li>
<li>Balance tool granularity, error handling and security</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Claude Code Configuration and Workflows (20%)</h3>
<ul>
<li>Configure and customise Claude Code for team workflows using CLAUDE.md files</li>
<li>Use Agent Skills, MCP server integrations and plan mode</li>
<li>Integrate Claude Code into development and CI/CD workflows (code review, test generation, PR feedback)</li>
<li>Choose between plan mode and direct execution and design custom slash commands</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Prompt Engineering and Structured Output (20%)</h3>
<ul>
<li>Engineer prompts that produce reliable structured output</li>
<li>Leverage JSON schemas, few-shot examples and extraction patterns</li>
<li>Extract structured data from unstructured documents with high accuracy</li>
<li>Handle edge cases gracefully and validate outputs against schemas</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Context Management and Reliability (15%)</h3>
<ul>
<li>Manage context windows across long documents, multi-turn conversations and multi-agent handoffs</li>
<li>Make sound escalation and reliability decisions (error handling, human-in-the-loop, self-evaluation)</li>
<li>Design for graceful degradation and production reliability</li>
<li>Apply self-evaluation patterns to improve output quality</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Claude Certified Architect - Foundations Certification | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for the Claude Certified Architect - Foundations certification (CCAR-F). Master agentic architecture, MCP tools, Claude Code, structured output and reliability in this 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Claude Certified Architect, Claude Certification, CCAR-F, Anthropic, Claude Code, Claude Agent SDK, MCP, AI Certification, Exam Prep')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C437-20260711-173800.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'claude-certified-architect-foundations-certification') ON DUPLICATE KEY UPDATE value = VALUES(value);
