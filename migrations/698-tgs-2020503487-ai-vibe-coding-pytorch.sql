-- 698: Repurpose WSQ course TGS-2020503487
--   "WSQ - Predictive Analytics with PyTorch: Transform Your Data to Prediction"
--   -> "WSQ - AI Vibe Coding with PyTorch"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.
-- Trainer bios untouched: they reference predictive analytics generically
-- (still accurate — Topic 3 covers predictive AI) and never quote the title.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503487');

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
UPDATE catalog_product_entity_varchar SET value = 'WSQ - AI Vibe Coding with PyTorch'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503487-20260722-164405.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - AI Vibe Coding with PyTorch'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'wsq-ai-vibe-coding-with-pytorch'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (store 0), and drop the duplicated store-scope rows
UPDATE catalog_product_entity_varchar SET value = 'WSQ AI Vibe Coding with PyTorch | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Build deep learning models fast with PyTorch and AI coding assistants: regression, classification, CNNs, and model deployment. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ PyTorch course, AI vibe coding PyTorch, deep learning course Singapore, AI-assisted coding, CNN computer vision course, regression classification PyTorch, neural network training, Tensorboard visualisation, PyTorch model deployment'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id IN (@a_mt, @a_md) AND store_id <> 0;
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND attribute_id = @a_mk AND store_id <> 0;

-- Course outline (description) — keep this course's h3.course-topic-h3 shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: AI Vibe Coding Fundamentals with PyTorch</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: Building Deep Learning Models with PyTorch</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: Predictive AI with Regression and Classification</h3>', '\n',
'<h3 class="course-topic-h3">Topic 4: Computer Vision with Convolutional Neural Networks (CNNs)</h3>', '\n',
'<h3 class="course-topic-h3">Topic 5: AI-Assisted Model Optimization and Deployment</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): new intro paragraphs, splice the
-- retained sections byte-identical at the Course Brochure heading.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ AI Vibe Coding with PyTorch</strong> is a hands-on course that teaches participants how to build modern AI applications rapidly using PyTorch together with AI-powered coding assistants. Rather than spending excessive time writing boilerplate code, participants will learn how to leverage Generative AI to accelerate development while understanding the core concepts of deep learning.</p>', '\n',
'<p>The course begins with the fundamentals of PyTorch, including tensors, automatic differentiation, neural networks, datasets, and model training. Participants will use AI-assisted development techniques to generate, explain, debug, and optimize PyTorch code, enabling them to prototype machine learning solutions faster while maintaining code quality and reliability.</p>', '\n',
'<p>Building on these foundations, the course explores the development of deep learning models for regression, classification, and computer vision using Convolutional Neural Networks (CNNs). Participants will learn to prepare datasets, train and evaluate models, tune hyperparameters, and interpret results using appropriate performance metrics and visualization techniques. Through practical labs, they will experience how AI coding assistants can speed up experimentation, troubleshooting, and model refinement.</p>', '\n',
'<p>The course also introduces best practices for AI-assisted software development, including prompt engineering for code generation, debugging strategies, model optimization, and responsible AI development. Using a Vibe Coding approach, participants will progressively build complete PyTorch applications through guided, hands-on projects.</p>', '\n',
'<p>By the end of the course, participants will be able to confidently design, build, train, evaluate, and optimize deep learning models using PyTorch while leveraging AI tools to improve productivity, accelerate development, and create practical AI solutions for business and engineering applications.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Brochure anchor in the retained section: stale Drive link titled with the
-- old course name (and a doubled "Brochure Brochure") -> on-site generated PDF.
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'https://drive.google.com/file/d/1WkeDWBrNkJ77AfaMbKcs9NDOjzJ8cRPz/view?usp=sharing', 'https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2020503487-SG.pdf')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'WSQ - Predictive Analytics with PyTorch: Transform Your Data to Prediction Brochure Brochure', 'WSQ - AI Vibe Coding with PyTorch Brochure')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'WSQ - Predictive Analytics with PyTorch: Transform Your Data to Prediction', 'WSQ - AI Vibe Coding with PyTorch')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Apply machine learning principles to gain business insights.</li>', '\n',
'<li>LO2: Aggregate data to help test problem using Pytorch.</li>', '\n',
'<li>LO3: Apply predictive data modeling techniques to identify underlying trend and patterns in data using neural networks.</li>', '\n',
'<li>LO4: Develop prototype classification model using machine learning techniques to gain new insight from data.</li>', '\n',
'<li>LO5: Identify patterns using convolutional neural network model to derive insights and make decision.</li>', '\n',
'<li>LO6: Use Tensorboard data visualisation tool to create interactive visualizations of data.</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2020503487_learning_outcomes';
