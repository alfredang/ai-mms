-- 214: Point search-term redirects at the spun-off sibling sites (SG store, store_id = 1).
--   Only fills empty redirects (never overwrites an existing intentional redirect).
--   Collation is case-insensitive, so a redirect on one row matches every case variant.
--
--   PEI / advanced certificates  -> https://www.tertiaryinfotech.edu.sg/
--     ...in cyber security        -> .../courses/advanced-certificate-in-cyber-security.html
--   Exam / voucher (head terms)  -> https://exams.tertiaryinfotech.com/
--   Kids / STEM                  -> https://ai4kids.tertiarycourses.com.sg/
--
-- exam/voucher is intentionally HEAD-TERMS-ONLY: the "...Exam Prep" training courses stay
-- on this site, so specific course-name searches are left untouched. kids/stem and
-- advanced-cert match more broadly because that content has moved off-site.

-- 1) Advanced Certificate in Cyber Security -> the specific edu.sg course page (run first).
UPDATE catalogsearch_query SET redirect = 'https://www.tertiaryinfotech.edu.sg/courses/advanced-certificate-in-cyber-security.html' WHERE store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text LIKE '%advanced cert%' AND LOWER(query_text) LIKE '%cyber%';

-- 2) Remaining "advanced certificate*" + "pei" -> edu.sg homepage.
UPDATE catalogsearch_query SET redirect = 'https://www.tertiaryinfotech.edu.sg/' WHERE store_id = 1 AND (redirect IS NULL OR redirect = '') AND ((query_text LIKE '%advanced cert%' AND LOWER(query_text) NOT LIKE '%cyber%') OR LOWER(query_text) = 'pei' OR LOWER(query_text) = 'pei courses');

-- 3) Kids / STEM -> ai4kids. ('stem' is word-bounded so it never matches "system"/"ecosystem".)
UPDATE catalogsearch_query SET redirect = 'https://ai4kids.tertiarycourses.com.sg/' WHERE store_id = 1 AND (redirect IS NULL OR redirect = '') AND (LOWER(query_text) LIKE '%kids%' OR LOWER(query_text) = 'stem' OR LOWER(query_text) LIKE 'stem %' OR LOWER(query_text) LIKE '% stem' OR LOWER(query_text) LIKE '% stem %' OR LOWER(query_text) LIKE 'stem for kids%');

-- 4) Exam / voucher head terms -> exams.tertiaryinfotech.com.
UPDATE catalogsearch_query SET redirect = 'https://exams.tertiaryinfotech.com/' WHERE store_id = 1 AND (redirect IS NULL OR redirect = '') AND LOWER(query_text) IN ('exam','exams','voucher','vouchers','exam voucher','exam vouchers','exam prep','practice exam','practice exams','exam pre','exam vpuvher','certification voucher','certification vouchers','comptia voucher','comptia vouchers','itil voucher','voucher itil');
