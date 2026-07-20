-- 629: backfill AI-series redirects for rows that did not exist when 621-628 ran.
--
-- ROOT CAUSE: Magento INSERTs a new catalogsearch_query row the first time a term is
-- searched. Migration 626 applied at 2026-07-20 08:14:45; a real search then created
-- the 'mlops' row (query_id 76432) at 08:28:54 -- 14 minutes later -- so 626's UPDATE
-- could not match a row that did not yet exist, and 'mlops' kept returning normal
-- search results. The same race can strand ANY seeded term whose row is created by a
-- live search after its migration has already run.
--
-- This migration re-applies the generic-term mapping so any row created in the
-- meantime picks up its redirect. It is safe to keep re-running.
--
-- Scope: fills EMPTY redirects only (does not re-overwrite anything 628 set, and does
-- not disturb production's curated course-title map).
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/ai-devops-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'ai devops','ai dev ops','ai devops series','devops ai','ai mlops',
  'mlops','ml ops','mlops course','mlops training',
  'machine learning ops','machine learning operations',
  'ai devops course','ai devops training',
  'ai devops with docker','ai devops with jenkins','ai devops with kubernetes',
  'ai devsecops','mlops ai','ml opts','mlopps','ai devopts'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/ai-security-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'ai security','ai security series','ai cyber security','ai cybersecurity','ai cyber',
  'security ai','ai for cyber security','ai for cybersecurity','ai for security',
  'ai in cyber security','ai governance','ai ethics','responsible ai','ai safety',
  'ai risk','ai security course','ai security training','ai security and governance',
  'ai secuirty','ai securty','ai cybersecuirty'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/ai-applications-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'ai application','ai applications','ai applications series','ai apps','ai app',
  'ai application development','ai application course','ai applications course',
  'build ai applications','building ai applications',
  'ai enterprise','ai enterprises','ai for enterprise','ai for enterprises',
  'enterprise ai','ai for business','ai in enterprise',
  'ai aplications','ai applicaton','ai appliations'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/codex-ai-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'codex','codex ai','codex ai series','ai codex','openai codex','open ai codex',
  'codex course','codex courses','codex training','codex series','codex cli',
  'codex coding','coding with codex','codec','codek','codx','cdoex'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/claude-ai-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'claude','claude ai','claude ai series','ai claude','anthropic','anthropic claude',
  'claude course','claude courses','claude training','claude series','claude cli',
  'claude opus','claude sonnet','claude desktop','claude agent','claude agents',
  'clade','claud','cluade','claude ai course','claude automation',
  'claude code','claude ios','claude coding'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/generative-ai-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'genai','generative ai','gen ai','generative','ai generative','generative ai tools',
  'genai tools','generative ai series','gen-ai','gen a i',
  'genai course','genai courses','genai training',
  'generative ai course','generative ai courses','generative ai training',
  'generative a.i','genrative ai','genarative ai','generatve ai','geneartive ai',
  'genai ai','gena i'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/ai-agents-series.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'agentic ai','agentic','ai agent','ai agents','agent','agents','ai agentic',
  'agentic ai automation','ai agents series',
  'agentic ai course','agentic ai courses','agentic ai training',
  'ai agent course','ai agent courses','ai agent training',
  'agentic course','agentic workflow','agentic workflows','agentic automation',
  'autonomous agents','autonomous ai agents',
  'multi agent','multi agents','multi-agent','agentic a i',
  'agentric ai','agenetic ai','agentik ai','ai agentz'
);

UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/ai-for-early-childhood.html'
WHERE @sg = 1 AND store_id = 1 AND (redirect IS NULL OR redirect = '') AND query_text IN (
  'early childhood','early childhood education','early childhood care','childhood',
  'preschool','preschool teacher','kindergarten','childcare','ece',
  'early chiildhook','early chilhood','earlychildhood'
);
