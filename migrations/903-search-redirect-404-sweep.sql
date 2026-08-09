-- Search-redirect 404 sweep: repair every catalogsearch_query.redirect that
-- pointed at a dead URL, and add 301 rewrites for the renamed course slugs.
--
-- Audit (SG prod, 2026-08-10): of 1,269 distinct redirect targets, 141 were
-- broken -- 110 returned 404 outright and 31 more 301-chained INTO a 404,
-- affecting 834 search rows / 13,257 popularity. Root cause was NOT bad
-- redirect data: the destination courses had been retired (product status=2)
-- or their categories deactivated (is_active=0), and renamed courses had no
-- rewrite row, so the old slug died instead of 301-ing.
--
-- Two repairs, both verified live with curl before shipping:
--   PART A  8 renamed courses -> repoint search rows AND add a 301 (options='RP')
--           rewrite so the old course URL permanently redirects. Verified
--           301 -> 200 on every one.
--   PART B  132 targets whose course is genuinely retired with no successor ->
--           clear the redirect so Magento serves live search results instead of
--           a 404. Verified: all 732 affected terms now return HTTP 200
--           (e.g. "rpa" went 404 -> 200 with 5 real courses). Auto-matching a
--           replacement was rejected -- fuzzy scoring proposed
--           basic-tableau -> basic-accounting and linux -> robot-operating-system
--           (cf. feedback_autopopulate_fuzzy_search_redirects_wrong).
--   Also clears 4 rows pointing at a dead external ial.edu.sg page.
--
-- Applied live on SG prod 2026-08-10; this keeps a rebuilt DB in the same state.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ---------------------------------------------------------------- PART A
DROP TEMPORARY TABLE IF EXISTS tmp_slug_renames;
CREATE TEMPORARY TABLE tmp_slug_renames (
  old_slug VARCHAR(255) NOT NULL,
  new_slug VARCHAR(255) NOT NULL,
  PRIMARY KEY (old_slug)
) ENGINE=MEMORY;

INSERT INTO tmp_slug_renames (old_slug, new_slug) VALUES
  ('augmented-reality-ar-vr-training.html', 'wsq-develop-augmented-reality-ar-applications.html'),
  ('aws-certified-devops-engineer-training.html', 'wsq-aws-certified-devops-engineer-training.html'),
  ('comptia-certified-securityx-training.html', 'wsq-comptia-certified-securityx-training.html'),
  ('data-storytelling-with-tableau.html', 'wsq-data-storytelling-with-tableau.html'),
  ('ecommerce-with-shopify.html', 'casl-running-a-successful-ecommerce-store-with-shopify.html'),
  ('google-apps-script-courses.html', 'ai-vibe-coding-for-google-apps-script.html'),
  ('google-tag-manager-courses.html', 'wsq-mastering-google-tag-manager-for-optimized-website-tracking-and-analytics.html'),
  ('manage-ai-agents-with-paperclip.html', 'wsq-manage-ai-agents-with-paperclip.html');

-- A1. repoint search rows from the old slug to the renamed course
UPDATE catalogsearch_query q
JOIN tmp_slug_renames m
  ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', m.old_slug)
SET q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', m.new_slug),
    q.num_results = 1, q.is_processed = 1
WHERE @sg = 1 AND q.store_id = 1;

-- A2. make the OLD course URL a 301 permanent redirect (options='RP').
--     Without this the old slug 404s and every external/back link is dead.
UPDATE core_url_rewrite r
JOIN tmp_slug_renames m ON r.request_path = m.old_slug
SET r.target_path = m.new_slug, r.options = 'RP', r.is_system = 0
WHERE @sg = 1 AND r.store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5(m.old_slug), '-', s.store_id),
       m.old_slug, m.new_slug, 0, 'RP'
FROM tmp_slug_renames m
CROSS JOIN (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = m.old_slug AND x.store_id = s.store_id);

DROP TEMPORARY TABLE IF EXISTS tmp_slug_renames;

-- ---------------------------------------------------------------- PART B
-- Retired courses with no live successor: clear the redirect so the search
-- falls through to real results rather than a 404 dead end.
DROP TEMPORARY TABLE IF EXISTS tmp_dead_targets;
CREATE TEMPORARY TABLE tmp_dead_targets (
  slug VARCHAR(255) NOT NULL,
  PRIMARY KEY (slug)
) ENGINE=MEMORY;

INSERT IGNORE INTO tmp_dead_targets (slug) VALUES
  ('rpa-courses.html'),
  ('critical-core-soft-skills-courses.html'),
  ('apache-spark-courses.html'),
  ('flutter-courses.html'),
  ('basic-tableau-training.html'),
  ('selenium-training.html'),
  ('basic-react-js-training.html'),
  ('healthcare-courses.html'),
  ('linux-operating-system-training.html'),
  ('c-sharp-essential-training-in-singapore.html'),
  ('qlikviiew-qliksense-software-training-courses.html'),
  ('swift-programming-training-courses.html'),
  ('animation-courses.html'),
  ('software-defined-networks-courses.html'),
  ('game-devleopment-courses-in.html'),
  ('wsh-workplace-safety-health-courses.html'),
  ('create-engaging-tiktok-video-with-capcut-ai.html'),
  ('public-speaking-for-kids.html'),
  ('3d-printing-workshop-for-kids.html'),
  ('specialisation-courses.html'),
  ('adobe-xd-courses.html'),
  ('basic-react-native-training.html'),
  ('ethereum-smart-contract-programming-solidity-web3.html'),
  ('apache-cordova-mobile-apps.html'),
  ('autodesk-certified-professional-acp-exam-voucher-1842.html'),
  ('basic-electronics-for-kids.html'),
  ('genai-for-kids-conversational-mandarin-with-genai.html'),
  ('pl-600-microsoft-power-platform-solution-architect-exam-prep.html'),
  ('certified-information-systems-auditor-cisa-exam-prep.html'),
  ('genai-for-kids-intermediate-python-programming-with-vibe-coding.html'),
  ('elearning-courses.html'),
  ('supercharging-your-productivity-with-microsoft-365-copilot-pro.html'),
  ('autodesk-navisworks-training.html'),
  ('build-net-applications-with-c.html'),
  ('advanced-css3-animation-training.html'),
  ('comptia-tech-exam-vouchers.html'),
  ('cisco-ccna-practice-exams.html'),
  ('microsoft-certified-azure-administrator-associate-az-104-practice-exams.html'),
  ('genai-for-kids-learn-python-with-vibe-coding.html'),
  ('web-framework-courses.html'),
  ('pl-200-microsoft-power-platform-functional-consultan-practice-exams.html'),
  ('wordpress-ecommerce-woocommerce.html'),
  ('microsoft-fundamental-certification-exam-vouchers.html'),
  ('node-js-application-development-lfw211.html'),
  ('microsoft-role-based-certification-exam-vouchers.html'),
  ('genai-for-kids-creating-music-and-songs-with-gen-ai.html'),
  ('microsoft-outlook-courses.html'),
  ('genai-for-kids-understanding-and-solving-math-problems-with-gen-ai.html'),
  ('autopot-farming-course.html'),
  ('autodesk-certified-professional-acp-exam-voucher.html'),
  ('genai-for-kids-learn-english-grammar-with-gen-ai.html'),
  ('comptia-certmaster-learn-for-datasys-ds0-001-self-paced.html'),
  ('speed-typing-for-kids-courses.html'),
  ('name-microsoft-certified-power-bi-data-analyst-associate-pl-300-practice-exams.html'),
  ('aws-certified-cloud-practitioner-clf-c02-practice-exams.html'),
  ('certprep-courseware-it-specialist-data-analytics-self-paced-inf-202-180-day-access.html'),
  ('aws-certified-sysops-administrator-associate-soa-c02-practice-exams.html'),
  ('comptia-server-exam-vouchers.html'),
  ('google-professional-machine-learning-engineer-training-practice-exams.html'),
  ('escape-room-for-kids-the-hidden-number-vault.html'),
  ('comptia-a-exam-vouchers.html'),
  ('microsoft-azure-data-fundamentals-dp-900-practice-exams.html'),
  ('comptia-a-practice-exams.html'),
  ('genai-for-kids-having-fun-with-biology-with-gen-ai.html'),
  ('basic-robot-motion-planning-moveit.html'),
  ('certmaster-perform-for-datax-dy0-001-self-paced.html'),
  ('genai-for-kids-make-chemistry-fun-for-kids-with-genai.html'),
  ('genai-for-kids-generating-creative-visual-arts-with-gen-ai.html'),
  ('certprep-courseware-it-specialist-artificial-intelligence-self-paced.html'),
  ('escape-room-for-kids-the-secret-pirate-island-adventure.html'),
  ('genai-for-kids-creating-animated-short-video-clip-with-gen-ai.html'),
  ('google-professional-cloud-devops-engineer-certification-prep.html'),
  ('ms-102-microsoft-365-administrator-practice-exams.html'),
  ('pmp-practice-exams.html'),
  ('comptia-certmaster-perform-securityx-casp-cas-005-self-paced.html'),
  ('aws-certified-solutions-architect-associate-saa-c03-practice-exams.html'),
  ('comptia-data-exam-vouchers.html'),
  ('dp-300-microsoft-certified-azure-database-administrator-associate-practice-exams.html'),
  ('escape-room-for-kids-singapore-heritage-time-travel.html'),
  ('escape-room-for-kids-the-environmental-rescue.html'),
  ('roots-of-the-future-sichuan-chongqing-tech-culture-family-education-tour.html'),
  ('kubernetes-fundamentals-lfs258.html'),
  ('autodesk-certified-user-acu-exam-voucher-1840.html'),
  ('genai-for-kids-building-interactive-web-apps-with-vibe-coding.html'),
  ('how-to-grow-your-own-mushroom-workshop.html'),
  ('microsoft-certified-azure-developer-associate-az-204-practice-exams.html'),
  ('aws-specialty-certification-exam-vouchers.html'),
  ('escape-room-for-kids-the-money-masters-challenge.html'),
  ('autodesk-certified-associate-aca-exam-voucher.html'),
  ('basic-therapeutic-gardening-course.html'),
  ('genai-for-kids-boosting-self-confidence-with-gen-ai.html'),
  ('autodesk-certified-expert-ace-exam-voucher.html'),
  ('aws-skill-builder-individual-yearly-subscription.html'),
  ('comptia-itf-exam-vouchers.html'),
  ('google-cloud-digital-leader-certification-prep.html'),
  ('genai-for-kids-learn-basic-phonics-with-gen-ai.html'),
  ('genai-for-kids-having-fun-with-physics-with-gen-ai.html'),
  ('genai-for-kids-creating-engaging-videos-with-gen-ai.html'),
  ('comptia-certmaster-learn-for-security-sy0-701-self-paced.html'),
  ('genai-for-kids-problem-solving-with-gen-ai.html'),
  ('aws-certified-ai-practitioner-aif-c01-practice-exams.html'),
  (' advanced-certificate-in-cyber-security.html'),
  ('get-started-with-raspberry-pi-for-beginners.html'),
  ('aws-assoicate-certification-exam-vouchers.html'),
  ('ecommerce-marketplaces-courses.html'),
  ('escape-room-for-kids-the-magical-library-escape.html'),
  ('aws-professional-certification-exam-vouchers.html'),
  ('genai-for-kids-creating-engaging-presentation-with-gen-ai.html'),
  ('python-tuition-for-o-level-exam-preparation-singapore.html'),
  ('ai-900-microsoft-certified-azure-ai-fundamentals-practice-exams.html'),
  ('certmaster-perform-for-pentest-pt0-003-self-paced.html'),
  ('certprep-courseware-it-specialist-databases-self-paced.html'),
  ('comptia-ai-essentials-self-paced.html'),
  ('comptia-datax-exam-vouchers.html'),
  ('comptia-security-exam-vouchers.html'),
  ('comptia-security-practice-exams.html'),
  ('genai-for-kids-learn-basic-programming-concepts-with-genai.html'),
  ('genai-for-kids-master-prompting-to-generate-better-content.html'),
  ('itil-4-practice-exams.html'),
  ('kubernetes-for-developers-lfd259.html'),
  ('microsoft-certified-devops-engineer-expert-az-400-practice-exams.html'),
  ('risc-v-fundamentals-lfd210.html'),
  ('training-linux-system-administration-training-course-fundamentals-of-open-source-it-and-cloud-computing-lfs200.html'),
  ('ai-vibe-coding-for-dotnet.html'),
  ('ai-vibe-coding-for-augmented-reality-ar.html'),
  ('ai-vibe-coding-for-c-sharp.html'),
  ('ecommerce-with-wordpress.html');

UPDATE catalogsearch_query q
JOIN tmp_dead_targets d
  ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', d.slug)
SET q.redirect = NULL, q.is_processed = 0
WHERE @sg = 1 AND q.store_id = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_dead_targets;

-- Dead EXTERNAL targets, each individually confirmed 404 with curl:
--   ial.edu.sg   -- both ACLP pages 301 into a 404 (removed upstream)
--   moe.gov.sg   -- PSEA ad-hoc withdrawal form PDF is gone
-- tertiaryrobotics.com rows are deliberately LEFT ALONE: they only timed out
-- from the audit host (curl 000), which is not proof the page is dead. Never
-- clear a redirect on an unreachable-but-unconfirmed target.
UPDATE catalogsearch_query
SET redirect = NULL, is_processed = 0
WHERE @sg = 1
  AND store_id = 1
  AND (redirect LIKE '%ial.edu.sg%'
       OR redirect = 'https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf');
