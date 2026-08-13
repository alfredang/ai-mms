-- 999: TGS-2025053228 "WSQ - AI Agent Cybersecurity" -- Course Outline trimmed
--      to the three topic HEADINGS only.
--
-- Follow-up to 954. That migration mapped the three supplied topics onto the
-- LU1/LU2/LU3 scaffold and expanded each into a list of sub-bullets; the admin
-- wants the "What You'll Learn" card to list just the three topic titles:
--
--   Topic 1: Developing Cybersecurity Policies with OpenClaw and Hermes Agents
--   Topic 2: AI Agent Monitoring, Compliance and Response to Emerging Threats
--   Topic 3: Continuous Cybersecurity Improvement with Autonomous AI Agent
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml line 6 + 22 -> productAttribute($p, $_description,
-- 'description')), so this is a pure data change -- no template edit. That one
-- card is the ONLY place `description` renders on the product page (grep of
-- view.phtml finds short_description only), so there is no second "Course
-- Outline" section left holding the detail -- trimming here trims the page.
--
-- Same shape as 960 (TGS-2024042310), 967 (TGS-2023039342) and 997
-- (TGS-2021008700); ~19 live SG courses are already headings-only, so this is
-- the established house format, not a one-off.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- the LU1/LU2/LU3 headings and every <p><em> sub-bullet are dropped. The
-- LSN_DATA JSON comment is dropped with them -- nothing reads it (grep of
-- app/design/frontend + app/code/local/MMD returns no consumer), and leaving a
-- stale copy describing sub-sections that no longer render would rot.
--
-- The separate primary-column Learning Outcomes card is fed by cms_block
-- course_TGS-2025053228_learning_outcomes and is deliberately NOT touched --
-- it keeps LO1-LO3 registered against the unchanged SKU.
--
-- Everything else from 954 is untouched (name, url_key, meta_*,
-- short_description, whoshouldattend, prerequisite, trainerprofile, labels,
-- categories, the 301), as is the 968 cover URL.
--
-- 954 is already applied + ledgered on SG prod, so editing it would never
-- re-run ([[feedback_edited_shared_migrations_never_rerun_on_prod]]); this
-- follow-up file is the correct vehicle.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statements below are guarded no-ops there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053228' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<h3 class="course-topic-h3">Topic 1: Developing Cybersecurity Policies with OpenClaw and Hermes Agents</h3>
<h3 class="course-topic-h3">Topic 2: AI Agent Monitoring, Compliance and Response to Emerging Threats</h3>
<h3 class="course-topic-h3">Topic 3: Continuous Cybersecurity Improvement with Autonomous AI Agent</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
