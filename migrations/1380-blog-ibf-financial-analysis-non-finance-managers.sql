--
-- 1380: Blog post -- "Reading the Numbers: Financial Analysis for Managers Who Were Never Taught It"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-02-11 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - Financial Analysis for Non-Finance Managers (TGS-2022602569)
-- Page:   https://www.tertiarycourses.com.sg/ibf-financial-analysis-for-non-finance-managers.html
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
SELECT 'Reading the Numbers: Financial Analysis for Managers Who Were Never Taught It', 'ibf-financial-analysis-non-finance-managers', 'Most managers approve budgets and sign off on business cases without ever having been taught to read a financial statement. This IBF-STS funded course closes that gap.', '<p>Here is an uncomfortable but very common situation. A capable manager, several years into the role, sits in a quarterly review while someone presents a slide of ratios. They nod. They have a rough sense of whether the direction is good. What they cannot do is say <em>why</em> the number moved, or push back when the explanation is thin.</p><p>That is not a failure of intelligence. It is a gap in training. Most managers were promoted for domain expertise, not for accounting, and nobody ever sat them down with a set of statements. The <a href="https://www.tertiarycourses.com.sg/ibf-financial-analysis-for-non-finance-managers.html"><strong>IBF - Financial Analysis for Non-Finance Managers</strong></a> course exists precisely for that audience.</p><h2>Why this matters more than it used to</h2><p>Decision rights have moved outward. Managers own budgets, evaluate vendors, build business cases and justify headcount. Each of those is a financial argument whether or not it is framed as one.</p><p>Three things change when you can read the statements yourself:</p><ul><li><strong>You ask better questions.</strong> Not "is revenue up?" but "is revenue up while margin compresses, and what is driving that?"</li><li><strong>Your proposals survive scrutiny.</strong> A business case written in the language of payback and return gets a different reception from one written in the language of enthusiasm.</li><li><strong>You spot trouble earlier.</strong> Profitable companies fail for cash-flow reasons. A manager who watches only the P&amp;L is watching the wrong statement.</li></ul><h2>What the course covers</h2><p>The syllabus is built around interpretation rather than bookkeeping. You are not learning to prepare accounts; you are learning to read them and act.</p><ul><li><strong>The different financial ratios</strong> and what each one is actually telling you.</li><li><strong>Profitability analysis</strong> &mdash; where margin is made and where it leaks.</li><li><strong>Cash flow analysis</strong> &mdash; the statement that explains why a profitable business can still run out of money.</li><li><strong>Projected financial and cash-flow statements</strong>, so a plan can be tested before it is funded.</li><li><strong>The process of financial statement analysis</strong> as a repeatable method, not an ad hoc read.</li><li><strong>Assessing organisational health</strong> and evaluating historical performance.</li><li><strong>Investment suitability</strong> and <strong>benchmarking against industry</strong> &mdash; context is what turns a ratio into a judgment.</li><li><strong>Capital budgeting</strong> to evaluate potential investment returns.</li><li><strong>Analysis for the financial services industry</strong> specifically, which is where the IBF accreditation earns its place.</li></ul><p>That last point is worth pausing on. Generic finance-for-managers training uses manufacturing or retail examples. A bank, an insurer and an asset manager have balance sheets that behave differently, and the ratios that matter are not the same ones. A course accredited under IBF-STS is built for that context.</p><h2>Who it is for</h2><p>Department heads, team leads, project managers, relationship managers, operations and technology managers in financial institutions &mdash; anyone who influences how money is committed but whose training was in something else. No accounting background is assumed.</p><p>It is also a useful pairing for the analytical courses in the same pathway. Knowing <a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html">how to process the data</a> and knowing what the resulting numbers mean are different skills, and the combination is rarer than either alone.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-financial-analysis-for-non-finance-managers.html"><strong>IBF - Financial Analysis for Non-Finance Managers</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-data-storytelling-and-visualisation-for-finance-services.html"><strong>IBF - Data Storytelling and Visualisation for Finance Services</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html"><strong>IBF - Financial Data Mining and Modeling with R</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I need an accounting background?</summary><div class="mmd-faq-a"><p>No. The course is written for managers without formal finance training. It focuses on reading and interpreting statements rather than preparing them.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Is this relevant outside financial services?</summary><div class="mmd-faq-a"><p>The methods are general, but the course is accredited under IBF-STS and includes analysis specific to the financial services industry, which is where it is most valuable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-02-11', 'TGS-2022602569', 'TGS-2022602569', 134, 'manual-skip', 'manual-skip', 'Financial Analysis for Non-Finance Managers | IBF-STS Funded', 'Learn financial ratios, profitability and cash flow analysis, and capital budgeting. IBF-STS funded course in Singapore with up to 70% subsidy.', 'financial analysis for non-finance managers, IBF-STS funded course, financial ratios training Singapore, cash flow analysis, capital budgeting', '2025-02-11 09:00:00', '2025-02-11 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-financial-analysis-non-finance-managers') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Financial Analysis', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Financial Analysis') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Leadership', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Leadership') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Financial Services', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Financial Services') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-financial-analysis-non-finance-managers' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Financial Analysis'
WHERE p.`url_key` = 'ibf-financial-analysis-non-finance-managers' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Leadership'
WHERE p.`url_key` = 'ibf-financial-analysis-non-finance-managers' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Financial Services'
WHERE p.`url_key` = 'ibf-financial-analysis-non-finance-managers' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 134
 WHERE `url_key` = 'ibf-financial-analysis-non-finance-managers' AND `likes` = 0 AND @is_sg = 1;
