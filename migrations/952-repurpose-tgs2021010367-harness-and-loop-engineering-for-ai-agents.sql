-- 952: Repurpose TGS-2021010367
--   "WSQ - Text Analytics with R"
--     -> "WSQ - Harness and Loop Engineering for AI Agents"
-- SKU unchanged (all SkillsFuture / SFEC / SFC / PSEA deep links stay valid).
--
-- Surfaces touched (per the TGS- rename checklist, verified by an EAV sweep of
-- BOTH value tables for the old title AND the old tech words "R"/"text mining"):
--   1  name
--   2  meta_title      (plain title: MMD_Seotitle prepends "WSQ funded" and
--                       appends the brand postfix at render time)
--   3  url_key + url_path deleted at EVERY scope + explicit 301 for old slug
--   4  short_description  -> About This Course prose ONLY
--   5  image/small_image/thumbnail _label + media-gallery label
--   6  trainerprofile   (course-teaching paragraph per trainer; credentials kept)
--   7  meta_description
--   8  meta_keyword
--   9  whoshouldattend  (job roles named the old technology)
--  10  prerequisite     (the ONE software-requirement <li> linking r-project.org)
--  11  description      (Course Outline, LSN_DATA JSON kept in sync)
--  12  learning_outcomes cms_block  <-- CREATED: this course never had one
--  13  category 106 "R " dropped (+ index mirror)
--
-- Learning Outcomes placement (explicit admin requirement):
--   This course's LOs were living INLINE in short_description under an
--   "<h2>Course Outcomes</h2>" heading. view.phtml's $_extractSection only
--   matches a "Learning Outcomes" heading, so that section was never stripped
--   and never populated the What You'll Learn card -- it rendered as part of the
--   About narrative instead. This migration (a) creates the per-course
--   course_TGS-2021010367_learning_outcomes cms_block, which the card prefers
--   over the regex fallback, and (b) truncates short_description at the
--   "<h2>Course Outcomes</h2>" boundary so the LOs exist in exactly one place.
--
-- Idempotent: every write is guarded (LOCATE probes / ON DUPLICATE KEY UPDATE /
-- NOT EXISTS), so a re-run converges.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => all
-- statements are guarded no-ops there (never a NULL entity_id INSERT).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021010367' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_pre    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_tp     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_il     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tl     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------------ 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Harness and Loop Engineering for AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------- 2. meta_title (plain)
-- No leading "WSQ", no "| Tertiary Courses Singapore" suffix -- MMD_Seotitle
-- composes both at render time; baking them in yields "WSQ funded WSQ ...".
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'Harness and Loop Engineering for AI Agents'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------- 3. url_key + 301
SET @old_slug := 'wsq-text-analytics-with-r';
SET @new_slug := 'wsq-harness-and-loop-engineering-for-ai-agents';

-- Remove any is_system = 0 squatter on the new path first: INSERT IGNORE
-- silently no-ops against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@new_slug, '.html') AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = @new_slug
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it;
-- a surviving store-scoped row still holding the old slug shadows the new URL.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the ~13 category
-- paths from its own rewrite history, but not this one).
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e, '/rp-952'), CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'), 0, 'RP'
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@old_slug, '.html') AND x.store_id = 1);

-- ---------------------------------------------- 4. short_description (About)
-- Prose only. The Learning Outcomes that used to sit inline under
-- "<h2>Course Outcomes</h2>" move to the cms_block in step 12.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to design reliable harnesses and execution loops for AI agents. Learners will explore how harness engineering combines instructions, context, tools, memory, permissions, validation rules, and evaluation mechanisms to guide agent behaviour and improve the quality of task execution.</p>
<p>Participants will learn to develop structured agent loops that enable AI agents to observe inputs, analyse information, plan actions, use tools, evaluate results, learn from feedback, and retry when required. The course covers loop controls such as stopping conditions, error recovery, state management, human approval, output validation, and performance monitoring to prevent repetitive, unsafe, or unsuccessful agent behaviour.</p>
<p>A key focus is the application of text analytics and text processing within agent harnesses and loops. Learners will prepare, clean, classify, summarise, and extract information from unstructured text such as documents, customer feedback, emails, reports, and online content. They will apply techniques including tokenisation, text normalisation, sentiment analysis, entity extraction, topic identification, semantic search, and text classification to help agents interpret inputs and make informed decisions.</p>
<p>Through hands-on projects, participants will build AI agent workflows that process text, retrieve relevant context, perform multi-step analysis, validate generated outputs, and refine results through iterative feedback loops. Emphasis is placed on reliability, traceability, security, human oversight, and measurable evaluation.</p>
<p>By the end of the course, learners will be able to design and optimise harness and loop engineering solutions that enable AI agents to process text effectively, complete complex tasks consistently, and generate dependable insights for real-world business applications.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- Any store-scoped short_description override would shadow store 0.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------- 11. description (Course Outline + LSN_DATA)
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Harness and Loop Engineering for AI Agent Text Analytics","subsecs":[]},{"title":"Topic 2: Text Collection, Cleaning and Pre-processing for Agent Workflows","subsecs":[]},{"title":"Topic 3: Text Analytics, Information Extraction and Feature Engineering","subsecs":[]},{"title":"Topic 4: Sentiment Analysis and Iterative Agent Evaluation Loops","subsecs":[]},{"title":"Topic 5: Sentiment Summarisation, Visualisation and Agent Output Optimisation","subsecs":[]}] -->
<p><strong>Topic 1: Harness and Loop Engineering for AI Agent Text Analytics</strong></p>
<p><strong>Topic 2: Text Collection, Cleaning and Pre-processing for Agent Workflows</strong></p>
<p><strong>Topic 3: Text Analytics, Information Extraction and Feature Engineering</strong></p>
<p><strong>Topic 4: Sentiment Analysis and Iterative Agent Evaluation Loops</strong></p>
<p><strong>Topic 5: Sentiment Summarisation, Visualisation and Agent Output Optimisation</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e, 'Design reliable harnesses and execution loops for AI agents. This WSQ-accredited course covers agent loop controls, text analytics, output validation and iterative evaluation. Enrol now.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ----------------------------------------------------------- 8. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Harness Engineering, Loop Engineering, AI Agents, Agentic AI, WSQ, Text Analytics, Sentiment Analysis, Agent Evaluation, WSQ Funding'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------- 5. cover alt labels
-- Plain title (no "WSQ - " prefix): the cover image itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'Harness and Loop Engineering for AI Agents'
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl) AND @e IS NOT NULL;

-- Fresh branded cover PNG (rendered from the NEW title, badges preserved:
-- WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC / Absentee Payroll / MCES)
-- and uploaded to R2. Without this the storefront keeps serving the cover
-- baked with the OLD course title.
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010367-20260813-035324.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Store-scoped covers would shadow the store-0 value above.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- The media-gallery per-image label renders as the zoom gallery's img
-- title/alt -- the rename template historically missed it.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Harness and Loop Engineering for AI Agents'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------------------- 9. whoshouldattend
-- Job roles named the old technology (Text Mining Specialist, Computational
-- Linguist, ...). Re-pointed at agent-engineering equivalents.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>AI Engineer</li>
<li>AI Agent Developer</li>
<li>Automation Engineer</li>
<li>Machine Learning Engineer</li>
<li>Data Scientist</li>
<li>Natural Language Processing Engineer</li>
<li>Conversational AI Developer</li>
<li>Solutions Architect (AI systems)</li>
<li>Business Process Automation Analyst</li>
<li>Knowledge Management Specialist</li>
<li>Customer Experience Analyst</li>
<li>Digital Transformation Specialist</li>
<li>Product Manager (AI products)</li>
<li>AI Quality and Evaluation Engineer</li>
<li>AI Governance and Risk Analyst</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------ 10. prerequisite
-- This blob ALSO holds the entire funding apparatus (PWM, eligibility table,
-- SkillsFuture / PSEA / SFEC / UTAP deep links, appeal process) -- NEVER
-- rewrite it wholesale. Replace ONLY the <li> holding the R download link.
-- Byte-probed: single-line, no CRLF inside this <li>.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<li><span style="text-decoration: underline;"><a href="https://cran.r-project.org/" target="_blank">R</a></span></li>',
        '<li><span style="text-decoration: underline;"><a href="https://www.python.org/downloads/" target="_blank">Python</a></span></li>')
 WHERE entity_id = @e AND attribute_id = @a_pre AND store_id = 0 AND @e IS NOT NULL
   AND LOCATE('cran.r-project.org', value) > 0;

-- ----------------------------------------------------------- 6. trainerprofile
-- Each bio is exactly two paragraphs: para 1 = career CREDENTIALS (real facts
-- about R/analytics experience -- kept verbatim, rewriting them would falsify
-- the bio), para 2 = a course-teaching claim scoped to the OLD topic. Only the
-- claim paragraphs are retargeted, one exact-string REPLACE() each.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In his Text Analytics with R training, Dwight emphasizes practical applications such as sentiment analysis, topic modeling, and social media text mining. He guides learners through R packages for data cleaning, natural language processing, and visualization, ensuring they gain hands-on experience. By integrating project-based learning and case studies, Dwight equips participants with the ability to transform raw text into actionable insights using R.</p>',
        '<p>In his Harness and Loop Engineering for AI Agents training, Dwight emphasizes practical applications such as agent evaluation loops, sentiment analysis, and text-driven decision making. He guides learners through harness design, tool use, memory and validation rules, ensuring they gain hands-on experience. By integrating project-based learning and case studies, Dwight equips participants with the ability to build agent workflows that turn raw text into dependable, actionable insights.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In his Text Analytics with R courses, Alvin focuses on both the theoretical underpinnings and hands-on practice. He trains learners to use R for text preprocessing, topic modeling, and statistical analysis, applying methods such as sentiment analysis and NLP. His teaching approach balances statistical rigor with practical case studies, enabling learners to apply text analytics effectively in business, research, and digital transformation contexts.</p>',
        '<p>In his Harness and Loop Engineering for AI Agents courses, Alvin focuses on both the theoretical underpinnings and hands-on practice. He trains learners to structure agent loops for text preprocessing, information extraction, and output validation, applying methods such as sentiment analysis and NLP. His teaching approach balances analytical rigor with practical case studies, enabling learners to apply agent harnesses effectively in business, research, and digital transformation contexts.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Text Analytics with R,&rdquo; Terence teaches participants how to analyze and interpret unstructured text data using R&rsquo;s powerful text mining and visualization tools. His sessions cover data cleaning, tokenization, sentiment analysis, and topic modeling using packages such as <em>tm</em>, <em>tidytext</em>, and <em>ggplot2</em>. By blending statistical rigor with practical application, he enables learners to uncover patterns, trends, and insights from text data that support evidence-based business strategies.</p>',
        '<p>In &ldquo;Harness and Loop Engineering for AI Agents,&rdquo; Terence teaches participants how to analyze and interpret unstructured text data inside agent workflows. His sessions cover data cleaning, tokenization, sentiment analysis, and topic identification, together with the loop controls that govern retries, stopping conditions, and human approval. By blending analytical rigor with practical application, he enables learners to uncover patterns, trends, and insights that support evidence-based business strategies.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Text Analytics with R,&rdquo; Chee Yong focuses on developing learners&rsquo; hands-on proficiency in R for natural language processing and text analytics. His sessions emphasize techniques for text cleaning, word frequency analysis, sentiment scoring, and visual storytelling through word clouds and clustering. Through step-by-step instruction and real-world case studies, he empowers participants to convert textual data into structured insights that enhance business intelligence and decision accuracy.</p>',
        '<p>In &ldquo;Harness and Loop Engineering for AI Agents,&rdquo; Chee Yong focuses on developing learners&rsquo; hands-on proficiency in building agent loops for natural language processing and text analytics. His sessions emphasize techniques for text cleaning, entity extraction, sentiment scoring, and evaluating agent outputs across iterations. Through step-by-step instruction and real-world case studies, he empowers participants to convert textual data into structured insights that enhance business intelligence and decision accuracy.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Text Analytics with R,&rdquo; Bernard guides learners through the analytical process of extracting, transforming, and interpreting text data. His sessions introduce participants to R&rsquo;s text mining ecosystem, including sentiment analysis, keyword extraction, and clustering methods. With his structured and application-oriented teaching style, he helps participants translate raw text into actionable insights that drive marketing intelligence, customer understanding, and data-informed strategy development.</p>',
        '<p>In &ldquo;Harness and Loop Engineering for AI Agents,&rdquo; Bernard guides learners through the process of extracting, transforming, and interpreting text data within agent harnesses. His sessions introduce participants to context management, tool use, and output validation, alongside sentiment analysis and keyword extraction. With his structured and application-oriented teaching style, he helps participants translate raw text into actionable insights that drive marketing intelligence, customer understanding, and data-informed strategy development.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 12. learning_outcomes cms_block
-- This course has NO course_TGS-2021010367_learning_outcomes block (it predates
-- the 885-891 block extraction), so a bare UPDATE would silently no-op.
-- Guarded-INSERT first, then UPDATE, so re-runs converge (915/931 shape).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2021010367 - Learning Outcomes', 'course_TGS-2021010367_learning_outcomes', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                    WHERE b.identifier = 'course_TGS-2021010367_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_TGS-2021010367_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By the end of the course, learners will be able to:</p>
<ul>
<li>LO1: Identify and develop text analytics solutions using Cross-Industry Standard Process for Data Mining (CRISP-DM).</li>
<li>LO2: Read in text corpus and perform text pre-processing.</li>
<li>LO3: Perform text analytics and modify the data with feature engineering.</li>
<li>LO4: Perform sentimental analysis from social media data.</li>
<li>LO5: Perform sentiment summarization and visualization.</li>
</ul>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_TGS-2021010367_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------------ 13. drop the "R " category
-- The course no longer teaches R. Category 106 keeps its other 16 R courses.
-- The delete MUST be mirrored into catalog_category_product_index or the
-- storefront listing never changes.
DELETE FROM catalog_category_product       WHERE category_id = 106 AND product_id = @e AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index WHERE category_id = 106 AND product_id = @e AND @e IS NOT NULL;
