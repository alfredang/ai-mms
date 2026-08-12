-- 931: Rename TGS-2026064719
--        "CASL - Design Thinking Course for Businesses"
--      -> "CASL - Generative AI for Design Thinking"
--
-- Course code (SKU) is UNCHANGED — TGS-2026064719 stays, so the per-SKU
-- cms_block identifiers, brochure PDF path, funding deep links and the
-- Funding Validity window (30 Jun 2026 – 29 Jun 2028) all stay put.
-- The CASL name prefix is retained (CASL rules: CASL badge tag, no OpenCerts
-- bullet, cover renders without the prefix). Follows the 904/929/930 shape.
--
-- NOTE: the plain title intentionally matches the separate non-funded course
-- C924 "Generative AI for Design Thinking" (generative-ai-for-design-thinking
-- .html) — this is the funded CASL counterpart, slugged with the casl- prefix
-- so the two URLs never collide.
--
-- Scope of this file:
--   1. name -> "CASL - Generative AI for Design Thinking";
--      image/gallery labels -> plain title (alt text mirrors the cover,
--      which strips the prefix)
--   2. course_image_url -> fresh cover rendered on prod 2026-08-12 (CASL +
--      funding chips, new title)
--   3. meta_title/meta_description/meta_keyword refreshed. meta_title omits
--      BOTH the funding token and the brand suffix — MMD_Seotitle composes
--      the <title> at render time (prefix + "| Tertiary Courses Singapore")
--   4. url_key -> casl-generative-ai-for-design-thinking; url_path deleted at
--      every scope so the Catalog URL Rewrites indexer regenerates it
--   5. 301 from the old bare slug; the ~56 legacy alias rewrites (old WSQ
--      slugs wsq-design-thinking-course[-for-businesses] etc.) that 301 into
--      the old slug are repointed straight at the new one (no 301 chains)
--   6. short_description -> the new "About This Course" copy (4 paragraphs;
--      full replace — sections live in per-SKU cms_blocks since 885-890)
--   7. description (Course Outline) -> the 4 new AI-focused topics, keeping
--      the existing <h3 class="course-topic-h3"> markup shape
--   8. search-term redirects retargeted off the old slug (~50 live SG rows)
--
-- NOT touched (verified against prod 2026-08-12):
--   - learning_outcomes cms_block — LO1-LO6 already match the requested text
--   - skills_framework block — the accredited TSC (DSN-ACE-3014-1.1) is
--     unchanged by this rename
--   - certification / funding_and_grant / funding_validity blocks +
--     news_from/to_date — SKU and funding window unchanged
--   - trainerprofile — mentions "design thinking" only generically; the old
--     course title never appears (LOCATE = 0 on every text attr except sdesc)
--
-- Partner-safe: TGS- SKUs only exist on SG; on MY/GH @e IS NULL and the file
-- no-ops (rewrite/search statements additionally guarded on the SG store /
-- full SG domain). Idempotent — re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064719' LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------------------------- 1. name + labels
UPDATE catalog_product_entity_varchar SET value = 'CASL - Generative AI for Design Thinking'
  WHERE entity_id = @e AND attribute_id = @a_name AND store_id = 0;

-- Labels carry the plain title (no "CASL -" prefix): they are alt text on the
-- course cover, which itself renders without the prefix.
UPDATE catalog_product_entity_varchar SET value = 'Generative AI for Design Thinking'
  WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_til) AND store_id = 0;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'Generative AI for Design Thinking'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. fresh cover (R2)
UPDATE catalog_product_entity_varchar
  SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064719-20260812-150859.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu;

-- ------------------------------------------------------------------ 3. SEO meta
-- Plain title only — MMD_Seotitle prepends the funding token and appends the
-- brand postfix at render time; baking either is the 853 anti-pattern.
UPDATE catalog_product_entity_varchar SET value = 'Generative AI for Design Thinking Course'
  WHERE entity_id = @e AND attribute_id = @a_mt;

UPDATE catalog_product_entity_varchar SET value = 'Master Generative AI for Design Thinking in Singapore. Combine human-centred innovation with generative AI to research users, ideate, prototype and test business solutions. Enjoy up to 70% CASL funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md;

UPDATE catalog_product_entity_text SET value = 'Generative AI, Design Thinking, AI-Powered Ideation, AI Prototyping, Business Innovation, CASL, User-Centered Design, Problem Solving'
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- ------------------------------------------------------------- 4. url_key + url_path
UPDATE catalog_product_entity_varchar SET value = 'casl-generative-ai-for-design-thinking'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 5. 301s off the old slug
-- Repoint the existing bare-slug rewrite row (the system row still holds the
-- old request_path until reindex) and force it permanent + manual; create the
-- row where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'casl-generative-ai-for-design-thinking.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'casl-design-thinking-course-for-businesses.html'
    AND store_id IN (0, 1);
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('casl-design-thinking-course-for-businesses.html'), '-', s.store_id),
       'casl-design-thinking-course-for-businesses.html',
       'casl-generative-ai-for-design-thinking.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'casl-design-thinking-course-for-businesses.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug (56 rows: the historical
-- wsq-design-thinking-course / wsq-design-thinking-course-for-businesses /
-- wsq-design-thinking-enterprises / wsq-cyber-security-awareness-course-1076
-- paths, bare and category-prefixed) — repoint straight at the new slug so
-- inbound links take one hop, not a chain. REPLACE also fixes the
-- category-prefixed targets; the category paths in those targets all belong
-- to categories this product is still assigned to.
UPDATE core_url_rewrite
  SET target_path = REPLACE(target_path,
      'casl-design-thinking-course-for-businesses.html',
      'casl-generative-ai-for-design-thinking.html')
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%casl-design-thinking-course-for-businesses.html'
    AND request_path <> 'casl-design-thinking-course-for-businesses.html';

-- ---------------------------------------- 6. short_description (About This Course)
-- Full replace: since the 885-890 extraction this course's short_description
-- holds only the intro prose (Brochure / Certification / Skills Framework /
-- Funding sections live in per-SKU cms_blocks).
UPDATE catalog_product_entity_text SET value = '<p>Generative AI for Design Thinking equips participants with the skills to combine human-centred innovation methods with generative AI to solve business challenges more creatively and efficiently. Participants will learn how to use AI tools throughout the Design Thinking process—from empathising with users and defining problems to generating ideas, developing prototypes and evaluating solutions.</p>
<p>Through practical exercises and business case studies, learners will use generative AI to analyse user feedback, develop personas, create empathy maps, identify customer pain points and formulate clear problem statements. They will also apply effective prompting techniques to explore diverse ideas, compare potential solutions and uncover new opportunities for products, services and process improvements.</p>
<p>The course introduces AI-assisted rapid prototyping for creating concepts, user journeys, visual mock-ups and presentation materials. Participants will learn to gather feedback, test assumptions and iteratively refine solutions while considering data privacy, bias, accuracy and responsible AI use.</p>
<p>By the end of the course, participants will be able to integrate generative AI into Design Thinking workflows, accelerate innovation and develop user-centred solutions that improve customer experience, team collaboration and business performance.</p>'
  WHERE entity_id = @e AND attribute_id = @a_sd;

-- ------------------------------------------------ 7. description (Course Outline)
-- Same markup shape as the current value (<h3 class="course-topic-h3"> per
-- topic). The requested outline carries topic titles only — no sub-bullets.
UPDATE catalog_product_entity_text SET value = '<h3 class="course-topic-h3">Topic 1: Generative AI Fundamentals for Design Thinking</h3>
<h3 class="course-topic-h3">Topic 2: AI-Assisted User Research and Opportunity Discovery</h3>
<h3 class="course-topic-h3">Topic 3: AI-Powered Ideation, Prototyping and Testing</h3>
<h3 class="course-topic-h3">Topic 4: Implementing and Measuring AI-Driven Design Solutions</h3>'
  WHERE entity_id = @e AND attribute_id = @a_desc;

-- --------------------------------------- 8. retarget search-term redirects
-- ~50 live SG rows point at the old slug (incl. the old WSQ title queries and
-- the legacy course code TGS-2020503676). REPLACE on the full SG-domain URL —
-- partner-safe. Search redirects are DATA — this file is ALSO applied live on
-- prod (see memory feedback_search_redirects_always_apply_live).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect,
      'https://www.tertiarycourses.com.sg/casl-design-thinking-course-for-businesses.html',
      'https://www.tertiarycourses.com.sg/casl-generative-ai-for-design-thinking.html')
  WHERE redirect LIKE '%casl-design-thinking-course-for-businesses.html%';
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/casl-generative-ai-for-design-thinking.html'
  WHERE @sg = 1 AND query_text = 'TGS-2026064719';
