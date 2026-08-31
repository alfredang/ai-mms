-- 1294: Rename two WSQ AI Courses children, re-slug BOTH to match their new
-- titles, 301 the old URLs, and set the requested sibling order.
--
-- RENAME 1  (284)  WSQ AI Ethics and Governance  -> WSQ AI Security Courses
--   url_key  wsq-ai-ethics-and-governance-courses -> wsq-ai-security-courses
-- RENAME 2  (425)  WSQ Programming & Vibe Coding -> WSQ AI Vibe Coding Courses
--   url_key  wsq-programming-vibe-coding-courses-tertiary-courses-singapore
--            -> wsq-ai-vibe-coding-courses
--
-- The re-slug is the owner's explicit follow-up instruction: "update the url
-- for all the reactivated catalog pages to align to the catalog title". Both
-- old slugs are live and indexed, so each gets a 301 (options='RP') at store 0
-- AND store 1 — a rename is not finished until the old URL 301s to the new one.
-- is_system=0 marks them manual so the catalog_url reindex is less likely to
-- clobber them. Written with ON DUPLICATE KEY UPDATE, not INSERT IGNORE:
-- IGNORE would silently no-op over an existing 302 row and leave the redirect
-- temporary, transferring no ranking.
--
-- ORDER under WSQ AI Courses (325) after this migration + 1295 + 1296:
--   1 WSQ Generative AI Courses      (379)
--   2 WSQ Agentic AI Courses         (196)
--   3 WSQ AI Agents Courses          (194)  <- moved up, was 5
--   4 WSQ Multi AI Agents Courses    (234)  <- new, added by 1295
--   5 WSQ AI Applications Courses    (383)  <- new, added by 1296
--   6 WSQ AI Vibe Coding Courses     (425)
--   7 WSQ AI Security Courses        (284)
-- "Place the WSQ AI Agent Courses after the WSQ Agentic AI Courses", then Multi
-- AI Agents after AI Agents, then AI Applications after Multi AI Agents. The two
-- renamed categories keep their relative order and fall in behind the new block.
-- All positions are written explicitly so siblings stay DISTINCT — duplicates
-- make the sort non-deterministic and the mega-menu flyout render unreliably.
--
-- Business-key lookups only. Idempotent (resolves each category by its old slug
-- first, then by its new slug so a re-run still enforces the final state).

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

SET @c_sec := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-ethics-and-governance-courses' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-security-courses' LIMIT 1));

SET @c_vibe := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk
     AND value='wsq-programming-vibe-coding-courses-tertiary-courses-singapore' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-vibe-coding-courses' LIMIT 1));

-- ------------------------------------------------------- 301 the old slugs
-- Captured BEFORE the url_key is overwritten.
-- Delete the old self-rewrites FIRST. core_url_rewrite is UNIQUE on
-- (request_path, store_id); if the old rows are still present when the 301s are
-- inserted, ON DUPLICATE KEY UPDATE rewrites those rows in place and a later
-- delete by the old id_path removes the 301 with them, leaving the old URL
-- 404ing at store 1.
DELETE FROM core_url_rewrite
WHERE id_path IN (CONCAT('category/', @c_sec), CONCAT('category/', @c_vibe))
  AND @c_sec IS NOT NULL AND @c_vibe IS NOT NULL;

INSERT INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('category/', @c_sec, '-301'),
       'wsq-ai-ethics-and-governance-courses.html',
       'wsq-ai-security-courses.html',
       0, 'RP', 'WSQ AI Ethics and Governance -> WSQ AI Security Courses'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @c_sec IS NOT NULL
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path),
                        options     = VALUES(options),
                        is_system   = VALUES(is_system);

INSERT INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('category/', @c_vibe, '-301'),
       'wsq-programming-vibe-coding-courses-tertiary-courses-singapore.html',
       'wsq-ai-vibe-coding-courses.html',
       0, 'RP', 'WSQ Programming & Vibe Coding -> WSQ AI Vibe Coding Courses'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @c_vibe IS NOT NULL
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path),
                        options     = VALUES(options),
                        is_system   = VALUES(is_system);

-- ------------------------------------------------------------- rename 284
DELETE v FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3
WHERE v.entity_id=@c_sec AND @c_sec IS NOT NULL AND v.store_id<>0
  AND a.attribute_code IN ('name','url_key','url_path','meta_title');

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @c_sec, t.val FROM (
  SELECT 'name'       AS code, 'WSQ AI Security Courses' AS val UNION ALL
  SELECT 'url_key',   'wsq-ai-security-courses'          UNION ALL
  SELECT 'url_path',  'wsq-ai-security-courses.html'     UNION ALL
  SELECT 'meta_title','WSQ AI Security Courses - Secure AI Systems and Agents | Tertiary Courses Singapore'
) t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
WHERE @c_sec IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_category_entity_text t
JOIN eav_attribute a ON a.attribute_id=t.attribute_id AND a.entity_type_id=3
WHERE t.entity_id=@c_sec AND @c_sec IS NOT NULL AND t.store_id<>0
  AND a.attribute_code IN ('description','meta_description','meta_keywords');

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @c_sec, t.val FROM (
  SELECT 'description' AS code, CONCAT(
'<p>As organisations put AI into production, the security question shifts from "can we build it" to "can we trust it". AI systems introduce attack surfaces traditional security controls were never designed for: prompt injection, model and data poisoning, jailbreaks, sensitive-data leakage through model outputs, and autonomous agents that hold real credentials and can act on live systems without a human in the loop.</p>',
'<p>Our WSQ AI Security Courses cover both halves of the problem — using AI to strengthen security, and securing AI itself. On the defensive side, courses apply AI and machine learning to cyber security and network security operations: anomaly and intrusion detection, threat triage and automated response. On the securing-AI side, courses address AI security governance, agent cybersecurity, and security operations for autonomous agents, including tool-permission control, sandboxing, monitoring agent behaviour in production and containing an agent that misbehaves.</p>',
'<p>Governance and responsible-AI practice complete the coverage. Courses on AI ethics, responsible AI and AI security governance address bias, transparency, explainability, accountability and the policies an organisation needs before deploying AI at scale — the groundwork for meeting regulatory expectations and Singapore''s Model AI Governance Framework.</p>',
'<h3>What you will learn</h3><ul>',
'<li>Applying AI and machine learning to cyber security and network security operations</li>',
'<li>AI-specific threats: prompt injection, jailbreaks, data and model poisoning, output leakage</li>',
'<li>Securing autonomous AI agents - permissions, sandboxing, monitoring and containment</li>',
'<li>Running security operations for agentic systems, including detection and incident response</li>',
'<li>AI security governance, responsible AI, bias, transparency and accountability</li>',
'<li>Building AI security awareness across technical and non-technical teams</li></ul>',
'<h3>Who should attend</h3>',
'<p>Security analysts and engineers, SOC and network teams, IT and cloud administrators, AI and data engineers deploying models into production, risk and compliance officers, and leaders accountable for AI governance.</p>',
'<h3>Funding</h3>',
'<p>These are WSQ, CASL and IBF funded courses. Eligible Singaporeans and PRs can enjoy SkillsFuture funding subsidies, and SkillsFuture Credit may be used to offset the nett course fee. Company-sponsored participants may also be eligible for SkillsFuture Enterprise Credit (SFEC) and absentee payroll. Please refer to each course page for the funding schemes that apply.</p>') AS val
  UNION ALL
  SELECT 'meta_description',
'WSQ AI Security Courses in Singapore. Learn AI for cyber and network security, AI agent cybersecurity, security operations for autonomous agents, and AI security governance. SkillsFuture funded.'
  UNION ALL
  SELECT 'meta_keywords',
'WSQ AI security course Singapore, AI cyber security training, AI for network security, AI agent cybersecurity, security operations autonomous AI agents, AI security governance, responsible AI, AI ethics course, prompt injection, model poisoning, AI security awareness, SkillsFuture AI security, WSQ funded AI training, CASL AI security, AI risk and compliance'
) t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
WHERE @c_sec IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------- rename 425
DELETE v FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3
WHERE v.entity_id=@c_vibe AND @c_vibe IS NOT NULL AND v.store_id<>0
  AND a.attribute_code IN ('name','url_key','url_path','meta_title');

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @c_vibe, t.val FROM (
  SELECT 'name'       AS code, 'WSQ AI Vibe Coding Courses' AS val UNION ALL
  SELECT 'url_key',   'wsq-ai-vibe-coding-courses'          UNION ALL
  SELECT 'url_path',  'wsq-ai-vibe-coding-courses.html'     UNION ALL
  SELECT 'meta_title','WSQ AI Vibe Coding Courses - Build Apps with AI Assisted Coding | Tertiary Courses Singapore'
) t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
WHERE @c_vibe IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_category_entity_text t
JOIN eav_attribute a ON a.attribute_id=t.attribute_id AND a.entity_type_id=3
WHERE t.entity_id=@c_vibe AND @c_vibe IS NOT NULL AND t.store_id<>0
  AND a.attribute_code IN ('description','meta_description','meta_keywords');

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @c_vibe, t.val FROM (
  SELECT 'description' AS code, CONCAT(
'<p>Vibe coding is the practice of building working software by directing an AI coding assistant in natural language — describing the outcome, reviewing what the AI produces, then steering, testing and refining it. It has moved software development from typing every line to specifying, reviewing and iterating, and it lets developers ship far faster while opening real application development to people who are not full-time programmers.</p>',
'<p>Our WSQ AI Vibe Coding Courses teach this discipline across the languages and platforms professionals actually deliver on. Web and full-stack tracks cover professional web apps, React full-stack builds, ASP.NET, RESTful APIs and eCommerce stores. Mobile tracks cover iOS and Android. Data and AI tracks cover Python, SQL, data analytics, data mining and modeling, deep learning, PyTorch and image generation. Specialist tracks cover game development, UI/UX, blockchain and Web3, C#, and multi-agent systems.</p>',
'<p>Every course is hands-on and outcome-based: participants finish having built and run something real. Just as important, the courses teach the judgement that separates productive vibe coding from generated code nobody can maintain — how to specify precisely, review and test AI output, catch subtle defects and security issues, and keep architecture sound as the codebase grows.</p>',
'<h3>What you will learn</h3><ul>',
'<li>Directing AI coding assistants effectively - prompting, specifying, iterating and reviewing</li>',
'<li>Building full-stack web applications, RESTful APIs and eCommerce stores with AI assistance</li>',
'<li>Developing iOS and Android mobile apps through AI-assisted workflows</li>',
'<li>Applying vibe coding to Python, SQL, data analytics, data mining, deep learning and PyTorch</li>',
'<li>Specialist builds: game development, UI/UX, blockchain and Web3, C#, and multi-agent systems</li>',
'<li>Reviewing, testing and securing AI-generated code so what you ship stays maintainable</li></ul>',
'<h3>Who should attend</h3>',
'<p>Software developers and engineers who want to ship faster, data analysts and scientists who code as part of their work, technical product managers and designers building prototypes, IT professionals automating tasks, and career switchers who want to build real applications. Courses range from beginner-friendly to advanced.</p>',
'<h3>Funding</h3>',
'<p>These are WSQ, CASL and IBF funded courses. Eligible Singaporeans and PRs can enjoy SkillsFuture funding subsidies, and SkillsFuture Credit may be used to offset the nett course fee. Company-sponsored participants may also be eligible for SkillsFuture Enterprise Credit (SFEC) and absentee payroll. Please refer to each course page for the funding schemes that apply.</p>') AS val
  UNION ALL
  SELECT 'meta_description',
'WSQ AI Vibe Coding Courses in Singapore. Build web, mobile, full-stack, data and game applications with AI-assisted coding in Python, SQL, React, C# and more. SkillsFuture funded, up to 70% subsidy.'
  UNION ALL
  SELECT 'meta_keywords',
'WSQ AI vibe coding course Singapore, vibe coding training, AI assisted programming, AI assisted coding, build web app with AI, AI coding assistant course, vibe coding Python, vibe coding SQL, full stack vibe coding, React vibe coding, iOS app vibe coding, Android app vibe coding, AI vibe coding for data analytics, SkillsFuture vibe coding, WSQ funded coding course, CASL vibe coding'
) t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
WHERE @c_vibe IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
