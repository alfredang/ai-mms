-- 1047: Rename C924
--   "Generative AI for Design Thinking"
--     -> "Generative AI for Agile Design Thinking"
-- SKU unchanged (C924). Content re-based on the WSQ sibling
--   TGS-2024049781 "WSQ - Fast-Track Innovations with Agile Design Thinking
--   and Generative AI (GenAI)"
-- so the non-WSQ short course mirrors the accredited course's agile framing.
--
-- Why the rename matters beyond cosmetics: C688 is ALSO titled "Generative AI
-- for Design Thinking". Moving C924 to the "Agile" variant removes that
-- duplicate-title collision.
--
-- BOTH courses are handled in THIS single file, on purpose. C924 vacates the
-- slug 'generative-ai-for-design-thinking' and C688 immediately claims it; that
-- handover must be atomic. Splitting it across two migration files leaves a
-- window in which a redirect squats the path, and the Catalog URL Rewrites
-- indexer then suffixes the new owner ('...-688.html') instead of granting it
-- the clean path. See section 3 and memory
-- feedback_flat_url_collision_suffix_explosion.
--
-- Surfaces touched:
--   1  name
--   2  meta_title
--   3  url_key + url_path dropped at every scope + explicit 301 for old slug
--   4  short_description  (About This Course prose)
--   5  description        (Course Outline: 4 agile topics + sub-bullets)
--   6  meta_description
--   7  meta_keyword
--   8  image/small_image/thumbnail _label + media-gallery label
--   9  whoshouldattend    (agile/innovation job roles)
--  10  C688 handover: claims the vacated slug, and is re-contented from its own
--      accredited sibling TGS-2026064719 "CASL - Generative AI for Design
--      Thinking" (url_key/url_path, short_description, description, meta_title,
--      meta_description, meta_keyword, whoshouldattend).
--
-- Deliberately NOT touched:
--   - price ($700), duration, sessions -- the course format is unchanged.
--   - `image`/`small_image`/`thumbnail` filesystem paths (file paths, not
--     display text; the storefront renders the R2 `course_image_url` cover).
--   - `course_image_url` -- the branded cover PNG is re-rendered from the new
--     title via the admin cover dialog, NOT via SQL (a stale URL here would
--     404). Re-render after this migration applies.
--   - prerequisite / trainerprofile / venue / additional_note -- generic,
--     tool-neutral, and still accurate for the retitled course.
--   - categories -- C924 already sits in Design Thinking (221), AI Courses
--     (252), GenAI Content Creation (200), Problem Solving (353) and the
--     Generative AI Series (433); the agile reframing does not change fit.
--
-- Idempotent: guarded writes (LOCATE probes / ON DUPLICATE KEY UPDATE /
-- NOT EXISTS), so a re-run converges.
-- Partner-safe: C924 is an SG SKU; @e IS NULL on MY/GH makes every statement
-- a guarded no-op there (never a NULL entity_id INSERT).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C924' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_il     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tl     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------------ 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for Agile Design Thinking'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------------- 2. meta_title
-- Plain title only: MMD_Seotitle appends the brand postfix at render time.
-- The live value baked "| Tertiary Courses Singapore" in, so this is also a
-- double-postfix cleanup.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'Generative AI for Agile Design Thinking'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. url_key + 301
-- Collision check done: no product owns 'generative-ai-for-agile-design-thinking'
-- (only C924 itself owns the old 'generative-ai-for-design-thinking').
-- NOTE: the old slug is deliberately left for C688 to claim in 1048 -- so this
-- migration must run BEFORE 1048, which apply.php guarantees by filename order.
SET @old_slug := 'generative-ai-for-design-thinking';
SET @new_slug := 'generative-ai-for-agile-design-thinking';

-- Remove any is_system = 0 squatter on the new path first: INSERT IGNORE
-- silently no-ops against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@new_slug, '.html') AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = @new_slug
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it; the
-- store-1 row still holds the OLD slug and would shadow the new URL.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- NO 301 is written for C924's old bare slug 'generative-ai-for-design-thinking'.
-- That is deliberate and load-bearing: C688 CLAIMS that exact slug in section 10
-- below (it matches C688's own, unchanged title), so the path must resolve to
-- C688's canonical 200 page -- not 301 away to the agile course.
--
-- Leaving a redirect there would ALSO trigger the flat-url collision-suffix
-- trap: the Catalog URL Rewrites indexer refuses to hand a path to a product
-- while another rewrite squats it, and silently suffixes the new owner instead
-- (observed locally: C688 became 'generative-ai-for-design-thinking-688.html').
-- See memory feedback_flat_url_collision_suffix_explosion.
--
-- Old C924 URLs that are NOT the bare slug (the ~10 category-path variants and
-- the historical 'agile-design-thinking-*' slugs) keep 301ing to the new agile
-- URL via the indexer's own rewrite history -- those are untouched here.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@old_slug, '.html')
   AND product_id = @e AND is_system = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 4. short_description (About)
-- Re-based on TGS-2024049781's About prose, de-WSQ-ed (this is the non-WSQ
-- C-prefix short course: no accreditation, no funding claims in the body).
UPDATE catalog_product_entity_text
   SET value = '<p>Generative AI for Agile Design Thinking equips professionals with the tools and methodologies to drive innovation across their organisation. The course integrates design thinking with agile principles to accelerate product and service development. Participants will learn how to leverage generative AI for rapid prototyping, problem framing, and ideation, while synthesising stakeholder inputs to uncover critical end-user needs.</p>
<p>Through hands-on exercises, participants will lead design thinking projects using project management tools, agile frameworks, and AI-driven techniques. The course also focuses on strategies for scaling innovations, engaging stakeholders, and managing resources efficiently.</p>
<p>By the end of the course, learners will be able to apply agile design thinking methodologies together with generative AI technologies to enhance organisational performance and drive sustained innovation.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- Any store-scoped override would shadow store 0.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 5. description (Outline)
-- Mirrors the four topics of TGS-2024049781. The existing C924 blob uses the
-- <h3> + per-topic <ul> shape (no LSN_DATA JSON comment) -- keep that shape.
-- The WSQ-only assessment/competency rows ("Drivers of organizational growth",
-- "Lead design thinking projects across the organization") are dropped: those
-- are SSG competency statements, not teaching topics for the short course.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Foundations of Design Thinking, Agile and Generative AI for Problem-Solving</h3>
<ul>
<li>What is Design Thinking? Mindsets and Methodologies for Innovation</li>
<li>Product Development through Design Thinking and Agile</li>
<li>How Generative AI Enhances Design Thinking and Agile Processes</li>
<li>Latest Trends in Innovation: Generative AI and Agile Design Thinking</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Problem Framing and Ideation with Design Thinking and Generative AI</h3>
<ul>
<li>Defining the Problem: Understanding the Challenge and Users</li>
<li>Persona Mapping and Empathy: Gathering Deep Insights with GenAI</li>
<li>Ideation and Brainstorming Techniques Enhanced by Generative AI</li>
<li>Prototyping with AI-Driven Tools: Rapid Development and Feedback</li>
<li>Synthesising Information from Different Sources to Understand End-User Needs</li>
<li>Engaging Stakeholders to Uncover Motivations</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Agile Development and AI for Rapid Solution Delivery</h3>
<ul>
<li>Agile Frameworks for Managing Innovation Projects</li>
<li>Converting Ideas into Agile Features, Stories and Tasks with GenAI</li>
<li>Using Generative AI for Faster Iterations and Feedback in Agile Sprints</li>
<li>Agile Tools and Techniques to Scale Solutions Across Teams</li>
<li>Resource Management and Project Management Tools and Techniques</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Scaling and Sustaining Innovations with Agile Design Thinking and Generative AI</h3>
<ul>
<li>Strategies for Scaling Design Thinking and AI Across an Organisation</li>
<li>Engaging Stakeholders and Creating Buy-in for AI-Driven Innovation</li>
<li>Resource Management in Innovation Projects Using AI Tools</li>
<li>Metrics and KPIs for Measuring the Success of Innovation Projects</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 6. meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e, 'Fast-track innovation by combining agile design thinking with generative AI. Frame problems, ideate, prototype and scale solutions faster in this hands-on 2-day course.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ----------------------------------------------------------- 7. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Generative AI, Agile Design Thinking, Innovation, Agile, Rapid Prototyping, Ideation, Design Sprint, Product Development, GenAI'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------- 8. cover alt labels
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for Agile Design Thinking'
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl) AND @e IS NOT NULL;

-- The media-gallery per-image label renders as the zoom gallery img title/alt.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Generative AI for Agile Design Thinking'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------------------- 9. whoshouldattend
-- Re-pointed at the agile/innovation roles the WSQ sibling targets (innovation
-- managers, product developers, agile PMs, UX designers, business analysts).
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Innovation Manager</li>
<li>Product Manager</li>
<li>Product Developer</li>
<li>Agile Project Manager</li>
<li>Scrum Master</li>
<li>Product Owner</li>
<li>UX Designer</li>
<li>Service Designer</li>
<li>Business Analyst</li>
<li>Design Strategist</li>
<li>Digital Transformation Consultant</li>
<li>R&amp;D Specialist</li>
<li>Marketing Strategist</li>
<li>Operations Manager</li>
<li>Entrepreneur</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ==========================================================================
-- 10. C688 handover
-- --------------------------------------------------------------------------
-- C688 "Generative AI for Design Thinking" keeps its TITLE and claims the slug
-- C924 just vacated (its old slug 'design-thinking-with-gen-ai' is a legacy of
-- the pre-rename title "Design Thinking with Gen AI"). Its content is re-based
-- on the accredited sibling TGS-2026064719 "CASL - Generative AI for Design
-- Thinking".
--
-- Deliberately NOT touched for C688:
--   - name -- already correct.
--   - price ($350), duration (7.5), sessions -- format unchanged; the price
--     already matches the CASL full fee.
--   - image paths, image labels, course_image_url -- the cover is already
--     branded with the correct (unchanged) title.
--   - prerequisite / trainerprofile / venue / additional_note.
--   - categories -- C688 already sits in Design Thinking (221), AI Courses
--     (252), Business & Soft Skills (68) and the Generative AI Series (433).
--
-- Funding note: C688 is a non-WSQ C-prefix course and carries NO funding. The
-- existing short_description says so and cross-links the funded alternative;
-- that cross-link is RETAINED, re-pointed at the CASL course (the old link
-- pointed at wsq-design-thinking-course.html).
-- ==========================================================================

SET @e688 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C688' LIMIT 1);
SET @c688_old_slug := 'design-thinking-with-gen-ai';

-- Clear any suffixed url_path the indexer may have written on a previous run
-- ('generative-ai-for-design-thinking-688.html'), plus the stale store-1 row;
-- both would shadow the clean path. Dropped at EVERY scope so the indexer
-- regenerates from url_key.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e688 AND attribute_id = @a_urlp AND @e688 IS NOT NULL;

-- Claim the vacated slug. Guarded-INSERT + UPDATE so a re-run converges.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_urlk, 0, @e688, @old_slug
 WHERE @e688 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e688 AND attribute_id = @a_urlk AND store_id <> 0 AND @e688 IS NOT NULL;

-- Drop any suffixed system rewrite from a previous run so the indexer is free
-- to grant C688 the clean path.
DELETE FROM core_url_rewrite
 WHERE product_id = @e688 AND request_path LIKE CONCAT(@old_slug, '-%') AND @e688 IS NOT NULL;

-- 301 for C688's OWN old bare slug. options = 'RP' makes it a 301 (an empty
-- options column is a 302 and transfers no ranking); written at BOTH scopes
-- per the course-url-change skill.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@old_slug, '.html'), options = 'RP', is_system = 0
 WHERE request_path = CONCAT(@c688_old_slug, '.html') AND store_id IN (0, 1) AND @e688 IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, @e688,
       CONCAT('manual-301-', MD5(CONCAT(@c688_old_slug, '.html')), '-', s.store_id),
       CONCAT(@c688_old_slug, '.html'), CONCAT(@old_slug, '.html'), 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @e688 IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@c688_old_slug, '.html') AND x.store_id = s.store_id);

-- ------------------------------------------ 10a. C688 short_description
UPDATE catalog_product_entity_text
   SET value = '<p>Generative AI for Design Thinking equips participants with the skills to combine human-centred innovation methods with generative AI to solve business challenges more creatively and efficiently. Learners explore how AI tools support every stage of the Design Thinking process, from empathising with users through to prototyping and evaluation.</p>
<p>Through practical exercises, participants use AI to analyse user feedback, develop personas, build empathy maps and identify pain points. They apply prompting techniques for ideation, explore AI-assisted rapid prototyping, and learn to gather feedback and refine solutions iteratively while implementing AI responsibly.</p>
<p>By the end of the course, participants will be able to embed generative AI into each phase of the design process and use practical metrics to measure whether their design ideas deliver the intended outcomes.</p>
<p>Certificate</p>
<p>All participants will receive a Certificate of Completion from Tertiary Courses after achieving at least 75% attendance.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course.</p>
<p>For funding support, please check out the details at <u><a href="https://www.tertiarycourses.com.sg/casl-generative-ai-for-design-thinking.html" rel="noopener noreferrer" target="_blank">CASL - Generative AI for Design Thinking</a></u></p>'
 WHERE entity_id = @e688 AND attribute_id = @a_sdesc AND store_id = 0 AND @e688 IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e688 AND attribute_id = @a_sdesc AND store_id <> 0 AND @e688 IS NOT NULL;

-- ------------------------------------------------- 10b. C688 description
-- The CASL course publishes topic HEADINGS only; the sub-bullets below are
-- derived from its published overview (AI-assisted research, personas/empathy
-- maps, pain points, prompting for ideation, rapid prototyping, responsible AI,
-- iterative refinement, outcome metrics) so the short course still shows a
-- teachable outline rather than four bare headings.
--
-- Shape change: the OLD value used the legacy <!-- LSN_DATA --> JSON comment
-- plus <p><strong>/<p><em> rows. Replaced wholesale with the modern
-- <h3 class="course-topic-h3"> + <ul> shape used by every recent course.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Generative AI Fundamentals for Design Thinking</h3>
<ul>
<li>Core Concepts of Design Thinking in the Age of AI</li>
<li>Traits of a Design Thinker and How AI Augments Creativity</li>
<li>Overview of Generative AI Tools for Human-Centred Design</li>
<li>Writing Effective Prompts for Design Work</li>
<li>Using AI Responsibly in the Design Process</li>
</ul>
<h3 class="course-topic-h3">Topic 2: AI-Assisted User Research and Opportunity Discovery</h3>
<ul>
<li>Analysing User Feedback and Research Data with AI</li>
<li>Developing Personas and Empathy Maps with Generative AI</li>
<li>Identifying User Pain Points and Unmet Needs</li>
<li>Framing the Problem and Defining Design Opportunities</li>
</ul>
<h3 class="course-topic-h3">Topic 3: AI-Powered Ideation, Prototyping and Testing</h3>
<ul>
<li>Prompting Techniques for Idea Generation at Scale</li>
<li>Selecting, Clustering and Scoring Ideas with AI</li>
<li>AI-Assisted Rapid Prototyping and Wireframing</li>
<li>Gathering Feedback and Refining Solutions Iteratively</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Implementing and Measuring AI-Driven Design Solutions</h3>
<ul>
<li>Embedding AI-Driven Design Thinking into Organisational Processes</li>
<li>Communicating Design Outcomes to Stakeholders</li>
<li>Metrics to Measure the Success of Design Ideas</li>
<li>Planning Next Steps for Scaling Design Solutions</li>
</ul>'
 WHERE entity_id = @e688 AND attribute_id = @a_desc AND store_id = 0 AND @e688 IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e688 AND attribute_id = @a_desc AND store_id <> 0 AND @e688 IS NOT NULL;

-- ------------------------------------------------- 10c. C688 meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e688, 'Generative AI for Design Thinking'
 WHERE @e688 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e688 AND attribute_id = @a_mtitle AND store_id <> 0 AND @e688 IS NOT NULL;

-- ------------------------------------------- 10d. C688 meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e688, 'Combine human-centred design thinking with generative AI. Research users, build personas, ideate, prototype and test faster in this hands-on 1-day course.'
 WHERE @e688 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e688 AND attribute_id = @a_mdesc AND store_id <> 0 AND @e688 IS NOT NULL;

-- ----------------------------------------------- 10e. C688 meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Generative AI, Design Thinking, Human-Centred Design, AI Design Thinking Course, Personas, Empathy Map, Rapid Prototyping, Ideation, Innovation'
 WHERE entity_id = @e688 AND attribute_id = @a_mkey AND @e688 IS NOT NULL;

-- -------------------------------------------- 10f. C688 whoshouldattend
-- Re-pointed at the CASL course's published target roles.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Product Manager</li>
<li>UX/UI Designer</li>
<li>Business Strategist</li>
<li>Innovation Consultant</li>
<li>Service Designer</li>
<li>Project Manager</li>
<li>Marketing Manager</li>
<li>Operations Manager</li>
<li>HR Specialist</li>
<li>Business Analyst</li>
<li>Design Strategist</li>
<li>Customer Experience Manager</li>
<li>Human-Centered Designer</li>
<li>Learning Experience Designer</li>
<li>Entrepreneur</li>
</ul>'
 WHERE entity_id = @e688 AND attribute_id = @a_who AND store_id = 0 AND @e688 IS NOT NULL;
