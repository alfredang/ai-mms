-- 945-repurpose-tgs2021008700-ai-vibe-coding-for-excel-vba.sql
--
-- Repurpose SG WSQ course TGS-2021008700 (entity 1219):
--   "WSQ - Software Automation with Excel VBA Programming"
--        -> "WSQ - AI Vibe Coding for Excel VBA"
--
-- SKU is UNCHANGED, so every SkillsFuture / SFC / SFEC / PSEA / UTAP deep link
-- keyed on the course code stays valid, and the SSG-accredited learning outcomes
-- (LO1-LO5, in cms_block course_TGS-2021008700_learning_outcomes) are delivered
-- against the same outcomes -- that block already matches the requested LO list
-- byte-for-byte and is deliberately NOT touched.
--
-- Slug: the SG non-WSQ twin C357 ALREADY owns 'ai-vibe-coding-for-excel-vba',
-- so the WSQ page takes the 'wsq-' prefixed slug. The old bare slug 301s to it.
--
-- Store guard: SG-only (this SKU exists only on the SG site); every statement is
-- entity-id scoped, so it is a no-op on partner DBs where entity 1219 is absent
-- or a different product. Guarded by a SKU check on the entity id.
--
-- Idempotent: INSERT ... ON DUPLICATE KEY UPDATE / guarded REPLACE()s.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021008700');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "WSQ - " prefix; the storefront H1 wants it)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 71, 0, @e, 'WSQ - AI Vibe Coding for Excel VBA'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2. meta_title -- PLAIN title. No leading "WSQ", no "| Tertiary Courses ..."
--    suffix: MMD_Seotitle composes <title> at render time (prepends the funding
--    token for SG TGS- SKUs and appends the brand postfix). Baking either in
--    yields "WSQ funded WSQ ... | Tertiary Courses Singapore".
--    Delete the store_id=1 override so the store 0 value is what renders.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 82, 0, @e, 'AI Vibe Coding for Excel VBA Course'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = 82 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. meta_description  (varchar attr -- feeds <meta name=description>,
--    og:description, twitter:description AND the JSON-LD description)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 84, 0, @e,
'Learn AI vibe coding for Excel VBA. Use natural-language prompts and AI coding assistants to generate, test and debug VBA macros, custom functions and forms that automate spreadsheet work. Enjoy up to 70% WSQ funding subsidy.'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = 84 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. meta_keyword (text attr)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 83, 0, @e,
'AI Vibe Coding, Excel VBA, VBA Programming, AI Coding Assistant, Excel Automation, Macros, User Defined Functions, WSQ'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 83 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. short_description -- "About This Course" (5 paragraphs as supplied).
--    This course's sections were already extracted to per-course cms/blocks
--    (no "<h2>Course Brochure</h2>" tail remains), so a full replace is correct
--    -- a LOCATE()-guarded splice would silently no-op here.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 73, 0, @e,
'<p>This course equips participants with practical skills to use AI vibe coding to create and improve Excel VBA automation solutions. Learners will use natural-language instructions and AI coding assistants to generate, explain, test, debug, and refine VBA code, enabling them to automate spreadsheet tasks without writing every line of code manually.</p>
<p>Participants will learn essential Excel VBA concepts, including the Visual Basic Editor, macros, variables, data types, procedures, functions, conditional statements, loops, and event-driven programming. They will apply these concepts to automate repetitive activities such as data entry, formatting, calculations, report generation, workbook management, and data validation.</p>
<p>The course also covers developing custom functions, creating interactive forms and controls, processing large datasets, handling errors, and integrating multiple worksheets and workbooks. Learners will use AI-assisted workflows to convert business requirements into working VBA solutions, troubleshoot code, and improve the reliability and maintainability of spreadsheet applications.</p>
<p>Through hands-on business projects, participants will build end-to-end Excel automation workflows that reduce manual effort, minimise errors, and improve operational efficiency. Emphasis is placed on reviewing AI-generated code, protecting sensitive data, documenting solutions, and applying safe macro practices.</p>
<p>By the end of the course, learners will be able to use AI vibe coding to design, develop, test, and maintain Excel VBA applications for finance, administration, operations, reporting, and other data-intensive business functions.</p>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 73 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. description -- Course Outline, 5 topics, h3 course-topic-h3 format
--    (matches the existing markup shape on this page).
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<h3 class="course-topic-h3">Topic 1: AI Vibe Coding for Excel VBA, Macros and Interface Design</h3>
<ul>
<li>What is AI Vibe Coding</li>
<li>AI Coding Assistants for Excel VBA</li>
<li>Access VBA and the Visual Basic Editor from Excel</li>
<li>Recording and Editing Macros</li>
<li>Prompting AI to Generate Your First VBA Code</li>
<li>Designing a Simple Excel Interface</li>
</ul>
<h3 class="course-topic-h3">Topic 2: VBA Programming Logic, Variables, Decisions and Loops</h3>
<ul>
<li>Variables and Constants</li>
<li>Data Types and Arrays</li>
<li>Operators and Expressions</li>
<li>Decisions and Conditional Statements</li>
<li>Loops and Iteration</li>
<li>Explaining and Refining AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Creating Custom Functions and Automated Procedures</h3>
<ul>
<li>Sub Procedures</li>
<li>User Defined Functions</li>
<li>Passing Arguments and Returning Values</li>
<li>Automating Data Entry, Formatting and Calculations</li>
<li>Generating Reports with AI-Assisted Workflows</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Managing Excel Objects, Testing and Debugging VBA Code</h3>
<ul>
<li>Excel Object Model: Workbooks, Worksheets, Ranges</li>
<li>Working Across Multiple Worksheets and Workbooks</li>
<li>Processing Large Datasets</li>
<li>Error Handling and Safe Macro Practices</li>
<li>Testing and Debugging with AI Assistance</li>
</ul>
<h3 class="course-topic-h3">Topic 5: Developing User-Defined Forms, Events and Documentation</h3>
<ul>
<li>User Forms and Controls</li>
<li>Events and Event Procedures</li>
<li>Building Interactive Business Applications</li>
<li>Reviewing AI-Generated Code and Protecting Sensitive Data</li>
<li>Documenting and Maintaining VBA Solutions</li>
</ul>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. Cover alt text: image_label / small_image_label / thumbnail_label
--    -- plain title, no "WSQ - " prefix (the cover itself strips the prefix).
--    The image/small_image/thumbnail PATHS are deliberately NOT renamed: they
--    are filesystem paths, not display text, and renaming them 404s the file.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @e, 'AI Vibe Coding for Excel VBA'
FROM eav_attribute a
WHERE a.entity_type_id = 4
  AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
  AND @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Vibe Coding for Excel VBA'
WHERE g.entity_id = @e
  AND @e IS NOT NULL
  AND gv.label LIKE '%Software Automation%';

-- ---------------------------------------------------------------------------
-- 8. trainerprofile -- retarget ONLY the course-teaching paragraph of each bio.
--    Paragraph 1 of every bio is career-history CREDENTIALS (genuine Excel VBA
--    expertise, delivery history) -- those are FACTS and are left untouched;
--    rewriting them would falsify a bio. Only the "In <Old Title>, X teaches..."
--    sentence retargets to the new course.
--    Single-line REPLACE()s on the exact quoted title string, so the
--    &ldquo;/&rdquo;/&rsquo;/&mdash; entities around them survive.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '&ldquo;Software Automation with Excel VBA Programming,&rdquo;',
      '&ldquo;AI Vibe Coding for Excel VBA,&rdquo;')
WHERE entity_id = @e AND attribute_id = 153 AND @e IS NOT NULL;

-- Retarget the teaching-claim wording so the bios describe AI-assisted delivery.
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Jim focuses on teaching participants how to use VBA to automate repetitive tasks',
      'Jim focuses on teaching participants how to use AI vibe coding to generate VBA that automates repetitive tasks')
WHERE entity_id = @e AND attribute_id = 153 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Terence helps participants master the practical application of VBA in automating reporting systems and analytical workflows.',
      'Terence helps participants master AI-assisted VBA development for automating reporting systems and analytical workflows.')
WHERE entity_id = @e AND attribute_id = 153 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Sing Loon focuses on building a strong foundation in coding logic and automation best practices.',
      'Sing Loon focuses on building a strong foundation in coding logic, AI-assisted development and automation best practices.')
WHERE entity_id = @e AND attribute_id = 153 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Dwight guides participants through the full process of designing, developing, and deploying VBA-driven automation systems.',
      'Dwight guides participants through the full process of designing, developing, and deploying VBA-driven automation systems with AI coding assistants.')
WHERE entity_id = @e AND attribute_id = 153 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Dr. Ang provides participants with a comprehensive understanding of VBA programming principles and automation design.',
      'Dr. Ang provides participants with a comprehensive understanding of AI vibe coding, VBA programming principles and automation design.')
WHERE entity_id = @e AND attribute_id = 153 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 9. url_key -> 'wsq-ai-vibe-coding-for-excel-vba'
--    NOTE the 'wsq-' prefix: the SG non-WSQ twin C357 already owns the bare
--    'ai-vibe-coding-for-excel-vba' slug. Never take it.
--    Delete url_path at EVERY scope so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 97, 0, @e, 'wsq-ai-vibe-coding-for-excel-vba'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = 97 AND store_id <> 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = 98 AND @e IS NOT NULL;

-- Clear any non-system squatter sitting on the NEW path, so the explicit 301
-- below (and the indexer) are not silently no-opped by a stale row.
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-ai-vibe-coding-for-excel-vba.html'
  AND is_system = 0;

-- Explicit permanent 301 from the OLD bare slug to the NEW one. The URL
-- Rewrites indexer auto-301s the ~20 category-prefixed paths on top of this.
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-software-automation-with-excel-vba-programming.html'
  AND is_system = 1;

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, NULL,
       'rp_tgs2021008700_vibecoding',
       'wsq-software-automation-with-excel-vba-programming.html',
       'wsq-ai-vibe-coding-for-excel-vba.html',
       0, 'RP', 'Repurpose 945: Software Automation with Excel VBA -> AI Vibe Coding for Excel VBA'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE
  target_path = VALUES(target_path),
  options     = VALUES(options),
  description = VALUES(description);

-- ---------------------------------------------------------------------------
-- 10. course_image_url -- the branded cover, re-rendered from the NEW title
--     (funding badges WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC /
--     Absentee Payroll / MCES preserved) and uploaded to R2.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 203, 0, @e,
'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021008700-20260813-034253.png'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 11. Brochure cms_block title (the PDF path is keyed on the UNCHANGED SKU, so
--     only the human-facing block title moves).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET title = 'Course Brochure - TGS-2021008700'
WHERE identifier = 'course_TGS-2021008700_brochure';

-- ---------------------------------------------------------------------------
-- Deliberately NOT touched, and why:
--   * cms_block course_TGS-2021008700_learning_outcomes -- LO1-LO5 already match
--     the requested outcomes byte-for-byte; they are the SSG-accredited outcomes
--     registered against the unchanged SKU.
--   * whoshouldattend -- 15 technology-neutral job roles (Data Analyst, Business
--     Analyst, ...). Verified clean of old-tech terms.
--   * prerequisite -- verified clean of old-title/old-tech terms; it also holds
--     the entire funding apparatus (PWM, eligibility table, SkillsFuture / PSEA /
--     SFEC / UTAP deep links, Appeal Process). Never rewrite wholesale.
--   * image / small_image / thumbnail -- filesystem paths, not display text.
--   * catalogsearch_query -- every VBA-intent row on SG has an EMPTY redirect
--     (verified: 76 rows, all redirect = ''), so there is nothing to retarget.
--   * duration (16) / price (750) / categories -- the subject is still Excel VBA
--     automation, so placements and commercials are unchanged.
--   * course_image_url -- the cover PNG still bakes the OLD title; it is
--     re-rendered from the new name post-deploy (CLI/admin), not via SQL.
-- ---------------------------------------------------------------------------
