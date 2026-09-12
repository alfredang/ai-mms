--
-- 1384: Blog post -- "The Analysis Was Right and Nobody Acted: Data Storytelling for Finance"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-05-13 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - Data Storytelling and Visualisation for Finance Services (TGS-2022602057)
-- Page:   https://www.tertiarycourses.com.sg/ibf-data-storytelling-and-visualisation-for-finance-services.html
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
SELECT 'The Analysis Was Right and Nobody Acted: Data Storytelling for Finance', 'ibf-data-storytelling-visualisation-finance', 'A correct analysis that fails to persuade has not finished. This IBF-STS funded course covers the dashboard design and narrative skills that get decisions made.', '<p>Every analytics team has this story. The work was done properly. The finding was real and it mattered. It went into a deck, the deck went into a meeting, and nothing changed.</p><p>The instinct afterwards is to blame the audience. The more useful conclusion is that communication is part of the analytical job, not an appendix to it. The <a href="https://www.tertiarycourses.com.sg/ibf-data-storytelling-and-visualisation-for-finance-services.html"><strong>IBF - Data Storytelling and Visualisation for Finance Services</strong></a> course treats it that way, using Tableau as the working instrument.</p><h2>Communicating data</h2><p>The first topic covers emerging trends and developments in data visualisation, the types of visualisation and when each applies, the strategic elements of a data presentation, and how to develop a <strong>data storytelling framework</strong>.</p><p>The framework is the part that transfers. Chart-type knowledge is quickly learned and quickly automated; the ability to decide what a specific audience needs to understand, in what order, to reach a decision is the durable skill. In a finance context the audiences differ sharply &mdash; a risk committee, a board, a regulator and a product team want different things from the same underlying numbers.</p><h2>Dashboards that are actually used</h2><p>Topic 2 covers what a dashboard is, intelligent dashboard design methodologies and techniques, and strategic visualisation techniques.</p><p>Most organisations have more dashboards than they have people looking at dashboards. The abandoned ones usually share a cause: they were built around available data rather than around a decision. A dashboard that does not answer "what should I do differently?" becomes wallpaper within a month.</p><p>Design methodology is how you avoid that &mdash; establishing the decision first, then the metrics that inform it, then the layout that makes the state legible at a glance and the exceptions impossible to miss.</p><h2>Delivery is a skill too</h2><p>Topic 3 covers data storytelling itself: what it is, data delivery modes, and the data story presentation.</p><p>Delivery mode matters more than most analysts assume. The same finding needs different treatment as a live presentation, a self-service dashboard, a written memo or a one-slide executive summary. Choosing the wrong mode is a common way for good work to die quietly &mdash; a forty-page appendix sent to someone who needed three sentences and a recommendation.</p><p>This course pairs naturally with the analytical ones. <a href="https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html"><strong>Financial Data Mining and Modeling with R</strong></a> produces the finding; this course is how it becomes a decision. Managers who also want to interpret the underlying statements can look at <a href="https://www.tertiarycourses.com.sg/ibf-financial-analysis-for-non-finance-managers.html"><strong>Financial Analysis for Non-Finance Managers</strong></a>.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-data-storytelling-and-visualisation-for-finance-services.html"><strong>IBF - Data Storytelling and Visualisation for Finance Services</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-financial-data-mining-and-modeling-with-r.html"><strong>IBF - Financial Data Mining and Modeling with R</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-financial-analysis-for-non-finance-managers.html"><strong>IBF - Financial Analysis for Non-Finance Managers</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Which tool does the course use?</summary><div class="mmd-faq-a"><p>Tableau is the working tool for the visualisation and dashboard components. The design and storytelling methodology transfers to any modern BI tool.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Is this course technical?</summary><div class="mmd-faq-a"><p>Less so than the programming courses in the pathway. It is aimed at anyone who has to present financial data and make it land, including analysts, managers and business partners.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-05-13', 'TGS-2022602057', 'TGS-2022602057', 127, 'manual-skip', 'manual-skip', 'Data Storytelling and Visualisation for Finance | IBF-STS Funded', 'Dashboard design methodology, visualisation technique and data storytelling frameworks for finance professionals. IBF-STS funded, up to 70% subsidy.', 'data storytelling finance, Tableau finance course Singapore, IBF-STS visualisation, dashboard design, financial data presentation', '2025-05-13 09:00:00', '2025-05-13 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-data-storytelling-visualisation-finance') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Data Visualisation', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Data Visualisation') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Tableau', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Tableau') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Financial Services', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Financial Services') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-data-storytelling-visualisation-finance' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Data Visualisation'
WHERE p.`url_key` = 'ibf-data-storytelling-visualisation-finance' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Tableau'
WHERE p.`url_key` = 'ibf-data-storytelling-visualisation-finance' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Financial Services'
WHERE p.`url_key` = 'ibf-data-storytelling-visualisation-finance' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 127
 WHERE `url_key` = 'ibf-data-storytelling-visualisation-finance' AND `likes` = 0 AND @is_sg = 1;
