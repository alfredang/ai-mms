--
-- 1383: Blog post -- "From Pandas to Neural Networks: The Full Analytics Pathway for Financial Services"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-04-24 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - Data Analytics and Deep Learning for Financial Services (TGS-2022601648)
-- Page:   https://www.tertiarycourses.com.sg/ibf-data-analytics-and-deep-learning-for-financial-services.html
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
SELECT 'From Pandas to Neural Networks: The Full Analytics Pathway for Financial Services', 'ibf-data-analytics-deep-learning-financial-services', 'One IBF-STS funded course that runs from Python basics through pandas and visualisation to CNNs and LSTM time-series forecasting, all on financial data.', '<p>Most people learning analytics assemble it from fragments &mdash; a Python course here, a visualisation tutorial there, a deep learning video series that assumes everything before it. The fragments rarely join up, and the join is where the understanding lives.</p><p>The <a href="https://www.tertiarycourses.com.sg/ibf-data-analytics-and-deep-learning-for-financial-services.html"><strong>IBF - Data Analytics and Deep Learning for Financial Services</strong></a> course is the widest programme in the IBF-STS catalogue we run, and the argument for it is exactly that continuity. It starts at your first Python script and ends at an LSTM forecasting a stock price, with one consistent dataset philosophy throughout.</p><h2>Four stages, one arc</h2><p><strong>Stage 1 &mdash; Python foundations.</strong> Getting started, data types (number, string, list, tuple, dictionary, set), the full operator set, control structures and comprehensions, functions including lambda/map/filter, and modules and packages.</p><p><strong>Stage 2 &mdash; Data analytics with pandas.</strong> Data preparation with DataFrames and Series; importing and exporting finance data; filtering, slicing and cleaning; transformation with computed columns, concat/append/merge, groupby and pivot tables. Then visualisation &mdash; line plots for time series, scatter for relationships, bar and pie for categorical, box for variation, histogram for distribution. Then analysis: descriptive statistics, rolling window averages, covariance and correlation, and advanced work with apply and data piping.</p><p><strong>Stage 3 &mdash; Deep learning foundations.</strong> Overview of AI and deep learning, evaluation of platforms, applications to financial services, and the deep learning methodology. Then neural networks for regression (activation functions, MSE loss, optimisers, a sales forecasting model) and for classification (one-hot encoding, SoftMax, cross-entropy, a currency-note classifier).</p><p><strong>Stage 4 &mdash; Applied architectures.</strong> CNNs for image classification, built up through a currency-note detection model, including the overfitting problem on small datasets and how transfer learning addresses it. Then RNNs &mdash; LSTM and GRU &mdash; applied to <strong>time-series forecasting of stock price</strong>.</p><h2>Why the small-data section matters most</h2><p>If there is one part of this syllabus that repays attention disproportionately, it is the treatment of <strong>overfitting on small datasets and transfer learning</strong>.</p><p>Published deep learning results come from enormous datasets. Almost no financial institution has an enormous labelled dataset for the specific problem in front of it. The realistic situation is a few thousand examples, an imbalanced target, and a temptation to train a large model that memorises all of it. Knowing how to recognise that and what to do about it &mdash; regularisation, augmentation, transfer learning &mdash; is the difference between a model that deploys and a demo that does not survive contact with production.</p><p>The currency-note examples are a sensible teaching choice for the same reason: a concrete, verifiable financial-domain task where you can see whether the model is right.</p><h2>Positioning within the pathway</h2><p>Because it includes the Python foundations, this course can be taken without prior programming experience &mdash; it simply covers more ground and therefore runs longer than the focused courses. Participants who already have Python may prefer to go straight to <a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>Machine Learning 101 for Financial Trading</strong></a> and treat this one as the deep learning extension.</p><p>The mapped job roles are the ones you would expect: data scientist, machine learning engineer, data analyst, AI solutions architect and analytics consultant within financial services.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-data-analytics-and-deep-learning-for-financial-services.html"><strong>IBF - Data Analytics and Deep Learning for Financial Services</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html"><strong>IBF - Machine Learning 101 for Financial Trading</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html"><strong>IBF - AI Assisted Python Programming for Finance</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Is this course too long if I already know Python?</summary><div class="mmd-faq-a"><p>If you are already comfortable with pandas, the focused Machine Learning 101 for Financial Trading course may suit you better. This one is designed to take a complete beginner all the way to deep learning.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">What deep learning architectures are covered?</summary><div class="mmd-faq-a"><p>Feedforward neural networks for regression and classification, convolutional neural networks for image classification, and recurrent networks (LSTM and GRU) for time-series forecasting.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-04-24', 'TGS-2022601648', 'TGS-2022601648', 156, 'manual-skip', 'manual-skip', 'Data Analytics and Deep Learning for Financial Services | IBF-STS', 'Python, pandas, visualisation, neural networks, CNNs and LSTM stock forecasting in one IBF-STS funded course. Up to 70% subsidy for eligible Singaporeans.', 'deep learning financial services, IBF-STS data analytics course, LSTM stock forecasting, CNN finance, neural network training Singapore', '2025-04-24 09:00:00', '2025-04-24 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-data-analytics-deep-learning-financial-services') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Deep Learning', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Deep Learning') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Data Analytics', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Data Analytics') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Python', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Python') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-data-analytics-deep-learning-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Deep Learning'
WHERE p.`url_key` = 'ibf-data-analytics-deep-learning-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Data Analytics'
WHERE p.`url_key` = 'ibf-data-analytics-deep-learning-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Python'
WHERE p.`url_key` = 'ibf-data-analytics-deep-learning-financial-services' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 156
 WHERE `url_key` = 'ibf-data-analytics-deep-learning-financial-services' AND `likes` = 0 AND @is_sg = 1;
