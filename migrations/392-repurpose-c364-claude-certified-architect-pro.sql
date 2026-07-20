-- Repurpose course C364 to "Claude Certified Architect - Professional
-- Certification" (Anthropic Claude cert prep, exam code CCAR-P). Course details
-- show the 7 exam domains from the exam guide; registration link points to the
-- Anthropic Partner Academy (Skilljar). NOT an AI Vibe Coding course (no badge).
-- Store scope 0. Idempotent. meta_description kept under varchar(255).
-- No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C364');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Claude Certified Architect - Professional Certification') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Prepare for and earn the Claude Certified Architect - Professional certification (exam code CCAR-P). This certification validates that you can design, build and deliver production-grade AI solutions using Anthropic Claude. It is intended for mid- to senior-level technical professionals &mdash; solution architects, AI/ML engineers, technical leads and senior software engineers &mdash; who select appropriate models, architectures and API patterns, apply prompt and context engineering, integrate Claude into enterprise systems, and incorporate evaluation, security, compliance and governance into their designs.</p>
<p>This 2-day course prepares you for all seven exam domains through hands-on solution design, model and prompt engineering, integration and RAG, evaluation and optimisation, governance and safety, stakeholder communication and developer productivity. The exam has 63 multiple-choice and multiple-response items, a 120-minute time limit and a passing scaled score of 720 (100-1,000). Register on the Anthropic Partner Academy: <a href="https://anthropic-partners.skilljar.com/claude-certified-architect-professional-certification" target="_blank">Claude Certified Architect - Professional</a>.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Domain 1 Solution Design and Architecture (17%)</h3>
<ul>
<li>Translate business problems into Claude-based AI solutions</li>
<li>Design end-to-end architectures (input, processing, output, feedback loops)</li>
<li>Select appropriate architectural patterns (workflow, agentic, augmented LLM)</li>
<li>Design multi-agent systems and orchestration strategies</li>
<li>Apply decomposition techniques and align solutions to business value pillars</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Claude Models, Prompting and Context Engineering (13%)</h3>
<ul>
<li>Select appropriate Claude models based on trade-offs</li>
<li>Design system prompts, templates and guardrails</li>
<li>Apply prompt engineering techniques (zero-shot, few-shot, chain-of-thought)</li>
<li>Optimise context windows, manage token usage and reuse prompts (caching, modular prompts, Skills)</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Integration (19%)</h3>
<ul>
<li>Design RAG pipelines with appropriate chunking, indexing and retrieval strategies</li>
<li>Evaluate connection protocols and select the integration mechanism (MCP, API/CLI, agent-to-agent)</li>
<li>Analyse authentication and authorisation requirements and identify security gaps</li>
<li>Evaluate accuracy-latency trade-offs, capability bloat and observability at scale</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Evaluation, Testing and Optimization (16%)</h3>
<ul>
<li>Define evaluation metrics (accuracy, latency, cost, safety, security)</li>
<li>Design evaluation datasets and test frameworks and run A/B testing</li>
<li>Diagnose system issues (prompt failure, hallucinations, model mismatch)</li>
<li>Optimise token usage, latency and cost-performance and monitor with observability tools</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Governance, Safety and Risk Management (14%)</h3>
<ul>
<li>Implement guardrails and safety controls</li>
<li>Identify risks, limitations and failure modes of LLM systems</li>
<li>Apply human-in-the-loop validation strategies</li>
<li>Ensure compliance with regulations (e.g., GDPR, HIPAA, FedRAMP) and address ethical AI considerations</li>
</ul>
<h3 class="course-topic-h3">Domain 6 Stakeholder Communication and Lifecycle Management (14%)</h3>
<ul>
<li>Conduct structured discovery and requirement gathering</li>
<li>Communicate architectural decisions and trade-offs</li>
<li>Manage stakeholder feedback loops and expectation alignment (including SLAs)</li>
<li>Document architectures and support lifecycle phases (discovery, design, handoff, monitoring, iteration)</li>
</ul>
<h3 class="course-topic-h3">Domain 7 Developer Productivity and Operational Enablement (7%)</h3>
<ul>
<li>Leverage Claude Code and developer tooling to accelerate delivery</li>
<li>Enable teams with Agent Skills, MCP servers and reusable configurations</li>
<li>Integrate Claude into CI/CD and operational workflows</li>
<li>Support onboarding, documentation and operational enablement</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Claude Certified Architect - Professional Certification | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for the Claude Certified Architect - Professional certification (CCAR-P). Master solution design, integration, RAG, evaluation, governance and lifecycle management in this 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Claude Certified Architect, Claude Certification, CCAR-P, Anthropic, Claude, Solution Architecture, RAG, Integration, AI Certification, Exam Prep')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C364-20260711-174059.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'claude-certified-architect-professional-certification') ON DUPLICATE KEY UPDATE value = VALUES(value);
