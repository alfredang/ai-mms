-- C139 "AI Vibe Coding for Android Apps Development" becomes the non-WSQ twin of
-- TGS-2024048313 (WSQ - AI Vibe Coding for Android Apps Development); its courseware is now the
-- converted WSQ set (github.com/tertiarycourses/C139-AI-Vibe-Coding-for-Android-Apps-Development),
-- compressed from the parent's 4 days into 2 (all 5 topics, all 23 labs).
--
-- 1. About + topics copied from the WSQ parent (5 Java/Android topics; replaces the previous
--    build's Kotlin/Jetpack Compose copy, which opened "This hands-on 2-day course"). Neither
--    text states a day count.
-- 2. meta_description rewritten (the old one named Kotlin, Cursor and "2-day course");
--    meta_keyword aligned with the Java/Android Studio syllabus.
-- 3. Funding block repointed from wsq-ai-vibe-coding-for-multi-agents-system.html (a different
--    course) to the real twin, wsq-ai-vibe-coding-for-android-apps-development.html.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Not in SQL: the schedule template switch B07 -> B17 (user's choice; the parent is on
-- (SG) WSQ-D04 but runs 4 days vs C139's 2, so the same-code rule does not apply) is a code path
-- (CoursesaveController::switchScheduleTemplateAction), already run on prod.
-- Post-deploy: flat reindex + cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C139' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024048313' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build native Android apps in Java with AI vibe coding. Learn Android Studio, OOP, UI design, Room, REST APIs, testing and Google Play deployment with Gemini as your AI pair programmer.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- an orphan TEXT-table meta_description would shadow the varchar value
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI Vibe Coding, Android, Java, Android Studio, Gemini, Jetpack Compose, Room, Retrofit, Google Play'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-android-apps-development.html" title="WSQ - AI Vibe Coding for Android Apps Development">WSQ - AI Vibe Coding for Android Apps Development</a></span></p>'
 WHERE @ok AND identifier = 'course_C139_funding_and_grant';
