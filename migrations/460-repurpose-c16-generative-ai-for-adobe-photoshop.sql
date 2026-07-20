-- Repurpose course C16 from "Basic Photoshop CC Training" to "Generative AI for Adobe Photoshop"
-- (1 day / 2 topics — Firefly-powered generative editing in
-- Photoshop). name, overview, topics, meta, url_key. Price ($350) and
-- duration (7.5h) already correct — untouched. Categories (Adobe / Photoshop /
-- Graphics Design) still fit — untouched. Certification + funding blocks are
-- generic and still valid — untouched. Clears per-store overrides of the
-- rewritten attributes so partner store scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C16.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C16');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Generative AI for Adobe Photoshop' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Unlock the new generation of image editing with Generative AI for Photoshop. This hands-on 1-day course shows you how Adobe Firefly&mdash;the generative AI engine built into Photoshop&mdash;transforms the way you create and edit images. You will learn to use Generative Fill and Generative Expand to add, remove and extend image content with simple text prompts, clean up photos in seconds with AI-powered removal tools, and generate entirely new backgrounds and scenes without complex masking or compositing.</p>
<p>Through practical exercises, participants will build complete generative editing workflows&mdash;retouching portraits, replacing backgrounds, extending canvases for different formats, creating text-to-image concepts with reference styles, and combining generative layers with classic Photoshop techniques for full creative control. You will also learn how to write effective prompts and understand the commercial-use and intellectual property considerations of AI-generated imagery. By the end of the course, you will be able to apply generative AI confidently to produce professional visuals in a fraction of the time.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Generative Editing Essentials in Photoshop</h3>
<ul>
<li>Introduction to Adobe Firefly and Generative AI in Photoshop</li>
<li>Writing Effective Prompts for Image Generation</li>
<li>Adding and Removing Content with Generative Fill</li>
<li>Extending Images with Generative Expand</li>
<li>One-Click Cleanup with the AI Remove Tool</li>
<li>Generating and Replacing Backgrounds</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Advanced Generative Workflows</h3>
<ul>
<li>Text-to-Image Generation with Reference Images and Styles</li>
<li>AI-Powered Portrait Retouching and Neural Filters</li>
<li>Combining Generative Layers with Masks and Blend Modes</li>
<li>Building End-to-End Generative Design Workflows</li>
<li>Commercial Use and Intellectual Property Considerations</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for Adobe Photoshop' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master generative AI in Photoshop with Adobe Firefly. Learn Generative Fill, Generative Expand, AI background replacement and text-to-image workflows in this hands-on 1-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI Photoshop, Adobe Firefly, Generative Fill, Generative Expand, AI Image Editing, Text to Image, AI Background Removal, Neural Filters, Photoshop Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'generative-ai-for-adobe-photoshop' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
