-- 949: Repurpose TGS-2024049780
--   "WSQ - Bioinformatics Data Analysis with R Bioconductor"
--     -> "WSQ - AI for Life Science and Bioinformatics"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: topic pivot from R/Bioconductor tooling
-- to AI-assisted life-science + bioinformatics workflows.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (LSN_DATA JSON
-- kept in sync with the visible markup), whoshouldattend, trainerprofile (para 2
-- of each bio only), image/small_image/thumbnail labels, media-gallery label,
-- 301 for the old bare slug, category placement (add AI Courses 252; drop the
-- R-tool category 106), and the AI Courses index mirror.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024049780_learning_outcomes -- the supplied LO1-LO5 are
--     byte-equivalent to the live block; they are the SSG-accredited outcomes
--     registered against the unchanged SKU.
--   * prerequisite -- "Software: NIL"; holds the entire funding apparatus
--     (SWDA TG, SkillsFuture, UTAP, Appeal Process). No old-tool link present.
--   * course_TGS-2024049780_skills_framework -- HCE-DAT-4007-1.1 (Healthcare SF)
--     still describes the course.
--   * brochure / certification / funding_and_grant blocks -- keyed on the SKU.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024049780' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI for Life Science and Bioinformatics'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Life Science and Bioinformatics'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply AI and computational methods to life science and bioinformatics data. Covers sequence analysis, genomic variants, protein structures, transcriptomics, machine learning for biological pattern discovery, and scientific data visualisation.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI for life science, bioinformatics course, AI bioinformatics, sequence analysis, genomic variant detection, protein structure analysis, transcriptomics, gene expression analysis, machine learning biology, bioinformatics data visualisation, WSQ bioinformatics course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-life-science-and-bioinformatics'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-for-life-science-and-bioinformatics.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row
-- in place into a permanent redirect instead; the indexer then mints a fresh
-- system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-for-life-science-and-bioinformatics.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-bioinformatics-data-analysis-with-r-bioconductor.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024049780-rp-949-', s.store_id),
       'wsq-bioinformatics-data-analysis-with-r-bioconductor.html',
       'wsq-ai-for-life-science-and-bioinformatics.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Life Science and Bioinformatics'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for Life Science and Bioinformatics'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. Subsections dropped: the supplied outline is
-- topic-level only. Replacement text is clean ASCII (the outgoing row carries
-- latin1 \x96 bytes that would choke apply.php's utf8 connection).
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Bioinformatics Fundamentals and Biological Sequence Analysis","subsecs":[]},{"title":"Topic 2: Protein Structure Analysis and Genomic Variant Detection","subsecs":[]},{"title":"Topic 3: Transcriptomics, Genomics and Gene Expression Analysis","subsecs":[]},{"title":"Topic 4: Machine Learning for Biological Pattern Discovery and Prediction","subsecs":[]},{"title":"Topic 5: Bioinformatics Data Visualisation and Scientific Insight Communication","subsecs":[]}] -->
<p><strong>Topic 1: Bioinformatics Fundamentals and Biological Sequence Analysis</strong></p>
<p><strong>Topic 2: Protein Structure Analysis and Genomic Variant Detection</strong></p>
<p><strong>Topic 3: Transcriptomics, Genomics and Gene Expression Analysis</strong></p>
<p><strong>Topic 4: Machine Learning for Biological Pattern Discovery and Prediction</strong></p>
<p><strong>Topic 5: Bioinformatics Data Visualisation and Scientific Insight Communication</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Post-885 block model: this course's short_description is prose only (977 bytes,
-- no <h2>Course Brochure</h2> tail, no SKU deep links) => a full replace is safe.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to apply artificial intelligence and computational methods to life science and bioinformatics data. Learners will explore how biological information can be collected, prepared, analysed, and interpreted to support research in genomics, transcriptomics, proteomics, drug discovery, and personalised healthcare.</p>
<p>Participants will learn the foundations of bioinformatics, including biological databases, sequence analysis, alignment, gene expression, genomic variation, and protein structure analysis. They will work with complex biological datasets to identify patterns, compare sequences, detect variants, and investigate relationships between genes, proteins, biological functions, and disease-related processes.</p>
<p>The course also introduces machine learning techniques for classifying biological data, predicting outcomes, detecting anomalies, clustering samples, and identifying important features. Learners will apply suitable evaluation methods to assess model performance and avoid issues such as overfitting, biased data, and incorrect biological interpretations.</p>
<p>Through hands-on activities, participants will use AI-assisted analytical workflows to explore datasets, visualise results, summarise scientific findings, and communicate evidence-based insights. Emphasis is placed on data quality, reproducibility, privacy, ethical use, model transparency, and the validation of AI-generated conclusions by qualified professionals.</p>
<p>By the end of the course, learners will be able to develop bioinformatics analysis workflows, apply AI techniques to life science data, evaluate analytical results, and present meaningful findings that support biological research and informed scientific decision-making.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------ 7. Who Should Attend
-- The old list named the retired tool ("R Programmer (Bioinformatics)"); the
-- rest of the roles stay valid for an AI-for-life-science course.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Bioinformatics Analyst</li>
<li>Data Scientist (Bioinformatics)</li>
<li>Computational Biologist</li>
<li>Biostatistician</li>
<li>Genomics Data Scientist</li>
<li>Bioinformatics Research Scientist</li>
<li>Molecular Data Analyst</li>
<li>Proteomics Data Analyst</li>
<li>Genomic Data Analyst</li>
<li>Clinical Bioinformatics Specialist</li>
<li>Bioinformatics Software Developer</li>
<li>Machine Learning Engineer (Life Sciences)</li>
<li>Bioinformatics Consultant</li>
<li>Biotechnologist</li>
<li>Biomedical Data Scientist</li>
<li>AI Engineer (Life Sciences)</li>
<li>Big Data Analyst (Life Sciences)</li>
<li>Research Associate (Genomics)</li>
<li>Systems Biologist</li>
<li>Healthcare Data Scientist</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 8. Trainer bios
-- Each bio is two paragraphs: para 1 = career CREDENTIALS (real R/Python
-- expertise, PhD, Plano/Tertiary history) -- FACTS, left untouched; para 2 = a
-- course-teaching claim scoped to the old R/Bioconductor topic -- retargeted.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Dwight guides learners through the fundamentals of bioinformatics data analysis using R and Bioconductor. His sessions emphasize workflow design, genomic data processing, and statistical interpretation for biological datasets. Learners gain practical experience in applying Bioconductor tools for sequence analysis, gene expression profiling, and biological network visualization. With his applied, research-driven approach, participants learn to harness R for advanced biological data analytics and scientific discovery.',
       'In this course, Dwight guides learners through the fundamentals of AI-assisted bioinformatics data analysis. His sessions emphasize workflow design, genomic data processing, and statistical interpretation for biological datasets. Learners gain practical experience in applying machine learning to sequence analysis, gene expression profiling, variant detection, and biological network visualization. With his applied, research-driven approach, participants learn to harness AI for advanced biological data analytics and scientific discovery.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Dr. Ang provides learners with a deep understanding of data-driven bioinformatics analysis using R and Bioconductor. His sessions focus on data preprocessing, visualization, and statistical modeling for genomics and proteomics research. Learners gain a comprehensive view of how R-based analytical workflows support precision medicine, biomarker discovery, and computational biology innovation. Through his structured and research-oriented instruction, participants build the capability to conduct reproducible and insightful biological data analysis using modern R frameworks.',
       'In this course, Dr. Ang provides learners with a deep understanding of AI-driven bioinformatics analysis. His sessions focus on data preprocessing, visualization, and predictive modeling for genomics and proteomics research. Learners gain a comprehensive view of how AI-assisted analytical workflows support precision medicine, biomarker discovery, and computational biology innovation. Through his structured and research-oriented instruction, participants build the capability to conduct reproducible and insightful biological data analysis using modern AI techniques.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the SUBJECT: drop the tool-specific "R" category (106),
-- and join cat 252 "AI Courses", the master listing every AI course belongs to.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE category_id = 106 AND product_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE category_id = 106 AND product_id = @e AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 252), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 252, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 252 AND cp.product_id = @e AND s.store_id > 0 AND @e IS NOT NULL;
