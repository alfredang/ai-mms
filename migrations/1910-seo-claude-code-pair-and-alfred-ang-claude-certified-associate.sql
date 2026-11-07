-- 1910: SEO for the Claude Code pair + Dr. Alfred Ang's Claude Certified Associate credential (owner request 2026-11-07).
--
--   (1) Target keywords "Agentic AI Training in Singapore", "Claude Code Training in Singapore" and
--       "Claude Code for Beginners" on TGS-2025052468 "WSQ - Agentic AI Applications with Claude Code"
--       (entity 1118) and its non-WSQ twin C1417 "Claude Code Masterclass" (entity 1417; its Funding block
--       links to the WSQ page). Per .claude/rules/seo-meta.md:
--         * meta_title: WSQ stored as the full rendered title; C1417 stored bare.
--         * meta_description 130-160 chars; WSQ ends with its badge funding line; C1417 has no funding words.
--         * meta_keyword (TEXT table): the three target phrases first.
--         * short_description (About): keyword-led, bolded once each, rewritten from each course's own syllabus;
--           pages cross-link; the mig 1880 "AI training in Singapore" line is kept verbatim.
--       "Beginners" is grounded: C1417's Prerequisite card says "This course is for beginners. No prerequisite
--       is required."; the WSQ entry requirement is computer literacy, not programming.
--   (2) Dr. Alfred Ang holds Anthropic's Claude Certified Associate - Foundations certification (badge supplied
--       by the owner). Every live Claude course shows a per-course <strong data-course-bio> bio, which overrides
--       the shared courses_trainers profile, so the sentence goes into each of the 14 course bios (after the
--       first sentence) AND into the shared profile (courses_trainers 1 + duplicate 799) for every other page.
--       C154 (disabled) uses a plain <strong> name, so the shared profile covers it.
--
--   PROBED on SG prod 2026-11-07: no store-view overrides or wrong-table orphans for these meta attributes.
--   Peer-safe: metas only replace the exact probed value; About only replaces the probed MD5; bios insert at a
--   unique anchor and skip any row that already mentions the certification. SG-only -> no-op on MY/GH. Idempotent.
--   Post-deploy: Redis/FPC flush, then curl the rendered <title>/<meta> and the Trainers tab.

SET NAMES utf8mb4;
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @w0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025052468' LIMIT 1);
SET @c0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1417' LIMIT 1);
SET @w  := IF(@sg = 1, @w0, NULL);
SET @c  := IF(@sg = 1, @c0, NULL);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'        AND entity_type_id=@et AND backend_type='varchar');
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description'  AND entity_type_id=@et AND backend_type='varchar');
SET @a_kw := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et AND backend_type='text');
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'    AND entity_type_id=@et AND backend_type='text');

-- ---------------------------------------------------------------- WSQ TGS-2025052468
UPDATE catalog_product_entity_varchar SET value = 'Funded up to 70% WSQ Agentic AI and Claude Code Training in Singapore | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Funded up to 70% WSQ Agentic AI Applications with Claude Code Course | Tertiary Courses Singapore';
UPDATE catalog_product_entity_varchar SET value = 'Claude Code training in Singapore: build agentic AI apps with MCP, RAG and sub-agents. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.'
 WHERE attribute_id = @a_md AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Build agentic AI apps with Claude Code using context engineering, MCP tools, RAG and sub agents. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.';
UPDATE catalog_product_entity_text SET value = 'agentic AI training in Singapore, Claude Code training in Singapore, Claude Code for beginners, Claude Code course, WSQ Claude Code course, Claude Code MCP and RAG, SkillsFuture Credit course, UTAP claimable course'
 WHERE attribute_id = @a_kw AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Claude Code course, agentic AI training Singapore, context engineering, MCP tools, RAG, Claude sub agents, WSQ Claude Code course, SkillsFuture Credit course, UTAP claimable course';
UPDATE catalog_product_entity_text SET value = '<p><strong>Agentic AI training in Singapore</strong>, built on <strong>Claude Code</strong>, Anthropic''s AI coding tool for the terminal and IDE. You build agentic AI applications that remember your project rules, call external tools through MCP, retrieve knowledge with RAG and hand work to sub-agents.</p>
<p><strong>Claude Code for beginners</strong> is where Topic 1 starts. You initialise Claude Code, work through its operation modes, vibe code your first app, then use context engineering and memory management so Claude Code knows your requirements, standards and domain knowledge every session. The entry requirement is basic computer literacy, not programming experience.</p>
<p>Topic 2 gives Claude Code reach. You write <strong>custom slash commands</strong> for jobs you repeat, and connect external systems, APIs, databases and development tools through the <strong>Model Context Protocol (MCP)</strong>.</p>
<p>Topic 3 turns one assistant into a working team. You build <strong>RAG</strong> pipelines and reusable <strong>skills</strong>, delegate tasks to <strong>sub-agents</strong>, and use <strong>hooks</strong> to automate and control agentic workflows. Then you test what you built: when retrieval misses, memory goes stale, a tool call fails or an agent stalls, you find the cause and report it.</p>
<p>This is <strong>Claude Code training in Singapore</strong> with WSQ funding of up to 70%. Want a non-funded course on everyday coding with an agent? Try the <a href="/claude-code-masterclass.html">Claude Code Masterclass</a>.</p>
<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/claude-ai-series.html">Claude training</a>.</p>'
 WHERE attribute_id = @a_sd AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND MD5(value) = '81ecaab4386ad14a3cf4f350a2847cf9';
-- ---------------------------------------------------------------- non-WSQ C1417
UPDATE catalog_product_entity_varchar SET value = 'Claude Code for Beginners: Claude Code Masterclass'
 WHERE attribute_id = @a_mt AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'Claude Code Masterclass';
UPDATE catalog_product_entity_varchar SET value = 'Claude Code for beginners: install it, build and test features, add hooks, skills and MCP, ship a project. Claude Code training in Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'Claude Code masterclass on agentic coding in the terminal and IDE: run multi-step dev workflows, extend Claude Code with hooks, skills and MCP, ship projects.';
UPDATE catalog_product_entity_text SET value = 'Claude Code for beginners, Claude Code training in Singapore, agentic AI training in Singapore, Claude Code course, Claude Code masterclass, Claude Code hooks and skills, MCP servers'
 WHERE attribute_id = @a_kw AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'Claude Code course, Claude Code training Singapore, agentic coding, Claude Code hooks, MCP servers, AI-assisted software development';
UPDATE catalog_product_entity_text SET value = '<p><strong>Claude Code for beginners</strong>, taught hands-on: you go from installing Claude Code to shipping a tested project with it. <strong>Claude Code</strong> is Anthropic''s AI coding tool for the terminal and IDE. It navigates your codebase, edits files, runs commands and tests, and works through multi-step tasks from plain-English instructions while you review and steer. No prerequisite is required, and developers, engineers, data professionals and technical leads who want to build, refactor and maintain software faster get as much from it as first-timers.</p>
<p>Topic 1 gets you running: install Claude Code, see how it reads and edits your project, set permissions, and write instructions and project memory files such as CLAUDE.md. Topic 2 covers <strong>agentic coding</strong> workflows: plan before you code, explore an unfamiliar codebase, implement features, fix bugs, write tests, refactor, and work with Git and pull requests. Topic 3 extends Claude Code with hooks, skills and <strong>MCP servers</strong> to automate checks, package repeatable expertise and connect external tools and data.</p>
<p>Topic 4 is a real project, taken from requirements to a tested, deployed result, with subagents and headless automation for the larger jobs. Throughout, you review AI-generated code critically, keep humans in control and protect your secrets.</p>
<p>This is <strong>Claude Code training in Singapore</strong> for anyone who wants to write software with an AI agent. For <strong>agentic AI training in Singapore</strong> that goes further into RAG, sub-agents and MCP integrations, see <a href="/wsq-agentic-ai-applications-with-claude-code.html">Agentic AI Applications with Claude Code</a>.</p>
<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/claude-ai-series.html">Claude training</a>.</p>'
 WHERE attribute_id = @a_sd AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND MD5(value) = '468461a5102d851e2fe5e96ed9f42e4c';
-- ---------------------------------------------------------------- Dr. Alfred Ang: per-course Claude bios
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('services, and today he builds the AI systems that automate that work. ', value) + CHAR_LENGTH('services, and today he builds the AI systems that automate that work. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 3844 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C141' LIMIT 1)
   AND LOCATE('services, and today he builds the AI systems that automate that work. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('uctivity and data platform, in which he holds several certifications. ', value) + CHAR_LENGTH('uctivity and data platform, in which he holds several certifications. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 6059 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C197' LIMIT 1)
   AND LOCATE('uctivity and data platform, in which he holds several certifications. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('ds-on design partner and as the engine inside the products he builds. ', value) + CHAR_LENGTH('ds-on design partner and as the engine inside the products he builds. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 6128 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C201' LIMIT 1)
   AND LOCATE('ds-on design partner and as the engine inside the products he builds. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('e the Claude Certified Architect - Foundations exam sets out to test. ', value) + CHAR_LENGTH('e the Claude Certified Architect - Foundations exam sets out to test. '), 0, 'He already holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 16303 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C437' LIMIT 1)
   AND LOCATE('e the Claude Certified Architect - Foundations exam sets out to test. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE(' the Claude Certified Architect - Professional exam sets out to test. ', value) + CHAR_LENGTH(' the Claude Certified Architect - Professional exam sets out to test. '), 0, 'He already holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 46143 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C740' LIMIT 1)
   AND LOCATE(' the Claude Certified Architect - Professional exam sets out to test. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('he web, iOS and Android, and Claude is central to how he builds them. ', value) + CHAR_LENGTH('he web, iOS and Android, and Claude is central to how he builds them. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 46268 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C744' LIMIT 1)
   AND LOCATE('he web, iOS and Android, and Claude is central to how he builds them. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('who already packages his own working methods into reusable AI skills. ', value) + CHAR_LENGTH('who already packages his own working methods into reusable AI skills. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 47268 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023018659' LIMIT 1)
   AND LOCATE('who already packages his own working methods into reusable AI skills. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('e the Claude Certified Associate - Foundations exam sets out to test. ', value) + CHAR_LENGTH('e the Claude Certified Associate - Foundations exam sets out to test. '), 0, 'He holds the Claude Certified Associate - Foundations certification himself, so he teaches this exam as someone who has passed it. ')
 WHERE @sg = 1 AND value_id = 70800 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C991' LIMIT 1)
   AND LOCATE('e the Claude Certified Associate - Foundations exam sets out to test. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('nds-on engineering of the automation that now drives email campaigns. ', value) + CHAR_LENGTH('nds-on engineering of the automation that now drives email campaigns. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 72952 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020503109' LIMIT 1)
   AND LOCATE('nds-on engineering of the automation that now drives email campaigns. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('k the Claude Certified Developer - Foundations exam sets out to test. ', value) + CHAR_LENGTH('k the Claude Certified Developer - Foundations exam sets out to test. '), 0, 'He already holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 82912 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1098' LIMIT 1)
   AND LOCATE('k the Claude Certified Developer - Foundations exam sets out to test. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE(' engineering work, and his public work shows how far he has taken it. ', value) + CHAR_LENGTH(' engineering work, and his public work shows how far he has taken it. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 86399 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025052468' LIMIT 1)
   AND LOCATE(' engineering work, and his public work shows how far he has taken it. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('27;s Claude sits at the centre of much of what Dr. Alfred Ang builds. ', value) + CHAR_LENGTH('27;s Claude sits at the centre of much of what Dr. Alfred Ang builds. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 124690 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1382' LIMIT 1)
   AND LOCATE('27;s Claude sits at the centre of much of what Dr. Alfred Ang builds. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('tware, which is exactly the perspective this masterclass is built on. ', value) + CHAR_LENGTH('tware, which is exactly the perspective this masterclass is built on. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 127364 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1417' LIMIT 1)
   AND LOCATE('tware, which is exactly the perspective this masterclass is built on. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
UPDATE catalog_product_entity_text SET value = INSERT(value, LOCATE('es taught in this course reflect decisions he makes in real projects. ', value) + CHAR_LENGTH('es taught in this course reflect decisions he makes in real projects. '), 0, 'He holds Anthropic&#x27;s Claude Certified Associate - Foundations certification. ')
 WHERE @sg = 1 AND value_id = 202728 AND attribute_id = @a_tp AND store_id = 0
   AND entity_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026061312' LIMIT 1)
   AND LOCATE('es taught in this course reflect decisions he makes in real projects. ', value) > 0 AND value NOT LIKE '%Foundations certification%';
-- ---------------------------------------------------------------- Dr. Alfred Ang: shared Trainer Profile
SET @ct_ok := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'courses_trainers');
SET @sql := IF(@sg = 1 AND @ct_ok = 1, 'UPDATE courses_trainers SET description = INSERT(description, LOCATE(''alongside enterprise-grade cloud and data platforms. '', description) + CHAR_LENGTH(''alongside enterprise-grade cloud and data platforms. ''), 0, ''He holds Anthropic''''s Claude Certified Associate - Foundations certification. ''), update_time = NOW() WHERE trainers_id IN (1, 799) AND title = ''Alfred Ang'' AND email = ''angch@tertiaryinfotech.com'' AND LOCATE(''alongside enterprise-grade cloud and data platforms. '', description) > 0 AND description NOT LIKE ''%Foundations certification%''', 'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
