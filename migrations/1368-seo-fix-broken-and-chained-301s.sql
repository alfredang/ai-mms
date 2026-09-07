-- 1368-seo-fix-broken-and-chained-301s.sql
--
-- GSC "Page with redirect" validation failed (503 failed / 616 pending, 2026-09-05).
-- The overwhelming majority of the 1,119 flagged URLs are CORRECT, intentional 301s
-- (renamed course slugs + the pre-FlatCategoryUrl deep category paths) and need no
-- change — only re-validation. A full crawl of all 1,119 found two real defects:
--
--   (a) 31 URLs that 301 to a target which is itself a 404, because the destination
--       course/category was later retired (product status=2, or category is_active=0,
--       or the product no longer exists in store 1 at all). A 301 into a 404 loses
--       the link equity entirely and keeps failing GSC validation.
--   (b) 27 URLs that take TWO hops (A -> B -> C) because the course was renamed
--       twice. Google follows these but discounts them and flags the chain.
--
-- Fix: repoint (a) at the nearest LIVE category/page, and flatten (b) so the first
-- request lands directly on the final destination. Both are core_url_rewrite data
-- changes only — no code, no catalog changes, nothing is enabled or disabled here.
--
-- Every destination below was verified HTTP 200 on www.tertiarycourses.com.sg
-- before this migration was written.
--
-- SG-only via @mms_instance: these slugs are SG catalogue history; MY/GH never had
-- them. Idempotent — re-running simply re-asserts the same target_path.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

-- ---------------------------------------------------------------------------
-- (a) Redirects whose target is retired -> repoint to the nearest live page.
--     Matched on target_path so EVERY old alias pointing at the dead page is
--     fixed at once (e.g. the 16 historical MS-600 -*.html slugs).
-- ---------------------------------------------------------------------------

UPDATE `core_url_rewrite`
   SET `target_path` = 'microsoft-certifications-exams.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'ms-600-microsoft-365-certified-teams-application-developer-associate-exam-prep-2204.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'human-resource-management-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'ai-for-performance-management.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ecommerce-training-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'ecommerce-with-wordpress.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'gaming-animation-and-video-courses-in.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'gaming-software-courses.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'graphics-design-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'genai-for-kids-create-comics-and-manga-with-genai.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'graphics-design-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'genai-for-kids-creating-engaging-stories-with-gen-ai.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'business-intelligence-software-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'orange-courses.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'certification-exam-prep-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'pearson-vue-it-specialists.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'certification-exam-prep-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'person-vue-it-specialist-exam-prep.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'graphics-design-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'procreate-digital-art-courses.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'digital-graphics-software-training.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'rhino-masterclass.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'digital-graphics-software-training.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'rhino-trainings.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'social-media-marketing-training-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'tiktok-social-media-courses.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'gaming-animation-and-video-courses-in.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'unity-training-courses.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'social-media-marketing-training-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `target_path` = 'xiaohongshu-social-commerce-courses.html';


-- ---------------------------------------------------------------------------
-- (b) Two-hop chains -> point the first hop straight at the final destination.
-- ---------------------------------------------------------------------------

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-infrastructure-series.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'adult-training-courses/computer-programming-and-infocomm-courses/artificial-intelligence-courses/voice-agents-and-video-agents-coures.html'
   AND `target_path` = 'ai-devops-series.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'video-marketing-live-streaming-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'adult-training-courses/digital-marketing-courses-in/video-marketing-live-streaming.html'
   AND `target_path` = 'video-marketing-live-streaming.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-for-hr-management.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'agentic-ai-for-hr.html'
   AND `target_path` = 'ai-for-hr.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'generative-ai-for-interviewing.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'c-programming-training.html'
   AND `target_path` = 'ai-vibe-coding-with-c.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'fine-tuning-open-source-llm.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'ci-cd-jenkins-pipeline-docker.html'
   AND `target_path` = 'ai-devops-with-jenkins.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'job-redesign-for-managing-ai-agents.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'cplusplus-programming-trainining.html'
   AND `target_path` = 'ai-vibe-coding-for-cpp.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-security-and-governance.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'explainable-ai-in-practice-case-studies-and-applications.html'
   AND `target_path` = 'ai-security-and-governance-for-ai-agents.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'fine-tuning-openvla-model.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'from-novice-to-pro-building-coding-skills-with-github-copilot.html'
   AND `target_path` = 'ai-vibe-coding-for-mobile-apps-development.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'multi-ai-agents-system-for-digital-marketing.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'full-angular-js-course.html'
   AND `target_path` = 'ai-vibe-coding-for-multi-agent-ai-systems.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'deploy-docker-with-ai.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'full-docker-training.html'
   AND `target_path` = 'ai-devops-with-docker.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-for-network-security.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'full-java-programming-training.html'
   AND `target_path` = 'ai-vibe-coding-for-java.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'codex-for-digital-marketing.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'full-vue-js-training.html'
   AND `target_path` = 'ai-vibe-coding-with-codex.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-for-business.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'game-devleopment-courses-in.html'
   AND `target_path` = 'ai-for-general-applications.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'business-innovation-with-ai.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'hcna-certification-prep-training.html'
   AND `target_path` = 'pearson-vue-certified-it-specialist-artificial-intelligence-training.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-for-hr-management.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'innovating-human-resource-management-with-generative-ai-gai.html'
   AND `target_path` = 'ai-for-hr.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'local-llm-deployment-with-vllm.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'javascript-essential-training-singapore.html'
   AND `target_path` = 'ai-vibe-coding-for-javascript.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'multi-ai-agents-system-for-algorithmic-trading.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'machine-learning-for-algorithmic-trading.html'
   AND `target_path` = 'multi-agents-system-for-algorithmic-trading.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'deploy-kubernetes-with-ai.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'mastering-docker-and-kubernetes-for-containerized-applications.html'
   AND `target_path` = 'ai-devops-with-kubernetes.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-agent-security.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'php-essential-training.html'
   AND `target_path` = 'ai-vibe-coding-for-php-and-mysql.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-vibe-coding-for-python.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'python-3-essential-training-in-singapore.html'
   AND `target_path` = 'ai-vibe-coding-with-python.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-vibe-coding-for-python.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'python-3-essential-training.html'
   AND `target_path` = 'ai-vibe-coding-with-python.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'codex-for-digital-marketing.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'vibe-coding-for-agentic-ai-automations.html'
   AND `target_path` = 'ai-vibe-coding-with-codex.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'fine-tuning-openvla-model.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'vibe-coding-for-android-and-ios-mobile-apps.html'
   AND `target_path` = 'ai-vibe-coding-for-mobile-apps-development.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'multi-ai-agents-system-for-digital-marketing.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'vibe-coding-for-multi-agent-ai-systems.html'
   AND `target_path` = 'ai-vibe-coding-for-multi-agent-ai-systems.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'ai-infrastructure-series.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'voice-agents-and-video-agents-coures.html'
   AND `target_path` = 'ai-devops-series.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'wsq-ai-security-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'wsq-ibf-skillsfuture-utap-funded-courses/wsq-ai-courses/wsq-ai-ethics-and-governance-courses.html'
   AND `target_path` = 'wsq-ai-ethics-and-governance-courses.html';

UPDATE `core_url_rewrite`
   SET `target_path` = 'wsq-ai-vibe-coding-courses.html', `options` = 'RP'
 WHERE @is_sg > 0
   AND `store_id` = 1
   AND `request_path` = 'wsq-ibf-skillsfuture-utap-funded-courses/wsq-ai-courses/wsq-programming-vibe-coding-courses-tertiary-courses-singapore.html'
   AND `target_path` = 'wsq-programming-vibe-coding-courses-tertiary-courses-singapore.html';

