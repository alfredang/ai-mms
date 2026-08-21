-- Search-term redirect: generic "statistics" searches -> CASL Statistics Fundamental
-- Training for Beginners (WSQ->CASL rename follow-through).
-- Applied live on SG prod 2026-08-21 (34 rows); this migration keeps a rebuilt DB in sync.
-- Scope is deliberately tight: the old wsq- slug repoint, the full course-title pattern,
-- and an explicit verified term list. A bare LIKE '%statistic%' would hijack sibling
-- courses (R / Excel / SPC / Python statistics terms) and must never be used here.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-statistics-fundamental-training-for-beginners.html';
SET @old := 'https://www.tertiarycourses.com.sg/wsq-statistics-fundamental-training-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND ( redirect = @old
    OR LOWER(query_text) LIKE '%statistics fundamental training for beginner%'
    OR LOWER(TRIM(query_text)) IN (
      'statistics','statistic','"statistics"',
      'statistics fundamental','statistic fundamental','statistic fundamentl',
      'statistics fundamentals','statistics fundamental learning',
      'wsq statistics','wsq sstatistics','wsq - statistics','wsq statistics fundamental',
      'statistics fundamental training','statistics fundamentals training',
      'statistics fundamental training course','statistics fundamental training cours',
      'statistics fundamental trainin','statistics fundamental trainng',
      'statistics fundamentall','statistics fundamential'
    ));
