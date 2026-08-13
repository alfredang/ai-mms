-- 997: TGS-2021008700 "WSQ - AI Vibe Coding for Excel VBA" -- Course Outline
--      trimmed to the five topic HEADINGS only.
--
-- Follow-up to 945. That migration expanded each supplied topic into a <ul> of
-- sub-bullets; the admin wants the "What You'll Learn" card to list just the
-- five topic titles, exactly as supplied:
--
--   Topic 1: AI Vibe Coding for Excel VBA, Macros and Interface Design
--   Topic 2: VBA Programming Logic, Variables, Decisions and Loops
--   Topic 3: Creating Custom Functions and Automated Procedures
--   Topic 4: Managing Excel Objects, Testing and Debugging VBA Code
--   Topic 5: Developing User-Defined Forms, Events and Documentation
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml line 6 + 22 -> productAttribute($p, $_description,
-- 'description')), so this is a pure data change -- no template edit.
-- Same shape as migrations 960 (TGS-2024042310) and 967 (TGS-2023039342),
-- which did this for their courses; 19 live SG courses are already
-- headings-only, so this is the established house format, not a one-off.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- only the <ul> bullet lists are dropped.
--
-- The separate primary-column "Learning Outcomes" / What-You'll-Learn LO card is
-- fed by cms_block course_TGS-2021008700_learning_outcomes and is deliberately
-- NOT touched -- it keeps the five SSG-accredited LO1-LO5 outcomes registered
-- against the unchanged SKU.
--
-- Everything else from 945 is untouched (name, url_key, meta_*,
-- short_description, whoshouldattend, prerequisite, trainerprofile, labels,
-- cover, categories, the 301).
--
-- 945 is already applied + ledgered on SG prod, so editing it would never
-- re-run ([[feedback_edited_shared_migrations_never_rerun_on_prod]]); this
-- follow-up file is the correct vehicle.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statements below are guarded no-ops there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021008700' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<h3 class="course-topic-h3">Topic 1: AI Vibe Coding for Excel VBA, Macros and Interface Design</h3>
<h3 class="course-topic-h3">Topic 2: VBA Programming Logic, Variables, Decisions and Loops</h3>
<h3 class="course-topic-h3">Topic 3: Creating Custom Functions and Automated Procedures</h3>
<h3 class="course-topic-h3">Topic 4: Managing Excel Objects, Testing and Debugging VBA Code</h3>
<h3 class="course-topic-h3">Topic 5: Developing User-Defined Forms, Events and Documentation</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
