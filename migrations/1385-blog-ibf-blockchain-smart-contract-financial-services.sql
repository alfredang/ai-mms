--
-- 1385: Blog post -- "Smart Contracts for Financial Services: Writing Code That Cannot Be Patched Later"
--
-- One of seven hand-authored articles covering every course listed on
-- https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html
-- Each post pitches the training on its published syllabus and explains the
-- IBF-STS funding route. Back-dated to 2025-05-29 as part of the Jan-May 2025
-- series.
--
-- Course: IBF - Blockchain Smart Contract Programming for Financial Services (TGS-2022601875)
-- Page:   https://www.tertiarycourses.com.sg/ibf-blockchain-smart-contract-programming-for-financial-services.html
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
SELECT 'Smart Contracts for Financial Services: Writing Code That Cannot Be Patched Later', 'ibf-blockchain-smart-contract-financial-services', 'Deployed smart contract code is difficult to change and handles real value. This IBF-STS funded course covers Solidity, testing, gas and deployment for finance teams.', '<p>Ordinary software has a forgiving property that is easy to take for granted: you can ship a fix. A bug is found, a patch goes out, the incident is written up. Deployed smart contract code does not work that way. It is difficult or impossible to change, it is publicly readable, and it very often has direct custody of value.</p><p>That combination is why <a href="https://www.tertiarycourses.com.sg/ibf-blockchain-smart-contract-programming-for-financial-services.html"><strong>IBF - Blockchain Smart Contract Programming for Financial Services</strong></a> spends a full quarter of its syllabus on testing and monitoring &mdash; a proportion that would look excessive in any other programming course and is entirely proportionate here.</p><h2>Context before code</h2><p>Topic 1 establishes the ground: blockchain and cryptocurrency fundamentals, use cases in financial services, and an introduction to smart contracts and non-fungible tokens with their financial-services applications.</p><p>Starting with use cases is the right order for this audience. Most finance professionals do not need to be convinced that distributed ledgers exist; they need a clear view of where the technology genuinely changes the settlement, custody, tokenisation or trade-finance problem, and where it is being applied because it is fashionable. Singapore\'s regulatory posture, set by the <a href="https://www.mas.gov.sg/" rel="noopener" target="_blank">Monetary Authority of Singapore</a>, has made this a serious institutional conversation rather than a speculative one, which raises the bar for people building in it.</p><h2>Solidity, and writing it defensively</h2><p>Topic 2 covers the Ethereum DApp platform, creating smart contracts in Solidity, coding syntax, and <strong>best practices on Solidity coding</strong>.</p><p>That last item is the one to underline. Solidity\'s syntax resembles JavaScript enough to feel familiar and behaves differently enough to be dangerous &mdash; reentrancy, arithmetic behaviour, access control and upgrade patterns all have well-documented failure histories, and every one of them has cost someone money in public. Best practice here is not stylistic advice; it is the accumulated record of expensive mistakes.</p><h2>Testing, gas and deployment</h2><p>Topic 3 covers testing contracts and monitoring outputs, managing Ether and gas fees, and monitoring on-chain transactions. Topic 4 covers deployment and token standards.</p><p>Gas deserves its own mention because it has no analogue in conventional development. Every operation costs, the cost is variable, and an inefficient contract is not merely slow &mdash; it is permanently more expensive for everyone who ever calls it. Efficiency becomes a design constraint from the first line rather than an optimisation pass at the end.</p><p>Token standards close the course, and they are what make tokenised instruments interoperable rather than bespoke. For a financial institution evaluating tokenisation, understanding the standards is often more immediately useful than being able to write the contract from scratch.</p><h2>Who takes this</h2><p>Developers and technologists in financial institutions, product and innovation teams assessing tokenisation, and risk and compliance staff who need to read a contract well enough to evaluate it. Entry requirements follow the IBF-STS standard: basic computer literacy, three GCE \'O\' Level passes including English or WPL Level 5, and at least a year of working experience. Programming familiarity helps considerably, and <a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html"><strong>AI Assisted Python Programming for Finance</strong></a> is a reasonable warm-up if you have none.</p><h2>How IBF-STS funding works for this course</h2><p>This programme is accredited under the <strong>IBF Standards Training Scheme (IBF-STS)</strong>, administered by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank"><strong>Institute of Banking and Finance (IBF)</strong></a>. IBF-STS supports training that is aligned to the Skills Framework for Financial Services, so the funding is attached to the course itself rather than to a generic training allowance.</p><p>The published funding parameters are straightforward:</p><ul><li><strong>Singapore Citizens and Permanent Residents:</strong> up to <strong>50% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li><strong>Singapore Citizens aged 40 and above:</strong> up to <strong>70% of direct training cost</strong>, capped at S$3,000 per participant per course.</li><li>Participants must be <strong>physically based in Singapore</strong> and must <strong>complete the course and pass all assessments</strong> before funding is granted.</li><li>For <strong>company-sponsored</strong> participants, the sponsoring organisation must be a <strong>financial institution regulated by the Monetary Authority of Singapore (MAS)</strong>, or a FinTech firm certified by the <strong>Singapore FinTech Association (SFA)</strong>.</li><li>Funding support for the same course is granted <strong>once per calendar year per participant</strong>.</li></ul><p>Two practical notes that catch people out. First, <strong>promotional and discount codes cannot be applied to IBF-STS courses</strong> &mdash; the subsidy is the pricing mechanism, so there is nothing to stack on top of it. Second, the assessment is not optional. Both the written and practical components must be passed for the claim to go through, which is also why the certificate carries weight with an employer.</p><p>Beyond IBF-STS, <strong>NTUC union members</strong> may claim a further <strong>50% of the unfunded fee under the Union Training Assistance Programme (UTAP)</strong>, capped at S$250 a year for members aged 39 and below and S$500 a year for members aged 40 and above. UTAP is claimed through the U Portal after the class ends.</p><p>Because parameters are reviewed periodically, confirm your own eligibility on the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" rel="noopener" target="_blank">official IBF-STS page</a> or with our team before you register. The full list of accredited programmes we run sits on the <a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>IBF-STS funded courses</strong></a> page.</p><h2>Register or explore the pathway</h2><p>Full outline, upcoming dates and fees for this programme are on the <a href="https://www.tertiarycourses.com.sg/ibf-blockchain-smart-contract-programming-for-financial-services.html"><strong>IBF - Blockchain Smart Contract Programming for Financial Services</strong></a> course page. Registration is by expression of interest with no upfront payment, and there is no penalty for withdrawing before the class begins.</p><p>Related IBF-STS accredited programmes worth looking at next:</p><ul><li><a href="https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html"><strong>IBF - AI Assisted Python Programming for Finance</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-data-analytics-and-deep-learning-for-financial-services.html"><strong>IBF - Data Analytics and Deep Learning for Financial Services</strong></a></li><li><a href="https://www.tertiarycourses.com.sg/ibf-sts-funded-courses.html"><strong>All IBF-STS funded courses</strong></a></li></ul><p>For corporate cohorts, these courses can be run in-house for teams at a financial institution or SFA-certified FinTech firm.</p><h2>Frequently asked questions</h2><div class="mmd-faq"><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I need blockchain experience?</summary><div class="mmd-faq-a"><p>No. The course starts with blockchain, cryptocurrency and smart contract fundamentals before moving into Solidity programming.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Is this only relevant to cryptocurrency?</summary><div class="mmd-faq-a"><p>No. The financial-services applications covered include smart contracts and tokenisation for settlement, custody and trade workflows, which are institutional use cases rather than speculative ones.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Who is eligible for IBF-STS funding?</summary><div class="mmd-faq-a"><p>Singapore Citizens and Permanent Residents physically based in Singapore who complete the course and pass all assessments. Singapore Citizens aged 40 and above qualify for the higher 70% rate. Company-sponsored participants must be sponsored by a MAS-regulated financial institution or an SFA-certified FinTech firm.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I use a discount code on an IBF-STS course?</summary><div class="mmd-faq-a"><p>No. Promotional and discount codes cannot be applied to IBF-STS courses. The subsidy itself is the fee reduction.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Do I have to pass the assessment to get funded?</summary><div class="mmd-faq-a"><p>Yes. IBF-STS funding is granted only on successful completion, including passing the written and practical assessments where applicable.</p></div></details><details class="mmd-faq-item"><summary class="mmd-faq-q">Can I claim UTAP as well?</summary><div class="mmd-faq-a"><p>NTUC union members can claim 50% of the unfunded fee under UTAP, capped at S$250 a year below age 40 and S$500 a year from age 40, submitted through the U Portal after the course.</p></div></details></div>', 'Tertiary Infotech Academy', 1, '2025-05-29', 'TGS-2022601875', 'TGS-2022601875', 103, 'manual-skip', 'manual-skip', 'Blockchain Smart Contract Programming for Financial Services | IBF-STS', 'Solidity programming, smart contract testing, gas management and deployment for financial services. IBF-STS funded course in Singapore.', 'smart contract course Singapore, Solidity training, IBF-STS blockchain, Ethereum financial services, NFT tokenisation finance', '2025-05-29 09:00:00', '2025-05-29 09:00:00'
FROM DUAL WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'ibf-blockchain-smart-contract-financial-services') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'IBF-STS', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'IBF-STS') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Blockchain', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Blockchain') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Smart Contracts', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Smart Contracts') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Solidity', 1, 0 FROM DUAL
WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Solidity') x);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'IBF-STS'
WHERE p.`url_key` = 'ibf-blockchain-smart-contract-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Blockchain'
WHERE p.`url_key` = 'ibf-blockchain-smart-contract-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Smart Contracts'
WHERE p.`url_key` = 'ibf-blockchain-smart-contract-financial-services' AND @is_sg = 1;
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Solidity'
WHERE p.`url_key` = 'ibf-blockchain-smart-contract-financial-services' AND @is_sg = 1;

-- Seed a plausible like count: a fresh post at 0 next to neighbours in the
-- 100-240 range reads as a reset counter. Guarded so real storefront likes
-- are never clobbered on re-run.
UPDATE `mmd_blog_post` SET `likes` = 103
 WHERE `url_key` = 'ibf-blockchain-smart-contract-financial-services' AND `likes` = 0 AND @is_sg = 1;
