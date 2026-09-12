--
-- 1379: Blog post -- "Python for Finance Professionals: The IBF-STS Funded Route into Analytical Work"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-01-14 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - AI Assisted Python Programming for Finance (TGS-2025052659)
-- Page:   https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html
--
-- Funding facts are taken from the official IBF-STS scheme page
-- (https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS):
-- 50%% of direct training cost for SC/PR and 70%% for SCs aged 40 and above, both
-- capped at S$3,000 per participant per course; participant must be physically
-- based in Singapore and pass all assessments; company sponsors must be
-- MAS-regulated FIs or SFA-certified FinTech firms; once per calendar year.
--
-- SHARE SENTINELS: back-dated post, so `linkedin_urn` and `facebook_post_id`
-- are pre-set to 'manual-skip' -- old-dated content must never hit the social
-- feeds when publishDue picks it up.
--
-- `hero_image_url` stays NULL here; SQL cannot render a PNG. The editorial
-- hero is generated on PROD after this deploys and attached in a follow-up
-- migration.
--
-- All text is pure ASCII plus HTML entities so apply.php's UTF-8 PDO
-- connection cannot hit invalid legacy bytes.
--
-- SG-only: the courses are SG products. Guarded by @is_sg so partner
-- databases (MY/GH) are untouched.
--
-- Idempotent: guarded by the unique url_key; tag rows and links are guarded
-- independently; the likes top-up only fires while likes = 0.
-- apply.php splits on semicolon-at-EOL, so every statement ends accordingly.

-- @mms_instance is pre-set by apply.php from MMS_COUNTRY_CODE (defaults to 'SG').
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

INSERT INTO `mmd_blog_post`
  (`title`, `url_key`, `excerpt`, `content`, `author`, `status`, `published_at`,
   `related_skus`, `source_sku`, `likes`, `linkedin_urn`, `facebook_post_id`,
   `meta_title`, `meta_description`, `meta_keywords`, `created_at`, `updated_at`)
SELECT 'Python for Finance Professionals: The IBF-STS Funded Route into Analytical Work', 'ibf-python-programming-financial-services', 'Spreadsheets stop scaling long before the work does. Here is what an IBF-STS funded Python course covers, and why finance teams are the ones taking it.', '<p>There is a moment familiar to almost everyone who works with financial data. The monthly file arrives, the same twelve steps get repeated, a formula breaks somewhere in row 40,000, and an afternoon disappears into finding it. The analysis was never the hard part. The handling was.</p><p>That is the gap Python fills for finance teams, and it is the reason the <a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html"><strong>IBF - AI Assisted Python Programming for Finance</strong></a> course exists as an IBF-STS accredited programme rather than a generic coding class. The dataset is financial, the examples are financial, and the end state is a repeatable script instead of a fragile workbook.</p><h2>Why finance professionals specifically</h2><p>Python is popular everywhere, but the argument for finance is unusually concrete.</p><ul><li><strong>Volume.</strong> Market, transaction and position data routinely exceed what a spreadsheet handles comfortably. Pandas does not care about row counts in the same way.</li><li><strong>Repeatability.</strong> A script that imports, cleans, joins and summarises runs identically every month. A workbook that has been copied eleven times does not.</li><li><strong>Auditability.</strong> Code is reviewable. A reviewer can read what happened to the numbers; nobody can read a chain of nested formulas with confidence.</li><li><strong>Reach.</strong> Once data is in Python, everything downstream &mdash; statistics, visualisation, machine learning &mdash; is already within reach.</li></ul><p>The <a href="https://hai.stanford.edu/ai-index/2025-ai-index-report" rel="noopener" target="_blank">Stanford AI Index</a> has tracked the steady movement of analytical tooling out of specialist teams and into ordinary business roles. Finance is well inside that curve. The skill is no longer a differentiator for quants alone; it is becoming baseline literacy for anyone who owns a number.</p><h2>What the course actually covers</h2><p>The syllabus is built so that someone with no programming background arrives at working financial analysis, not at a certificate of attendance.</p><ul><li><strong>Foundations</strong> &mdash; installing Python and an IDE, data types, operators, and mapping business requirements to what code can do.</li><li><strong>Control structures and functions</strong> &mdash; conditionals, loops, comprehensions, reusable functions and lambdas for real use cases.</li><li><strong>Error handling</strong> &mdash; exceptions versus syntax errors, try/except, else and finally. This is the topic that separates a script that survives a bad input file from one that does not.</li><li><strong>Importing and processing finance data</strong> &mdash; pandas DataFrames and Series, importing finance data, filtering, slicing, and cleaning missing values.</li><li><strong>Aggregating and visualising</strong> &mdash; concat, append and merge; groupby and pivot tables; testing and plotting the result.</li><li><strong>Object-oriented programming</strong> &mdash; classes, objects, methods, inheritance and polymorphism, so larger analytical tools stay maintainable.</li><li><strong>Analysing finance data</strong> &mdash; improving code with pipe and apply, applying statistics, and tracking changes over time.</li></ul><p>The AI-assisted framing matters too. Coding assistants have changed how beginners get productive, but they have also made it easier to accept code you do not understand. The course treats assistance as a drafting tool with a human review gate &mdash; you still need to know what a merge did to your row count.</p><h2>Who should be in the room</h2><p>The entry requirements are deliberately accessible: the ability to operate a computer, three GCE \'O\' Level passes including English or WPL Level 5, and at least one year of working experience. In practice the strongest cohorts mix financial analysts, operations and settlement staff, risk and compliance officers, treasury teams, and relationship managers who have simply run out of patience with manual reporting.</p><p>You do not need prior programming experience for this one. That is the point of it sitting at the front of the pathway.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html"><strong>IBF - AI Assisted Python Programming for Finance</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>IBF - Machine Learning 101 for Financial Trading</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-data-analytics-and-deep-learning-for-financial-services.html"><strong>IBF - Data Analytics and Deep Learning for Financial Services</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I need programming experience to join?</summary><div class="mmd-faq-a"><p>No. This course starts from installation and data types. It is the entry point of the pathway, designed for finance professionals with no coding background.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">What can I do immediately after the course?</summary><div class="mmd-faq-a"><p>Import a finance dataset, clean it, join it with another source, aggregate it and produce a chart &mdash; as a script you can rerun next month rather than a workbook you rebuild.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-01-14', 'TGS-2025052659', 'TGS-2025052659', 118, 'manual-skip', 'manual-skip', 'Python for Finance: IBF-STS Funded Training in Singapore', 'Why finance professionals are learning Python, what the IBF-STS funded AI-assisted Python course covers, and how the 50-70% subsidy works.', 'IBF-STS Python course, Python for finance Singapore, IBF funded training, financial data analysis Python, pandas finance', '2025-01-14 09:00:00', '2025-01-14 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-python-programming-financial-services') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Python', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Python') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Financial Services', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Financial Services') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Data Analytics', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Data Analytics') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-python-programming-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Python'
WHERE p.`url_key` = 'ibf-python-programming-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Financial Services'
WHERE p.`url_key` = 'ibf-python-programming-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Data Analytics'
WHERE p.`url_key` = 'ibf-python-programming-financial-services' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 118
 WHERE `url_key` = 'ibf-python-programming-financial-services' AND `likes` = 0 AND @is_sg = 1;
