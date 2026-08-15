-- 1031: Point PDPA / "personal data protection" search terms at the live WSQ course.
--
-- Context: the only enabled PDPA course on SG is TGS-2025060471
-- "WSQ - Personal Data Protection Management for SMEs". The two non-WSQ variants
-- (C1245b, C1313 "Fundamentals of the Personal Data Protection Act (PDPA) (2020)")
-- are disabled (status = 2), so a generic PDPA term hides nothing by redirecting here.
--
-- Four high-traffic rows previously pointed at the category page
-- wsq-cyber-security-pdpa-courses.html (incl. "pdpa" itself, popularity 505) or at
-- data-governance-protection-courses.html. A product page beats a category listing.
--
-- Correction, not a fill: uses `redirect <> @tgt` so already-populated wrong targets
-- are overwritten (the empty-only guard would silently skip them).
-- LIKE pattern rather than a frozen exact-term list so typo/paren variants and rows
-- created after this migration was written are covered too.
-- SG-only via the store guard; a no-op on partner sites (WSQ is SG-only).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-personal-data-protection-management-for-smes.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @tgt
  AND (LOWER(query_text) LIKE '%pdpa%'
    OR LOWER(query_text) LIKE '%personal data%');
