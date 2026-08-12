-- 929: Rename TGS-2021002504
--        "WSQ - Vibe Coding for Agentic AI Workflows and Responsive Web UI"
--      -> "WSQ - AI Vibe Coding for UI/UX"
--
-- Course code (SKU) is UNCHANGED — TGS-2021002504 stays, so every SkillsFuture /
-- SFEC / SFC / PSEA deep link keyed on the course code remains correct and no
-- funding content is touched. Follows the 851 + 853 + 855 playbook for TGS- renames.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> wsq-ai-vibe-coding-for-ui-ux ; url_path deleted at every scope
--      so the Catalog URL Rewrites indexer regenerates it
--   3. explicit 301 from the old bare slug (the indexer auto-301s the category
--      paths for this product; the bare path is belt-and-braces — see 647/851)
--   4. meta_keyword refreshed to lead with the new course name
--   5. media gallery per-image label
--   6. search-term redirect for the old-title search query (empty-only guard)
--
-- meta_title deliberately omits BOTH the leading "WSQ" and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending "WSQ funded" for any SG TGS- SKU and appending the
-- brand postfix (Block/Html/Head.php). Baking either in yields the duplicated
-- "WSQ funded WSQ ..." tag that 853 had to clean up on TGS-2024045797.
--
-- NOT rewritten (already verbatim-correct against the requested content):
--   - description (Course Outline Topics 1-4)
--   - short_description (the three "About This Course" paragraphs)
--   - cms_block course_TGS-2021002504_learning_outcomes (LO1-LO4)
--   - cms_block course_TGS-2021002504_brochure (title carries the SKU only)
--   - trainerprofile (no trainer bio quotes the course title — checked)
--
-- The cover PNG needs no code change: MMD_CourseImage strips a leading "WSQ -"
-- before rendering (Model/Cover.php::cleanTitle), so the image will show
-- "AI Vibe Coding for UI/UX". The existing PNG still bakes the old long title —
-- regenerate the cover from the admin after this applies.
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops). Idempotent — re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021002504' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - AI Vibe Coding for UI/UX' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No "WSQ" token and no brand suffix — MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI Vibe Coding for UI/UX' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI Vibe Coding for UI/UX training in Singapore. Vibe code responsive web UIs with agentic AI tools like Claude Code and Google AI Studio — GUI components, interactivity and single-page apps. Up to 70% WSQ funding.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-ai-vibe-coding-for-ui-ux' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ -" prefix) — they are alt text on
-- the course cover, which itself renders without the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI Vibe Coding for UI/UX' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI Vibe Coding for UI/UX' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI Vibe Coding for UI/UX' FROM dual WHERE @e IS NOT NULL
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
  AND request_path = 'wsq-vibe-coding-for-agentic-ai-workflows-and-responsive-web-ui.html'
  AND @e IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2021002504_old_', s.store_id),
       'wsq-vibe-coding-for-agentic-ai-workflows-and-responsive-web-ui.html',
       'wsq-ai-vibe-coding-for-ui-ux.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'wsq-vibe-coding-for-agentic-ai-workflows-and-responsive-web-ui.html'
      AND c.is_system = 1);

-- ------------------------------------------------------------- 4. meta_keyword
-- Lead with the new course name; the syllabus (agentic AI + responsive UI) is
-- unchanged so the rest of the phrase set stays accurate.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI vibe coding course, vibe coding UI UX, WSQ vibe coding course, agentic AI web development, responsive web UI design, AI-assisted coding Singapore, Claude Code training, Google AI Studio course, GUI component design, single page web application, prompt-driven development, AI agent workflows, WSQ UI UX course, SkillsFuture vibe coding, AI web design course' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------- 5. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Vibe Coding for UI/UX'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------- 6. search-term redirect for old title
-- After the rename, an on-site search for the OLD title no longer matches the
-- catalog name, so point it at the new URL. Empty-only guard: never overwrite an
-- existing intentional redirect. Guarded on @e so it no-ops on partner DBs.
-- (No existing catalogsearch_query.redirect rows target the old slug — checked;
-- also applied live on prod per feedback_search_redirects_always_apply_live.)
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-ui-ux.html',
    is_processed = 1
WHERE @e IS NOT NULL
  AND query_text = 'Vibe Coding for Agentic AI Workflows and Responsive Web UI'
  AND (redirect IS NULL OR redirect = '');

-- Belt-and-braces: retarget any live rows that DO point at the old slug (prod
-- rows can postdate the local snapshot).
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-ui-ux.html',
    is_processed = 1
WHERE @e IS NOT NULL
  AND redirect LIKE '%wsq-vibe-coding-for-agentic-ai-workflows-and-responsive-web-ui%';
