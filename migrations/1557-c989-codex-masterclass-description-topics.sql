-- 1557: C989 Codex Masterclass — description, topics and meta from the converted
-- one-day courseware (twin of WSQ TGS-2023041081, Topics 1-3 / Labs 2-11).
-- Idempotent, keyed by SKU; a site without C989 is a no-op.
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C989' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_meta := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_sess := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_dur := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Master Codex, the agentic coding surface in the ChatGPT desktop app, in one hands-on masterclass. Codex plans, writes, runs and checks code on its own inside your project while you review and guide the work. Instead of coding every step yourself, you describe the goal, approve the plan and evaluate the result against evidence.</p><p>Working as the AI-assisted developer behind a fictitious cooking school, participants take one business from a written brief to a live website: Codex plans the site with /plan, builds it from the course catalogue, adds durable rules in AGENTS.md and a sign-up form for every course, and publishes it to GitHub Pages. They then turn the course brochures into a SQLite knowledge base behind a retrieval-augmented (RAG) course assistant, drive it to 30/30 golden questions with /goal, add a ChatGPT mode and red-team it, and QA the whole site with Computer Use.</p><p>The masterclass closes with the features that make an agent dependable: community skills from skills.sh, custom skills created with the skill creator, a timed workshop popup and a hook that re-checks the site after every edit. Emphasis is placed on planning before editing, permission control, keeping secrets out of static sites, evaluation against evidence and human review, so participants leave able to use Codex to build, test and govern real applications.</p>'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1 Fundamentals: Chat, Work and Codex</h3>
<ul>
<li>The evolution of AI engineering, harness engineering and the agent loop</li>
<li>OpenAI products and the GPT-6 models; the ChatGPT desktop app and plugins</li>
<li>Projects, folders and permissions; the 7-step Codex workflow and /plan</li>
<li>Context engineering with AGENTS.md; a sign-up form with no backend</li>
<li>Publishing to GitHub Pages and Sites</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Tools and the SQLite RAG Assistant</h3>
<ul>
<li>Codex slash commands and working with /goal</li>
<li>Retrieval-augmented generation from your own documents</li>
<li>A SQLite FTS5 knowledge base that runs in the browser</li>
<li>Measuring before trusting: golden-question evaluation</li>
<li>Search mode vs ChatGPT mode; keys and static sites; red-teaming</li>
<li>QA of the whole site with the Computer Use tool</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Skills and Hooks</h3>
<ul>
<li>What an agent skill is; where skills live; SKILL.md vs AGENTS.md</li>
<li>Installing community skills from skills.sh</li>
<li>Creating custom Codex skills with the skill creator</li>
<li>Hooks: code that always runs; timer, event or schedule</li>
<li>A workshop popup and a hook that checks every edit</li>
</ul>'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_meta, 0, @pid, 'Master OpenAI Codex in this hands-on Codex Masterclass: plan and build a website with /plan and AGENTS.md, add a SQLite RAG course assistant, QA it with Computer Use, and govern it with skills and hooks at Tertiary Courses Singapore.'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '1' FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '7.5' FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- drop any store-scope overrides so the store-0 copy is what every scope serves
DELETE FROM catalog_product_entity_text WHERE entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0 AND @pid IS NOT NULL;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @pid AND attribute_id IN (@a_meta, @a_sess, @a_dur) AND store_id <> 0 AND @pid IS NOT NULL;
