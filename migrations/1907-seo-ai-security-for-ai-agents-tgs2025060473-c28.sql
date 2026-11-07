-- 1907: SEO + course copy for the "AI Security for AI Agents" pair (owner request 2026-11-07).
--   TGS-2025060473 "WSQ - AI Security for Autonomous AI Agents" (entity 1884) and its non-WSQ twin
--   C28 "AI Agent Security" (entity 28). Courseware v5.0 changed the syllabus, so both pages move to
--   the v5 three topics and one shared About text (the non-WSQ copy follows the WSQ parent), and
--   both target the keyword "AI Security for AI Agents" (.claude/rules/seo-meta.md):
--     * meta_title: WSQ stored as the full rendered title; C28 stored bare.
--     * meta_description 130-160 chars; WSQ ends with its funding line; C28 has no funding words.
--     * meta_keyword (TEXT table), 8 phrases each.
--     * short_description (About) and description (topics + LSN_DATA), identical on both, no day count.
--   PROBED on SG prod before writing: no store-view overrides exist for these attributes; the C28
--   funding block already redirects to the WSQ page; schedule templates already match (A06 / WSQ-A06).
--   Peer-safe: each UPDATE only replaces the value probed on 2026-11-07, so a later edit is never
--   reverted. SG-only (store guard + SKU) -> no-op on MY/GH. Idempotent.

SET NAMES utf8mb4;
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @w0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025060473' LIMIT 1);
SET @c0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C28' LIMIT 1);
SET @w  := IF(@sg = 1, @w0, NULL);
SET @c  := IF(@sg = 1, @c0, NULL);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'        AND entity_type_id=@et);
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description'  AND entity_type_id=@et AND backend_type='varchar');
SET @a_kw := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et);
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
SET @a_de := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'       AND entity_type_id=@et);

SET @sd := '<p><strong>AI security for AI agents</strong> starts with one uncomfortable fact: an AI agent cannot reliably tell your instructions from an attacker''s. In this hands-on course you attack a real <strong>Hermes Agent</strong> three ways, stop it each time, then write the policy and the incident report your organisation needs.</p>
<p>You begin with how always-on AI agents work and where they already sit in business: <strong>OpenClaw</strong>, <strong>Hermes Agent</strong>, Google''s Gemini agent, <strong>Meta Muse</strong>, <strong>OpenAI dots</strong>, <strong>Grok Bot</strong> and <strong>Manus Cue</strong>, compared side by side. You set up an always-on assistant and check its work against the source.</p>
<p>Then you break one. On a free model you plant a <strong>prompt injection</strong> in a customer review, <strong>jailbreak</strong> the agent with a role-play request, and watch an ordinary request cause a <strong>data leak</strong> of personal data covered by the PDPA. You fix each attack with a stronger model, a guardrail, or a check written in code, and you measure the difference.</p>
<p>Finally you govern AI agents with the five principles of AI security: Data Control, Permission Control, Human in the Loop, Traceability and Right-Sized Models, linked to IMDA''s Model AI Governance Framework for Agentic AI, OWASP and the PDPA. You build an <strong>AI Governance Policy</strong> through an interview prompt and an <strong>AI Incident Report</strong> from mock agent traces.</p>
<p>No coding is needed. Every lab comes as one folder with mock data, scripts and a PDF of prompts.</p>';
SET @de := '<!-- LSN_DATA: [{"title": "Topic 1: Human-AI Collaboration and Always-On AI Agents", "subsecs": []}, {"title": "Topic 2: AI Agent Vulnerabilities: Prompt Injection, Jailbreak and Data Leak", "subsecs": []}, {"title": "Topic 3: AI Governance and Security: The Five Principles of AI Security", "subsecs": []}] -->
<p><strong>Topic 1: Human-AI Collaboration and Always-On AI Agents</strong></p>
<p><strong>Topic 2: AI Agent Vulnerabilities: Prompt Injection, Jailbreak and Data Leak</strong></p>
<p><strong>Topic 3: AI Governance and Security: The Five Principles of AI Security</strong></p>
';

-- ---------------------------------------------------------------- WSQ TGS-2025060473
UPDATE catalog_product_entity_varchar SET value = 'Funded up to 70% WSQ AI Security for AI Agents Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Funded up to 70% WSQ AI Security for Autonomous AI Agents Course | Tertiary Courses Singapore';
UPDATE catalog_product_entity_varchar SET value = 'AI security for AI agents: stop prompt injection, jailbreaks and data leaks with 5 security principles. Up to 70% WSQ funding; SkillsFuture Credit claimable.'
 WHERE attribute_id = @a_md AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Secure autonomous AI agents on OpenClaw and Hermes Agent: protect tools, data and memory, monitor risk. Up to 70% WSQ funding; SkillsFuture Credit claimable.';
UPDATE catalog_product_entity_text SET value = 'AI security for AI agents course, AI security for AI agents training Singapore, AI agent security course, prompt injection training, AI jailbreak and data leak prevention, AI governance policy, WSQ AI security course, SkillsFuture Credit course'
 WHERE attribute_id = @a_kw AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'AI agent security course, AI security training Singapore, OpenClaw, Hermes Agent, Paperclip, multi-agent workflow security, AI risk management, WSQ course Singapore, SkillsFuture Credit course';
UPDATE catalog_product_entity_text SET value = @sd
 WHERE attribute_id = @a_sd AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL
   AND value LIKE '<p>This course equips participants with essential knowledge%';
UPDATE catalog_product_entity_text SET value = @de
 WHERE attribute_id = @a_de AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL
   AND value LIKE '%Topic 1: Autonomous AI Agent Fundamentals with OpenClaw and Hermes Agent%';

-- ---------------------------------------------------------------- non-WSQ C28 (copy follows the WSQ parent)
UPDATE catalog_product_entity_varchar SET value = 'AI Security for AI Agents: AI Agent Security Course'
 WHERE attribute_id = @a_mt AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'AI Agent Security Course';
UPDATE catalog_product_entity_varchar SET value = 'AI security for AI agents, hands-on: attack a live agent with prompt injection, jailbreak and data leak tests, fix each, then write an AI governance policy.'
 WHERE attribute_id = @a_md AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'AI agent security for autonomous agents on OpenClaw, Hermes Agent and Paperclip. Secure tools, data, memory and multi-agent workflows, and set up governance.';
UPDATE catalog_product_entity_text SET value = 'AI security for AI agents course, AI security for AI agents training Singapore, AI agent security course, prompt injection training, AI jailbreak prevention, AI data leak prevention, AI governance policy, Hermes Agent security'
 WHERE attribute_id = @a_kw AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'AI agent security course, AI security training Singapore, OpenClaw, Hermes Agent, Paperclip, multi-agent workflow security, AI risk governance';
UPDATE catalog_product_entity_text SET value = @sd
 WHERE attribute_id = @a_sd AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL
   AND value LIKE '<p>This course equips participants with essential knowledge%';
UPDATE catalog_product_entity_text SET value = @de
 WHERE attribute_id = @a_de AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL
   AND value LIKE '%Topic 1: Autonomous AI Agent Fundamentals with OpenClaw and Hermes Agent%';
