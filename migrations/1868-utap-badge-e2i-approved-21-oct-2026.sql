-- 1868: UTAP badge for the 16 courses e2i approved for UTAP on 21 Oct 2026 (valid 21 Oct 2026 -
-- 31 Mar 2027, e2i "Application for UTAP Funding for WSQ Courses - Change in Name" thread). 14 of
-- them lacked the UTAP tag; CompTIA Server+ (TGS-2024048318) and Linux+ (TGS-2024048316) already had
-- it. The 23 courses approved on 2 Oct 2026 were all already tagged.
--
-- The UTAP tag drives the storefront chip, the WSQ Funding card's UTAP section, the Course Info
-- "How to Apply UTAP" tab and the Edit Course > Funding and Grant UTAP checkbox, so one tag write
-- covers all of them. e2i lists courses under the title they were approved with; mapped to SKUs from
-- title history (499 cover snapshot of 2026-07-17 + rename migrations):
--   Pearson Vue Certified IT Specialist - Cloud Computing      -> TGS-2025056362 (now AI for Cloud Computing)
--   Driving Digital Transformation with M365 Copilot for Orgs  -> TGS-2024049182 (now Business Transformation with Agentic AI and AI Agents)
--   Native Android Apps Development with Java and Vibe Coding  -> TGS-2024048313 (now AI Vibe Coding for Android Apps Development)
--   Business Transformation with OpenClaw and NFT              -> TGS-2026064859 (now CASL - Autonomous AI Agents with OpenClaw)
--   AI Vibe Coding with Pytorch                                -> TGS-2026064720 (now CASL - AI Vibe Coding for Advanced Data Modeling)
--   the other nine titles match the current course name.
--
-- meta_description / meta_keyword gain UTAP per .claude/rules/seo-meta.md (same shape as 1856):
-- WSQ/IBF "SkillsFuture Credit and UTAP claimable.", CASL without the SFC badge "UTAP claimable.",
-- keywords + "UTAP claimable course". Peer-safe: a row is only replaced while it still holds the value
-- live on SG prod on 2026-10-26. Six descriptions had course text trimmed to stay <= 160 chars.
--
-- SG-only (store guard; TGS- SKUs do not exist on MY/GH either) -> no-op on partners. Idempotent.
-- Post-deploy: re-render the 14 covers (UTAP chip is baked into the PNG):
--   php scripts/maintenance/rerender-covers-for-badge.php --apply --badge=UTAP --sku=<the 14 SKUs>

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @utap := (SELECT tag_id FROM tag WHERE name = 'UTAP' LIMIT 1);
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description' AND backend_type = 'varchar');
SET @a_mkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword' AND backend_type = 'text');
SET @ok := (@sg = 1 AND @utap IS NOT NULL AND @a_mdesc IS NOT NULL AND @a_mkey IS NOT NULL);

DROP TABLE IF EXISTS mms_utap_1868_stage;

CREATE TABLE mms_utap_1868_stage (
  sku    VARCHAR(64) NOT NULL PRIMARY KEY,
  old_md VARCHAR(255) NOT NULL,
  md     VARCHAR(255) NOT NULL,
  old_mk TEXT NOT NULL,
  mk     TEXT NOT NULL
) DEFAULT CHARSET = utf8;

INSERT INTO mms_utap_1868_stage (sku, old_md, md, old_mk, mk) VALUES
('TGS-2020503501', 'Generative AI for SEO: AI keyword research, content strategy, SEO-optimised writing and on-page SEO. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'Generative AI for SEO: AI keyword research, content strategy, SEO writing and on-page SEO. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'generative AI SEO course, SEO training Singapore, AI keyword research, SEO content writing, on-page SEO, WSQ SEO course, SkillsFuture Credit course', 'generative AI SEO course, SEO training Singapore, AI keyword research, SEO content writing, on-page SEO, WSQ SEO course, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2024048313', 'AI vibe coding for Android: build native Java apps, design UIs, call APIs, test, publish to Google Play. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'AI vibe coding for Android: build native Java apps, design UIs and publish to Google Play. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'AI vibe coding Android course, Android app development training Singapore, Java for Android, Android Studio, Android UI design, Google Play deployment, WSQ course Singapore, SkillsFuture Credit course', 'AI vibe coding Android course, Android app development training Singapore, Java for Android, Android Studio, Android UI design, Google Play deployment, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2024048317', 'CompTIA A+ Core 1 and 2 prep: support Windows, install PC components and follow a troubleshooting method. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'CompTIA A+ Core 1 and 2 prep: support Windows, install PC components and troubleshoot faults. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'CompTIA A+ course, CompTIA A+ training Singapore, Core 1 and Core 2, PC components, Windows support, IT troubleshooting, WSQ course Singapore, SkillsFuture Credit course', 'CompTIA A+ course, CompTIA A+ training Singapore, Core 1 and Core 2, PC components, Windows support, IT troubleshooting, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2024049182', 'Agentic AI business transformation: find AI agent use cases, plan integration and set governance. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'Agentic AI business transformation: find AI agent use cases, plan integration and set governance. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'agentic AI business transformation course, AI agents training Singapore, AI agent use cases, workflow integration, AI governance, AI adoption, WSQ course Singapore, SkillsFuture Credit course', 'agentic AI business transformation course, AI agents training Singapore, AI agent use cases, workflow integration, AI governance, AI adoption, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2024051250', 'Use the DISC AsiaPlus model to read personality styles, adapt how you lead and work better in teams. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'Use the DISC AsiaPlus model to read personality styles, adapt how you lead and work in teams. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'DISC AsiaPlus course, DISC personality training Singapore, reading people, team collaboration, leadership styles, workplace behaviour profiling, WSQ course Singapore, SkillsFuture Credit course', 'DISC AsiaPlus course, DISC personality training Singapore, reading people, team collaboration, leadership styles, workplace behaviour profiling, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2024052081', 'Build and automate AI video and voice agents with n8n and agentic AI, with real-time interaction. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'Build and automate AI video and voice agents with n8n and agentic AI, with real-time interaction. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'n8n AI agents course, AI video and voice agents training Singapore, n8n automation, AI avatar, agentic AI workflows, interactive voice agents, WSQ course Singapore, SkillsFuture Credit course', 'n8n AI agents course, AI video and voice agents training Singapore, n8n automation, AI avatar, agentic AI workflows, interactive voice agents, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2025052468', 'Build agentic AI apps with Claude Code using context engineering, MCP tools, RAG and sub agents. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'Build agentic AI apps with Claude Code using context engineering, MCP tools, RAG and sub agents. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'Claude Code course, agentic AI training Singapore, context engineering, MCP tools, RAG, Claude sub agents, WSQ Claude Code course, SkillsFuture Credit course', 'Claude Code course, agentic AI training Singapore, context engineering, MCP tools, RAG, Claude sub agents, WSQ Claude Code course, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2025052659', 'Python for finance with AI assistance: data types, control flow and functions for finance use cases. Up to 70% IBF funding; SkillsFuture Credit claimable.', 'Python for finance with AI assistance: data types, control flow and functions for finance tasks. Up to 70% IBF funding; SkillsFuture Credit and UTAP claimable.', 'Python for finance course, Python programming training Singapore, AI assisted coding, financial data analysis, Python functions, IBF Python for finance course, SkillsFuture Credit course', 'Python for finance course, Python programming training Singapore, AI assisted coding, financial data analysis, Python functions, IBF Python for finance course, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2025052674', 'AI vibe coding for game development: prototype gameplay with AI assistants, then test and deploy. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'AI vibe coding for game development: prototype gameplay with AI assistants, then test and deploy. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'AI vibe coding game development course, game development training Singapore, AI coding assistants, gameplay systems, game testing, game deployment, WSQ course Singapore, SkillsFuture Credit course', 'AI vibe coding game development course, game development training Singapore, AI coding assistants, gameplay systems, game testing, game deployment, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2025056362', 'AI for cloud computing: set up cloud services, deploy and test databases, troubleshoot and secure. Up to 70% WSQ funding; SkillsFuture Credit claimable.', 'AI for cloud computing: set up cloud services, deploy databases, troubleshoot and secure them. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.', 'AI for cloud computing course, cloud computing training Singapore, cloud deployment, cloud troubleshooting, cloud security, database testing, WSQ course Singapore, SkillsFuture Credit course', 'AI for cloud computing course, cloud computing training Singapore, cloud deployment, cloud troubleshooting, cloud security, database testing, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course'),
('TGS-2026064176', 'Build AI agents with the Hermes Agent framework: tools, memory, multi-agent workflows and secure deployment. Up to 70% CASL funding; SFEC claimable.', 'Build AI agents with the Hermes Agent framework: tools, memory, multi-agent workflows and secure deployment. Up to 70% CASL funding; UTAP claimable.', 'Hermes Agent course, Hermes Agent training Singapore, AI agents, agentic AI, multi-agent workflows, AI agent deployment, CASL course', 'Hermes Agent course, Hermes Agent training Singapore, AI agents, agentic AI, multi-agent workflows, AI agent deployment, CASL course, UTAP claimable course'),
('TGS-2026064534', 'Build a full stack React web app with vibe coding: React hooks, routing, API integration and cloud deployment. Up to 70% CASL funding; SFEC claimable.', 'Build a full stack React web app with vibe coding: React hooks, routing, API integration and cloud deployment. Up to 70% CASL funding; UTAP claimable.', 'React vibe coding course, React web app training Singapore, full stack React, React hooks, React Router, API integration, CASL course', 'React vibe coding course, React web app training Singapore, full stack React, React hooks, React Router, API integration, CASL course, UTAP claimable course'),
('TGS-2026064720', 'AI vibe coding for advanced data modelling: build neural networks, CNNs and transformer models. Up to 70% CASL funding; SFEC claimable.', 'AI vibe coding for advanced data modelling: build neural networks, CNNs and transformer models. Up to 70% CASL funding; UTAP claimable.', 'AI vibe coding data modelling course, data modelling training Singapore, deep learning, neural networks, convolutional neural network, transformer, CASL course', 'AI vibe coding data modelling course, data modelling training Singapore, deep learning, neural networks, convolutional neural network, transformer, CASL course, UTAP claimable course'),
('TGS-2026064859', 'Build autonomous AI agents with OpenClaw: assess business use cases, design agent workflows and manage risks. Up to 70% CASL funding; SFEC claimable.', 'Build autonomous AI agents with OpenClaw: assess business use cases, design agent workflows and manage risks. Up to 70% CASL funding; UTAP claimable.', 'OpenClaw AI agents course, autonomous AI agents training Singapore, OpenClaw, agent workflows, AI agent use cases, AI risk management, CASL course', 'OpenClaw AI agents course, autonomous AI agents training Singapore, OpenClaw, agent workflows, AI agent use cases, AI risk management, CASL course, UTAP claimable course');

-- UTAP tag on the SG store, if missing
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT @utap, NULL, e.entity_id, 1, 1, NOW()
  FROM catalog_product_entity e
  JOIN mms_utap_1868_stage s ON s.sku = TRIM(e.sku)
 WHERE @ok
   AND NOT EXISTS (SELECT 1 FROM tag_relation r
                    WHERE r.tag_id = @utap AND r.product_id = e.entity_id
                      AND r.store_id = 1 AND r.customer_id IS NULL);

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id
  JOIN mms_utap_1868_stage s ON s.sku = TRIM(e.sku)
   SET v.value = s.md
 WHERE @ok AND v.attribute_id = @a_mdesc AND v.store_id = 0 AND v.value = s.old_md;

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
  JOIN mms_utap_1868_stage s ON s.sku = TRIM(e.sku)
   SET t.value = s.mk
 WHERE @ok AND t.attribute_id = @a_mkey AND t.store_id = 0 AND t.value = s.old_mk;

DROP TABLE IF EXISTS mms_utap_1868_stage;

-- Rebuild tag_summary for UTAP (per-store rows + store 0 roll-up), as in 655
DELETE FROM tag_summary WHERE @ok AND tag_id = @utap;

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT r.tag_id, r.store_id, 0, COUNT(DISTINCT r.product_id), 0, 0, 0, 0
  FROM tag_relation r
 WHERE @ok AND r.tag_id = @utap
 GROUP BY r.tag_id, r.store_id;

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT r.tag_id, 0, 0, COUNT(DISTINCT r.product_id), 0, 0, 0, 0
  FROM tag_relation r
 WHERE @ok AND r.tag_id = @utap
 GROUP BY r.tag_id;
