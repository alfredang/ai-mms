-- 929: Rename TGS-2021008635
--        "WSQ - Develop Full Stack Web Applications with Vue Using Vibe Coding"
--      -> "WSQ - AI Vibe Coding for Full Stack Web Applications"
--
-- Course code (SKU) is UNCHANGED — TGS-2021008635 stays, so every SkillsFuture /
-- SFEC / SFC / PSEA deep link keyed on the course code remains correct and no
-- funding content is touched. Follows the 855 playbook for TGS- renames.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / meta_keyword / image labels -> new title
--   2. url_key -> wsq-ai-vibe-coding-for-full-stack-web-applications ; url_path
--      deleted at every scope so the Catalog URL Rewrites indexer regenerates it
--   3. explicit 301 from the old bare slug (the indexer auto-301s the category
--      paths for this product; the bare path is belt-and-braces — see 647/855)
--   4. short_description replaced with the new "About This Course" copy. This
--      course's sections (Brochure / Skills Framework / Certification) were
--      already stripped to per-course cms/block rows on prod, so there is no
--      "<h2>Course Brochure</h2>" tail to splice — full replace is correct here.
--   5. description (Course Outline) -> the 5 new topics, keeping the existing
--      LSN_DATA JSON header + <p><strong> markup shape
--   6. cms_block course_TGS-2021008635_learning_outcomes -> new LO1-LO5
--      (same markup shape as the current block, "Vue" dropped)
--   7. media gallery per-image label
--   8. search-term redirects retargeted off the old slug (5 live rows on SG)
--
-- meta_title deliberately omits BOTH the leading "WSQ" and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending "WSQ funded" for any SG TGS- SKU and appending the
-- brand postfix (Block/Html/Head.php). Baking either in yields the duplicated
-- "WSQ funded WSQ ..." tag that 853 had to clean up on TGS-2024045797.
--
-- NOT rewritten:
--   - trainerprofile — the four bios reference "full stack training"
--     generically and never quote the course title (verified on prod)
--   - brochure cms/block — title + PDF path are keyed on the unchanged SKU
--   - skills_framework / certification / funding_and_grant blocks — title-free
--
-- The cover PNG still bakes the old title — regenerate it after this applies
-- (MMD_CourseImage strips the leading "WSQ -" via Model/Cover.php::cleanTitle,
-- so the new image shows "AI Vibe Coding for Full Stack Web Applications").
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops). Idempotent — re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021008635' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - AI Vibe Coding for Full Stack Web Applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No "WSQ" token and no brand suffix — MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI Vibe Coding for Full Stack Web Applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI Vibe Coding for Full Stack Web Applications training in Singapore. Build responsive UIs, REST APIs and databases with AI coding assistants. Up to 70% WSQ funding subsidy.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-ai-vibe-coding-for-full-stack-web-applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ -" prefix) — they are alt text on
-- the course cover, which itself renders without the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI Vibe Coding for Full Stack Web Applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI Vibe Coding for Full Stack Web Applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI Vibe Coding for Full Stack Web Applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Drop any non-system squatter on the old path first (see 647: INSERT IGNORE
-- silently no-ops against a stale is_system row and the 301 never ships).
DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path = 'wsq-develop-full-stack-web-applications-with-vue-using-vibe-coding.html'
  AND @e IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2021008635_old_', s.store_id),
       'wsq-develop-full-stack-web-applications-with-vue-using-vibe-coding.html',
       'wsq-ai-vibe-coding-for-full-stack-web-applications.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'wsq-develop-full-stack-web-applications-with-vue-using-vibe-coding.html'
      AND c.is_system = 1);

-- ---------------------------------------- 4. short_description (About This Course)
-- Full replace: this course's short_description holds only the intro copy (the
-- Brochure / Skills Framework / Certification sections live in cms/block rows),
-- so there is no tail to preserve.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sd, 0, @e, '<p>AI Vibe Coding for Full Stack Web Applications equips aspiring developers and IT professionals with the practical skills to build modern, end-to-end web applications using AI-assisted development workflows. Participants will learn to translate natural-language requirements into functional code, accelerate development with AI coding assistants and iteratively refine applications through structured prompting, testing and debugging.</p>
<p>The course covers essential front-end development skills, including responsive user interfaces, interactive controls, reusable components, navigation and form handling. Learners will also develop back-end services, REST APIs, database models, authentication and data-processing functions to support complete web application workflows.</p>
<p>Through hands-on projects, participants will use AI Vibe Coding to scaffold applications, generate code, connect front-end interfaces to back-end services and integrate databases and external APIs. They will learn to inspect and validate AI-generated code for functionality, security, maintainability and performance rather than relying on unverified outputs.</p>
<p>The course also introduces version control, application testing, documentation and cloud deployment practices. By the end of the course, learners will be able to design, build, troubleshoot and deploy a complete full stack web application while using AI responsibly to improve development speed and productivity.</p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ------------------------------------------------ 5. description (Course Outline)
-- Same shape as the current value: LSN_DATA JSON header + one <p><strong> per topic.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_desc, 0, @e, '<!-- LSN_DATA: [{"title":"Topic 1: Designing Full Stack Web Applications with AI Vibe Coding","subsecs":[]},{"title":"Topic 2: Building Dynamic and Responsive User Interfaces","subsecs":[]},{"title":"Topic 3: Creating Interactive Controls and Application Features","subsecs":[]},{"title":"Topic 4: Developing Reusable Components and Full Stack Architecture","subsecs":[]},{"title":"Topic 5: Building Forms, Managing Data and Producing Documentation","subsecs":[]}] -->
<p><strong>Topic 1: Designing Full Stack Web Applications with AI Vibe Coding</strong></p>
<p><strong>Topic 2: Building Dynamic and Responsive User Interfaces</strong></p>
<p><strong>Topic 3: Creating Interactive Controls and Application Features</strong></p>
<p><strong>Topic 4: Developing Reusable Components and Full Stack Architecture</strong></p>
<p><strong>Topic 5: Building Forms, Managing Data and Producing Documentation</strong></p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- meta_keyword: lead with the new course name.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI vibe coding course, vibe coding Singapore, full stack web development course, AI-assisted coding, AI coding assistants, WSQ full stack web application course, front-end development course, back-end development, REST API development, responsive web design, WSQ vibe coding course' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------- 6. Learning Outcomes cms/block (LO1-LO5)
UPDATE cms_block
SET content = '<p>By the end of the course, learners will be able to&nbsp;</p>
<ul>
<li>LO1: Design a simple App interface</li>
<li>LO2: Utilize directives</li>
<li>LO3: Create elements and controls to meet design objectives</li>
<li>LO4: Create components in the software design</li>
<li>LO5: Produce forms and documentation</li>
</ul>'
WHERE identifier = 'course_TGS-2021008635_learning_outcomes';

-- ------------------------------------------------- 7. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Vibe Coding for Full Stack Web Applications'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------- 8. retarget search-term redirects
-- 5 live SG rows point at the old slug (incl. the bare course code
-- TGS-2021008635 and the old full title as a query). Search redirects are DATA —
-- this was ALSO applied live on prod (see memory
-- feedback_search_redirects_always_apply_live).
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-full-stack-web-applications.html',
    is_processed = 1
WHERE store_id = 1
  AND redirect LIKE '%wsq-develop-full-stack-web-applications-with-vue-using-vibe-coding%';
