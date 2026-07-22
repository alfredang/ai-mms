-- 705: Repurpose WSQ course TGS-2023036657
--   "WSQ - TikTok Marketing: Turning Engagement into Leads"
--   -> "WSQ - Agentic AI for TikTok Marketing"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.
-- Trainer bios untouched: no course-title quotes; TikTok-marketing expertise
-- copy remains accurate for the new identity.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036657');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- Name + labels + cover
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Agentic AI for TikTok Marketing'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036657-20260722-165433.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - Agentic AI for TikTok Marketing'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'wsq-agentic-ai-for-tiktok-marketing'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'WSQ Agentic AI for TikTok Marketing | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Plan, create, and automate TikTok marketing with AI agents: content creation, campaign automation, and performance analytics. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ TikTok marketing course, agentic AI marketing, AI TikTok content creation, TikTok campaign automation, AI social media marketing Singapore, AI marketing agents, TikTok ads analytics, short-form video marketing, AI lead generation'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Course outline (description) — keep this course's h3.course-topic-h3 shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Foundations of Agentic AI for TikTok Marketing</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: AI-Powered TikTok Content Creation and Campaign Automation</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: Optimising, Analysing, and Scaling TikTok Marketing with AI Agents</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): new intro paragraphs, splice the
-- retained sections byte-identical at the Course Brochure heading.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ Agentic AI for TikTok Marketing</strong> equips learners with the knowledge and practical skills to leverage Agentic AI and Generative AI to plan, create, automate, and optimise TikTok marketing campaigns. Participants will learn how AI agents can streamline the entire content marketing workflow, from market research and content planning to video production, publishing, audience engagement, and performance analysis, helping businesses scale their TikTok presence more efficiently.</p>', '\n',
'<p>The course introduces the fundamentals of TikTok marketing, the TikTok algorithm, audience behaviour, and content strategies that drive engagement and conversions. Learners will discover how AI agents can autonomously perform tasks such as trend discovery, competitor analysis, keyword and hashtag research, content ideation, script generation, caption writing, and campaign planning while maintaining alignment with business objectives.</p>', '\n',
'<p>Participants will gain hands-on experience using AI-powered tools to generate short-form video concepts, automate content creation workflows, schedule posts, monitor campaign performance, and analyse engagement metrics. The course also explores multi-agent collaboration, where specialised AI agents work together to support content creation, social media management, customer interaction, and marketing analytics.</p>', '\n',
'<p>The course further covers responsible AI usage, brand consistency, governance, and human-in-the-loop practices to ensure AI-generated content remains accurate, ethical, and aligned with organisational goals. By the end of the course, learners will be able to design and deploy AI-assisted TikTok marketing workflows that improve content productivity, increase audience engagement, generate qualified leads, and drive measurable business growth.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Brochure anchor in the retained section: stale Drive link with old title ->
-- on-site generated PDF with the new name.
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'https://drive.google.com/file/d/1sUjb60zOF-2l1gwVXjuFURLJAv943FkP/view?usp=sharing', 'https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2023036657-SG.pdf')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'WSQ - TikTok Marketing: Turning Engagement into Leads', 'WSQ - Agentic AI for TikTok Marketing')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Formulate TikTok marketing strategies to attract leads</li>', '\n',
'<li>LO2: Create viral content on TikTok.</li>', '\n',
'<li>LO3: Evaluate the performance of TikTok advertisement campaign</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2023036657_learning_outcomes';
