-- 935: TGS-2021008635 — clear the two Vue-specific leaks that 930 missed.
--
-- 930 renamed this course "WSQ - Develop Full Stack Web Applications with Vue
-- Using Vibe Coding" -> "WSQ - AI Vibe Coding for Full Stack Web Applications"
-- and rewrote name / meta_* / url_key / short_description / description /
-- learning-outcomes block / image labels / search redirects.
--
-- A post-deploy leak scan across EVERY text+varchar attribute (not just the
-- ones in the rename checklist) found two more surfaces still selling the
-- course as Vue-specific:
--
--   1. whoshouldattend — the job-role list named "Vue.js Developer",
--      "Mobile App Developer (using Vue Native)", "E-commerce Website
--      Developer (using Vue)", "CMS Developer (integrating with Vue)" and
--      "Digital Product Manager (overseeing Vue projects)". The course is now
--      framework-agnostic AI-assisted full stack, so those five rows are
--      re-pointed at the equivalent framework-neutral role.
--   2. prerequisite — "Minimum Software/Hardware Requirement" listed a single
--      download link to vuejs.org. Replaced with the tools the course actually
--      uses (an AI coding assistant + a code editor + a modern browser).
--      Everything else in that attribute (PWM, Funding Eligibility table with
--      every SkillsFuture/PSEA/SFEC/UTAP deep link, Appeal Process) is left
--      byte-identical — the REPLACE targets only the <ul> holding the Vue link.
--
-- Both statements are targeted REPLACE()s guarded on @e, so they are idempotent
-- (after the first run the old substrings no longer exist) and partner-safe
-- (TGS- SKUs only exist on SG; @e IS NULL elsewhere and the file no-ops).
--
-- Deliberately NOT touched: the `image`/`small_image`/`thumbnail` media path
-- still contains the old slug in its FILENAME. That is a stored media
-- reference, never rendered to a user (the storefront serves the R2 cover via
-- course_image_url, re-rendered under the new title). Renaming the file would
-- break the gallery row for zero user-visible gain.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021008635' LIMIT 1);

SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'whoshouldattend');
SET @a_pre := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'prerequisite');

-- ------------------------------------------------- 1. whoshouldattend roles
UPDATE catalog_product_entity_text
SET value = REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(value,
              '<li>Vue.js Developer</li>',
              '<li>Front-End Framework Developer</li>'),
              '<li>Mobile App Developer (using Vue Native)</li>',
              '<li>Mobile App Developer</li>'),
              '<li>E-commerce Website Developer (using Vue)</li>',
              '<li>E-commerce Website Developer</li>'),
              '<li>CMS Developer (integrating with Vue)</li>',
              '<li>CMS Developer</li>'),
              '<li>Digital Product Manager (overseeing Vue projects).</li>',
              '<li>Digital Product Manager.</li>')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_wsa;

-- --------------------------------------- 2. prerequisite software requirement
-- Targets ONLY the <ul> that holds the vuejs.org download link. The rest of the
-- attribute (funding tables, SkillsFuture/PSEA/SFEC/UTAP deep links, PWM,
-- Appeal Process) is untouched.
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      '<li><a href="https://vuejs.org/v2/guide/installation.html" target="_blank"><span style="text-decoration: underline;">Vue.js</span></a></li>',
      '<li><a href="https://claude.com/product/claude-code" target="_blank"><span style="text-decoration: underline;">An AI coding assistant</span></a></li>\n<li><a href="https://code.visualstudio.com/download" target="_blank"><span style="text-decoration: underline;">Visual Studio Code</span></a></li>\n<li>A modern web browser (Chrome or Edge)</li>')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_pre;
