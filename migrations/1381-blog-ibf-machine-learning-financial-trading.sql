--
-- 1381: Blog post -- "Machine Learning for Financial Trading: Start with the Methodology, Not the Model"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-03-11 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - Machine Learning 101 for Financial Trading (TGS-2023018794)
-- Page:   https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html
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
SELECT 'Machine Learning for Financial Trading: Start with the Methodology, Not the Model', 'ibf-machine-learning-financial-trading', 'Most trading models fail for reasons that have nothing to do with the algorithm. This IBF-STS funded course starts where the failures actually happen.', '<p>The most expensive lesson in applied machine learning is that a model which looks excellent on historical data can be worthless the moment it meets tomorrow. In most domains that produces a bad quarter. In trading it produces a loss with a timestamp on it.</p><p>Which is why the <a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>IBF - Machine Learning 101 for Financial Trading</strong></a> course opens with methodology rather than with algorithms. Before any model is fitted, the class works through what a target is, what a feature is, how training and prediction are separated, and how a model is evaluated. Those four things explain most of the failures.</p><h2>Why the methodology comes first</h2><p>It is genuinely easy now to fit a model. A handful of lines of Python will train a random forest on a price series and print an accuracy figure. The figure will often be impressive. It will also frequently be meaningless, because:</p><ul><li><strong>Information leaked</strong> from the future into the training set &mdash; the single most common defect in financial modelling.</li><li><strong>The metric was wrong for the question.</strong> Accuracy on an imbalanced target tells you almost nothing useful.</li><li><strong>The model memorised</strong> a regime that has since ended.</li><li><strong>The features encoded</strong> something the model would not have had access to at decision time.</li></ul><p>None of these are algorithm problems. They are methodology problems, and no choice of model fixes them. Teaching evaluation discipline first is the difference between a course that produces working practitioners and one that produces confident ones.</p><h2>The syllabus</h2><p>Three topics, each with direct trading application.</p><p><strong>Topic 1 &mdash; Machine learning methodology.</strong> Introduction to machine learning; machine learning versus deep learning; supervised versus unsupervised learning; implementation steps; targets and features; model training and prediction; and the metrics used to evaluate models.</p><p><strong>Topic 2 &mdash; Supervised models and applications.</strong> Linear regression, logistic regression, Na&iuml;ve Bayes, decision trees, random forests, XGBoost and neural networks. The breadth is deliberate &mdash; part of the skill is knowing which family suits which problem, and gradient boosting on tabular financial data remains a genuinely strong default.</p><p><strong>Topic 3 &mdash; Unsupervised models and applications.</strong> K-means and hierarchical clustering, and principal component analysis. Underrated in trading contexts: clustering finds regimes and peer groups you did not define in advance, and PCA is how you deal with dozens of correlated factors without pretending they are independent.</p><p>Assessment is by written and practical exam, which is an IBF-STS requirement and also the reason the certificate carries weight.</p><h2>Prerequisites and who takes it</h2><p><strong>Basic Python programming knowledge is required</strong> for this course, along with the standard entry criteria: three GCE \'O\' Level passes including English or WPL Level 5, and a minimum of one year of working experience. If Python is not yet in place, start with <a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html"><strong>IBF - AI Assisted Python Programming for Finance</strong></a> and come back to this one.</p><p>Typical participants are quantitative researchers, data analysts, traders and portfolio support staff, risk analysts, and technologists building systems for trading desks. The job roles the course maps to include data scientist, machine learning engineer, quantitative researcher, predictive modeller and AI solutions architect.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>IBF - Machine Learning 101 for Financial Trading</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-data-analytics-and-deep-learning-for-financial-services.html"><strong>IBF - Data Analytics and Deep Learning for Financial Services</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html"><strong>IBF - Financial Data Mining and Modeling with R</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I need Python before this course?</summary><div class="mmd-faq-a"><p>Yes. Basic Python programming knowledge is a stated entry requirement. The IBF AI-Assisted Python Programming for Finance course covers what is needed.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Does the course cover deep learning?</summary><div class="mmd-faq-a"><p>It distinguishes machine learning from deep learning and covers neural networks among the supervised models. For CNNs, RNNs and time-series forecasting in depth, the Data Analytics and Deep Learning for Financial Services course goes further.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-03-11', 'TGS-2023018794', 'TGS-2023018794', 141, 'manual-skip', 'manual-skip', 'Machine Learning 101 for Financial Trading | IBF-STS Funded', 'Supervised and unsupervised models applied to financial trading, with the evaluation discipline that keeps them honest. IBF-STS funded, up to 70% subsidy.', 'machine learning financial trading, IBF-STS machine learning course, XGBoost finance, supervised learning trading, Singapore quant training', '2025-03-11 09:00:00', '2025-03-11 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-machine-learning-financial-trading') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Machine Learning', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Machine Learning') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Financial Trading', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Financial Trading') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Python', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Python') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-machine-learning-financial-trading' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Machine Learning'
WHERE p.`url_key` = 'ibf-machine-learning-financial-trading' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Financial Trading'
WHERE p.`url_key` = 'ibf-machine-learning-financial-trading' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Python'
WHERE p.`url_key` = 'ibf-machine-learning-financial-trading' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 141
 WHERE `url_key` = 'ibf-machine-learning-financial-trading' AND `likes` = 0 AND @is_sg = 1;
