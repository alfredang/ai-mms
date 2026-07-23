-- 725: Repurpose WSQ course TGS-2020503501
--   "WSQ - Search Engine Optimization (SEO) for Small and Medium Enterprises"
--   -> "WSQ - Generative AI for Search Engine Optimization (SEO)"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.
-- Trainer bios untouched: no course-title quotes; SEO expertise copy remains
-- accurate for the new identity.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503501');

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
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Generative AI for Search Engine Optimization (SEO)'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503501-20260722-171741.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (all store rows)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - Generative AI for Search Engine Optimization (SEO)'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'wsq-generative-ai-for-search-engine-optimization-seo'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'WSQ Generative AI for Search Engine Optimization (SEO) | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Use Generative AI for keyword research, SEO content creation, on-page optimisation, and performance analysis. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ SEO course, generative AI SEO Singapore, AI content creation SEO, AI keyword research, on-page SEO with AI, SEO content strategy, prompt engineering SEO, AI digital marketing course, organic traffic growth'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Course outline (description) — keep this course's h3.course-topic-h3 shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Fundamentals of SEO and Generative AI</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: AI-Powered Keyword Research and Content Strategy</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: Creating SEO-Optimised Content with Generative AI</h3>', '\n',
'<h3 class="course-topic-h3">Topic 4: AI for On-Page SEO and Content Optimisation</h3>', '\n',
'<h3 class="course-topic-h3">Topic 5: SEO Performance, Ethics, and Best Practices with AI</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): new intro paragraphs, splice the
-- retained sections byte-identical at the Course Brochure heading.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ Generative AI for SEO</strong> equips learners with the knowledge and practical skills to leverage Generative AI to improve search engine visibility, create high-quality SEO content, and streamline digital marketing workflows. Participants will learn how AI tools can accelerate keyword research, content planning, on-page optimisation, and content generation while maintaining quality, relevance, and search engine best practices.</p>', '\n',
'<p>The course introduces the fundamentals of modern SEO alongside Generative AI technologies, enabling learners to develop AI-assisted strategies for creating blogs, landing pages, product descriptions, FAQs, metadata, and other search-optimised content. Participants will explore prompt engineering techniques to generate engaging, keyword-rich content that aligns with user intent and supports higher search engine rankings.</p>', '\n',
'<p>Learners will also discover how AI can assist with competitor analysis, topic clustering, content gap analysis, internal linking strategies, and SEO performance optimisation. Through practical exercises, participants will use Generative AI to automate repetitive SEO tasks, improve content productivity, and enhance website visibility while ensuring accuracy, originality, and responsible AI usage.</p>', '\n',
'<p>The course further covers AI-assisted content review, search engine guidelines, ethical considerations, and human oversight to ensure AI-generated content meets quality standards and supports long-term SEO success. By the end of the course, learners will be able to integrate Generative AI into their SEO workflow to produce scalable, search-optimised content that increases organic traffic, strengthens online presence, and supports business growth.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Brochure anchor: stale Drive link with old title -> on-site generated PDF
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'https://drive.google.com/file/d/1LhxXpuGdV93JE9lsF5-MXj1wrQDAMy1Q/view?usp=sharing', 'https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2020503501-SG.pdf')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'WSQ - Search Engine Optimization (SEO) for Small and Medium Enterprises', 'WSQ - Generative AI for Search Engine Optimization (SEO)')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Evaluate SEO and internet marketing strategies of a website</li>', '\n',
'<li>LO2: Manage keyword research in alignment with SEO</li>', '\n',
'<li>LO3: Provide on-page SEO strategies and recommendations</li>', '\n',
'<li>LO4: Manage off-page SEO strategies and performance across multiple channels</li>', '\n',
'<li>LO5: Monitor google analytics dashboards and reports to evaluate SEO performances</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2020503501_learning_outcomes';
