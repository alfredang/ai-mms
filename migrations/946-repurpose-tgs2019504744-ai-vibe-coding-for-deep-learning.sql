-- 946: Repurpose TGS-2019504744
--   FROM "WSQ - Building Your First Machine Learning Model with Python and Tensorflow"
--   TO   "WSQ - AI Vibe Coding for Deep Learning"
-- SKU is UNCHANGED (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
--
-- Surfaces touched (per the TGS- rename checklist; each one confirmed by a
-- pre-write sweep of catalog_product_entity_varchar + _text for the old
-- title AND its tech words Tensorflow / Keras / Machine Learning):
--   1  name                      -> WSQ - AI Vibe Coding for Deep Learning
--   2  meta_title                -> plain title, no "WSQ" prefix, no brand suffix
--                                   (MMD_Seotitle composes both at render time; the
--                                   outgoing value baked in BOTH and is fixed here)
--   3  url_key + url_path DELETE  -> wsq-ai-vibe-coding-for-deep-learning + explicit 301
--   4  short_description          -> new About This Course prose (FULL replace: this
--                                   product is post-885, its sections already live in
--                                   cms_blocks, so there is no Brochure tail to splice.
--                                   The inline "Course Learning Outcomes" list is
--                                   dropped here — see the note at section 5.)
--   5  learning_outcomes block    -> guarded INSERT then content (block did NOT exist)
--   6  description                -> new Topic 1-5
--   7  *_label + media gallery    -> plain title (alt text on the cover)
--   8  meta_description / meta_keyword / whoshouldattend
--   9  prerequisite               -> ONLY the two software <li> rows (TensorFlow /
--                                   Keras install links); the rest of that blob is the
--                                   funding apparatus and is never rewritten wholesale
--  10  trainerprofile             -> para-2 teaching claims only; para-1 credentials kept
--  11  categories                 -> add 414 "AI Vibe Coding Series" (9 of 11 sibling
--                                   WSQ - AI Vibe Coding courses hold it; this course
--                                   was missing it). Mirrored into
--                                   catalog_category_product_index.
--
-- Deliberately unchanged:
--   * sku, price, duration (16h), sessions (2)
--   * tags/badges — WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, MCES, Absentee Payroll
--     are byte-identical to the AI Vibe Coding siblings' set, so no tag change.
--   * the brochure / certification / skills_framework / funding_and_grant cms_blocks
--     (all keyed on the unchanged SKU; none of them mention the old technology —
--     verified by a content LIKE sweep)
--   * image/small_image/thumbnail filesystem paths (paths, not display text —
--     renaming them 404s the file; the storefront renders the R2 course_image_url)
--   * course_image_url (the cover PNG is re-rendered out-of-band, not by SQL)
--   * every other category placement — the course still teaches deep learning, so
--     AI / Programming / Python / Data Management all still describe it.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every statement
-- no-ops there (UPDATEs match nothing; INSERTs are guarded on @e IS NOT NULL).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2019504744' LIMIT 1);

SET @a_name     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_who      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_trainer  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilabel   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------------ 1. name
-- Keep the "WSQ - " prefix (the storefront H1 wants it) and match the sibling
-- family's "AI Vibe Coding for <topic>" shape.
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Vibe Coding for Deep Learning'
 WHERE entity_id = @e AND attribute_id = @a_name;

-- ------------------------------------------------------- 2. meta_title / SEO
-- The outgoing value was "WSQ Basic Deep Learning ... | Tertiary Courses Singapore",
-- baking in BOTH the funding token and the brand suffix that MMD_Seotitle adds at
-- render time (yielding "WSQ funded WSQ ... | Tertiary Courses Singapore").
-- Store the plain title only.
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Deep Learning'
 WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
   SET value = 'Use AI vibe coding with Python to build, train and optimise deep learning models - neural networks, CNNs and transfer learning. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
   SET value = 'AI vibe coding course Singapore, deep learning course Singapore, WSQ deep learning training, neural network course, CNN image classification course, transfer learning training, AI coding assistant course, Python deep learning course, WSQ AI certification'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0;

-- ------------------------------------------------------------- 3. url_key
-- Collision check done before writing: no other product owns
-- 'wsq-ai-vibe-coding-for-deep-learning' or any '%vibe-coding-for-deep-learning%'
-- slug, and the non-WSQ deep-learning courses (C539 deep-learning-with-pytorch,
-- C1228 build-large-language-models-...-keras-3) own unrelated slugs.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-vibe-coding-for-deep-learning'
 WHERE entity_id = @e AND attribute_id = @a_urlkey;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it.
-- (This product had store-0 AND store-1 rows still holding the old .html path.)
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Clear any non-system squatter sitting on the new path first, otherwise the
-- INSERT IGNORE below silently no-ops against the stale row (see migration 647).
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-vibe-coding-for-deep-learning.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old bare slug. The indexer auto-301s the ~15 category
-- paths; this covers the flat URL that is linked from off-site.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1,
       'rp_tgs2019504744_mlmodel_1',
       'wsq-building-your-first-machine-learning-model-with-python-and-tensorflow.html',
       'wsq-ai-vibe-coding-for-deep-learning.html',
       0, 'RP', '946 rename: Building Your First ML Model -> AI Vibe Coding for Deep Learning'
  FROM dual WHERE @e IS NOT NULL;

-- The course carried older aliases from two previous renames
-- (deep-learning-with-keras-1017.html, wsq-deep-learning-tensorflow-keras.html)
-- whose target_path still names the outgoing slug. Repoint them at the live page
-- so they resolve in one hop instead of forming a 301 chain to a dead slug.
-- Anchored on the FULL old filename so no sibling course's aliases are caught.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-vibe-coding-for-deep-learning.html'
 WHERE is_system = 0
   AND target_path = 'wsq-building-your-first-machine-learning-model-with-python-and-tensorflow.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------------- 4. image alt labels
-- Plain title, no "WSQ - " prefix: these are alt text on the cover, which itself
-- strips the prefix (CourseImage/Model/Cover.php::cleanTitle).
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Deep Learning'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'AI Vibe Coding for Deep Learning'
 WHERE g.entity_id = @e;

-- --------------------------------------------------- 5. Learning Outcomes
-- This course PREDATES the 885-891 block extraction: it had NO
-- course_TGS-2019504744_learning_outcomes block at all, and its outcomes sat
-- inline in short_description under an "<h2>Course Learning Outcomes</h2>"
-- heading. That heading does NOT match view.phtml::$_extractSection (which
-- anchors on "Learning Outcomes", not "Course Learning Outcomes"), so the
-- inline copy was never stripped. Creating the block WITHOUT also rewriting
-- short_description would therefore double-render the outcomes. Section 6
-- below replaces short_description with prose only.
--
-- Guarded INSERT first: a bare UPDATE against a missing block silently no-ops.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2019504744 - Learning Outcomes',
       'course_TGS-2019504744_learning_outcomes',
       '', NOW(), NOW(), 1
  FROM dual
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                    WHERE b.identifier = 'course_TGS-2019504744_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_TGS-2019504744_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By the end of the course, learners will be able to:</p>
<ul>
<li>LO1 - Setup Deep Learning frameworks.</li>
<li>LO2 - Understand and code Neural Network models for Regression.</li>
<li>LO3 - Understand and code Neural Network models for Classification.</li>
<li>LO4 - Understand and code Convolutional Neural Network models for Image Classification.</li>
<li>LO5 - Understand and use pre-trained models for transfer learning.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2019504744_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------------ 6. About This Course (sdesc)
-- FULL replace is correct here: a pre-write LOCATE() probe confirmed this value
-- has NO '<h2>Course Brochure</h2>' tail (sections already moved to cms_blocks),
-- so there is nothing to splice and nothing byte-fragile to preserve. This also
-- removes the inline "Course Learning Outcomes" list per the note in section 5.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to use AI vibe coding and Python to develop deep learning applications. Learners will use natural-language instructions and AI coding assistants to generate, explain, test, debug, and improve code, making neural network development more accessible without requiring every component to be written manually.</p>
<p>Participants will explore the foundations of deep learning, including artificial neurons, network layers, activation functions, loss functions, gradient descent, and backpropagation. They will learn how to prepare datasets, design neural network architectures, train models, evaluate results, and adjust parameters to improve performance.</p>
<p>The course covers practical deep learning applications such as image classification, visual recognition, text analysis, and predictive modelling. Learners will build fully connected neural networks and convolutional neural networks while using AI-assisted workflows to select suitable architectures, troubleshoot training issues, and interpret model outputs.</p>
<p>Through hands-on projects, participants will develop end-to-end deep learning workflows, from data preparation and model development to testing, visualisation, and deployment planning. Emphasis is placed on validating AI-generated code, reducing overfitting, maintaining data quality, comparing model performance, and applying responsible AI practices.</p>
<p>By the end of the course, learners will be able to use AI vibe coding with Python to build, train, evaluate, and optimise deep learning models for real-world applications. This course is suitable for beginner and intermediate learners with basic programming or data analytics knowledge.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0;

-- ------------------------------------- 7. Course Outline (description)
-- Keeps the existing "<h3 class=course-topic-h3>" markup shape this product and
-- its AI Vibe Coding siblings already use (the theme normalises bullets from it;
-- no LSN_DATA comment on this product, so none is introduced).
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: AI Vibe Coding and Deep Learning Environment Setup</h3>
<h3 class="course-topic-h3">Topic 2: Neural Networks for Regression and Predictive Modelling</h3>
<h3 class="course-topic-h3">Topic 3: Neural Networks for Data Classification</h3>
<h3 class="course-topic-h3">Topic 4: Convolutional Neural Networks for Image Classification</h3>
<h3 class="course-topic-h3">Topic 5: Transfer Learning and Fine-Tuning Pre-Trained Model</h3>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- ------------------------------------------------------- 8. whoshouldattend
-- The old list named the retired framing ("Deep Learning Researcher",
-- "NLP Engineer (branching into deep learning)"). The course still teaches deep
-- learning, so most roles stand; the list is refreshed to lead with the
-- AI-vibe-coding framing and drop the narrow research/bioinformatics roles.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>AI Developer</li>
<li>Machine Learning Engineer</li>
<li>Data Scientist</li>
<li>Data Analyst</li>
<li>Python Developer</li>
<li>Software Developer</li>
<li>Computer Vision Engineer</li>
<li>AI Solutions Architect</li>
<li>Predictive Analytics Specialist</li>
<li>Business Intelligence Analyst</li>
<li>AI Product Manager</li>
<li>Automation Engineer</li>
<li>Data Engineer</li>
<li>Technical Consultant (AI)</li>
<li>AI/ML Educator or Trainer</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0;

-- ------------------------------------------------------------ 9. prerequisite
-- This attribute ALSO holds the whole funding apparatus (PWM, Funding
-- Eligibility table, SkillsFuture / PSEA / SFEC / UTAP deep links, Appeal
-- Process) => never rewrite it wholesale. Replace ONLY the two <li> rows under
-- "Minimum Software/Hardware Requirement" that link the old install guides.
-- Single-line REPLACE (the blob is CRLF WYSIWYG content, so a multi-line
-- pattern would silently no-op); the exact bytes were LOCATE()-probed first.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<li><span style="text-decoration: underline;"><a href="https://www.tensorflow.org/install/pip" target="_blank">TensorFlow</a></span></li>',
        '<li><span style="text-decoration: underline;"><a href="https://www.python.org/downloads/" target="_blank">Python</a></span></li>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<li><span style="text-decoration: underline;"><a href="https://www.liquidweb.com/kb/how-to-install-keras/" target="_blank">Keras Guide</a></span></li>',
        '<li><span style="text-decoration: underline;"><a href="https://colab.research.google.com/" target="_blank">Google Colab</a></span> (no installation required)</li>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0;

-- --------------------------------------------------------- 10. trainerprofile
-- Each of the 4 bios is exactly two paragraphs: para 1 = career-history
-- CREDENTIALS (real TensorFlow/Keras/IBM expertise, PhD, teaching history) which
-- stay VERBATIM — rewriting them would falsify a bio — and para 2 = a
-- course-teaching claim scoped to the old course title. Retarget ONLY para 2,
-- one targeted REPLACE() per bio so the &nbsp;/entity bytes survive.
-- Pass condition after applying: the remaining TensorFlow/ML mentions in this
-- attribute all sit in para 1.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'With hands-on experience in building machine learning models, Quah has guided learners through data preparation, feature engineering, and model deployment using TensorFlow pipelines. He emphasizes practical, project-based learning where participants construct models from scratch, evaluate performance, and implement solutions in real-world contexts. His ability to bridge technical knowledge with accessible explanations ensures learners gain both confidence and competence in building their first machine learning models.',
        'In the AI Vibe Coding for Deep Learning training, Quah guides learners through data preparation, network design, and model evaluation using AI coding assistants. He emphasizes practical, project-based learning where participants build neural networks with natural-language prompts, validate the generated code, and apply the results in real-world contexts. His ability to bridge technical knowledge with accessible explanations ensures learners gain both confidence and competence in developing deep learning models.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'With over a decade of teaching experience, Dr Ang emphasizes hands-on application of Python and TensorFlow for machine learning model development. Learners benefit from his structured approach, starting with supervised learning concepts before progressing to building and training neural networks. His teaching style blends theory with practical coding exercises, ensuring participants gain the skills needed to design, evaluate, and deploy their own machine learning models.',
        'With over a decade of teaching experience, Dr Ang emphasizes hands-on application of AI vibe coding with Python for deep learning development. Learners benefit from his structured approach, starting with neural network fundamentals before progressing to convolutional networks and transfer learning. His teaching style blends theory with practical AI-assisted coding exercises, ensuring participants gain the skills needed to design, evaluate, and optimise their own deep learning models.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'Certified in AI engineering and machine learning, Solomon has also served as lead instructor for data science bootcamps and corporate training programs. He specializes in guiding learners through their first steps in TensorFlow, helping them build, train, and evaluate neural network models. His teaching emphasizes hands-on coding, best practices in model development, and real-world case applications, equipping participants with the confidence to apply machine learning effectively.',
        'Certified in AI engineering and machine learning, Solomon has also served as lead instructor for data science bootcamps and corporate training programs. He specializes in guiding learners through AI-assisted deep learning workflows, helping them build, train, and evaluate neural network and CNN models. His teaching emphasizes hands-on vibe coding, best practices in model development, and real-world case applications, equipping participants with the confidence to apply deep learning effectively.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'Since 2017, Terence has focused on training and consulting, helping professionals upskill in Python, data analytics, and machine learning. His training approach for TensorFlow emphasizes building a strong foundation in Python coding before guiding learners to develop, train, and deploy their first machine learning models. By combining his practical industry background with hands-on teaching, Terence ensures participants gain the applied knowledge to confidently implement machine learning in real-world organizational contexts.',
        'Since 2017, Terence has focused on training and consulting, helping professionals upskill in Python, data analytics, and machine learning. His approach to AI vibe coding emphasizes building a strong foundation in Python before guiding learners to prompt, validate, and refine AI-generated deep learning code. By combining his practical industry background with hands-on teaching, Terence ensures participants gain the applied knowledge to confidently implement deep learning in real-world organizational contexts.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

-- --------------------------------------------------------- 11. categories
-- The course keeps every existing placement (it still teaches deep learning, so
-- AI / Programming / Python / Data Management all still describe it). It is only
-- MISSING the series category its 11 renamed siblings sit in: 414 "AI Vibe
-- Coding Series" (held by 9 of them). Appended at MAX(position)+1 so the
-- category-ordering sweep can renumber later.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 414, @e,
       COALESCE((SELECT MAX(x.position) FROM (SELECT * FROM catalog_category_product) x
                  WHERE x.category_id = 414), 0) + 1
  FROM dual
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity c WHERE c.entity_id = 414);

-- Mirror into the index or the storefront listing never changes.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT ccp.category_id, ccp.product_id, ccp.position, 1, s.store_id, 4
  FROM catalog_category_product ccp
  CROSS JOIN (SELECT store_id FROM core_store WHERE store_id > 0) s
 WHERE ccp.product_id = @e
   AND ccp.category_id = 414
   AND @e IS NOT NULL;
