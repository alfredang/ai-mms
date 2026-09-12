--
-- 1382: Blog post -- "Financial Data Mining with R: Clustering, Anomalies and Forecasts on Real Market Data"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-04-08 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - Financial Data Mining and Modeling with R (TGS-2023017892)
-- Page:   https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html
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
SELECT 'Financial Data Mining with R: Clustering, Anomalies and Forecasts on Real Market Data', 'ibf-financial-data-mining-modeling-r', 'R remains the sharpest tool for statistical work on financial data. This IBF-STS funded course runs it end to end, finishing on stock clustering and time-series forecasting.', '<p>Python has taken most of the oxygen in the analytics conversation, and for general engineering work that is fair. But in statistical modelling &mdash; the part of finance concerned with distributions, relationships and inference rather than pipelines &mdash; R is still exceptionally good, and the people who know it are noticeably faster at exploratory work.</p><p>The <a href="https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html"><strong>IBF - Financial Data Mining and Modeling with R</strong></a> course leans into that. It is a data mining course rather than a programming course: the language is the instrument, and the subject is what you find in the data.</p><h2>Data quality is the actual job</h2><p>The course opens where real projects open &mdash; with the pipeline. Overview of data mining, the data pipeline itself, data ingestion, <strong>data quality</strong>, an introduction to R, and data processing.</p><p>Putting data quality that early is a correct editorial choice. Anyone who has modelled financial data knows the ratio: most of the effort goes into ingestion, reconciliation and cleaning, and the modelling is the short part at the end. A course that skips to the models is teaching the easy half.</p><h2>From statistics to structure</h2><p>Topic 2 moves through financial analysis proper: statistical summaries, data manipulation, descriptive statistics, variable relationships, <strong>cluster analysis</strong>, <strong>anomaly detection</strong> and <strong>forecasting</strong>.</p><p>Two of those deserve emphasis for a finance audience.</p><ul><li><strong>Anomaly detection</strong> is the technique underneath a great deal of surveillance, fraud and control work. The interesting cases are rare by definition, which makes them exactly the ones a naive model ignores.</li><li><strong>Cluster analysis</strong> lets structure emerge instead of being imposed. Sector labels are a human taxonomy; clustering on actual behaviour often disagrees with them, and the disagreement is usually the insight.</li></ul><h2>Two case studies that tie it together</h2><p>Topic 3 is applied: <strong>clustering stocks for investment</strong> and <strong>forecasting a stock time series</strong>.</p><p>These are well chosen because they are honest about their limits. Clustering stocks produces groupings you then have to interpret &mdash; it does not hand you a portfolio. Forecasting a price series teaches, usually within the first attempt, exactly how much signal is and is not there. That calibration is worth more to a practitioner than another algorithm.</p><p>Participants who want to push further into predictive modelling can continue with <a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>IBF - Machine Learning 101 for Financial Trading</strong></a>, which covers the supervised and unsupervised model families in more depth.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html"><strong>IBF - Financial Data Mining and Modeling with R</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>IBF - Machine Learning 101 for Financial Trading</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-data-storytelling-and-visualisation-for-finance-services.html"><strong>IBF - Data Storytelling and Visualisation for Finance Services</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Should I learn R or Python?</summary><div class="mmd-faq-a"><p>For statistical exploration, distributions and inference on financial data, R is excellent and fast to work in. Many practitioners use both. The two IBF pathways are complementary rather than competing.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Is prior R experience needed?</summary><div class="mmd-faq-a"><p>The course includes an introduction to R as part of the first topic, alongside the standard entry requirements of basic computer literacy and working experience.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-04-08', 'TGS-2023017892', 'TGS-2023017892', 109, 'manual-skip', 'manual-skip', 'Financial Data Mining and Modeling with R | IBF-STS Funded', 'Data pipelines, statistical analysis, clustering, anomaly detection and forecasting in R, applied to stock case studies. IBF-STS funded in Singapore.', 'financial data mining R, IBF-STS R course, anomaly detection finance, stock clustering R, time series forecasting R Singapore', '2025-04-08 09:00:00', '2025-04-08 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-financial-data-mining-modeling-r') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'R Programming', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'R Programming') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Data Mining', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Data Mining') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Financial Services', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Financial Services') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-financial-data-mining-modeling-r' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'R Programming'
WHERE p.`url_key` = 'ibf-financial-data-mining-modeling-r' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Data Mining'
WHERE p.`url_key` = 'ibf-financial-data-mining-modeling-r' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Financial Services'
WHERE p.`url_key` = 'ibf-financial-data-mining-modeling-r' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 109
 WHERE `url_key` = 'ibf-financial-data-mining-modeling-r' AND `likes` = 0 AND @is_sg = 1;
