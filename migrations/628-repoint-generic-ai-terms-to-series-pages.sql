-- 628: REPOINT generic AI search terms to the new "... Series" category pages.
--
-- WHY THIS EXISTS: migrations 621-627 only filled empty redirects
-- (redirect IS NULL OR redirect = ''), per the standing rule never to overwrite an
-- intentional redirect. On PRODUCTION these generic terms were already populated
-- with OLDER targets, so those UPDATEs correctly skipped them and the terms kept
-- landing on the previous pages:
--
--   codex           -> codex-cli-fundamentals-for-agentic-vibe-coding.html
--   claude          -> wsq-agentic-ai-applications-with-claude-code.html
--   genai           -> chatgpt-and-generative-ai-courses.html
--   agentic ai      -> ai-agent-courses.html
--
-- This migration is the DELIBERATE overwrite the user asked for. It is the only
-- migration in this series that writes over a non-empty redirect, and it does so
-- for an EXPLICIT, hand-listed set of GENERIC terms only.
--
-- NOT TOUCHED -- production holds a large, carefully curated map sending long exact
-- course-title queries to their own course pages, e.g.
--   "WSQ - Digital Marketing with Generative AI" -> digital-marketing-with-generative-ai-genai.html
--   "Agentic AI Automation with n8n"             -> wsq-agentic-ai-automation-with-n8n.html
--   "non code agentic ai"                        -> wsq-no-code-and-low-code-agentic-ai-applications.html
-- Those are intentional and remain untouched: this migration matches ONLY the exact
-- generic strings listed below, never a LIKE pattern.
--
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- Codex -> Codex AI Series
UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/codex-ai-series.html'
WHERE @sg = 1 AND store_id = 1 AND query_text IN (
  'codex','codex ai','codex ai series','ai codex','openai codex','open ai codex',
  'codex course','codex courses','codex training','codex series','codex cli',
  'codex coding','coding with codex','codec','codek','codx','cdoex'
);

-- Claude -> Claude AI Series
UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/claude-ai-series.html'
WHERE @sg = 1 AND store_id = 1 AND query_text IN (
  'claude','claude ai','claude ai series','ai claude','anthropic','anthropic claude',
  'claude course','claude courses','claude training','claude series','claude cli',
  'claude opus','claude sonnet','claude desktop','claude agent','claude agents',
  'clade','claud','cluade','claude ai course','claude automation',
  'claude code','claude ios','claude coding'
);

-- GenAI / Generative AI -> Generative AI Series
UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/generative-ai-series.html'
WHERE @sg = 1 AND store_id = 1 AND query_text IN (
  'genai','generative ai','gen ai','generative','ai generative','generative ai tools',
  'genai tools','generative ai series','gen-ai','gen a i',
  'genai course','genai courses','genai training',
  'generative ai course','generative ai courses','generative ai training',
  'generative a.i','genrative ai','genarative ai','generatve ai','geneartive ai',
  'genai ai','gena i'
);

-- Agentic AI / AI Agents -> AI Agents Series
UPDATE catalogsearch_query SET redirect = 'https://www.tertiarycourses.com.sg/ai-agents-series.html'
WHERE @sg = 1 AND store_id = 1 AND query_text IN (
  'agentic ai','agentic','ai agent','ai agents','agent','agents','ai agentic',
  'agentic ai automation','ai agents series',
  'agentic ai course','agentic ai courses','agentic ai training',
  'ai agent course','ai agent courses','ai agent training',
  'agentic course','agentic workflow','agentic workflows','agentic automation',
  'autonomous agents','autonomous ai agents',
  'multi agent','multi agents','multi-agent','agentic a i',
  'agentric ai','agenetic ai','agentik ai','ai agentz'
);
