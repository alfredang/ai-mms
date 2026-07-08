-- 308: Blog SEO polish — trim 3 over-length meta titles to <=60 chars, and
-- spread all 10 blog posts' publish dates across 1 Jan - 30 Jun 2026 so the
-- /blog index and homepage widget read as a real, cadenced journal (sorted
-- latest first by published_at). Pure idempotent UPDATEs keyed by url_key —
-- safe to re-run and safe on any instance (runs after 303 + 307).

-- --- Meta title length fixes (SEO: keep titles <= ~60 chars) ---
UPDATE `mmd_blog_post` SET `meta_title` = 'Blockchain & OpenClaw Business Course SG | WSQ Funded' WHERE `url_key` = 'business-innovation-with-openclaw-and-blockchain';
UPDATE `mmd_blog_post` SET `meta_title` = 'Microsoft Copilot Studio Chatbot Course SG | WSQ Funded' WHERE `url_key` = 'build-chatbots-with-microsoft-copilot-studio';
UPDATE `mmd_blog_post` SET `meta_title` = 'Create Engaging Videos with GenAI SG | WSQ Funded' WHERE `url_key` = 'create-engaging-videos-with-generative-ai';

-- --- Publish-date spread (1 Jan 2026 -> 30 Jun 2026, ~18-day cadence) ---
UPDATE `mmd_blog_post` SET `published_at` = '2026-06-27', `created_at` = '2026-06-27 09:00:00' WHERE `url_key` = 'getting-started-with-claude-code';
UPDATE `mmd_blog_post` SET `published_at` = '2026-06-08', `created_at` = '2026-06-08 09:00:00' WHERE `url_key` = 'build-professional-web-apps-with-vibe-coding';
UPDATE `mmd_blog_post` SET `published_at` = '2026-05-20', `created_at` = '2026-05-20 09:00:00' WHERE `url_key` = 'agentic-ai-automation-with-n8n';
UPDATE `mmd_blog_post` SET `published_at` = '2026-05-01', `created_at` = '2026-05-01 09:00:00' WHERE `url_key` = 'business-innovation-with-openclaw-and-blockchain';
UPDATE `mmd_blog_post` SET `published_at` = '2026-04-12', `created_at` = '2026-04-12 09:00:00' WHERE `url_key` = 'create-engaging-videos-with-generative-ai';
UPDATE `mmd_blog_post` SET `published_at` = '2026-03-24', `created_at` = '2026-03-24 09:00:00' WHERE `url_key` = 'build-chatbots-with-microsoft-copilot-studio';
UPDATE `mmd_blog_post` SET `published_at` = '2026-03-05', `created_at` = '2026-03-05 09:00:00' WHERE `url_key` = 'pmp-certification-35-pdu-guide';
UPDATE `mmd_blog_post` SET `published_at` = '2026-02-15', `created_at` = '2026-02-15 09:00:00' WHERE `url_key` = 'sql-fundamentals-for-beginners';
UPDATE `mmd_blog_post` SET `published_at` = '2026-01-27', `created_at` = '2026-01-27 09:00:00' WHERE `url_key` = 'python-fundamentals-for-beginners';
UPDATE `mmd_blog_post` SET `published_at` = '2026-01-08', `created_at` = '2026-01-08 09:00:00' WHERE `url_key` = 'urban-farming-with-hydroponics-guide';
