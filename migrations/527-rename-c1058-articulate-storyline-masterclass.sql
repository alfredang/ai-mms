-- Rename C1058: "Articulate Storyline 360 Essential Training"
--             -> "Articulate Storyline 360 Masterclass"
-- Rebrand only: name, overview, meta, image labels, cover. The curriculum
-- (description), price ($350) and duration are intentionally kept.
-- url_key stays articulate-storyline-360-essential-training (precedent
-- C947/C950/C1013: keep the slug — no url_path drop / rewrite reindex churn,
-- no 301 needed).
-- Funding block added pointing at the FINAL WSQ url
-- wsq-mastering-articulate-storyline-360-for-e-learning-content-creation.html
-- (verified 200 on www.tertiarycourses.com.sg 2026-07-18).
-- Cover re-rendered 2026-07-18 with the new title (no funding chips —
-- C1058 carries no funding-badge tags) and uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1058
-- (partners carry M-prefix SKUs, which are intentionally untouched).
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1058');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Articulate Storyline 360 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Dive into the transformative world of elearning content with our Articulate Storyline 360 Masterclass. This masterclass encapsulates everything, from the very basics of elearning content to the intricate processes of inserting images, characters, external media, and even publishing handouts to Microsoft Word. Be it setting up your project preferences, adjusting slide properties, or exploring the potential of triggers and timings, this training has got you covered.</p>
<p>Moreover, with our professionally curated curriculum, you''ll get hands-on experience in creating projects either from existing slides or from scratch. And to ensure that your content is inclusive, we also guide you on accessibility best practices. By the end, not only will you be adept at crafting interactive elearning modules, but you''ll also be proficient in assessing learner engagement through questions and publishing your course online.</p>
<h2>Funding and Grant Applications</h2>
<p class="p1">No funding is available for this course.</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-mastering-articulate-storyline-360-for-e-learning-content-creation.html" title="WSQ Mastering Articulate Storyline 360 Course">WSQ - Mastering Articulate Storyline 360 for e-Learning Content Creation Course</a></span></p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Articulate Storyline 360 Masterclass | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Articulate Storyline 360 in this hands-on masterclass — build interactive elearning modules with images, characters, triggers, timings, and quizzes, then publish accessible courses online.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Articulate Storyline 360 Masterclass, Articulate Storyline Course, Storyline Training, eLearning Authoring, Interactive eLearning, Triggers and Timings, Quiz Design, Course Publishing, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1058-20260717-182822.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Articulate Storyline 360 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Articulate Storyline 360 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Articulate Storyline 360 Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image gallery label, not the EAV labels
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Articulate Storyline 360 Masterclass'
WHERE g.entity_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_mk);
