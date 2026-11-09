-- 1913: Higgsfield course copy + SEO for the GenAI video pair (owner request 2026-11-09).
--
--   WSQ TGS-2024043855 "WSQ - Creating Engaging Videos with Generative AI (GenAI)" (entity 1180) and its
--   non-WSQ twin C1373 "Generative AI for Video Creation" (entity 1373; its Funding block already links to the
--   WSQ page and it already sits in the Generative AI Series, category 433). Courseware v11 runs the whole
--   pipeline in Higgsfield (Supercomputer agent, Cinema Studio, Seedance 2.5, Draft mode, Elements), so the
--   old Sora / Runway / Veed / ChatGPT copy is replaced.
--
--   Target keywords: "Generative AI for video creation", "Higgsfield", "GenAI for video creation",
--   "Higgsfield AI", "AI influencer", "AI marketing videos". Each page leads with its own phrase so the twins
--   do not compete: WSQ -> "GenAI for video creation" + "Higgsfield"; C1373 -> "Generative AI for video
--   creation" + "Higgsfield AI". Both cover AI influencer, micro drama, AI short films and AI marketing videos
--   and cross-link each other. Per .claude/rules/seo-meta.md:
--     * meta_title: WSQ stored as the full rendered title; C1373 stored bare.
--     * meta_description 130-160 chars; WSQ ends with its existing badge funding line (unchanged);
--       C1373 has no funding words.
--     * meta_keyword (TEXT table): target phrases first.
--     * short_description (About): rewritten from the v11 syllabus; the "AI training in Singapore" line is kept.
--
--   PROBED on SG prod 2026-11-09: all four attributes exist only at store 0 for both entities (no store-view
--   overrides, no wrong-table orphans). Peer-safe: metas replace only the exact probed value; About replaces
--   only the probed MD5. SG-only -> no-op on MY/GH. Idempotent.
--   Post-deploy: Redis/FPC flush, then curl the rendered <title>/<meta> and the About section.

SET NAMES utf8mb4;
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @w0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043855' LIMIT 1);
SET @c0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1373' LIMIT 1);
SET @w  := IF(@sg = 1, @w0, NULL);
SET @c  := IF(@sg = 1, @c0, NULL);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'        AND entity_type_id=@et AND backend_type='varchar');
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description'  AND entity_type_id=@et AND backend_type='varchar');
SET @a_kw := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et AND backend_type='text');
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);

-- ---------------------------------------------------------------- WSQ TGS-2024043855
UPDATE catalog_product_entity_varchar SET value = 'Funded up to 70% WSQ GenAI for Video Creation with Higgsfield | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Funded up to 70% WSQ Creating Engaging Videos with Generative AI | Tertiary Courses Singapore';
UPDATE catalog_product_entity_varchar SET value = 'GenAI for video creation in Higgsfield: AI influencers, micro dramas, AI marketing videos. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.'
 WHERE attribute_id = @a_md AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'Create videos with generative AI: write scripts, add captions, clean up audio and footage. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.';
UPDATE catalog_product_entity_text SET value = 'GenAI for video creation, Higgsfield course, Higgsfield AI training Singapore, AI influencer course, AI marketing videos, WSQ generative AI video course, SkillsFuture Credit course, UTAP claimable course'
 WHERE attribute_id = @a_kw AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND value = 'generative AI video course, AI video creation training Singapore, AI video scripts, video editing, closed captions, AI VFX, WSQ course Singapore, SkillsFuture Credit course, UTAP claimable course';
UPDATE catalog_product_entity_text SET value = '<p><strong>GenAI for video creation</strong>, done end to end in <strong>Higgsfield</strong>. You brief Higgsfield''s Supercomputer agent in plain English, or direct every shot yourself in Cinema Studio, and take an idea to a published 15-second film. The same pipeline makes an <strong>AI influencer</strong> post, an AI micro drama episode, an AI short film or a set of <strong>AI marketing videos</strong>.</p>
<p>Topic 1 opens with what AI has changed in video, using real AI movies, micro dramas, influencers, singers and ads. You then write a script and shot list with Supercomputer and AI Director, turn your house standards into a reusable Higgsfield Skill, and plan the work and its credit budget.</p>
<p>Topic 2 is about consistency and quality. You build Elements, the characters, locations and props that keep a face the same from shot to shot, then direct shots and takes in Cinema Studio with Seedance 2.5. You test on cheap 480p Draft takes before paying for a 1080p final, and score the cut against quality parameters.</p>
<p>Topic 3 fixes and finishes. You replace objects, upscale, reframe and regenerate a failed shot, add voice, music and cinematic effects, compare video models, and publish in 9:16 and 16:9 with an AI-content label. You close with a mini capstone, directing your own 15-second video, and the ethics of AI video: consent and likeness, copyright and disclosure, with real cases.</p>
<p>This is a WSQ course with funding of up to 70%. Want the same Higgsfield workflow as a non-funded course? See <a href="/generative-ai-for-video-creation.html">Generative AI for Video Creation</a>.</p>
<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/generative-ai-series.html">generative AI training</a>.</p>'
 WHERE attribute_id = @a_sd AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL AND MD5(value) = '3e19fa655599d4554633d7f0d0e147cf';
-- ---------------------------------------------------------------- non-WSQ C1373
UPDATE catalog_product_entity_varchar SET value = 'Generative AI for Video Creation: Higgsfield AI'
 WHERE attribute_id = @a_mt AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'Generative AI for Video Creation Course';
UPDATE catalog_product_entity_varchar SET value = 'Generative AI for video creation with Higgsfield AI: make AI influencer posts, micro dramas, AI short films and AI marketing videos, hands-on in Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'Generative AI for video creation: write scripts with AI, improve footage on AI video platforms, and add avatars, voiceovers and captions to finish quickly.';
UPDATE catalog_product_entity_text SET value = 'generative AI for video creation, Higgsfield AI course, Higgsfield training Singapore, AI influencer course, AI marketing videos, AI short films, AI micro drama'
 WHERE attribute_id = @a_kw AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND value = 'generative AI for video creation course, AI video training Singapore, AI video editing, AI avatars, AI voiceover, video scripting';
UPDATE catalog_product_entity_text SET value = '<p><strong>Generative AI for video creation</strong> with <strong>Higgsfield AI</strong>: one studio for the whole job, from script and cast to shoot, fix and publish. You make the formats people watch today, from <strong>AI influencer</strong> posts and AI micro drama episodes to <strong>AI short films</strong> and <strong>AI marketing videos</strong>, and finish with a 15-second video you directed yourself. It suits marketers, social media managers, trainers and content creators.</p>
<p>Topic 1 shows what AI has changed in video, with real AI movies, micro dramas, influencers, singers and ads. You then brief Higgsfield''s Supercomputer agent and AI Director for a script and shot list, save your house rules as a reusable Skill, and plan the work and its credit budget.</p>
<p>Topic 2 keeps every shot consistent. You save characters, locations and props as Elements so a face stays the same across shots, direct shots and takes in Cinema Studio with Seedance 2.5, and test on cheap 480p Draft takes before you pay for a 1080p final.</p>
<p>Topic 3 fixes and finishes: replace an object, upscale, reframe or regenerate one failed shot, add voice, music and cinematic effects, and publish in 9:16 and 16:9 with an AI-content label. A mini capstone puts it all together, and a closing session covers consent, likeness, copyright and disclosure, with real cases.</p>
<p>The same Higgsfield workflow is also taught as <a href="/wsq-creating-engaging-videos-with-generative-ai-genai.html">Creating Engaging Videos with Generative AI (GenAI)</a>.</p>
<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/generative-ai-series.html">generative AI training</a>.</p>'
 WHERE attribute_id = @a_sd AND entity_id = @c AND store_id = 0 AND @c IS NOT NULL AND MD5(value) = '41ab09fc0f4c93e87aaf5db99a9f677c';
