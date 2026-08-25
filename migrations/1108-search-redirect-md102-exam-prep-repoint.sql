-- Repoint search redirects that target the retired MD-102 Exam Prep course.
-- The old slug md-102-microsoft-certified-endpoint-administrator-associate-exam-prep.html
-- now 301s to an unrelated CompTIA page, so terms like "MD102" / "MD-102 Exam Prep class"
-- were chaining users to the wrong course. Applied live on SG prod 2026-08-25; this keeps
-- a rebuilt/restored DB in the same state. Complements 1107 (which deliberately excluded
-- exam-prep-worded terms while the sibling was assumed live).
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-microsoft-certified-endpoint-administrator-associate-md-102.html';
SET @old := 'https://www.tertiarycourses.com.sg/md-102-microsoft-certified-endpoint-administrator-associate-exam-prep.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect = @old;
