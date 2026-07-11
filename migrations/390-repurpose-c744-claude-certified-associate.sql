-- Repurpose course C744 to "Claude Certified Associate - Foundations
-- Certification" (Anthropic Claude cert prep). The course details show the 7
-- exam domains from the CCAO-F exam guide. Registration link points to the
-- Anthropic Partner Academy (Skilljar). NOT an AI Vibe Coding course (no badge).
-- Per-market price left unchanged. Store scope 0. Idempotent. No content line
-- ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C744');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Claude Certified Associate - Foundations Certification') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Prepare for and earn the Claude Certified Associate - Foundations certification (exam code CCAO-F). This certification validates that you can apply Claude to complete real-world business and productivity tasks with minimal guidance &mdash; using built-in platform features and tools to streamline workflows, identifying opportunities to improve processes with Claude, selecting approaches that balance quality, efficiency and cost, and recognising limitations and when to escalate. It is intended for professionals who use Claude as a productivity tool in roles such as operations, marketing, project management, education and communications.</p>
<p>This 2-day course prepares you for all seven exam domains through hands-on practice with Claude Projects, Artifacts, prompting, output evaluation, model selection, workflow integration, configuration, responsible use and troubleshooting. The exam has 60 multiple-choice and multiple-response items, a 120-minute time limit and a passing scaled score of 720 (100-1,000). Register for the exam on the Anthropic Partner Academy: <a href="https://anthropic-partners.skilljar.com/claude-certified-associate-foundations-certification" target="_blank">Claude Certified Associate - Foundations</a>.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Domain 1 Prompting and Task Execution (14%)</h3>
<ul>
<li>Create effective prompts for business and technical tasks</li>
<li>Apply task decomposition techniques to structure complex requests</li>
<li>Iterate prompts to improve output quality</li>
<li>Adapt prompting strategies based on task type (analysis, research, drafting, brainstorming)</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Output Evaluation and Validation (21%)</h3>
<ul>
<li>Evaluate Claude-generated outputs for accuracy and completeness</li>
<li>Identify hallucinations, inconsistencies and biases in responses</li>
<li>Apply fact-checking and validation techniques</li>
<li>Determine when human review or additional verification is required</li>
<li>Edit, adapt, refine and compare outputs for the intended audience</li>
<li>Organise and curate information and select appropriate output formats (artifacts, inline, structured data)</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Product and Model Selection (12%)</h3>
<ul>
<li>Select appropriate Claude product features (Projects, research mode, chat, artifacts)</li>
<li>Differentiate between Claude model types (Haiku, Sonnet, Opus)</li>
<li>Align model selection with task requirements (cost, speed, quality)</li>
<li>Understand and manage context limitations and memory considerations (when to restart, summarise or persist)</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Workflow Integration and Solution Design (16%)</h3>
<ul>
<li>Apply Claude to analyse requirements and use cases</li>
<li>Leverage Claude for research, planning and process optimisation</li>
<li>Use Claude to support solution design, development and iteration</li>
<li>Integrate Claude into existing workflows to augment or redesign them</li>
<li>Communicate Claude value and limitations to stakeholders</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Configuration and Knowledge Management (12%)</h3>
<ul>
<li>Configure Claude Projects with instructions and knowledge sources</li>
<li>Manage uploaded knowledge and connectors (e.g., Google Drive, Gmail)</li>
<li>Create effective system-level instructions</li>
<li>Inform, maintain and update Claude configurations, knowledge sources and instructions</li>
</ul>
<h3 class="course-topic-h3">Domain 6 Governance, Risk, and Responsible Use (15%)</h3>
<ul>
<li>Identify appropriate and inappropriate use cases</li>
<li>Apply data sensitivity, regulatory and privacy considerations</li>
<li>Follow organisational AI policies and governance standards</li>
<li>Understand the ethical implications of AI usage</li>
</ul>
<h3 class="course-topic-h3">Domain 7 Troubleshooting and Optimization (10%)</h3>
<ul>
<li>Identify, diagnose and resolve issues with underperforming prompts or poor outputs</li>
<li>Adjust approach based on feedback and results</li>
<li>Optimise workflows for efficiency and effectiveness</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Claude Certified Associate - Foundations Certification | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for the Claude Certified Associate - Foundations certification (CCAO-F). Master all 7 exam domains - prompting, output evaluation, model selection, workflow integration, configuration, governance and troubleshooting - in this 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Claude Certified Associate, Claude Certification, CCAO-F, Anthropic, Claude, AI Certification, Exam Prep, Prompting, Generative AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C744-20260711-171438.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'claude-certified-associate-foundations-certification') ON DUPLICATE KEY UPDATE value = VALUES(value);
