-- 1030: SG search-term redirects — prioritise WSQ courses over their non-WSQ twins.
--
-- Rule: when a search term redirects to a non-WSQ course that has a PROVABLE WSQ
-- equivalent, point the term at the WSQ course instead. "Provable" means the WSQ
-- slug is the same slug with a wsq-/casl-/ibf- prefix, or an identical token set —
-- never a fuzzy/token-overlap guess (see feedback_autopopulate_fuzzy_search_redirects_wrong).
--
-- Search terms already pointing at a category page are left alone: a category is an
-- acceptable destination per the standing rule.
--
-- Applied live on SG prod 2026-08-15; this file keeps a rebuilt DB consistent.
-- Correction (not a fill) => guard on `redirect = <old>`, NOT the empty-only guard.
-- SG-only: the store guard makes this a no-op on MY/GH (WSQ/TGS- is SG-only).

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @b  := 'https://www.tertiarycourses.com.sg/';

-- ---------------------------------------------------------------------------
-- Part A: Design of Experiment (DOE) — the reported case.
-- C950 "Design of Experiment (DOE) Masterclass" vs
-- TGS-2024051249 "WSQ - Practical Design of Experiment (DoE) for Engineers and Researchers".
-- Matched by word-boundary regex on "doe" plus the spelled-out phrase, so typo/paren
-- variants and rows created later are all covered. The boundary is essential: a naive
-- '%doe%' also matches cdoex / claude cdoe / atudoesk, which point at other courses.
-- ---------------------------------------------------------------------------
SET @doe := CONCAT(@b, 'wsq-practical-design-of-experiment-doe-for-engineers-and-researchers.html');

UPDATE catalogsearch_query
SET redirect = @doe, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @doe
  AND (LOWER(query_text) LIKE '%design of exp%'
       OR LOWER(query_text) REGEXP '(^|[^a-z])doe([^a-z]|$)');

-- ---------------------------------------------------------------------------
-- Part B: the 15 non-WSQ targets with a provable WSQ/CASL twin.
-- Keyed on the exact old target URL so nothing else can be caught.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
SET redirect = CONCAT(@b, CASE redirect
      WHEN CONCAT(@b,'certified-lean-six-sigma-black-belt-clssbb.html')                 THEN 'wsq-certified-lean-six-sigma-black-belt-clssbb-training.html'
      WHEN CONCAT(@b,'aws-certified-solutions-architect-professional-training.html')    THEN 'wsq-aws-certified-solutions-architect-professional-training.html'
      WHEN CONCAT(@b,'ai-vibe-coding-with-python.html')                                 THEN 'wsq-ai-vibe-coding-with-python.html'
      WHEN CONCAT(@b,'dp-700-microsoft-certified-fabric-data-engineer-associate.html')  THEN 'wsq-microsoft-certified-fabric-data-engineer-associate-dp-700-training.html'
      WHEN CONCAT(@b,'ai-vibe-coding-for-machine-learning.html')                        THEN 'wsq-ai-vibe-coding-for-machine-learning.html'
      WHEN CONCAT(@b,'ai-vibe-coding-for-ios-mobile-apps-development.html')             THEN 'wsq-ai-vibe-coding-for-ios-mobile-apps-development.html'
      WHEN CONCAT(@b,'generative-ai-for-problem-solving.html')                          THEN 'wsq-generative-ai-for-problem-solving.html'
      WHEN CONCAT(@b,'agentic-ai-for-video-creation.html')                              THEN 'wsq-agentic-ai-for-video-creation.html'
      WHEN CONCAT(@b,'ai-vibe-coding-for-android-apps-development.html')                THEN 'wsq-ai-vibe-coding-for-android-apps-development.html'
      WHEN CONCAT(@b,'generative-ai-for-3d-modeling.html')                              THEN 'wsq-generative-ai-for-3d-modeling.html'
      WHEN CONCAT(@b,'ai-vibe-coding-for-excel-vba.html')                               THEN 'wsq-ai-vibe-coding-for-excel-vba.html'
      WHEN CONCAT(@b,'ai-for-cyber-security.html')                                      THEN 'wsq-ai-for-cyber-security.html'
      WHEN CONCAT(@b,'ai-vibe-coding-for-game-development.html')                        THEN 'wsq-ai-vibe-coding-for-game-development.html'
      WHEN CONCAT(@b,'generative-ai-for-design-thinking.html')                          THEN 'casl-generative-ai-for-design-thinking.html'
      WHEN CONCAT(@b,'ai-agents-with-gemini-spark.html')                                THEN 'casl-ai-agents-with-gemini-spark.html'
    END),
    num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect IN (
      CONCAT(@b,'certified-lean-six-sigma-black-belt-clssbb.html'),
      CONCAT(@b,'aws-certified-solutions-architect-professional-training.html'),
      CONCAT(@b,'ai-vibe-coding-with-python.html'),
      CONCAT(@b,'dp-700-microsoft-certified-fabric-data-engineer-associate.html'),
      CONCAT(@b,'ai-vibe-coding-for-machine-learning.html'),
      CONCAT(@b,'ai-vibe-coding-for-ios-mobile-apps-development.html'),
      CONCAT(@b,'generative-ai-for-problem-solving.html'),
      CONCAT(@b,'agentic-ai-for-video-creation.html'),
      CONCAT(@b,'ai-vibe-coding-for-android-apps-development.html'),
      CONCAT(@b,'generative-ai-for-3d-modeling.html'),
      CONCAT(@b,'ai-vibe-coding-for-excel-vba.html'),
      CONCAT(@b,'ai-for-cyber-security.html'),
      CONCAT(@b,'ai-vibe-coding-for-game-development.html'),
      CONCAT(@b,'generative-ai-for-design-thinking.html'),
      CONCAT(@b,'ai-agents-with-gemini-spark.html')
  );
