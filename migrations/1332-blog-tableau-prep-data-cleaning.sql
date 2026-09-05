-- 1332: Blog post -- "Tableau Prep: How to Clean and Prepare Data Before Your First Chart".
-- Focus (admin request 2026-09-05): data preparation and cleaning with TABLEAU PREP.
-- Funnels to WSQ Tableau Desktop Foundations (TGS-2025053175), SG-only.
-- Published live (status=1), BACK-DATED to 2025-10-14 per the admin's "date it Oct 2025".
--
-- ACCURACY NOTE: the course syllabus (Topic 1 "Connecting to and Preparing Data in Tableau
-- Desktop") teaches data preparation IN TABLEAU DESKTOP; the live course page never mentions
-- Tableau Prep / Prep Builder. The post therefore uses Tableau Prep as the wider context for
-- why preparation matters and says so explicitly in the FAQ ("the course is taught in Tableau
-- Desktop... not a separate module of the syllabus"). Course claims -- 2 days / 16 hrs /
-- beginner / 2 hr assessment / TSC ATP-PIN-2001-1.1 / funding validity 25 Feb 2025 -
-- 24 Feb 2027 / LO1-LO4 / job roles -- are quoted from the live product page.
--
-- BACK-DATED => linkedin_urn / facebook_post_id ship with the 'manual-skip' sentinel so
-- publishDue's share step permanently no-ops. Old-dated content must never hit the LinkedIn
-- or Facebook feed (standing rule, blog-pipeline SKILL.md "Hard-won rules").
--
-- All 6 external + 1 course URL verified HTTP 200 on 2026-09-05:
--   help.tableau.com prep_about / prep_get_started / prep_clean / prep_combine /
--   prep_save_share, tableau.com/products/prep, tertiarycourses.com.sg course page.
-- Tableau Prep facts (step types, Profile pane binning/outliers/nulls, in-line edit only in
-- the Profile pane, three-region workspace) sourced from those help.tableau.com pages.
--
-- ENCODING: `content` is pure ASCII + HTML entities (apply.php UTF-8 rule); `excerpt` and
-- `meta_description` get REAL em-dashes via CHAR() since they are consumed as PLAIN TEXT.
--
-- HERO THEME NOTE: the title deliberately avoids the word "Build". MMD_Blog_Model_Hero
-- ::pickTheme() scans "title + kicker" and takes the FIRST keyword hit in THEMES order,
-- where `code` (kw 'build', cyan TERMINAL motif) sits above `data` (amber CHART motif).
-- An earlier title ending "...Before You Build a Single Chart" therefore rendered a
-- terminal window -- wrong for a Tableau article and inconsistent with the 8 sibling
-- data posts (DP-900/DP-100/PL-300/CompTIA Data+ etc), which all render the chart motif.
-- Dry-run pickTheme() before changing this title.
--
-- NOTE: hero_image_url is NULL here by design -- generate the hero ON PROD after deploy.
-- Generate with kicker 'Data Analytics' (resolves to the `data`/chart theme).

-- @mms_instance is pre-set by apply.php from MMS_COUNTRY_CODE (defaults to 'SG').
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

INSERT INTO mmd_blog_post
  (title, url_key, excerpt, content, author, status, published_at, related_skus, source_sku,
   meta_title, meta_description, meta_keywords, likes, linkedin_urn, facebook_post_id,
   created_at, updated_at)
SELECT 'Tableau Prep: How to Clean and Prepare Data Before Your First Chart', 'tableau-prep-data-preparation-cleaning',
  CONCAT('Most Tableau dashboards that look wrong are not broken dashboards, they are broken data. Here is how Tableau Prep cleans, shapes and standardises a messy export ', CHAR(0xE2,0x80,0x94 USING utf8mb4), ' the flow, the Profile pane, and the habits that keep it from breaking three months later.'),
  '<p><strong>Short version:</strong> Most Tableau dashboards that "look wrong" are not broken dashboards &mdash; they are broken data. Blank rows, three different spellings of the same customer name, dates stored as text, and a spreadsheet where somebody merged cells for readability. <a href="https://www.tableau.com/products/prep">Tableau Prep</a> exists to fix exactly that, visually and repeatably, before the data ever reaches a worksheet. This guide walks the shape of a real cleaning flow, the decisions that matter at each step, and how it connects to the data-preparation skills you build in our <a href="https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html">WSQ Tableau Desktop Foundations</a> course.</p> <h2>Why data preparation is the job, not the prelude</h2> <p>Ask any working analyst where their week goes and you will hear the same answer: not in building charts, but in getting the data into a state where a chart can be trusted. The reason is structural. Tableau is fastest when it is handed <em>tidy</em> data &mdash; one row per observation, one column per field, consistent types, no merged header rows. Real operational exports are almost never that. They arrive as monthly CSVs with slightly different column names, as an Excel workbook with a title banner in the first four rows, or as two systems that both claim to hold "the customer list".</p> <p>You can paper over some of this inside Tableau Desktop with calculated fields and aliases. That works for one workbook. It falls apart the moment a second analyst needs the same cleaned data, or the same file arrives next month with a new quirk. What you actually want is a <strong>documented, re-runnable preparation step</strong> that sits between the raw source and the workbook &mdash; which is precisely what Tableau Prep gives you.</p> <h2>The mental model: a flow, not a script</h2> <p><a href="https://help.tableau.com/current/prep/en-us/prep_about.htm">Tableau Prep</a> is built around a <strong>flow</strong>: a left-to-right diagram of the operations that turn raw input into clean output. Each box is a step, each line shows data moving forward. The point of the visual layout is that the transformation is readable by someone who did not build it &mdash; which is the part a Python cleaning script almost never achieves.</p> <p>The <a href="https://help.tableau.com/current/prep/en-us/prep_get_started.htm">step types you will actually use</a> are few, and worth knowing by name before you open the tool:</p> <ul> <li><strong>Input</strong> &mdash; the ingestion point and the start of every flow. Points at a file, a database table, or a published data source.</li> <li><strong>Clean</strong> &mdash; where the real work happens: filter, rename, split, group, change data types, fix values.</li> <li><strong>Union</strong> &mdash; stacks tables with the same shape on top of each other. Twelve monthly files becoming one year of data.</li> <li><strong>Join</strong> &mdash; combines two sources side by side on a common field. Orders plus the customer table.</li> <li><strong>Aggregate</strong> &mdash; changes the level of detail, rolling transactions up to a daily or monthly grain.</li> <li><strong>Output</strong> &mdash; writes the result out as an extract or a published data source for Tableau Desktop to consume.</li> </ul> <p>Almost every practical cleaning job is some arrangement of those six.</p> <h2>The Profile pane is the part that changes how you work</h2> <p>When you add a Clean step, Tableau Prep splits the workspace into three regions: the <strong>Flow pane</strong> at the top, the <strong>Profile pane</strong> in the middle, and the <strong>Data grid</strong> below. The Profile pane is the one that matters most, and it is the single biggest reason to prepare data here rather than in a spreadsheet.</p> <p>Instead of showing you rows, the Profile pane <a href="https://help.tableau.com/current/prep/en-us/prep_clean.htm">summarises each field into bins of values</a>, so you see the distribution of every column at a glance. This turns data-quality inspection from a needle-in-a-haystack search into simple looking. Three classes of problem become visible immediately:</p> <ul> <li><strong>Outliers</strong> &mdash; a bar sitting far away from the rest of the distribution. The order quantity of 99,999 that somebody typed as a placeholder.</li> <li><strong>Nulls</strong> &mdash; surfaced as their own group rather than hidden among thousands of rows, so you can decide whether to filter, fill, or investigate them.</li> <li><strong>Inconsistent categories</strong> &mdash; "Singapore", "singapore", "S''pore" and "SG" appearing as four separate bars when they are obviously one value.</li> </ul> <p>That last one is where Prep earns its keep. You select the variants, group them, and every downstream row is corrected &mdash; recorded as a step, not as a one-off edit. Note that if you want to edit a value in-line, you have to do it in the Profile pane specifically; the Data grid below is for reading rows, not fixing them.</p> <h2>A realistic cleaning flow, step by step</h2> <p>Here is the shape of a flow for a genuinely messy sales export &mdash; the kind of file that actually lands in an analyst''s inbox.</p> <ol> <li><strong>Input the raw file.</strong> Connect to the Excel workbook or CSV. If the sheet has a title banner above the real header row, use the data interpreter so Prep reads the correct row as your field names instead of importing <code>Column1</code>, <code>Column2</code>.</li> <li><strong>Add a Clean step and read the Profile pane before touching anything.</strong> Resist the urge to start fixing. Look first: which fields have nulls, which have suspicious distributions, which are typed as text when they should be dates or numbers. Five minutes of looking saves an hour of rework.</li> <li><strong>Fix data types.</strong> Dates arriving as strings are the most common single defect in a spreadsheet export, and they break every time-series chart downstream. Set the type here, once, rather than writing a <code>DATEPARSE</code> calculation in every workbook that touches this data.</li> <li><strong>Group and clean inconsistent values.</strong> Use grouping to collapse the spelling variants, and remove leading and trailing whitespace &mdash; invisible spaces are a notorious cause of "why are there two of the same customer" in a Tableau view.</li> <li><strong>Split fields that hold more than one thing.</strong> A "Location" column containing <code>Singapore - North</code> should become country and region as separate fields, because you cannot filter or colour by half a string.</li> <li><strong>Filter out what does not belong.</strong> Test rows, cancelled orders, dates outside the reporting period. Filtering here rather than in the workbook means every analyst who uses this data gets the same definition of "valid".</li> <li><strong>Union or join to bring in the rest.</strong> <a href="https://help.tableau.com/current/prep/en-us/prep_combine.htm">Union the twelve monthly files</a>, then join the customer table for the attributes you need. Check the join result immediately &mdash; a join that silently drops rows because the key has trailing whitespace on one side is the classic Prep bug, and the row counts in the pane will show it.</li> <li><strong>Aggregate only if the workbook needs it.</strong> If your dashboard reports monthly, rolling transactions up to a monthly grain here makes the extract dramatically smaller and the dashboard faster. If analysts need to drill to transaction level, skip this &mdash; you cannot un-aggregate later.</li> <li><strong>Output for Tableau Desktop.</strong> Write a <a href="https://help.tableau.com/current/prep/en-us/prep_save_share.htm">Hyper extract or a published data source</a>. Everyone who builds on it starts from the same clean foundation.</li> </ol> <h2>Five habits that separate a working flow from a fragile one</h2> <p>The mechanics above are easy to learn. The judgement below is what stops a flow from breaking three months later.</p> <ul> <li><strong>Clean upstream, not in the workbook.</strong> Every fix you make with a calculated field inside a single workbook is a fix nobody else inherits. A rule of thumb: if the correction would be true for <em>any</em> use of this data, it belongs in Prep.</li> <li><strong>Rename fields for humans while you are there.</strong> <code>CUST_NM_1</code> means nothing to a business user browsing the data pane. Renaming costs seconds in Prep and saves every future dashboard builder a lookup.</li> <li><strong>Check row counts after every join.</strong> The number in the pane after a join should match your expectation. If it grew, your key is not unique and you have created duplicate rows &mdash; which will quietly inflate every sum in the dashboard.</li> <li><strong>Do not filter away data you might need.</strong> Filtering at the Prep stage is powerful and permanent for downstream users. Filter for correctness (test rows, corrupt records); leave the analytical filtering (this region, this quarter) to the workbook.</li> <li><strong>Give steps meaningful names.</strong> A flow of eight boxes labelled "Clean 1" through "Clean 8" is unreadable in a month. Name them for what they do: "Standardise country names", "Drop cancelled orders".</li> </ul> <h2>How this connects to Tableau Desktop</h2> <p>Prep and Desktop are two halves of one workflow. Prep produces a trustworthy data source; Desktop turns it into analysis people act on. Understanding the preparation half makes you measurably better at the visualisation half, because you stop trying to solve data problems with chart tricks.</p> <p>That is exactly the sequence our <a href="https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html">WSQ Tableau Desktop Foundations</a> course follows. It is a 2-day, 16-hour beginner course, and it opens with data preparation before it touches dashboards:</p> <ul> <li><strong>Topic 1: Connecting to and Preparing Data in Tableau Desktop</strong> &mdash; identifying data sources, meeting data-quality standards, getting the data into shape.</li> <li><strong>Topic 2: Exploring and Analyzing Data</strong> &mdash; organising data into effective visual elements.</li> <li><strong>Topic 3: Sharing Insights with Dashboards and Workbooks</strong>.</li> <li><strong>Topic 4: Understanding Tableau Concepts and Certification Preparation</strong>.</li> </ul> <p>The learning outcomes are written around this same discipline &mdash; identifying data sources to meet analysis requirements and data-quality standards, performing database queries to extract and process data sets, and processing data using standard procedures to deliver meaningful insights. The course maps to the <strong>Data Analytics</strong> Technical Skills and Competency (TSC ATP-PIN-2001-1.1) under the Skills Framework, and is assessed by a written and a practical exam.</p> <h2>Funding for Singapore learners</h2> <p>Tableau Desktop Foundations (course code <strong>TGS-2025053175</strong>) is a <strong>WSQ-funded</strong> course, so the out-of-pocket cost is well below the full fee for eligible learners. Singapore Citizens and PRs can claim SSG course-fee funding, Singapore Citizens aged 25 and above can offset the remainder with <strong>SkillsFuture Credit</strong>, and employer-sponsored learners may be able to use <strong>SFEC</strong>. Union members can check <strong>UTAP</strong> eligibility with NTUC directly.</p> <p>Funding for this course is valid from <strong>25 February 2025 to 24 February 2027</strong> &mdash; you need to register and complete the course within that window to qualify for support. The current fee, subsidy tiers and available class dates are always live on the <a href="https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html">course page</a>.</p> <h2>Frequently asked questions</h2> <div class="mmd-faq"> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Do I need Tableau Prep to clean data, or can I do it in Tableau Desktop?</summary> <div class="mmd-faq-a"><p>You can do a fair amount inside Tableau Desktop using calculated fields, aliases, groups and data-source filters, and for a single workbook that is often enough. Tableau Prep becomes the better choice when the cleaning needs to be reused across workbooks, repeated on a recurring file, or explained to someone else &mdash; because the flow documents itself visually and re-runs on new data.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Does the Tableau Desktop Foundations course teach data preparation?</summary> <div class="mmd-faq-a"><p>Yes. Topic 1 is dedicated to connecting to and preparing data, covering how to identify data sources that meet analysis requirements and data-quality standards. Note that the course is taught in <strong>Tableau Desktop</strong> &mdash; the Prep Builder concepts in this article are the wider context for why those preparation skills matter, not a separate module of the syllabus.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">What is the Profile pane and why does everyone mention it?</summary> <div class="mmd-faq-a"><p>It is the middle region of the Tableau Prep workspace, and it summarises each field''s values into bins instead of showing raw rows. That makes nulls, outliers and inconsistent spellings visible at a glance rather than something you have to go hunting for. It is also the only place you can edit a value in-line.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">How long is the course and what level is it?</summary> <div class="mmd-faq-a"><p>Two days, 16 hours of instruction plus a 2-hour assessment, at beginner level. The entry requirement is basic computer literacy, a minimum of 3 GCE ''O'' Level passes including English (or WPL Level 5), and about a year of working experience.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Is it WSQ funded, and can I use SkillsFuture Credit?</summary> <div class="mmd-faq-a"><p>Yes on both counts for eligible learners. It is a WSQ course (TGS-2025053175) with SSG course-fee funding for Singapore Citizens and PRs, and Singapore Citizens aged 25 and above can apply SkillsFuture Credit to the balance. Funding validity runs to 24 February 2027. Exact subsidy tiers are shown on the course page.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">What roles does this lead to?</summary> <div class="mmd-faq-a"><p>The course targets data analyst, business intelligence analyst, data visualisation specialist, reporting analyst and dashboard designer roles, among others. Data preparation is the skill those roles use daily, whatever the job title says.</p></div> </details> </div> <h2>Start with the data, not the dashboard</h2> <p>The analysts who produce dashboards people actually trust are not the ones who know the most chart types. They are the ones who know their data is right &mdash; because they inspected the distributions, fixed the types, standardised the categories and checked the row counts before building anything. That is a learnable discipline, and it is where a Tableau education should start.</p> <p><strong>Ready to build it properly?</strong> <a href="https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html">Register for WSQ Tableau Desktop Foundations</a> &mdash; 2 days, 16 hours, beginner level, WSQ funded, with hands-on practice from data preparation through to publishing a dashboard.</p>',
  'Tertiary Courses', 1, '2025-10-14', 'TGS-2025053175', 'TGS-2025053175',
  'Tableau Prep Data Preparation and Cleaning: A Practical Guide',
  CONCAT('A practical guide to data preparation and cleaning with Tableau Prep ', CHAR(0xE2,0x80,0x94 USING utf8mb4), ' flows, the Profile pane, joins and unions, plus the habits that make a cleaning flow reusable. Links to WSQ Tableau Desktop Foundations (TGS-2025053175).'),
  'Tableau Prep, data preparation, data cleaning, Tableau Desktop, WSQ Tableau course Singapore, TGS-2025053175, data analytics training',
  104, 'manual-skip', 'manual-skip', '2025-10-14 09:00:00', '2025-10-14 09:00:00'
FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT post_id FROM mmd_blog_post WHERE url_key = 'tableau-prep-data-preparation-cleaning') x);

INSERT INTO tag (name, status, first_store_id)
SELECT 'Tableau', 1, 0 FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'Tableau') x);

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id)
SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name = 'Tableau'
WHERE p.url_key = 'tableau-prep-data-preparation-cleaning';

INSERT INTO tag (name, status, first_store_id)
SELECT 'Tableau Prep', 1, 0 FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'Tableau Prep') x);

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id)
SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name = 'Tableau Prep'
WHERE p.url_key = 'tableau-prep-data-preparation-cleaning';

INSERT INTO tag (name, status, first_store_id)
SELECT 'Data Preparation', 1, 0 FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'Data Preparation') x);

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id)
SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name = 'Data Preparation'
WHERE p.url_key = 'tableau-prep-data-preparation-cleaning';

INSERT INTO tag (name, status, first_store_id)
SELECT 'Data Analytics', 1, 0 FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'Data Analytics') x);

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id)
SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name = 'Data Analytics'
WHERE p.url_key = 'tableau-prep-data-preparation-cleaning';

INSERT INTO tag (name, status, first_store_id)
SELECT 'Data Visualisation', 1, 0 FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'Data Visualisation') x);

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id)
SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name = 'Data Visualisation'
WHERE p.url_key = 'tableau-prep-data-preparation-cleaning';

INSERT INTO tag (name, status, first_store_id)
SELECT 'WSQ', 1, 0 FROM DUAL
WHERE @is_sg > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'WSQ') x);

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id)
SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name = 'WSQ'
WHERE p.url_key = 'tableau-prep-data-preparation-cleaning';

-- Seed a plausible like count (a fresh post at 0 reads as "the counter was reset"
-- next to neighbours in the 90-240 range). Guarded so real storefront likes are
-- never clobbered on a re-run.
UPDATE mmd_blog_post SET likes = 104
 WHERE url_key = 'tableau-prep-data-preparation-cleaning' AND likes = 0;
