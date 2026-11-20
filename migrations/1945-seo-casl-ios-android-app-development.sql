-- 1945: SEO for CASL TGS-2026066894 "CASL - AI Vibe Coding for iOS and Android Apps" (entity 1310), owner request 2026-11-20.
--
--   Target keywords: "iOS app development", "mobile app development", "Android app development".
--   Per .claude/rules/seo-meta.md:
--     * meta_title: stored as the full rendered title (SG funded); core wording 51 chars, keywords first.
--     * meta_description 130-160 chars, ends with the badge funding line. The course now carries the
--       SkillsFuture Credit badge (WSQ/CASL badge rule 2026-11-20), so the line claims SkillsFuture Credit.
--     * meta_keyword (TEXT table): the three target phrases first.
--     * short_description (About): opening and audience paragraphs carry the three phrases; the syllabus
--       paragraphs are unchanged; adds links to the single-platform WSQ iOS and Android courses.
--   name (H1), url_key, topics and assessment are NOT changed.
--
--   PROBED on SG prod 2026-11-20: all four attributes exist only at store 0 (no store-view overrides, no
--   wrong-table orphans). Peer-safe: metas replace only the exact probed value; About replaces only the
--   probed MD5. SG-only -> no-op on MY/GH. Idempotent.
--   Post-deploy: cache flush, then curl the rendered <title>/<meta> and the About section.

SET NAMES utf8mb4;
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @p0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026066894' LIMIT 1);
SET @p  := IF(@sg = 1, @p0, NULL);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'        AND entity_type_id=@et AND backend_type='varchar');
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description'  AND entity_type_id=@et AND backend_type='varchar');
SET @a_kw := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et AND backend_type='text');
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar SET value = 'Funded up to 70% CASL iOS and Android App Development with AI Vibe Coding | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @p AND store_id = 0 AND @p IS NOT NULL AND value = 'Funded up to 70% CASL AI Vibe Coding for iOS and Android Apps Course | Tertiary Courses Singapore';
UPDATE catalog_product_entity_varchar SET value = 'Mobile app development with AI vibe coding: iOS app development and Android app development, hands-on. Up to 70% CASL funding; SkillsFuture Credit claimable.'
 WHERE attribute_id = @a_md AND entity_id = @p AND store_id = 0 AND @p IS NOT NULL AND value = 'AI vibe coding for iOS and Android apps: prompt AI to build screens and app logic, link APIs and test. Up to 70% CASL funding; SFEC claimable.';
UPDATE catalog_product_entity_text SET value = 'mobile app development course, iOS app development course, Android app development course, mobile app development training Singapore, AI vibe coding for iOS and Android apps, CASL mobile app development course, SkillsFuture Credit course'
 WHERE attribute_id = @a_kw AND entity_id = @p AND store_id = 0 AND @p IS NOT NULL AND value = 'AI vibe coding mobile apps course, mobile app development training Singapore, iOS apps, Android apps, vibe coding, app testing, CASL course';
UPDATE catalog_product_entity_text SET value = '<p>Learn <strong>mobile app development</strong> the AI way. This course covers <strong>iOS app development</strong> and <strong>Android app development</strong> using <strong>vibe coding</strong>, an AI-assisted approach in which working software is produced from natural language instruction. You describe the app you want, the AI generates the screens and logic, and you review, test and improve the result.</p><p>Learners will first understand vibe coding concepts, AI-assisted intent-driven workflows, and how mobile applications are structured across client-side and server-side components. They will then create nuanced and strategic prompts that optimise AI model performance, combining prompting methodologies and applying task decomposition to structure complex build requests.</p><p>The course covers the generation and refinement of mobile screens and application logic, as well as the integration of backend services and application programming interfaces. Learners will also set up appropriate testing conditions, define test cases and technical criteria, evaluate application performance and data transfer integrity, and interpret test results to determine whether a build is fit to release.</p><p>Learners will diagnose and optimise underperforming prompts and generated code by adjusting their approach based on the results returned, and develop a repeatable improvement cycle. The course also covers ethical principles for AI-assisted development, responsible AI development frameworks, data governance, security and privacy, and safeguards including human review before AI-generated code reaches production.</p><p>Designed for beginner to intermediate learners, this course suits aspiring mobile app developers, IT professionals, product practitioners and business technologists. No prior mobile app development experience is required.</p>
<p>Want to go deeper on one platform? See <a href="/wsq-ai-vibe-coding-for-ios-mobile-apps-development.html">AI Vibe Coding for iOS Mobile Apps Development</a> and <a href="/wsq-ai-vibe-coding-for-android-apps-development.html">AI Vibe Coding for Android Apps Development</a>.</p>
<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/ai-vibe-coding-series.html">AI vibe coding courses</a>.</p>'
 WHERE attribute_id = @a_sd AND entity_id = @p AND store_id = 0 AND @p IS NOT NULL AND MD5(value) = 'f253648c1e1f3556200c37f031d98ac5';
