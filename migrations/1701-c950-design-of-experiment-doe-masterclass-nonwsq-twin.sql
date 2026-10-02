-- C950 Design of Experiment (DOE) Masterclass = the 2-day non-WSQ twin of TGS-2024051249 (WSQ - Practical
-- Design of Experiment (DoE) for Engineers and Researchers). Courseware v1.0 converted from the WSQ v6.0 set
-- (github.com/tertiarycourses/C950-Design-of-Experiment-DOE-Masterclass).
--
-- 1. "What's This Course About" copied from the parent (its "This WSQ course, <parent title>," opener names this
--    course instead); course topics copied from the parent's LSN_DATA (same 4 topics / 35 sub-topics; latin1
--    NBSP / en-dash bytes ASCII-sanitised). No day count, no WSQ wording. Store-scope overrides removed.
-- 2. Prerequisite: software was "TBD" -> the courseware's tools (browser-based NovaDOE + Excel workbooks).
-- 3. Funding block course_C950_funding_and_grant (did not exist) created, store 0, house wording pointing at the
--    WSQ twin https://www.tertiarycourses.com.sg/wsq-practical-design-of-experiment-doe-for-engineers-and-researchers.html
--    (returns 200).
-- Name / slug / fee / duration / sessions / meta are already right ( / 15 / 2, meta states no day count).
-- Schedule template B17 -> B19 (parent is on (SG) WSQ-B19) is a code path
-- (CoursesaveController::switchScheduleTemplateAction), not SQL - done separately on prod.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C950' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024051249' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- ------------------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course, Design of Experiment (DOE) Masterclass, equips participants with essential skills to design, analyze, and optimize experiments for improved process performance. Participants will gain a thorough understanding of DoE fundamentals, factorial experiments, and how to apply ANOVA to assess the significance of variables. By learning how to identify key factors affecting performance, participants will be able to confidently select appropriate DoE projects and execute them with precision.</p>\n<p>The course covers advanced topics like fractional factorial designs, screening methods, and modeling techniques such as Taguchi and Response Surface Methodology (RSM). By the end of the course, learners will be able to evaluate the effectiveness of their DoE projects and make data-driven recommendations for continuous process improvement.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1 Fundamentals of Design of Experiment","subsecs":[{"title":"Introduction to Design of Experiment (DoE)","links":[]},{"title":"Dependent and Independent variables","links":[]},{"title":"Purpose of DoE","links":[]},{"title":"Stages of DoE","links":[]},{"title":"Factor, Level and Treatment","links":[]},{"title":"Introduction to single factor experiments","links":[]},{"title":"One-Way Analysis of Variance (ANOVA)","links":[]},{"title":"Decomposition of the Sum of Squares","links":[]}]},{"title":"Topic 2 Factorial DoE","subsecs":[{"title":"Introduction to Factorial DoE","links":[]},{"title":"Main Effects and Interactions between factors","links":[]},{"title":"Why using Factorial DoE","links":[]},{"title":"Two-Factors Two-Levels (2^2) DoE","links":[]},{"title":"Regression equation for 2^2 DoE","links":[]},{"title":"2^2 experiment with Interactions","links":[]},{"title":"Regression model for 2^2 DoE with Interactions","links":[]},{"title":"Analysis of Variance (ANOVA) of 2^2 DoE","links":[]},{"title":"Adding the third factor - 2^3 DoE","links":[]},{"title":"ANOVA of 2^3 DoE","links":[]},{"title":"Regression model for 2^3 DoE","links":[]},{"title":"General 2^k DoE","links":[]},{"title":"Analysis procedure of any 2^k DoE","links":[]},{"title":"Blocking a replicated design","links":[]},{"title":"Analysis a 2^k DoE with blocks as replicates","links":[]},{"title":"Confounding a 2^k DoE in blocks","links":[]}]},{"title":"Topic 3 Fractional Factorial DoE","subsecs":[{"title":"Introduction to Fractional Factorial DoE","links":[]},{"title":"One-Half fraction designs","links":[]},{"title":"Confounding in partial factorial design","links":[]},{"title":"Design resolution","links":[]},{"title":"ANOVA of fractional DoE","links":[]},{"title":"One-Quarter fraction designs","links":[]}]},{"title":"Topic 4 Screening, Modeling and Optimizing DoE","subsecs":[{"title":"Screening designs","links":[]},{"title":"Plackett Burman design","links":[]},{"title":"Taguchi design","links":[]},{"title":"Response Surface Method (RSM)","links":[]},{"title":"Central Composite Design (CCD)","links":[]}]}] -->\n<p><strong>Topic 1 Fundamentals of Design of Experiment</strong></p>\n<p><em>Introduction to Design of Experiment (DoE)</em></p>\n<p><em>Dependent and Independent variables</em></p>\n<p><em>Purpose of DoE</em></p>\n<p><em>Stages of DoE</em></p>\n<p><em>Factor, Level and Treatment</em></p>\n<p><em>Introduction to single factor experiments</em></p>\n<p><em>One-Way Analysis of Variance (ANOVA)</em></p>\n<p><em>Decomposition of the Sum of Squares</em></p>\n<p><strong>Topic 2 Factorial DoE</strong></p>\n<p><em>Introduction to Factorial DoE</em></p>\n<p><em>Main Effects and Interactions between factors</em></p>\n<p><em>Why using Factorial DoE</em></p>\n<p><em>Two-Factors Two-Levels (2^2) DoE</em></p>\n<p><em>Regression equation for 2^2 DoE</em></p>\n<p><em>2^2 experiment with Interactions</em></p>\n<p><em>Regression model for 2^2 DoE with Interactions</em></p>\n<p><em>Analysis of Variance (ANOVA) of 2^2 DoE</em></p>\n<p><em>Adding the third factor - 2^3 DoE</em></p>\n<p><em>ANOVA of 2^3 DoE</em></p>\n<p><em>Regression model for 2^3 DoE</em></p>\n<p><em>General 2^k DoE</em></p>\n<p><em>Analysis procedure of any 2^k DoE</em></p>\n<p><em>Blocking a replicated design</em></p>\n<p><em>Analysis a 2^k DoE with blocks as replicates</em></p>\n<p><em>Confounding a 2^k DoE in blocks</em></p>\n<p><strong>Topic 3 Fractional Factorial DoE</strong></p>\n<p><em>Introduction to Fractional Factorial DoE</em></p>\n<p><em>One-Half fraction designs</em></p>\n<p><em>Confounding in partial factorial design</em></p>\n<p><em>Design resolution</em></p>\n<p><em>ANOVA of fractional DoE</em></p>\n<p><em>One-Quarter fraction designs</em></p>\n<p><strong>Topic 4 Screening, Modeling and Optimizing DoE</strong></p>\n<p><em>Screening designs</em></p>\n<p><em>Plackett Burman design</em></p>\n<p><em>Taguchi design</em></p>\n<p><em>Response Surface Method (RSM)</em></p>\n<p><em>Central Composite Design (CCD)</em></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- ------------------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>No installation needed for the designs - every lab generates its design in the browser with <span style="text-decoration: underline;"><a href="https://alfredang.github.io/novadoe/" target="_blank">NovaDOE</a></span></li>\n<li>Microsoft Excel (desktop or Microsoft 365) for the lab workbooks, and a modern web browser (Chrome, Edge, Firefox or Safari)</li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Window or Mac Laptops</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_prereq AND store_id <> 0;

-- ------------------------------------------------------------- funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C950 - Funding and Grant', 'course_C950_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C950_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C950_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C950_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-practical-design-of-experiment-doe-for-engineers-and-researchers.html" title="WSQ - Practical Design of Experiment (DoE) for Engineers and Researchers">WSQ - Practical Design of Experiment (DoE) for Engineers and Researchers</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C950_funding_and_grant';
