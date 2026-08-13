-- 960: TGS-2024042310 "WSQ - AI for Game Development" -- Course Outline trimmed
--      to the five topic HEADINGS only.
--
-- Follow-up to 959. That migration expanded each supplied topic into a <ul> of
-- sub-bullets; the admin wants the "What You'll Learn" card to list just the
-- five topic titles, exactly as supplied:
--
--   Topic 1: Unity and C# Programming with Claude Code and Codex
--   Topic 2: Prototyping 3D Games with AI-Assisted Coding
--   Topic 3: Enhancing Unity Gameplay, UI, Animation and Audio
--   Topic 4: Developing Complete Unity Games with C# Classes and Objects
--   Topic 5: Game Testing, Deployment, Documentation and Version Control
--
-- The "What You'll Learn" card renders the product `description` VERBATIM
-- (view/description.phtml line 68 -> productAttribute($p, $_description,
-- 'description')), so this is a pure data change -- no template edit.
--
-- Markup keeps the live <h3 class="course-topic-h3"> shape the theme styles;
-- only the <ul> bullet lists are dropped.
--
-- Everything else from 959 is untouched (name, url_key, meta_*,
-- short_description, trainerprofile, labels, category 252, the 301).
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => the
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024042310' LIMIT 1);

SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e,
       CONCAT(
         '<h3 class="course-topic-h3">Topic 1: Unity and C# Programming with Claude Code and Codex</h3>',
         '<h3 class="course-topic-h3">Topic 2: Prototyping 3D Games with AI-Assisted Coding</h3>',
         '<h3 class="course-topic-h3">Topic 3: Enhancing Unity Gameplay, UI, Animation and Audio</h3>',
         '<h3 class="course-topic-h3">Topic 4: Developing Complete Unity Games with C# Classes and Objects</h3>',
         '<h3 class="course-topic-h3">Topic 5: Game Testing, Deployment, Documentation and Version Control</h3>'
       )
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;
