-- 933: Repurpose TGS-2020505925 (SKU unchanged)
--   "WSQ - Image and Video Processing with OpenCV"
--   -> "WSQ - Generative AI for Image and Video Creation"
--
-- Course code stays TGS-2020505925 so every SkillsFuture / SFC / SFEC / PSEA /
-- UTAP deep link keyed on the course code remains valid, and the funding badge
-- tags (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll, MCES) and
-- funding_and_grant block stay correct untouched. Follows the 855/930/931
-- TGS- rename playbook.
--
-- Surfaces changed here:
--   1. name / image labels / media-gallery label
--   2. url_key + url_path purge at every scope + 301 from the old bare slug +
--      legacy alias repoint (no collision: no other product owns the new slug)
--   3. meta_title / meta_description / meta_keyword
--   4. short_description (About This Course) - full replace, and the OpenCV
--      "Course Material" Raspberry Pi kit block is dropped (a generative-AI
--      creation course loans no RPi hardware)
--   5. description (Course Outline) -> the 5 new topics, same
--      <h3 class="course-topic-h3"> markup shape as the current value
--   6. learning_outcomes cms_block -> the 6 new LOs
--   7. whoshouldattend -> creative/marketing roles (was CV-engineer roles)
--   8. prerequisite -> the OpenCV install links replaced with generative-AI
--      tool access; every WSQ funding/appeal section left byte-identical
--   9. trainerprofile -> the three "In his OpenCV training..." teaching
--      paragraphs retargeted; career-history facts left alone
--  10. categories: drop Computer Vision / Robotics & IoT / Raspberry Pi;
--      add the GenAI placements mirrored from sibling TGS-2024043855
--  11. search-term redirects: OpenCV-intent terms are NOT sent here (this is no
--      longer a computer-vision course) - only the bare course code follows the
--      renamed page. No live SG row currently targets the old slug.
--
-- meta_title deliberately omits "WSQ" and the brand suffix: MMD_Seotitle
-- composes the <title> at render time (Block/Html/Head.php::_fundingPrefix).
--
-- NOT changed: SKU, funding_and_grant / funding-validity, certification block,
-- brochure block (SKU-keyed), skills_framework TSC (Computer Vision Technology
-- ICT-DIT-4022-1.1 remains the registered competency standard for this TGS
-- code - changing it is an SSG registration matter, not a content edit),
-- badge tags, price, assessment_methods.
--
-- The cover PNG (course_image_url) still bakes the old title and the brochure
-- PDF still describes OpenCV - regenerate both after this applies.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement no-ops. Idempotent - re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505925' LIMIT 1);

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_wsa   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_pre   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

-- ----------------------------------------------------------- 1. name + labels
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'WSQ - Generative AI for Image and Video Creation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Labels are alt text on the cover, which strips the "WSQ - " prefix itself
-- (CourseImage/Model/Cover.php::cleanTitle), so they carry the plain title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Generative AI for Image and Video Creation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Generative AI for Image and Video Creation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Generative AI for Image and Video Creation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'Generative AI for Image and Video Creation'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- -------------------------------------------------------------------- 2. URL
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_uk, 0, @e, 'wsq-generative-ai-for-image-and-video-creation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear store-scoped overrides so store 0 wins for every renamed varchar.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_uk, @a_mt, @a_md, @a_il, @a_sil, @a_til);

-- url_path at EVERY scope (store 0 + 1 rows exist) - the URL indexer regenerates.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- 301 from the old bare slug. Drop any WRONG-target non-system squatter first
-- (647: INSERT against a stale row silently no-ops and the 301 never ships).
DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path = 'wsq-image-and-video-processing-with-opencv.html'
  AND target_path <> 'wsq-generative-ai-for-image-and-video-creation.html'
  AND @e IS NOT NULL;

-- Guarded against ANY row on the request_path: pre-reindex the system row still
-- holds it (the indexer's rewrite history takes over at reindex); post-reindex
-- this fills the bare-slug 301 if the indexer didn't.
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2020505925_opencv_', s.store_id),
       'wsq-image-and-video-processing-with-opencv.html',
       'wsq-generative-ai-for-image-and-video-creation.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'wsq-image-and-video-processing-with-opencv.html');

-- Repoint legacy alias rewrites (older nicf-*/wsq-* slugs for this course) so
-- they don't 301-chain through the retired slug. Category-prefixed targets keep
-- their prefix - only the product filename changes.
UPDATE core_url_rewrite
SET target_path = REPLACE(target_path,
      'wsq-image-and-video-processing-with-opencv.html',
      'wsq-generative-ai-for-image-and-video-creation.html')
WHERE is_system = 0 AND @e IS NOT NULL
  AND target_path LIKE '%wsq-image-and-video-processing-with-opencv.html';

-- --------------------------------------------------------------- 3. SEO meta
-- Plain title only: MMD_Seotitle prepends the funding prefix and appends the
-- brand postfix at render time (baking either duplicates them).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for Image and Video Creation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description feeds meta/og/twitter description AND the JSON-LD description.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Create, edit and enhance images and videos with generative AI. Learn prompt engineering for visuals, image-to-image editing, style control and AI video creation. Up to 70% WSQ funding subsidy.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI for Image and Video Creation, AI image generation, AI video creation, prompt engineering for visuals, image editing with AI, AI animation, visual content creation, WSQ Funding, generative AI course Singapore' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_mk, @a_sdesc, @a_desc);

-- ---------------------------------------------- 4. About This Course (sdesc)
-- Full replace. The retired value ended with a "Course Material" section that
-- loaned a Raspberry Pi 4 kit for the OpenCV labs - deliberately dropped, this
-- course has no hardware component.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @e, '<p>Generative AI for Image and Video Creation equips participants with practical skills to create, edit, and enhance visual content using modern generative AI tools. Learners will explore how text prompts, reference images, storyboards, and creative briefs can be transformed into high-quality images, animations, and videos for marketing, education, social media, entertainment, and business communication.</p>
<p>Through hands-on activities, participants will learn prompt engineering for visual generation, image-to-image transformation, style control, inpainting, background replacement, visual effects, and image enhancement. They will also develop video concepts, scripts, scenes, camera directions, character actions, and transitions before generating and assembling AI-powered video content.</p>
<p>The course covers creative workflow planning, visual consistency, audio and caption integration, iterative refinement, and content optimization for different platforms and audiences. Participants will learn to evaluate generated outputs for quality, accuracy, brand alignment, bias, copyright concerns, and responsible AI use. By the end of the course, learners will be able to plan and produce engaging image and video content efficiently using end-to-end generative AI workflows.</p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- 5. Course Outline (description)
-- Same markup shape as the current value (h3.course-topic-h3 per topic). The
-- admin supplied topic titles only - no sub-bullets invented.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Generative AI Fundamentals for Image and Video Creation</h3>
<h3 class="course-topic-h3">Topic 2: AI Image Generation, Editing and Visual Enhancement</h3>
<h3 class="course-topic-h3">Topic 3: AI-Based Visual Features, Styles and Consistency</h3>
<h3 class="course-topic-h3">Topic 4: Generative AI Video Creation, Animation and Editing</h3>
<h3 class="course-topic-h3">Topic 5: Evaluating Cloud and Edge AI Creative Workflows</h3>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------ 6. What You'll Learn (learning_outcomes block)
-- Keeps the existing &nbsp;-after-LOn shape of the block written by 885.
UPDATE cms_block SET content = '<p>By end of the course, learners should be able to</p>
<ul>
<li>LO1: Understand basic vision systems concepts and applications</li>
<li>LO2:&nbsp;Apply image processing</li>
<li>LO3:&nbsp;Implement feature extraction</li>
<li>LO4:&nbsp;Apply machine learning based computer vision methods</li>
<li>LO5:&nbsp;Implement video analytics algorithms</li>
<li>LO6:&nbsp;Evaluate edge vs cloud-based computer vision systems</li>
</ul>'
  WHERE identifier = 'course_TGS-2020505925_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. Who Should Attend
-- Was a computer-vision engineering role list; the course now targets creative,
-- marketing and content roles.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_wsa, 0, @e, '<ul>
<li>Content Creator</li>
<li>Digital Marketer</li>
<li>Social Media Manager</li>
<li>Graphic Designer</li>
<li>Video Editor</li>
<li>Multimedia Producer</li>
<li>Marketing Communications Executive</li>
<li>Brand and Creative Strategist</li>
<li>Instructional Designer</li>
<li>E-Learning Content Developer</li>
<li>Product Marketing Executive</li>
<li>Corporate Communications Officer</li>
<li>Advertising Creative</li>
<li>Small Business Owner</li>
<li>Entrepreneur</li>
</ul>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_wsa;

-- --------------------------------------- 8. Prerequisite - software block only
-- Targeted REPLACE on the OpenCV install links; every other section of this
-- 12KB blob (entry requirements, PWM, funding eligibility table, SkillsFuture /
-- UTAP steps, appeal process) is left byte-identical.
-- NOTE: this blob uses CRLF line endings, so a multi-line SQL literal will NOT
-- match. Each <li> is replaced on its own single line instead - line-ending
-- agnostic, and each substring is unique within the blob.
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
  '<li><span style="text-decoration: underline;"><a href="https://docs.opencv.org/4.x/d3/d52/tutorial_windows_install.html" target="_blank">OpenCV (Windows)</a></span></li>',
  '<li>A modern web browser (Google Chrome or Microsoft Edge recommended)</li>')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_pre;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
  '<li><span style="text-decoration: underline;"><a href="https://docs.opencv.org/4.x/d0/db2/tutorial_macos_install.html" target="_blank">OpenCV (MacOS)</a></span></li>',
  '<li>Accounts for the generative AI image and video tools used in class (free tiers are sufficient; sign-up instructions are provided before the course)</li>')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_pre;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
  '<p>You can download and install the following software:</p>',
  '<p>You will need access to the following:</p>')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_pre;

-- ------------------------------------------ 9. Trainer bios (course mentions)
-- Each bio's SECOND paragraph is the "what I teach on this course" claim; the
-- first paragraph is career history and stays untouched. Byte-probed against
-- the current values - each REPLACE matches exactly once.
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
  'In his OpenCV training, Richard focuses on teaching learners the foundations of image and video processing using Python. His sessions cover image manipulation, object detection, facial recognition, and real-time video analysis, ensuring participants gain both conceptual and practical knowledge. By combining decades of technical expertise with applied teaching, Richard equips learners to build their own computer vision applications using OpenCV.',
  'In his generative AI training, Richard focuses on teaching learners how to turn prompts, reference images, and creative briefs into finished visual content. His sessions cover AI image generation, image-to-image editing, style and consistency control, and AI-assisted video creation, ensuring participants gain both conceptual and practical knowledge. By combining decades of technical expertise with applied teaching, Richard equips learners to build their own end-to-end generative AI creative workflows.')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
  'In his OpenCV courses, Shawn emphasizes practical, beginner-friendly projects in image and video processing. His training covers integrating OpenCV with IoT and automation systems, enabling learners to apply computer vision in real-world scenarios such as smart monitoring and image-based sensing. With his strong blend of technical expertise and industry leadership, Shawn helps participants explore OpenCV as a powerful tool for business and innovation.',
  'In his generative AI courses, Shawn emphasizes practical, beginner-friendly projects in AI image and video creation. His training covers building repeatable creative workflows and integrating AI-generated visuals into marketing, training, and business communication, enabling learners to apply generative AI in real-world scenarios. With his strong blend of technical expertise and industry leadership, Shawn helps participants explore generative AI as a powerful tool for business and innovation.')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
  'In his OpenCV training, Woei Ming focuses on bridging computer vision with AI and data science applications. His sessions introduce learners to image filtering, feature extraction, and real-time video analysis, with applied examples in manufacturing and automation. By integrating academic research with industry use cases, he ensures learners acquire both the technical skills and applied insights to leverage OpenCV effectively in real-world problem-solving.',
  'In his generative AI training, Woei Ming focuses on bridging AI-generated visuals with practical business and data storytelling applications. His sessions introduce learners to prompt engineering for images, visual style and brand consistency, and AI video generation, with applied examples in product, training, and campaign content. By integrating academic research with industry use cases, he ensures learners acquire both the technical skills and applied insights to leverage generative AI effectively in real-world problem-solving.')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp;

-- ------------------------------------------------------------- 10. Categories
-- Resolve BY NAME (ids differ per instance). Drop the computer-vision/hardware
-- placements; add the GenAI placements mirrored from the closest sibling,
-- TGS-2024043855 "WSQ - Creating Engaging Videos with Generative AI".
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.store_id = 0
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE cp.product_id = @e AND @e IS NOT NULL
    AND v.value IN ('Computer Vision', 'Robotics & IoT', 'Raspberry Pi', 'WSQ Mfg & Green Courses');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE v.store_id = 0 AND @e IS NOT NULL
    AND v.value IN ('Media & Design', 'GenAI Video Creation', 'WSQ Generative AI Courses',
                    'Generative AI Series', 'WSQ Graphics Design & Media Courses');

-- --------------------------------------------------- 11. Search-term redirects
-- No live SG row targets the old slug today, and the ~30 OpenCV-intent terms
-- (opencv, python opencv, "NICF - Image and Video Processing with OpenCV", ...)
-- have redirect IS NULL. They are deliberately LEFT NULL: this page no longer
-- teaches OpenCV, so pointing computer-vision searches at it would be a wrong
-- redirect (see memory feedback_search_redirect_guard_skips_wrong_targets).
-- Only the bare course code follows the renamed page.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-image-and-video-creation.html',
      is_processed = 1
  WHERE query_text = 'TGS-2020505925' AND @e IS NOT NULL;

-- Belt-and-braces for any row that DOES point at the retired slug (prod may
-- differ from the local clone - search redirects are data, applied live too).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect,
        'wsq-image-and-video-processing-with-opencv.html',
        'wsq-generative-ai-for-image-and-video-creation.html'),
      is_processed = 1
  WHERE @e IS NOT NULL
    AND redirect LIKE '%wsq-image-and-video-processing-with-opencv.html%';
