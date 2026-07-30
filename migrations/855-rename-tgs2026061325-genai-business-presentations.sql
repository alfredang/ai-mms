-- 855: Rename TGS-2026061325
--        "WSQ - Designing and Delivering Impactful Business Presentations Using AI"
--      -> "WSQ - Generative AI for Business Presentations"
--
-- Course code (SKU) is UNCHANGED — TGS-2026061325 stays, so every SkillsFuture /
-- SFEC / SFC / PSEA deep link in short_description remains correct and no funding
-- content is touched. Follows the 851 + 853 playbook for TGS- renames.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> wsq-generative-ai-for-business-presentations ; url_path deleted
--      at every scope so the Catalog URL Rewrites indexer regenerates it
--   3. explicit 301 from the old bare slug (the indexer auto-301s the ~20 category
--      paths for this product, but the bare path is belt-and-braces — see 647/851)
--   4. short_description: the two intro paragraphs ("About This Course") are
--      replaced with the three supplied paragraphs; the tail from
--      "<h2>Course Brochure</h2>" onward is spliced byte-identically so Brochure /
--      Skills Framework (TAC-BIN-5077-1.1) / Certification / WSQ Funding survive
--      untouched
--   5. media gallery per-image label
--   6. brochure CMS block title
--   7. trainerprofile — the bio's closing line quotes the course by name
--      ("... the WSQ – Designing and Delivering Impactful Business Presentations
--      Using AI programme"), so it has to track the rename (same trap 854 caught
--      on TGS-2024045797)
--   8. search-term redirects retargeted off the old slug
--
-- meta_title deliberately omits BOTH the leading "WSQ" and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending "WSQ funded" for any SG TGS- SKU and appending the
-- brand postfix (Block/Html/Head.php). Baking either in yields the duplicated
-- "WSQ funded WSQ ..." tag that 853 had to clean up on TGS-2024045797.
--
-- NOT rewritten (already verbatim-correct against the requested content):
--   - description (Course Outline LU1-LU4 + its LSN_DATA JSON header)
--   - cms_block course_TGS-2026061325_learning_outcomes (LO1-LO4)
--
-- The cover PNG needs no code change: MMD_CourseImage strips a leading "WSQ -"
-- before rendering (Model/Cover.php::cleanTitle line 109), so the image shows
-- "Generative AI for Business Presentations". The existing PNG still bakes the
-- old long title — regenerate the cover from the admin after this applies.
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops). Idempotent — re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061325' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - Generative AI for Business Presentations' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No "WSQ" token and no brand suffix — MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'Generative AI for Business Presentations' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'Generative AI for Business Presentations training in Singapore. Use Gamma, Napkin, Microsoft 365 Copilot and Google Gemini to plan, design and deliver AI-powered slides, videos and demos for any business audience. Up to 70% WSQ funding.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-generative-ai-for-business-presentations' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ -" prefix) — they are alt text on
-- the course cover, which itself renders without the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'Generative AI for Business Presentations' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'Generative AI for Business Presentations' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'Generative AI for Business Presentations' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
-- (181 backfilled per-store meta_title for the retired MY/GH/NG/BT/IN stores
-- carrying the OLD title — those rows would otherwise shadow the rename.)
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
  AND request_path = 'wsq-designing-and-delivering-impactful-business-presentations-using-ai.html'
  AND @e IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2026061325_old_', s.store_id),
       'wsq-designing-and-delivering-impactful-business-presentations-using-ai.html',
       'wsq-generative-ai-for-business-presentations.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'wsq-designing-and-delivering-impactful-business-presentations-using-ai.html'
      AND c.is_system = 1);

-- ------------------------------------------ 4. short_description intro rewrite
-- Splice: new "About This Course" paragraphs + everything from Course Brochure
-- onward preserved byte-for-byte (Skills Framework, Certification, WSQ Funding,
-- and every SkillsFuture/SFEC/SFC/PSEA deep link keyed on the unchanged SKU).
UPDATE catalog_product_entity_text
SET value = CONCAT('<p>This course equips learners with the skills to design, deliver, and enhance business presentations using cutting-edge Generative AI tools such as Gamma, Napkin, Microsoft 365 Copilot and Google Gemini Plus. Participants will gain the ability to define clear objectives that align with organisational goals, choose the most effective presentation formats, and produce AI-powered materials such as slides, videos, and demonstrations tailored to diverse audience needs. A strong focus is placed on engaging and influencing business audiences through customised messaging and interactive strategies, along with techniques for managing discussions and negotiations confidently. Learners will also develop habits of continuous improvement to strengthen their overall business communication effectiveness.</p>\n<p>In today&rsquo;s rapidly changing corporate landscape, effective business communication is essential, and the integration of Generative AI into presentation delivery is becoming a major competitive advantage. This course is especially valuable for professionals across industries where stakeholder engagement, persuasive messaging, and the strategic use of technology are key to success. By completing this course, learners enhance their career potential, preparing for roles that demand strong communication abilities and AI fluency&mdash;skills that are increasingly essential for leadership, client relations, and strategic functions. It opens pathways for career growth in business development, consulting, and management.</p>\n<p>Designed for intermediate to advanced learners, the course is ideal for those with a basic foundation in business communication who want to advance their presentation skills through the use of Generative AI.</p>\n',
                   SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
WHERE entity_id = @e AND @e IS NOT NULL
  AND attribute_id = @a_sd
  AND LOCATE('<h2>Course Brochure</h2>', value) > 0
  AND LOCATE('cutting-edge Generative AI tools', value) = 0;

-- meta_keyword: lead with the new course name; the rest of the phrase set is
-- still accurate for the (unchanged) syllabus.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'generative AI for business presentations, WSQ AI presentation course, AI presentation tools, Gamma AI presentation, Napkin AI, Microsoft 365 Copilot presentations, Google Gemini presentations, business presentation skills, persuasive presentations, stakeholder communication, AI-enhanced business communication, WSQ business communication course' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------- 5. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Generative AI for Business Presentations'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------------ 6. brochure CMS block
-- Title-only text fix; the PDF path is keyed on the unchanged SKU.
UPDATE cms_block
SET title = 'Course Brochure - TGS-2026061325'
WHERE identifier = 'course_TGS-2026061325_brochure';

-- ------------------------------------------- 7. trainer bio quotes the title
-- The bio closes with "... an ideal facilitator for the WSQ &ndash; Designing and
-- Delivering Impactful Business Presentations Using AI programme." The REPLACE
-- targets the title text only, leaving the &ndash; entity and surrounding prose
-- untouched. Idempotent (the old string is gone after the first run).
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Designing and Delivering Impactful Business Presentations Using AI',
      'Generative AI for Business Presentations')
WHERE entity_id = @e AND @e IS NOT NULL
  AND attribute_id = (SELECT attribute_id FROM eav_attribute
                      WHERE entity_type_id = @etid AND attribute_code = 'trainerprofile');

-- --------------------------------------- 8. retarget search-term redirects
-- 189 / 630 / 851 shipped redirects pointing at the OLD slug. Those files never
-- re-run on prod, so the live rows must be remapped here (matched by LIKE on the
-- target, so course-code terms and title-phrase terms are all caught).
-- NOTE: search redirects are DATA — a shipped migration alone does not fix an
-- already-populated prod row on a DB whose ledger has moved past this file, so
-- this was ALSO applied live on prod (see memory
-- feedback_search_redirects_always_apply_live).
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-business-presentations.html',
    is_processed = 1
WHERE store_id = 1
  AND redirect LIKE '%wsq-designing-and-delivering-impactful-business-presentations-using-ai%';
