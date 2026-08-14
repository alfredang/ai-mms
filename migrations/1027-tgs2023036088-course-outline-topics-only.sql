-- 1027: TGS-2023036088 "WSQ - Agentic AI for Video Creation" -- Course Outline
--       trimmed to the three topic HEADINGS only.
--
-- Follow-up to 1013. That migration retitled the three topics but kept the two
-- sub-bullets under each; the admin wants the "What You'll Learn" card to list
-- just the three topic titles:
--
--   Topic 1: Creative Strategy and End-to-End Video Production with Agentic AI
--   Topic 2: AI-Assisted Video Editing, Storytelling and Quality Assurance
--   Topic 3: Workflow Optimisation, Industry Compliance and Emerging Video Technologies
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml line 22 -> productAttribute($p, $_description,
-- 'description')), so this is a pure data change -- no template edit. That card
-- is the ONLY place `description` renders on the product page, so there is no
-- second "Course Outline" section left holding the detail.
--
-- Same shape as 960, 967, 997 and 999; ~19 live SG courses are already
-- headings-only, so this is the established house format, not a one-off.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- the <ul>/<li> sub-bullets are dropped.
--
-- The separate primary-column Learning Outcomes card is fed by cms_block
-- course_TGS-2023036088_learning_outcomes (created in 1013) and is deliberately
-- NOT touched -- it keeps LO1-LO3 registered against the unchanged SKU.
--
-- Everything else from 1013 is untouched (name, url_key, meta_*,
-- short_description, labels, the 301), as is the regenerated cover URL.
--
-- 1013 is already applied + ledgered on SG prod, so editing it would never
-- re-run; this follow-up file is the correct vehicle.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statements below are guarded no-ops there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036088' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<h3 class="course-topic-h3">Topic 1: Creative Strategy and End-to-End Video Production with Agentic AI</h3>
<h3 class="course-topic-h3">Topic 2: AI-Assisted Video Editing, Storytelling and Quality Assurance</h3>
<h3 class="course-topic-h3">Topic 3: Workflow Optimisation, Industry Compliance and Emerging Video Technologies</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;
