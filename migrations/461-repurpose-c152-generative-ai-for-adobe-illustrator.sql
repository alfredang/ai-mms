-- Repurpose course C152 from "Illustrator CC Essential Training" to
-- "Generative AI for Adobe Illustrator" (1 day / 2 topics — Firefly-powered
-- generative vector design in Illustrator). name, overview, topics, meta,
-- url_key. Price ($350) and duration (8.25h = 1 day) already correct —
-- untouched. Categories (Adobe / Illustrator / Graphics Design) still fit —
-- untouched. Certification + funding blocks are generic and still valid —
-- untouched. Clears per-store overrides of the rewritten attributes so
-- partner store scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C152.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C152');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Generative AI for Adobe Illustrator' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Step into the future of vector design with Generative AI for Adobe Illustrator. This hands-on 1-day course shows you how Adobe Firefly&mdash;the generative AI engine built into Illustrator&mdash;transforms the way you create logos, icons, illustrations and patterns. You will learn to generate fully editable vector graphics from simple text prompts with Text to Vector Graphic, restyle entire artworks in seconds with Generative Recolor, and fill shapes with AI-generated content that matches your creative direction.</p>
<p>Through practical exercises, participants will build complete generative design workflows&mdash;creating scenes, subjects and seamless patterns from prompts, matching styles with reference artwork, identifying and matching fonts with Retype, and combining generative output with classic Illustrator tools like the Pen tool and Pathfinder for full creative control. You will also learn how to write effective prompts and understand the commercial-use and intellectual property considerations of AI-generated artwork. By the end of the course, you will be able to apply generative AI confidently to produce professional vector designs in a fraction of the time.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Generative Vector Design Essentials in Illustrator</h3>
<ul>
<li>Introduction to Adobe Firefly and Generative AI in Illustrator</li>
<li>Writing Effective Prompts for Vector Generation</li>
<li>Creating Subjects, Scenes and Icons with Text to Vector Graphic</li>
<li>Generating Seamless Patterns from Text Prompts</li>
<li>Matching Styles with Reference Artwork</li>
<li>Editing and Refining Generated Vector Graphics</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Advanced Generative Workflows</h3>
<ul>
<li>Exploring Color Variations with Generative Recolor</li>
<li>Identifying and Matching Fonts with Retype</li>
<li>Presenting Designs with AI-Powered Mockups</li>
<li>Combining Generative Output with the Pen Tool and Pathfinder</li>
<li>Building End-to-End Workflows for Logos, Icons and Illustrations</li>
<li>Commercial Use and Intellectual Property Considerations</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for Adobe Illustrator' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master generative AI in Adobe Illustrator with Adobe Firefly. Learn Text to Vector Graphic, Generative Recolor, pattern generation and AI-powered design workflows in this hands-on 1-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI Illustrator, Adobe Firefly, Text to Vector Graphic, Generative Recolor, AI Vector Design, AI Pattern Generation, Retype, AI Logo Design, Illustrator Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'generative-ai-for-adobe-illustrator' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
