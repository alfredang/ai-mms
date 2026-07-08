-- 337: Redirect the "iso 9001 auditor" search term (and the literal "iso 900
-- auditor" typo the user named) to the WSQ ISO 9001 QMS Internal Auditor
-- course page. Scope is DELIBERATELY narrow: only these two exact terms — the
-- many ISO 9001 *Lead* Auditor terms are a DIFFERENT course (CQI/IRCA Lead
-- Auditor) and must not point here.
--
-- 'iso 9001 auditor' already exists (redirect NULL) → UPDATE. 'iso 900 auditor'
-- likely doesn't → INSERT if missing (catalogsearch_query has no unique key on
-- (query_text,store_id), so we can't ON DUPLICATE KEY; INSERT..SELECT WHERE NOT
-- EXISTS instead). Target verified HTTP 200 on the SG domain.
--
-- SG-guarded via the default-scope base_url so this is a no-op on the MY/GH
-- partner DBs (a .com.sg redirect there would be a forbidden cross-site
-- redirect). Non-overwriting: only fills redirect IS NULL/''.
SET @is_sg = (
    SELECT IF(COUNT(*) > 0, 1, 0) FROM core_config_data
    WHERE path = 'web/unsecure/base_url' AND scope = 'default'
      AND value LIKE '%www.tertiarycourses.com.sg%'
);
SET @target = 'https://www.tertiarycourses.com.sg/wsq-iso-9001-quality-management-system-qms-internal-auditor-training.html';

-- Fill the existing term(s)
SET @sql = IF(@is_sg = 1,
    'UPDATE catalogsearch_query SET redirect = @target
       WHERE query_text IN (''iso 9001 auditor'', ''iso 900 auditor'')
         AND (redirect IS NULL OR redirect = '''')',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Add the literal "iso 900 auditor" term if it isn't present yet
SET @sql = IF(@is_sg = 1,
    'INSERT INTO catalogsearch_query
        (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
     SELECT ''iso 900 auditor'', 1, 1, @target, 1, 1, 1, 1 FROM DUAL
      WHERE NOT EXISTS (
        SELECT 1 FROM catalogsearch_query WHERE query_text = ''iso 900 auditor'' AND store_id = 1)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
