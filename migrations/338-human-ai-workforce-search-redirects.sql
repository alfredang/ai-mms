-- 338: Redirect human-AI-workforce search terms to the WSQ "Build a Human-AI
-- Workforce with Autonomous AI Agents" course page. Terms requested: "human ai
-- interface", "ui ai workforce", "ai human interface", "human-ai", "ai-human
-- workforce" — plus hyphen/word-order variants and close synonyms.
--
-- Scope is DELIBERATELY narrow: HR-with-AI terms ("ai for human resource"),
-- AI-digital-human terms, and autonomous robots/driving terms are DIFFERENT
-- courses and are NOT in this list. Full course-title searches for other
-- courses (e.g. "Autonomous Agents with LLMs") are also excluded.
--
-- "ai human" and "autonomous ai agent" already exist (redirect NULL) → UPDATE
-- covers them; the rest are INSERTed if missing (catalogsearch_query has no
-- unique key on (query_text, store_id), so INSERT..SELECT WHERE NOT EXISTS).
-- Target verified HTTP 200 on the SG domain. All terms pure ASCII.
--
-- SG-guarded via @mms_instance (set by apply.php from MMS_COUNTRY_CODE; unset
-- = SG) so this is a no-op on the MY/GH partner DBs (a .com.sg redirect there
-- would be a forbidden cross-site redirect). Non-overwriting: only fills
-- redirect IS NULL/''.
SET @is_sg = IF(@mms_instance = 'SG', 1, 0);
SET @target = 'https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html';

-- Fill any of the terms that already exist without a redirect
SET @sql = IF(@is_sg = 1,
    'UPDATE catalogsearch_query SET redirect = @target
       WHERE query_text IN (
         ''human ai interface'', ''human-ai interface'', ''ai human interface'', ''ai-human interface'',
         ''ui ai workforce'',
         ''human-ai'', ''human ai'', ''ai-human'', ''ai human'',
         ''human-ai workforce'', ''human ai workforce'', ''ai-human workforce'', ''ai human workforce'',
         ''ai workforce'',
         ''autonomous ai agents'', ''autonomous ai agent'',
         ''human ai collaboration'', ''human-ai collaboration'')
         AND store_id = 1
         AND (redirect IS NULL OR redirect = '''')',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Add any of the terms that don't exist yet (store_id 1 = SG storefront)
SET @sql = IF(@is_sg = 1,
    'INSERT INTO catalogsearch_query
        (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
     SELECT t.q, 1, 1, @target, 1, 1, 1, 1
       FROM (SELECT ''human ai interface'' AS q
             UNION ALL SELECT ''human-ai interface''
             UNION ALL SELECT ''ai human interface''
             UNION ALL SELECT ''ai-human interface''
             UNION ALL SELECT ''ui ai workforce''
             UNION ALL SELECT ''human-ai''
             UNION ALL SELECT ''human ai''
             UNION ALL SELECT ''ai-human''
             UNION ALL SELECT ''ai human''
             UNION ALL SELECT ''human-ai workforce''
             UNION ALL SELECT ''human ai workforce''
             UNION ALL SELECT ''ai-human workforce''
             UNION ALL SELECT ''ai human workforce''
             UNION ALL SELECT ''ai workforce''
             UNION ALL SELECT ''autonomous ai agents''
             UNION ALL SELECT ''autonomous ai agent''
             UNION ALL SELECT ''human ai collaboration''
             UNION ALL SELECT ''human-ai collaboration'') t
      WHERE NOT EXISTS (
        SELECT 1 FROM catalogsearch_query c
         WHERE c.query_text = t.q AND c.store_id = 1)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
