-- 1026: TGS-2024045799 "WSQ - Agentic AI for Product Development"
--       -- Course Outline trimmed to the three topic HEADINGS only.
--
-- Follow-up to 1012. That migration wrote the three supplied topics and expanded
-- each into a list of sub-bullets; the admin wants the "What You'll Learn" card
-- to list just the three topic titles:
--
--   Topic 1: Evaluating Agentic AI Tools for Product Research and Development
--   Topic 2: Building and Optimising Agentic AI Product Development Workflows
--   Topic 3: Deploying and Evaluating Agentic AI-Powered Product Solutions
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml -> productAttribute($p, $_description, 'description')),
-- so this is a pure data change -- no template edit. That one card is the ONLY
-- place `description` renders on the product page, so there is no second
-- "Course Outline" section left holding the detail -- trimming here trims the
-- page.
--
-- Same shape as 960 (TGS-2024042310), 967 (TGS-2023039342), 997
-- (TGS-2021008700), 999 (TGS-2025053228) and 1025 (TGS-2023036153); ~20 live SG
-- courses are already headings-only, so this is the established house format.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- every <ul>/<li> sub-bullet is dropped. Verified on the live value: this
-- course carries NO LSN_DATA JSON comment (LOCATE = 0), so there is none to
-- keep in sync, and there is no store-scoped override (store 0 only).
--
-- The separate primary-column card titled "Learning Outcomes" is fed by
-- cms_block course_TGS-2024045799_learning_outcomes and is deliberately NOT
-- touched -- it keeps LO1-LO3, the SSG-accredited outcomes registered against
-- the unchanged SKU.
--
-- Everything else from 1012 is untouched (name, url_key, meta_*,
-- short_description, whoshouldattend, prerequisite, trainerprofile, labels,
-- media-gallery label, categories, the 301), as is the re-rendered cover URL.
--
-- 1012 is already applied + ledgered on SG prod, so editing it would never
-- re-run ([[feedback_edited_shared_migrations_never_rerun_on_prod]]); this
-- follow-up file is the correct vehicle.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statements below are guarded no-ops there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045799' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<h3 class="course-topic-h3">Topic 1: Evaluating Agentic AI Tools for Product Research and Development</h3>
<h3 class="course-topic-h3">Topic 2: Building and Optimising Agentic AI Product Development Workflows</h3>
<h3 class="course-topic-h3">Topic 3: Deploying and Evaluating Agentic AI-Powered Product Solutions</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
