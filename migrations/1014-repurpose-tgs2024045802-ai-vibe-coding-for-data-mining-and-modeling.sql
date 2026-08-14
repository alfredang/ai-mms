-- 1014: Repurpose TGS-2024045802
--   "WSQ - Neo4j Graph Data Science and Large Language Model (LLM)"
--     -> "WSQ - AI Vibe Coding for Data Mining and Modeling"
--
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link is keyed
-- on it). Admin-supplied content 2026-08-14: 4 LOs, 4 topics, About narrative.
--
-- Surfaces touched, from the mandatory pre-write EAV sweep of BOTH value tables
-- (memory feedback_tgs_course_rename_checklist -- the sweep is what found these,
-- not an enumerated checklist):
--   name, url_key (+ url_path DELETE at every scope), meta_title, meta_description,
--   meta_keyword, image_label/small_image_label/thumbnail_label, media-gallery
--   label, short_description (About narrative), description (Course Outline /
--   LSN_DATA + rendered topics), whoshouldattend (job roles named the OLD tech),
--   trainerprofile (course-teaching paragraph only), the learning_outcomes
--   cms_block, a 301 for the old bare slug, and category placement.
--
-- THE ACCREDITED TSC IS UNCHANGED AND IS THE POINT OF THIS REPURPOSE. The
-- skills_framework block reads "Data Mining and Modelling STP-DAT-3003-1.1 TSC
-- under Sea Transport Skills Framework" -- the new title aligns the course back
-- to its own registered competency. The admin-supplied LOs are the live LOs with
-- the Neo4j-specific wording removed (LO1 "Neo4j graph data science guidelines"
-- -> "data science guidelines"; LO2 drops "using graph database algorithms";
-- LO4 drops "on Neo4j graph data sets"). LO3 is byte-identical and stays.
-- Graph ML / graph-based modelling REMAIN in scope (LO3 + Topic 2/3 keep them) --
-- what is retired is the Neo4j PRODUCT, not the graph competency.
--
-- NEW-TITLE COLLISION CHECK (memory
-- feedback_repurpose_target_name_may_already_exist_as_live_twin -- probe name AND
-- url_key, not just url_key):
--   * name LIKE '%Data Mining%' / '%Vibe Coding%' returned a NEAR twin --
--     TGS-2022014977 "WSQ - AI Vibe Coding for Data Mining" (live, slug
--     wsq-ai-vibe-coding-for-data-mining). The requested title carries
--     "and Modeling", so the two titles and slugs stay distinct. Flagged to the
--     admin; not resolved here.
--   * url_key LIKE '%data-mining%' / '%vibe-coding%': no row owns
--     'wsq-ai-vibe-coding-for-data-mining-and-modeling'. The slug is free, so the
--     standard wsq--prefixed form is used (no disambiguating suffix needed).
--
-- meta_title: PLAIN title -- NO leading "WSQ", NO "| Tertiary Courses Singapore"
-- suffix. MMD_Seotitle composes <title> at render time (prepends "WSQ funded" for
-- SG TGS- SKUs and appends the brand postfix). The OLD value baked in BOTH
-- ("WSQ Neo4j ... | Tertiary Courses Singapore") -- the 853 bug -- so this
-- migration also cleans that up.
--
-- short_description: FULL REPLACE is correct here, not a splice. This course is
-- post-885: its sections live in cms_block rows (brochure / learning_outcomes /
-- certification / skills_framework / funding_and_grant, all confirmed present)
-- and the sdesc holds ONLY the two intro paragraphs -- there is no
-- "<h2>Course Brochure</h2>" tail to preserve and no ad-hoc inline vendor
-- section (surface 12 checked: the whole blob was dumped and read first).
--
-- TRAINER BIOS -- surgical, not wholesale. All 5 bios split cleanly:
--   * para 1 = career CREDENTIALS (real data-architecture / AI-strategy /
--     data-engineering history). TRUE and LEFT ALONE -- rewriting would falsify
--     a real person's bio.
--   * para 2 = a COURSE-TEACHING claim opening 'In "Neo4j Graph Data Science and
--     Large Language Model (LLM)," <name> ...'. Retargeted to the AI-vibe-coding
--     data-mining delivery.
-- One exact single-line REPLACE() per bio -- a multi-line REPLACE() silently
-- no-ops on these CRLF WYSIWYG blobs (memory
-- feedback_multiline_replace_fails_on_crlf_blobs).
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku, price (900), duration (16), sessions (2) -- accredited course params.
--   * prerequisite -- holds the ENTIRE funding apparatus (PWM, Funding
--     Eligibility, SkillsFuture/PSEA/SFEC deep links, Appeal Process). Its
--     "Minimum Software/Hardware Requirement" section carries NO Neo4j tool link
--     (checked line by line), so there is nothing to swap. Deep-link counts to
--     preserve: myskillsfuture=1, mom=1, ntuc=0.
--   * course_TGS-2024045802_skills_framework -- the TSC the new title realigns
--     to; must NOT change.
--   * _certification / _brochure / _funding_and_grant -- keyed on the unchanged
--     SKU; WSQ accreditation, fee table and OpenCerts wording are unaffected by
--     a title change.
--   * badge tags (funding eligibility unchanged).
--   * image/small_image/thumbnail PATHS (/w/s/wsq-neo4j-...jpg) -- filesystem
--     paths, not display text; renaming them 404s the file. The storefront
--     renders course_image_url. Only the LABELS (alt text) change here; the R2
--     cover PNG still bakes the old title and is re-rendered from the admin.
--   * catalogsearch_query -- the anchored sweep on the FULL old filename
--     ('%wsq-neo4j-graph-data-science-and-large-language-model-llm.html%') and on
--     the bare course code returned ZERO rows. The 23 rows matching 'neo4j' ALL
--     have an EMPTY redirect and are Neo4j-graph-database intent belonging to
--     other live courses -- filling them toward this page would be actively wrong
--     (memory feedback_repurpose_target_name_may_already_exist_as_live_twin).
--     Search redirects are DATA and are applied live, never via a migration.
--
-- CATEGORY PLACEMENT: the repurpose retires the Neo4j PRODUCT, so category 416
-- "Graph Database" (8 members, a pure Neo4j/graph-product listing) no longer
-- describes the course and is dropped -- mirrored into
-- catalog_category_product_index or the storefront listing never changes (memory
-- feedback_category_swap_needs_index_mirror). Cat 110 "Databases" is dropped for
-- the same reason. Every other placement is KEPT: the course still teaches data
-- mining, modelling, graph ML and LLM narrative analytics, so 252 AI Courses,
-- 139 AI Applications Series, 433 Generative AI Series, 55 Infocomm Technology
-- and all four WSQ listings still apply.
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses; MY/GH partner DBs have no
-- such SKU, so every statement matches zero rows there (clean no-op).
--
-- IDEMPOTENCY: every statement either sets a full target value or REPLACE()s an
-- exact old string that no longer exists after the first run. Re-running converges.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045802');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='whoshouldattend');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "WSQ - " prefix -- the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'WSQ - AI Vibe Coding for Data Mining and Modeling'
WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'wsq-ai-vibe-coding-for-data-mining-and-modeling'
WHERE entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Drop any is_system = 0 squatter on the NEW path first: INSERT IGNORE silently
-- no-ops against a stale row (the 647 trap).
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-ai-vibe-coding-for-data-mining-and-modeling.html' AND is_system = 0;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the ~20 category
-- paths from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       'wsq-neo4j-graph-data-science-and-large-language-model-llm.html',
       'wsq-ai-vibe-coding-for-data-mining-and-modeling.html',
       0, 'RP', 'Repurpose 1014: old Neo4j slug -> AI Vibe Coding for Data Mining and Modeling'
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'wsq-neo4j-graph-data-science-and-large-language-model-llm.html'
      AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 3. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title: MMD_Seotitle adds "WSQ funded" + the brand
--    suffix at render time. The old value baked in both (the 853 bug).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Data Mining and Modeling'
WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Use AI vibe coding and Python to mine data, build computational models and generate insights. Hands-on classification, clustering and pattern discovery. Up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'AI Vibe Coding, Data Mining, Data Modeling, Python, WSQ Funding, AI Coding Assistant, Machine Learning, Pattern Discovery, Narrative Analytics'
WHERE entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 4. Alt-text labels + media-gallery label. These carry the PLAIN title (the
--    cover renderer itself strips the "WSQ - " prefix). The R2 cover PNG is
--    re-rendered separately from the admin.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Data Mining and Modeling'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI Vibe Coding for Data Mining and Modeling'
WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 5. short_description -- the "About This Course" narrative (admin-supplied).
--    Full replace: sections live in cms_block rows, sdesc is prose only.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>This course equips participants with practical skills to use AI vibe coding and Python for data mining, computational modelling, and insight generation. Learners will use natural-language instructions and AI coding assistants to generate, explain, test, debug, and refine code, enabling them to develop data solutions more efficiently without writing every component manually.</p>
<p>Participants will learn how to collect, clean, transform, and explore structured and unstructured data. They will apply data mining methods such as classification, regression, clustering, association analysis, anomaly detection, similarity analysis, and pattern discovery to address real-world business and technical problems. The course also covers feature engineering, data visualisation, model selection, and the interpretation of complex relationships within datasets.</p>
<p>Building on these foundations, learners will design and evaluate computational models using suitable algorithms and performance metrics. They will use AI-assisted coding to compare modelling approaches, optimise parameters, identify issues such as overfitting and data leakage, and improve model reliability. Where appropriate, learners will also explore graph-based modelling to analyse relationships, communities, connections, and paths within interconnected data.</p>
<p>Through hands-on projects, participants will develop end-to-end Python workflows that transform raw data into validated models, visual findings, and actionable recommendations. By the end of the course, learners will be able to use AI vibe coding to select appropriate algorithms, build reliable data mining models, evaluate results, and communicate insights for evidence-based decision-making.</p>'
WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- 6. description -- the Course Outline. Both the LSN_DATA JSON comment (which
--    drives the structured outline) and the rendered <p> markup must agree; the
--    storefront reads LSN_DATA when present. 4 admin-supplied topics.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Data Science Guidelines and Data Preparation","subsecs":[]},{"title":"Topic 2: Graph Data Mining, Pattern Discovery and Algorithm Selection","subsecs":[]},{"title":"Topic 3: Graph Machine Learning for Classification, Clustering and Prediction","subsecs":[]},{"title":"Topic 4: LLM-Powered Narrative Analytics and Insight Generation","subsecs":[]}] -->
<p><strong>Topic 1: Data Science Guidelines and Data Preparation</strong></p>
<p><strong>Topic 2: Graph Data Mining, Pattern Discovery and Algorithm Selection</strong></p>
<p><strong>Topic 3: Graph Machine Learning for Classification, Clustering and Prediction</strong></p>
<p><strong>Topic 4: LLM-Powered Narrative Analytics and Insight Generation</strong></p>'
WHERE entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 7. whoshouldattend -- the job-role list named the OLD product (Neo4j
--    Developer, Graph Database Administrator, ...). Re-pointed at data-mining /
--    modelling roles; genuinely generic data roles are kept as-is.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<ul>
<li>Data Scientist</li>
<li>Data Analyst</li>
<li>Data Mining Specialist</li>
<li>Machine Learning Engineer</li>
<li>Business Intelligence Analyst</li>
<li>Data Engineer</li>
<li>Predictive Analytics Specialist</li>
<li>Data Analytics Consultant</li>
<li>Research Analyst</li>
<li>Operations Analyst</li>
<li>Data Modelling Specialist</li>
<li>AI Solutions Architect</li>
<li>Data Visualization Expert</li>
<li>Statistical Analyst</li>
<li>Data Strategy Consultant</li>
<li>Product Manager (focused on data products)</li>
<li>Innovation Specialist</li>
<li>Business Owner or Manager working with data</li>
</ul>'
WHERE entity_id = @e AND attribute_id = @a_who;

-- ---------------------------------------------------------------------------
-- 8. trainerprofile -- retarget the COURSE-TEACHING paragraph only (para 2 of
--    each bio). Career-history / credential paragraphs are left factual.
--    One exact single-line REPLACE() per bio (CRLF-safe).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'In &ldquo;Neo4j Graph Data Science and Large Language Model (LLM),&rdquo; Hwee Theng combines her expertise in data architecture, AI strategy, and applied analytics to help professionals harness graph databases and generative AI for knowledge discovery. Her training emphasizes the integration of Neo4j graph algorithms with LLMs for intelligent data reasoning and context-aware automation. Through practical projects, she equips participants to design scalable graph-based AI systems capable of uncovering deep insights from complex, interconnected data.',
      'In &ldquo;AI Vibe Coding for Data Mining and Modeling,&rdquo; Hwee Theng combines her expertise in data architecture, AI strategy, and applied analytics to help professionals mine data and build computational models for knowledge discovery. Her training emphasizes the use of AI coding assistants to prepare data, select algorithms, and interpret complex relationships within datasets. Through practical projects, she equips participants to design reliable data mining workflows capable of uncovering deep insights from complex, interconnected data.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'In &ldquo;Neo4j Graph Data Science and Large Language Model (LLM),&rdquo; Woei Ming guides learners through building intelligent graph-based AI systems for industrial and enterprise use cases. His sessions emphasize connecting knowledge graphs with LLMs to enhance reasoning, automation, and decision intelligence. By applying his expertise in data engineering and model deployment, he empowers participants to integrate Neo4j and AI pipelines for advanced analytics and contextual data understanding.',
      'In &ldquo;AI Vibe Coding for Data Mining and Modeling,&rdquo; Woei Ming guides learners through building computational models for industrial and enterprise use cases. His sessions emphasize AI-assisted coding for classification, clustering, and prediction to enhance reasoning, automation, and decision intelligence. By applying his expertise in data engineering and model deployment, he empowers participants to build end-to-end Python pipelines for advanced analytics and contextual data understanding.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'In &ldquo;Neo4j Graph Data Science and Large Language Model (LLM),&rdquo; Siew Yee teaches professionals how to design and operationalize graph-based AI systems. His training focuses on the convergence of knowledge graphs, NLP, and generative AI&mdash;demonstrating how Neo4j can be used to enhance reasoning, contextual retrieval, and intelligent automation. His sessions blend technical rigor with strategic insight, preparing learners to apply graph-based AI in real-world business transformation initiatives.',
      'In &ldquo;AI Vibe Coding for Data Mining and Modeling,&rdquo; Siew Yee teaches professionals how to design and operationalize data mining workflows. His training focuses on the convergence of pattern discovery, model evaluation, and generative AI&mdash;demonstrating how AI vibe coding can be used to enhance reasoning, insight generation, and intelligent automation. His sessions blend technical rigor with strategic insight, preparing learners to apply data mining and modelling in real-world business transformation initiatives.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'In &ldquo;Neo4j Graph Data Science and Large Language Model (LLM),&rdquo; Truman teaches how to integrate AI pipelines with Neo4j graph databases in hybrid and cloud environments. His sessions emphasize secure architecture, model orchestration, and performance optimization. By merging practical engineering with AI reasoning concepts, he helps learners design robust, production-ready multi-agent AI and graph-driven solutions that support enterprise-level data intelligence.',
      'In &ldquo;AI Vibe Coding for Data Mining and Modeling,&rdquo; Truman teaches how to build AI-assisted data pipelines and computational models in hybrid and cloud environments. His sessions emphasize secure architecture, model orchestration, and performance optimization. By merging practical engineering with AI reasoning concepts, he helps learners design robust, production-ready data mining and modelling solutions that support enterprise-level data intelligence.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'In &ldquo;Neo4j Graph Data Science and Large Language Model (LLM),&rdquo; James focuses on the creative and practical aspects of visualizing graph-based data and integrating LLMs into data storytelling. His sessions guide learners to apply Neo4j visualization tools, prompt engineering, and generative models for building intelligent dashboards and narrative-driven AI systems. With his strong design and technology background, he enables participants to communicate complex relationships and insights effectively using graph-based AI.',
      'In &ldquo;AI Vibe Coding for Data Mining and Modeling,&rdquo; James focuses on the creative and practical aspects of visualizing mined data and integrating LLMs into data storytelling. His sessions guide learners to apply Python visualization tools, prompt engineering, and generative models for building intelligent dashboards and narrative-driven insights. With his strong design and technology background, he enables participants to communicate complex relationships and insights effectively using AI vibe coding.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

-- ---------------------------------------------------------------------------
-- 9. learning_outcomes cms_block -- the What You'll Learn card. The admin-supplied
--    LOs are the live SSG-registered LOs with the Neo4j product wording removed.
--    The block EXISTS (block_id 1754, verified), so a plain UPDATE is safe here;
--    no guarded INSERT needed (contrast: memory surface 6b).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Develop data science guidelines to enhance data-mining applications.</li>
<li>LO2:&nbsp;Identify and rectify data problems.</li>
<li>LO3:&nbsp;Construct graph machine learning models to identify patterns and trends in data sets.</li>
<li>LO4:&nbsp;Perform narrative analytics using Large Language Model (LLM) models.</li>
</ul>'
WHERE identifier = 'course_TGS-2024045802_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 10. Category placement -- drop the two Neo4j-product listings, mirrored into
--     catalog_category_product_index or the storefront never changes.
--     416 "Graph Database" (8 members, pure graph-product listing), 110
--     "Databases" (30 members). Every other placement still applies.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product       WHERE product_id = @e AND category_id IN (110, 416);
DELETE FROM catalog_category_product_index WHERE product_id = @e AND category_id IN (110, 416);
