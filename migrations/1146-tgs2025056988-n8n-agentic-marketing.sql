-- 1146: Revamp TGS-2025056988 storefront content around n8n automation.
--
-- Scope is deliberately narrow:
--   * short_description: replace Claude Cowork / MCP / Claude Skills copy with
--     the n8n research -> strategy -> content -> approval -> social publishing
--     -> measurement automation taught by the v2.0 courseware.
--   * description: replace the three Claude topic headings with three n8n
--     mechanism-led topic headings.
--   * meta title / description / keyword: remove stale Claude positioning.
--
-- Deliberately unchanged: SKU, product name, URL, price, schedules, funding,
-- learning-outcomes CMS block, Skills Framework, certification, brochure,
-- trainers, badges, categories, images, recommended courses and assessments.
--
-- TGS- products are SG-only. On partner databases @e is NULL and every write
-- no-ops. Idempotent: each UPDATE converges on a complete target value.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056988' LIMIT 1);

SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

-- About This Course: full replace. The current value is prose-only; the
-- five protected per-course sections remain in cms/block and are untouched.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips learners with practical skills to design and operate agentic digital-marketing automations with n8n. Participants will turn campaign briefs into governed workflows that research evidence, define audiences and KPIs, formulate channel strategy, create content, coordinate review, and measure outcomes across multiple channels.</p>
<p>Learners will work with n8n triggers, webhooks, spreadsheet inputs, structured data, API calls, AI model nodes, validation branches, retries, and audit records. The focus is on orchestration rather than one-off prompting: every workflow makes inputs, decisions, outputs, ownership, and failure handling visible.</p>
<p>Across a connected lab journey, participants will score research sources, rank audience opportunities, model channel budget and ROI, generate channel-specific content, and apply brand, claim, and compliance checks. A human-in-the-loop state machine supports approve, revise, reject, and timeout paths before an idempotent social-publishing dry run can proceed.</p>
<p>Participants will then ingest performance events, attribute results, detect ROI anomalies, and create bounded optimisation actions that feed back into campaign planning. Credentials remain in n8n Credentials or another secret manager, while publishing exercises default to safe dry-run mode.</p>
<p>This course is suitable for beginner and intermediate digital marketers, campaign managers, content teams, and business users who want to build measurable end-to-end marketing automation with n8n and agentic AI while retaining accountable human oversight.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- Course outline: three headings, matching the existing accredited three-topic
-- shape while replacing the obsolete Claude-specific implementation.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Evidence-Led Marketing Research, Audience Signals and KPI Planning with n8n","subsecs":[]},{"title":"Topic 2: Governed Multi-Channel Content Automation and Human Approval","subsecs":[]},{"title":"Topic 3: Social Publishing, Performance Attribution and Optimisation with n8n","subsecs":[]}] -->
<p><strong>Topic 1: Evidence-Led Marketing Research, Audience Signals and KPI Planning with n8n</strong></p>
<p><strong>Topic 2: Governed Multi-Channel Content Automation and Human Approval</strong></p>
<p><strong>Topic 3: Social Publishing, Performance Attribution and Optimisation with n8n</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Digital Marketing with n8n Automation'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Build governed n8n marketing automations from research and content creation to human approval, social publishing, ROI measurement and optimisation. Up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'n8n digital marketing automation, agentic AI marketing, human in the loop, AI content workflow, social media automation, marketing research automation, campaign ROI, marketing orchestration, WSQ digital marketing course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0 AND @e IS NOT NULL;

-- This install reads the product summary from the SG flat catalog. Mirror the
-- new admin-scope value so the storefront changes immediately after deploy.
UPDATE catalog_product_flat_1 f
  JOIN catalog_product_entity_text v
    ON v.entity_id = f.entity_id AND v.attribute_id = @a_sdesc AND v.store_id = 0
   SET f.short_description = v.value
 WHERE f.entity_id = @e AND @e IS NOT NULL;

-- Invalidate product/page cache tags; the new container rebuilds rendered HTML.
TRUNCATE TABLE core_cache_tag;
