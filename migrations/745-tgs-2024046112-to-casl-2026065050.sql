-- 745: Repurpose + re-register WSQ course
--   "WSQ - Generative AI for Finance and Fintech" (TGS-2024046112)
--   -> "CASL - Generative AI for Finance and Fintech" (TGS-2026065050)
-- The SKU CHANGES (new SSG registration). Also: new LOs, new 5-topic outline
-- with subtopics, new About, new cover, per-SKU cms_block identifiers renamed,
-- funding/brochure links rewritten to the new TGS code.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024046112');

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
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026065050'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026065050') x);

-- Name + labels + cover
UPDATE catalog_product_entity_varchar SET value = 'CASL - Generative AI for Finance and Fintech'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026065050-20260722-174548.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Generative AI for Finance and Fintech'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'casl-generative-ai-for-finance-and-fintech'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'CASL Generative AI for Finance and FinTech | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Master Generative AI and Agentic AI for finance: Excel Copilot FP&A, financial process automation, fraud detection, and AI governance. Funding available.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'CASL Generative AI finance course, GenAI fintech Singapore, agentic AI finance automation, Excel Copilot FP&A, AI fraud detection, AI risk management, multi-agent financial workflows, AI governance finance'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Course outline (description) — h3.course-topic-h3 + subtopic <ul> shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Introduction to Generative AI and Its Foundations in Finance</h3>', '\n',
'<ul>', '\n',
'<li>Basics of AI and Machine Learning</li>', '\n',
'<li>Introduction to Generative AI and Agentic AI</li>', '\n',
'<li>Use Cases of Gen AI and Agentic AI in Finance</li>', '\n',
'<li>Build Single and Multi-Agent for Financial Services</li>', '\n',
'</ul>', '\n',
'<h3 class="course-topic-h3">Topic 2: Excel Copilot For Finance Planning and Analysis</h3>', '\n',
'<ul>', '\n',
'<li>Excel Copilot for Finance</li>', '\n',
'<li>Summarize Financial Data</li>', '\n',
'<li>Process Financial Data</li>', '\n',
'<li>Financial Planning &amp; Analysis (FP&amp;A)</li>', '\n',
'</ul>', '\n',
'<h3 class="course-topic-h3">Topic 3: Practical Applications of Agentic AI to Automate Financial Processes</h3>', '\n',
'<ul>', '\n',
'<li>Case Studies of Agentic AI for Financial Processes</li>', '\n',
'<li>Agentic AI Automation for Financial Processes</li>', '\n',
'<li>Multi Agent Automation for Financial Processes</li>', '\n',
'</ul>', '\n',
'<h3 class="course-topic-h3">Topic 4: AI Risk Management and Fraud Detection</h3>', '\n',
'<ul>', '\n',
'<li>AI for Risk Management</li>', '\n',
'<li>Build a Fraud Detection System using GenAI</li>', '\n',
'</ul>', '\n',
'<h3 class="course-topic-h3">Topic 5: Future Trends and Innovations in Generative AI for Finance</h3>', '\n',
'<ul>', '\n',
'<li>Future Trends in Generative AI for Finances</li>', '\n',
'<li>Adoption of Generative AI Innovations in Organizations</li>', '\n',
'</ul>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course: new intro paragraphs, splice retained sections
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>CASL Generative AI for Finance and Fintech</strong> steps you into the future of finance with comprehensive coverage of Generative AI (GenAI) and Agentic AI tailored specifically for financial professionals. The course begins by establishing a strong foundation in AI, Machine Learning, and Generative AI, emphasizing their transformative role in the finance and fintech sectors. Participants will learn how to design and deploy both single and multi-agent systems to automate and enhance financial operations, planning, and decision-making.</p>', '\n',
'<p>In the next module, learners will explore the practical power of Excel Copilot for Finance, mastering how to summarize, process, and analyze financial data through AI-driven tools that streamline Financial Planning and Analysis (FP&amp;A) tasks. Through hands-on exercises, participants will experience how AI can boost productivity and insight generation in financial modeling.</p>', '\n',
'<p>The course then transitions to the application of Agentic AI for financial process automation, examining real-world case studies and guiding participants to build and deploy autonomous agents that handle complex financial workflows and reporting. Learners will gain firsthand experience in implementing multi-agent automation systems for finance operations.</p>', '\n',
'<p>A dedicated section on AI Risk Management and Fraud Detection enables participants to understand how AI models can predict, detect, and mitigate financial risks. Learners will also build a fraud detection system using Generative AI, applying advanced AI tools to real-world data.</p>', '\n',
'<p>Finally, the course concludes by exploring future trends and innovations in Generative AI for Finance, helping participants anticipate emerging technologies and adopt AI-driven innovations within their organizations. By the end of the program, learners will be equipped with both strategic and technical expertise to lead the AI transformation in financial services.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Retained sections: repoint every old TGS reference (funding + brochure
-- links) to the new registration, and retitle any old-name mentions.
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2024046112', 'TGS-2026065050')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Generative AI for Finance and Fintech', 'CASL - Generative AI for Finance and Fintech')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers to the new SKU, refresh LO content
UPDATE cms_block SET identifier = 'course_TGS-2026065050_brochure', title = REPLACE(title, 'TGS-2024046112', 'TGS-2026065050')
  WHERE identifier = 'course_TGS-2024046112_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026065050_learning_outcomes', title = REPLACE(title, 'TGS-2024046112', 'TGS-2026065050')
  WHERE identifier = 'course_TGS-2024046112_learning_outcomes';
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Support Artificial Intelligence (AI) and Generative AI innovations to champion organisation-wide innovation.</li>', '\n',
'<li>LO2: Evaluate and implement GAI technologies for the organisation.</li>', '\n',
'<li>LO3: Review and adopt new GAI technologies by reviewing use cases in finance operations.</li>', '\n',
'<li>LO4: Review AI ethics and governance in organization''s processes for proactive risk monitoring and safety.</li>', '\n',
'<li>LO5: Review emerging trends in GAI and strategize cost control measures to support innovation initiatives.</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2026065050_learning_outcomes';

-- Trainer bios: retitle any old prefixed-title quotes
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Generative AI for Finance and Fintech', 'CASL - Generative AI for Finance and Fintech')
  WHERE entity_id = @e AND attribute_id = @a_tp;
