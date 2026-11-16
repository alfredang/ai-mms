-- 1901: eight search-term redirects (SG only), all applied live on SG prod 2026-11-05
-- (search redirects are data, not code). This file exists so a rebuilt/restored DB
-- keeps the same state.
--
-- 1. "AI Agent with Hermes Agent" (+ truncated "AI Agent with Hermes Agen") -> the CASL
--    course TGS-2026064176, matching the existing "hermes" / "hermes agent" redirects.
-- 2. "AI Vibe Coding for Game Development" (+ "WSQ - ..." variant) -> the WSQ course.
-- 3. "Mastering the Art & Science of Working with People & Teams using DISC AsiaPlus"
--    and its title variants, plus discasia/discasira (were on the old 301 slug) -> WSQ course.
-- 4. "Automate Video and Voice AI Agents with n8n" (+ "[VIRTUAL] WSQ - ...") -> WSQ course.
-- 5. "CompTIA A+ (Core 1 and 2)" (+ "WSQ - ...", and "A  Core 1 and 2" with the + lost) -> WSQ course.
-- 6. "Native Android Apps Development with Java and Vibe Coding" (was on the generic
--    programming-courses.html category) -> WSQ AI Vibe Coding for Android Apps Development.
-- 7. "Generative AI for Search Engine Optimization (SEO)" (+ "WSQ - ...") -> WSQ course.
-- 8. "AI Vibe Coding for Multi Agents System" (+ variants, "vibe coding multi agent", and rows
--    still on the course's old 301 slug wsq-vibe-coding-for-multi-agent-ai-systems) -> WSQ course.
--
-- NULL-safe guard `NOT (redirect <=> @tgt)` fills empty rows and overwrites wrong
-- ones. Tight title patterns so no unrelated rows are swept in.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @tgt := 'https://www.tertiarycourses.com.sg/casl-ai-agent-with-hermes-agent.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) LIKE 'ai agent with hermes agen%';

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-game-development.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%ai vibe coding for game dev%';

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-mastering-the-art-and-science-of-working-with-people-and-teams-using-disc-asiaplus.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%mastering the art%working with people%'
       OR LOWER(query_text) IN ('discasia', 'discasira'));

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-automate-video-and-voice-ai-agents-with-n8n.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%video and voice ai agents%n8n%';

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-comptia-certified-a-training-core-1-and-core-2.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%comptia a+ (core 1 and 2)%'
       OR LOWER(TRIM(query_text)) = 'a  core 1 and 2');

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-android-apps-development.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%native android apps development with java%vibe coding%';

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-search-engine-optimization-seo.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%generative ai for search engine optim%';

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-multi-agents-system.html';
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%ai vibe coding for multi agent%'
       OR LOWER(TRIM(query_text)) = 'vibe coding multi agent'
       OR redirect = 'https://www.tertiarycourses.com.sg/wsq-vibe-coding-for-multi-agent-ai-systems.html');
