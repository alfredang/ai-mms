-- 1697: on-site search redirects requested 2026-10-02, alongside retiring the
-- Vue JS (1690), Responsive Web Design (1691), Notion (1695) and Wix (1696)
-- category pages:
--   wix                    -> WSQ Build Your Online Presence ... with Wix (TGS-2023018262)
--   notion                 -> WSQ Mastering Notion for Content, Project and Database Mgmt
--   vue                    -> WSQ AI Vibe Coding for Full Stack Web Applications (TGS-2021008635)
--   responsive web design  -> Web Development category (web-design-courses.html)
--   java                   -> Programming category (programming-courses.html)
-- Every target was checked as a direct 200 on SG prod before writing.
--
-- Corrections OVERWRITE (NULL-safe `NOT (redirect <=> @tgt)`), matched by LIKE so
-- typo/variant rows and rows created later are covered. Collateral exclusions:
--   vue  -- every "Pearson Vue" exam search (pearson / pearon / person) stays as is.
--   java -- JavaScript searches are a different language and stay as is.
-- The bare term is seeded where no row exists. SG-only (store guard).

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ------------------------------------------------------------------- seeds
INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
SELECT t.q, 1, 1, NULL, 1, 1, 1, 1
  FROM (SELECT 'wix' q UNION ALL SELECT 'notion' UNION ALL SELECT 'vue'
        UNION ALL SELECT 'responsive web design' UNION ALL SELECT 'java') t
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM catalogsearch_query c
                   WHERE c.store_id = 1 AND LOWER(TRIM(c.query_text)) = t.q);

-- -------------------------------------------------------------------- wix
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-build-your-online-presence-and-website-with-wix-for-beginners.html';
UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1 AND NOT (redirect <=> @tgt)
   AND LOWER(query_text) LIKE '%wix%';

-- ----------------------------------------------------------------- notion
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-mastering-notion-for-content-project-and-database-management.html';
UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1 AND NOT (redirect <=> @tgt)
   AND LOWER(query_text) LIKE '%notion%';

-- -------------------------------------------------------------------- vue
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-full-stack-web-applications.html';
UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1 AND NOT (redirect <=> @tgt)
   AND LOWER(query_text) LIKE '%vue%'
   AND LOWER(query_text) NOT LIKE '%pearson%'
   AND LOWER(query_text) NOT LIKE '%pearon%'
   AND LOWER(query_text) NOT LIKE '%person%';

-- -------------------------------------------------- responsive web design
SET @tgt := 'https://www.tertiarycourses.com.sg/web-design-courses.html';
UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1 AND NOT (redirect <=> @tgt)
   AND LOWER(query_text) LIKE '%responsive%';

-- ------------------------------------------------------------------- java
SET @tgt := 'https://www.tertiarycourses.com.sg/programming-courses.html';
UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1 AND NOT (redirect <=> @tgt)
   AND LOWER(query_text) LIKE '%java%'
   AND LOWER(query_text) NOT LIKE '%javascript%'
   AND LOWER(query_text) NOT LIKE '%java script%';
