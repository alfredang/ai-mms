-- Repurpose course C162 from "Sketchup Essential Training" to
-- "Generative AI for 3D Modeling". Rewrites name, overview, the two topics
-- (1-day course, 2 topics per house style), meta, url_key, image labels and a
-- freshly rendered cover (course_image_url). Price ($350) and duration
-- (1 day / 7.5h) intentionally kept.
-- Funding cms_block course_c162_funding_and_grant is retargeted directly on
-- SG prod only (WSQ 3D Modelling with Blender) — not in this shared migration.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C162.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C162');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_cimg  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_pre   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Generative AI for 3D Modeling' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Create 3D assets in minutes with generative AI. This hands-on 1-day course shows you how to turn text prompts and reference images into fully-textured 3D models using the latest generative AI tools, and how to bring those AI-generated assets into Blender for refinement. You will learn to craft effective prompts for geometry and style, generate models from both text and images, and produce AI textures and materials that bring your designs to life.</p>
<p>Through practical projects, participants will build a complete AI-assisted 3D pipeline — generating models with text-to-3D and image-to-3D workflows, inspecting and cleaning up meshes, retopologizing and UV-unwrapping in Blender, applying AI-generated textures, and exporting production-ready assets. By the end of the course, you will be able to combine generative AI with traditional 3D tools to produce high-quality 3D assets for games, 3D printing and visualization in a fraction of the usual time.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Generating 3D Models with AI</h3>
<ul>
<li>Introduction to Generative AI for 3D Modeling</li>
<li>Prompting for Geometry, Style and Detail</li>
<li>Text-to-3D Model Generation</li>
<li>Image-to-3D Model Generation</li>
<li>Generating Textures and Materials with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Refining and Exporting AI-Generated Assets</h3>
<ul>
<li>Importing AI-Generated Models into Blender</li>
<li>Mesh Cleanup and Retopology</li>
<li>Applying and Adjusting AI Textures</li>
<li>Exporting Assets for Games, 3D Printing and Visualization</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for 3D Modeling' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Turn text prompts and images into fully-textured 3D models with generative AI, refine them in Blender and export production-ready assets for games, 3D printing and visualization in this hands-on 1-day course.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI, 3D Modeling, Text-to-3D, Image-to-3D, AI Texturing, Blender, 3D Assets, AI 3D Generation, 3D Printing, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'generative-ai-for-3d-modeling' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Fresh cover rendered 2026-07-18 from the new title (no funding badges)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cimg, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C162-20260717-170121.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Generative AI for 3D Modeling' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Generative AI for 3D Modeling' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Generative AI for 3D Modeling' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Prerequisite: keep promo code + entry requirements, replace the Sketchup
-- software section with the generative AI 3D toolchain
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pre, 0, @e, '<h2>Promotion Code</h2>
<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>
<h2>Minimum Entry Requirement</h2>
<p>Knowledge and Skills</p>
<ul>
<li>Able to operate using computer functions</li>
<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>
</ul>
<p>Attitude</p>
<ul>
<li>Positive Learning Attitude</li>
<li>Enthusiastic Learner</li>
</ul>
<p>Experience</p>
<ul>
<li>Minimum of 1 year of working experience.</li>
</ul>
<p>Target Age Group: 21-65 years old</p>
<h2>Minimum Software/Hardware Requirement</h2>
<h2>Software Requirement</h2>
<p>Please sign up for free accounts with the generative AI 3D tools below and install Blender before the class. Note that we don''t provide the software</p>
<ul>
<li><a href="https://www.meshy.ai" target="_blank">Meshy AI</a></li>
<li><a href="https://www.tripo3d.ai" target="_blank">Tripo AI</a></li>
<li><a href="https://www.blender.org/download/" target="_blank">Blender</a></li>
</ul>
<p><strong>Hardware:</strong> Windows and Mac Laptops</p>' FROM DUAL WHERE @e IS NOT NULL AND @a_pre IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Upsell rail: swap the Sketchup WSQ course for the Blender 3D-modelling WSQ
SET @wsq_old := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2021010185');
SET @wsq_new := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2022015368');
DELETE FROM catalog_product_link
WHERE product_id=@e AND @e IS NOT NULL AND link_type_id=4 AND linked_product_id=@wsq_old AND @wsq_old IS NOT NULL;
INSERT IGNORE INTO catalog_product_link (product_id, linked_product_id, link_type_id)
SELECT @e, @wsq_new, 4 FROM DUAL WHERE @e IS NOT NULL AND @wsq_new IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_cimg, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk, @a_pre);

-- Stale url_path rows point at the old sketchup-essential-training URL; drop
-- them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;
