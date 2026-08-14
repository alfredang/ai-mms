-- 1028: TGS-2023036653 "WSQ - Generative AI for Problem Solving" -- Course
--       Outline trimmed to the three topic HEADINGS only.
--
-- Follow-up to 1011. That migration replaced the old topics with the three
-- supplied ones but kept the pre-existing sub-bullet lists under each heading;
-- the admin wants the "What You'll Learn" card to list just the three titles:
--
--   Topic 1: Identifying Performance Gaps and Root Causes with Generative AI
--   Topic 2: Developing Corrective Plans and Evaluating Potential Solutions
--   Topic 3: Selecting, Implementing and Measuring the Effectiveness of Solutions
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml line 6 + 22 -> productAttribute($p, $_description,
-- 'description')), so this is a pure data change -- no template edit. That one
-- card is the ONLY place `description` renders on the product page, so there is
-- no second "Course Outline" section left holding the detail -- trimming here
-- trims the page.
--
-- Same shape as 960 (TGS-2024042310), 967 (TGS-2023039342), 997
-- (TGS-2021008700) and 999 (TGS-2025053228); ~19 live SG courses are already
-- headings-only, so this is the established house format, not a one-off.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- every <ul>/<li> sub-bullet is dropped. (This course predates the LSN_DATA
-- JSON shape, so there is no stale JSON comment to drop with them.)
--
-- The separate primary-column Learning Outcomes card is fed by cms_block
-- course_TGS-2023036653_learning_outcomes and is deliberately NOT touched --
-- it keeps LO1-LO3 registered against the unchanged SKU.
--
-- Everything else from 1011 is untouched (name, url_key, meta_*,
-- short_description, whoshouldattend, prerequisite, trainerprofile, labels,
-- categories, the 301), as is the regenerated cover.
--
-- 1011 is already applied + ledgered on SG prod, so editing it would never
-- re-run ([[feedback_edited_shared_migrations_never_rerun_on_prod]]); this
-- follow-up file is the correct vehicle.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statements below are guarded no-ops there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036653' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<h3 class="course-topic-h3">Topic 1: Identifying Performance Gaps and Root Causes with Generative AI</h3>
<h3 class="course-topic-h3">Topic 2: Developing Corrective Plans and Evaluating Potential Solutions</h3>
<h3 class="course-topic-h3">Topic 3: Selecting, Implementing and Measuring the Effectiveness of Solutions</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
