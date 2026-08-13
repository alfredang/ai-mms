-- 967: TGS-2023039342 "WSQ - Generative AI for 3D Design" -- Course Outline
--      trimmed to the six topic HEADINGS only.
--
-- Follow-up to 963. That migration expanded each supplied topic into a <ul> of
-- sub-bullets; the admin wants the "What You'll Learn" card to list just the
-- six topic titles, exactly as supplied:
--
--   Topic 1: AI-Assisted Machine Part Design and Conceptualization
--   Topic 2: Generative AI for Sketching and 3D CAD Modeling
--   Topic 3: AI-Assisted Assembly Design and Modeling
--   Topic 4: Creating Exploded Views and Assembly Animations with AI
--   Topic 5: AI-Assisted GD&T and Standardized Technical Drawings
--   Topic 6: Orthographic Modeling, AI-Based Review and Design Optimization
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml -> productAttribute($p, $_description,
-- 'description')), so this is a pure data change -- no template edit.
-- Same shape as migration 960 (TGS-2024042310), which did this for its course.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- only the <ul> bullet lists are dropped. The ampersand in Topic 5 stays
-- HTML-encoded (GD&amp;T) -- it renders as "GD&T".
--
-- The separate primary-column "Learning Outcomes" card is fed by cms_block
-- course_TGS-2023039342_learning_outcomes and is deliberately NOT touched --
-- it keeps the six SSG-accredited LO1-LO6 outcomes.
--
-- Everything else from 963 is untouched (name, url_key, meta_*,
-- short_description, whoshouldattend, prerequisite, trainerprofile, labels,
-- cover, categories, the 301).
--
-- 963 is already applied + ledgered on SG prod, so editing it would never
-- re-run ([[feedback_edited_shared_migrations_never_rerun_on_prod]]); this
-- follow-up file is the correct vehicle.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023039342' LIMIT 1);

SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e,
       CONCAT(
         '<h3 class="course-topic-h3">Topic 1: AI-Assisted Machine Part Design and Conceptualization</h3>',
         '<h3 class="course-topic-h3">Topic 2: Generative AI for Sketching and 3D CAD Modeling</h3>',
         '<h3 class="course-topic-h3">Topic 3: AI-Assisted Assembly Design and Modeling</h3>',
         '<h3 class="course-topic-h3">Topic 4: Creating Exploded Views and Assembly Animations with AI</h3>',
         '<h3 class="course-topic-h3">Topic 5: AI-Assisted GD&amp;T and Standardized Technical Drawings</h3>',
         '<h3 class="course-topic-h3">Topic 6: Orthographic Modeling, AI-Based Review and Design Optimization</h3>'
       )
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- A store-scoped description override would shadow the store-0 value above.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;
