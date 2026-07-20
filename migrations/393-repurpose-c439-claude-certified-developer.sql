-- Repurpose course C439 to "Claude Certified Developer - Foundations
-- Certification" (Anthropic Claude cert prep, exam code CCDV-F). Course details
-- show the 8 exam domains from the exam guide; registration link points to the
-- Anthropic Partner Academy (Skilljar). NOT an AI Vibe Coding course (no badge).
-- Store scope 0. Idempotent. meta_description kept under varchar(255).
-- No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C439');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Claude Certified Developer - Foundations Certification') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Prepare for and earn the Claude Certified Developer - Foundations certification (exam code CCDV-F). This certification validates that you can build, integrate and ship production-grade applications, agents and workflows using Anthropic Claude at a foundational level. It is intended for technical professionals &mdash; AI/ML engineers, technical leads and senior software engineers &mdash; who bridge Claude&rsquo;s capabilities and production-ready applications through API integration, agent and tool construction, prompt and context engineering, evaluation, security and model selection.</p>
<p>This 2-day course prepares you for all eight exam domains through hands-on practice building agents with the Claude Agent SDK, integrating the Claude API, operating Claude Code, engineering prompts and context, running evals, managing cost and model selection, applying security guardrails, and building custom tools and MCP servers. The exam has 53 multiple-choice and multiple-response items, a 120-minute time limit and a passing scaled score of 720 (100-1,000). Register on the Anthropic Partner Academy: <a href="https://anthropic-partners.skilljar.com/claude-certified-developer-foundations-certification" target="_blank">Claude Certified Developer - Foundations</a>.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Domain 1 Agents and Workflows (14.7%)</h3>
<ul>
<li>Apply agent and workflow architecture patterns and decide when to use a workflow versus an agent</li>
<li>Construct Claude agents with the Claude Agent SDK, custom agent loops and harnesses, and hooks for deterministic actions</li>
<li>Choose managed deployment models (self-hosted vs Anthropic-hosted) and design manager/subagent hierarchies</li>
<li>Apply agent design patterns (tool-use loops, sub-agents, memory, context-window management) and frameworks such as Strands, LangGraph and PydanticAI</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Applications and Integration (33.1%)</h3>
<ul>
<li>Translate business requirements into functional and infrastructure requirements and manage the systems life cycle</li>
<li>Apply Claude API mechanics (messages, tools, streaming, vision, thinking, caching, batch API, realtime vs batch tradeoffs)</li>
<li>Apply software engineering foundations (REST APIs, JSON, async programming, version control, code review, refactoring)</li>
<li>Design Claude applications across interfaces (Claude Code, Desktop, claude.ai, API, SDKs) with sound schema design and session hygiene</li>
<li>Manage configuration with CLAUDE.md files, settings.json, model version pinning, prompt versioning and plugin dependencies</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Claude Code (3.1%)</h3>
<ul>
<li>Operate Claude Code core components (Rules, Skills, Commands, Agents, Agent Memory)</li>
<li>Use session management, built-in and custom slash commands, headless, streaming and auto modes</li>
<li>Apply the CLAUDE.md hierarchy, repository initialization and settings.json configuration</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Eval, Testing and Debugging (2.6%)</h3>
<ul>
<li>Debug and handle errors in Claude applications (error type identification, recovery strategy selection)</li>
<li>Use trace analysis to identify failure modes</li>
<li>Isolate problem origin between the integration layer and model output</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Model Selection and Optimization (16.8%)</h3>
<ul>
<li>Apply LLM fundamentals (tokens, context windows, sampling, non-determinism, next-token generation) and thinking modes (fast, extended, adaptive, effort levels)</li>
<li>Apply technical fundamentals of AI application development (SDKs wrapping REST APIs, websockets)</li>
<li>Select models by capability and tradeoffs (Opus vs Sonnet vs Haiku; quality, latency, cost; behavior changes across releases)</li>
<li>Manage cost and tokens (usage tracking, cost modeling, prompt caching, cache check-pointing)</li>
</ul>
<h3 class="course-topic-h3">Domain 6 Prompt and Context Engineering (11.0%)</h3>
<ul>
<li>Engineer context (context-window management, preventing context drift and bloat via tool-output pruning and compaction, context isolation through subagents)</li>
<li>Engineer prompts (instruction clarity, few-shot examples, system vs user placement, output constraints, iterative refinement, input sanitization)</li>
<li>Handle output with structured-output patterns, response validation, defensive parsing and skepticism toward confident output</li>
</ul>
<h3 class="course-topic-h3">Domain 7 Security and Safety (8.1%)</h3>
<ul>
<li>Apply AI application security (prompt-injection mitigation, jailbreak defense, untrusted-input handling, data-leakage and PII prevention, authentication, authorization, confidentiality and integrity)</li>
<li>Apply guardrails and secure-by-design deployment (content policy, guardrail layering, least privilege)</li>
<li>Leverage Claude hooks to prevent destructive actions</li>
<li>Manage identity, secrets and API keys across development and production environments</li>
</ul>
<h3 class="course-topic-h3">Domain 8 Tools and MCPs (10.6%)</h3>
<ul>
<li>Implement tools and function calling (tool description writing, error handling, agentic harness dispatch, client-side vs server-side tools, approval patterns)</li>
<li>Weigh tradeoffs across built-in tools, custom tools, Skills and MCPs</li>
<li>Develop MCP servers (server authoring, deployment, MCP resources, tools and prompts)</li>
<li>Apply MCP communication patterns (stdio, sockets, client vs server)</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Claude Certified Developer - Foundations Certification | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for the Claude Certified Developer - Foundations certification (CCDV-F). Master agents, Claude API integration, Claude Code, model selection, security and MCP tools in this 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Claude Certified Developer, Claude Certification, CCDV-F, Anthropic, Claude API, Claude Agent SDK, Claude Code, MCP, AI Certification, Exam Prep')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C439-20260711-175509.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'claude-certified-developer-foundations-certification') ON DUPLICATE KEY UPDATE value = VALUES(value);
