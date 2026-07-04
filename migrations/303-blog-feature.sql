-- 303: MMD_Blog feature — post/tag-link/vote tables, sample "Claude Code" lead-magnet
--      post (+ tags + seed ratings), and the "Blog" link in the top-nav CMS block.
--
-- Notes for future editors:
--  * apply.php splits statements on ";" at end-of-line — the long HTML content
--    value below is intentionally ONE line.
--  * Everything is idempotent (CREATE IF NOT EXISTS / WHERE NOT EXISTS / NOT LIKE
--    guards) so re-runs and partner-server runs are safe. All referenced tables
--    (cms_block, tag) are core Magento and exist on every instance.

CREATE TABLE IF NOT EXISTS `mmd_blog_post` (
    `post_id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title`            VARCHAR(255) NOT NULL,
    `url_key`          VARCHAR(255) NOT NULL,
    `excerpt`          TEXT NULL,
    `content`          MEDIUMTEXT NULL,
    `hero_image_url`   VARCHAR(512) NULL,
    `author`           VARCHAR(255) NULL,
    `status`           TINYINT NOT NULL DEFAULT 0,
    `published_at`     DATE NULL,
    `related_skus`     VARCHAR(512) NULL,
    `source_sku`       VARCHAR(64) NULL,
    `linkedin_urn`     VARCHAR(128) NULL,
    `meta_title`       VARCHAR(255) NULL,
    `meta_description` TEXT NULL,
    `meta_keywords`    TEXT NULL,
    `rating_sum`       INT UNSIGNED NOT NULL DEFAULT 0,
    `rating_count`     INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`       DATETIME NULL,
    `updated_at`       DATETIME NULL,
    PRIMARY KEY (`post_id`),
    UNIQUE KEY `UQ_MMD_BLOG_URL_KEY` (`url_key`),
    KEY `IDX_MMD_BLOG_STATUS_PUBLISHED` (`status`, `published_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_blog_post_tag` (
    `post_id` INT UNSIGNED NOT NULL,
    `tag_id`  INT UNSIGNED NOT NULL,
    PRIMARY KEY (`post_id`, `tag_id`),
    KEY `IDX_MMD_BLOG_TAG` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_blog_post_vote` (
    `vote_id`    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `post_id`    INT UNSIGNED NOT NULL,
    `voter_hash` CHAR(40) NOT NULL,
    `rating`     TINYINT UNSIGNED NOT NULL,
    `created_at` DATETIME NULL,
    PRIMARY KEY (`vote_id`),
    UNIQUE KEY `UQ_MMD_BLOG_VOTE` (`post_id`, `voter_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Sample post: Claude Code (lead magnet -> WSQ Agentic AI with Claude Code course)
-- ---------------------------------------------------------------------------
INSERT INTO `mmd_blog_post` (`title`, `url_key`, `excerpt`, `content`, `author`, `status`, `published_at`, `related_skus`, `meta_title`, `meta_description`, `meta_keywords`, `created_at`, `updated_at`) SELECT 'Getting Started with Claude Code: Your AI Pair Programmer for Agentic Applications', 'getting-started-with-claude-code', 'Claude Code turns plain-English prompts into working, production-grade applications. Here is how it works, what you can build, and how to master it with up to 70% WSQ funding and your SkillsFuture Credit.', '<h2>Why everyone is talking about Claude Code</h2><p>Every developer and tech team faces the same squeeze: backlogs keep growing, boilerplate eats your week, and the business wants AI features shipped yesterday. Agentic coding tools change that equation. Among them, <strong>Claude Code</strong> — the terminal-based AI coding agent from Anthropic — has become the tool serious builders reach for when they want more than autocomplete.</p><h2>What exactly is Claude Code?</h2><p>Claude Code is an <strong>agentic AI pair programmer</strong> that runs in your terminal or IDE. Instead of suggesting one line at a time, it plans and executes whole tasks:</p><ul><li>Reads and understands your entire repository, not just the open file</li><li>Writes new features across multiple files, then runs your tests to verify them</li><li>Debugs failing builds, refactors legacy code and explains what it changed</li><li>Automates git workflows — branches, commits and pull requests from a prompt</li><li>Connects to external tools and APIs through MCP (Model Context Protocol) to become a true AI agent</li></ul><h2>What can you actually build with it?</h2><table><tr><th>Use case</th><th>What Claude Code does for you</th></tr><tr><td>Web apps and dashboards</td><td>Scaffolds full-stack apps, wires the database, styles the UI</td></tr><tr><td>Agentic AI workflows</td><td>Builds multi-step agents that call tools, browse data and act autonomously</td></tr><tr><td>Automation scripts</td><td>Turns a plain-English request into tested Python or JavaScript</td></tr><tr><td>Legacy code rescue</td><td>Explains, documents and modernises code nobody wants to touch</td></tr></table><p>In our hands-on classes, learners with modest coding backgrounds ship a working agentic application on day one — that is the real promise of vibe coding done professionally. If you want a structured path, the <a href="{{store direct_url=''wsq-agentic-ai-applications-with-claude-code.html''}}">WSQ Agentic AI Applications with Claude Code course</a> walks you from first prompt to deployed agent.</p><h2>Claude Code vs. traditional development</h2><ul><li><strong>Speed:</strong> features that took days now take hours — you review and direct instead of typing every line</li><li><strong>Quality:</strong> the agent runs your linters and tests before it declares a task done</li><li><strong>Coverage:</strong> one person can now move across frontend, backend, data and DevOps</li></ul><p>The catch? Results depend heavily on how well you brief, scope and verify the agent. Prompting an agentic coder is a <em>skill</em> — and that skill is exactly what employers are hiring for in 2026.</p><h2>Who should learn Claude Code?</h2><ul><li>Developers who want to multiply their output with agentic workflows</li><li>Data analysts and ops professionals automating reports and pipelines</li><li>Product managers and founders prototyping without waiting on an engineering queue</li><li>Career switchers entering tech through AI-assisted (vibe) coding</li></ul><h2>Fund your upskilling: WSQ funding + SkillsFuture Credit</h2><p>Here is the best part for Singapore-based learners: our Claude Code training is a <strong>WSQ-accredited course</strong>, which means <strong>up to 70% SkillsFuture (WSQ) course fee funding</strong> for eligible Singaporeans and PRs — and Singaporeans can <strong>claim their SkillsFuture Credit</strong> to offset the remaining fee, often bringing out-of-pocket cost close to zero. Companies sponsoring staff enjoy the same subsidies plus absentee payroll support, and SMEs get enhanced funding rates. <a href="{{store direct_url=''wsq-agentic-ai-applications-with-claude-code.html''}}">Check your funding eligibility and upcoming class dates here</a>.</p><h2>FAQ</h2><h3>Do I need to be a strong programmer to start?</h3><p>No. Claude Code lowers the barrier dramatically — you describe intent in English and review the output. Basic logic helps, and our trainers cover the fundamentals as you build. Complete beginners often start with the <a href="{{store direct_url=''wsq-build-professional-web-apps-quickly-with-ai-assisted-vibe-coding.html''}}">WSQ AI-assisted vibe coding for web apps course</a> first.</p><h3>Can I use WSQ funding and SkillsFuture Credit together?</h3><p>Yes. The WSQ baseline subsidy (50%, or up to 70% for Singaporeans aged 40 and above under MCES) is applied first, and you can then use SkillsFuture Credit to pay the nett fee. Our admissions team handles the paperwork for you.</p><h3>How is this different from ChatGPT or Copilot?</h3><p>Autocomplete tools suggest snippets; Claude Code is an <strong>agent</strong> — it plans, edits multiple files, runs commands and iterates until the task passes. For building agent-based automations end to end, see the <a href="{{store direct_url=''vibe-coding-for-agentic-ai-automations.html''}}">Vibe Coding for Agentic AI Automations course</a>.</p><h2>What to do next</h2><ol><li>Pick a small real project you have been putting off — an internal tool, a report automation, a web app</li><li>Reserve a seat in the <a href="{{store direct_url=''wsq-agentic-ai-applications-with-claude-code.html''}}"><strong>WSQ Agentic AI Applications with Claude Code</strong></a> class — seats are limited and funded places go fast</li><li>Bring your laptop; you will leave with a deployed agentic application and the skills to build the next ten</li></ol>', 'Tertiary Infotech Academy', 1, CURDATE(), 'TGS-2025052468, TGS-2025052341, C818', 'Claude Code Course Singapore | Agentic AI with WSQ Funding', 'Learn what Claude Code is, what you can build with it, and how to master agentic AI coding with up to 70% WSQ funding and SkillsFuture Credit in Singapore.', 'claude code, agentic ai, vibe coding, ai coding course, wsq funding, skillsfuture credit, anthropic claude', NOW(), NOW() FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `mmd_blog_post` WHERE `url_key` = 'getting-started-with-claude-code');

-- Tags (reuse the core Magento tag vocabulary; status 1 = approved)
INSERT INTO `tag` (`name`, `status`) SELECT 'Claude Code', 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tag` WHERE `name` = 'Claude Code');
INSERT INTO `tag` (`name`, `status`) SELECT 'Agentic AI', 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tag` WHERE `name` = 'Agentic AI');
INSERT INTO `tag` (`name`, `status`) SELECT 'Vibe Coding', 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tag` WHERE `name` = 'Vibe Coding');
INSERT INTO `tag` (`name`, `status`) SELECT 'AI Tools', 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tag` WHERE `name` = 'AI Tools');

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`) SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` IN ('Claude Code', 'Agentic AI', 'Vibe Coding', 'AI Tools') WHERE p.`url_key` = 'getting-started-with-claude-code';

-- Seed ratings so the star widget demonstrates the aggregate display
INSERT IGNORE INTO `mmd_blog_post_vote` (`post_id`, `voter_hash`, `rating`, `created_at`) SELECT p.`post_id`, 'seed-vote-0000000000000000000000000001', 5, NOW() FROM `mmd_blog_post` p WHERE p.`url_key` = 'getting-started-with-claude-code';
INSERT IGNORE INTO `mmd_blog_post_vote` (`post_id`, `voter_hash`, `rating`, `created_at`) SELECT p.`post_id`, 'seed-vote-0000000000000000000000000002', 5, NOW() FROM `mmd_blog_post` p WHERE p.`url_key` = 'getting-started-with-claude-code';
INSERT IGNORE INTO `mmd_blog_post_vote` (`post_id`, `voter_hash`, `rating`, `created_at`) SELECT p.`post_id`, 'seed-vote-0000000000000000000000000003', 4, NOW() FROM `mmd_blog_post` p WHERE p.`url_key` = 'getting-started-with-claude-code';

UPDATE `mmd_blog_post` p SET p.`rating_sum` = (SELECT COALESCE(SUM(v.`rating`), 0) FROM `mmd_blog_post_vote` v WHERE v.`post_id` = p.`post_id`), p.`rating_count` = (SELECT COUNT(*) FROM `mmd_blog_post_vote` v WHERE v.`post_id` = p.`post_id`) WHERE p.`url_key` = 'getting-started-with-claude-code';

-- ---------------------------------------------------------------------------
-- Top navigation: add the Blog link to the shared nav-links CMS block
-- (rendered right-aligned next to Contact Us by the Ultimo mega-menu).
-- ---------------------------------------------------------------------------
UPDATE `cms_block` SET `content` = CONCAT(`content`, '<li class="nav-item level0 level-top right"><a class="level-top" href="{{store direct_url=''blog''}}" title="Blog"><span>Blog</span></a></li>') WHERE `identifier` = 'block_nav_links' AND `content` NOT LIKE '%direct_url=''blog''%';
