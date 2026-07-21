-- Repurpose four SG non-WSQ Claude courses into the Claude Masterclass line-up
-- (requested 2026-07-21):
--
--   C1382  "Agentic AI with Claude Code"           -> "Claude Cowork Masterclass"
--          url_key: agentic-ai-with-claude-code    -> claude-cowork-masterclass
--          Subject CHANGES (Code -> Cowork): overview + topics rewritten
--          (1 day / 7.5h / $350 kept; 3 topics). Certificate + WSQ funding
--          sections kept in short_description (present before this change).
--
--   C1417  "Claude Cowork for Business Automation" -> "Claude Code Masterclass"
--          url_key: claude-cowork-for-business-automation -> claude-code-masterclass
--          Subject CHANGES (Cowork -> Code): overview + topics rewritten
--          (2 days / 15h / $700 kept; 4 topics, 2 per day). Dropped from
--          Business & Soft Skills / Media & Design / GenAI Content Creation
--          (a developer course now) - categories resolved BY NAME.
--
--   C201   "Claude AI for Excel Data Analysis"     -> "Claude Design Masterclass"
--          url_key: claude-ai-for-excel-data-analysis -> claude-design-masterclass
--          Subject CHANGES (Excel -> Design): overview + topics rewritten
--          (1 day / 7.5h / $350 kept; 2 topics). Dropped from the Excel/data
--          categories (Microsoft, Microsoft Excel, Data Management, Data
--          Analytics), added to Media & Design - resolved BY NAME.
--
--   C197   "Claude for Microsoft 365"              -> "Claude Microsoft 365 Masterclass"
--          url_key: claude-for-microsoft-365       -> claude-microsoft-365-masterclass
--          Rebrand only (same subject): name, overview intro, meta, labels,
--          cover. Curriculum kept. Categories kept.
--
-- New covers rendered 2026-07-21 from the new titles (no funding chips - none
-- of the four carries funding-badge tags) and uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, relabels the media-gallery images (product-page
-- zoom gallery reads catalog_product_entity_media_gallery_value.label), and
-- drops url_path at every scope so the Catalog URL Rewrites indexer
-- regenerates the new URLs. 301s from the old slugs ship in 647.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without the SKUs.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e1382 := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1382');
SET @e1417 := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1417');
SET @e201  := (SELECT entity_id FROM catalog_product_entity WHERE sku='C201');
SET @e197  := (SELECT entity_id FROM catalog_product_entity WHERE sku='C197');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

-- ---------------------------------------------------------------------------
-- C1382 -> Claude Cowork Masterclass
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e1382, 'Claude Cowork Masterclass' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e1382, 'claude-cowork-masterclass' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e1382, '<p>Put an AI coworker on your team in this hands-on Claude Cowork Masterclass. Claude Cowork is Anthropic&rsquo;s agentic AI workspace that works directly with your files and folders &mdash; organising documents, drafting reports, building spreadsheets and presentations, and completing multi-step tasks from a single plain-English brief, with no coding required. In this masterclass, you will set up Cowork, connect it to your working folders, and learn to delegate real work to Claude while you stay in control of quality and accuracy.</p>
<p>Through practical projects, participants will use Cowork to organise messy folders, produce documents and management reports, process and analyse data, and run research and summarisation tasks end to end. You will learn to brief Claude effectively, run and review multi-step tasks, connect additional tools and integrations, and apply approvals, guardrails and secure practices when working with business data. By the end of the masterclass, you will be able to make Claude Cowork your everyday AI coworker and hand off hours of routine work every week.</p>
<h2>Certificate</h2>
<p>All participants will receive a Certificate of Completion from Tertiary Courses after achieved at least 75% attendance.</p>
<div style=" width: 100%; padding: 10px; border-radius: 25px;">
<h2>Funding and Grant Applications</h2>
<p>For WSQ funding, please checkout the details at <span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-create-engaging-content-with-generative-ai-gai.html" title="WSQ">WSQ - Create Engaging Content with Generative AI (GAI)</a></span></p>
</div>' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e1382, '<h3 class="course-topic-h3">Topic 1: Getting Started with Claude Cowork</h3>
<ul>
<li>Introduction to Claude Cowork and Agentic AI for Everyday Work</li>
<li>Setting Up Cowork and Connecting Your Files and Folders</li>
<li>Briefing Claude: Effective Prompting for Delegated Tasks</li>
<li>Running, Monitoring and Reviewing Cowork Sessions</li>
<li>Responsible, Secure and Private Use of AI with Work Data</li>
<li>Hands-on: Delegate Your First Task to Claude Cowork</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Automating Everyday Work with Cowork</h3>
<ul>
<li>Organising Files and Folders Automatically</li>
<li>Drafting Documents, Reports and Presentations</li>
<li>Processing and Analysing Data in Spreadsheets</li>
<li>Research, Summarisation and Report Generation</li>
<li>Running Multi-Step Tasks End to End</li>
<li>Hands-on: Turn a Messy Folder into a Management-Ready Report</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Advanced Cowork Workflows</h3>
<ul>
<li>Connecting Tools, Apps and Data Sources with Integrations</li>
<li>Building Repeatable Playbooks for Recurring Work</li>
<li>Running Parallel Tasks and Managing Longer Projects</li>
<li>Approvals, Guardrails and Human-in-the-Loop Review</li>
<li>Rolling Out Cowork Across Your Team</li>
<li>Hands-on: Build a Repeatable Cowork Workflow for Your Own Work</li>
</ul>' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e1382, 'Claude Cowork Masterclass' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e1382, 'Master Claude Cowork, Anthropic''s agentic AI workspace — delegate file organisation, documents, spreadsheets, research and multi-step business tasks to an AI coworker, no coding required.' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e1382, 'Claude Cowork Masterclass, Claude Cowork Course, Claude Cowork Training, Anthropic Claude, Agentic AI, AI Coworker, AI Productivity, Business Automation, File Automation, AI for Work, Singapore' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-21
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e1382, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1382-20260721-151022.png' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e1382, 'Claude Cowork Masterclass' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e1382, 'Claude Cowork Masterclass' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e1382, 'Claude Cowork Masterclass' FROM DUAL WHERE @e1382 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Claude Cowork Masterclass'
WHERE g.entity_id = @e1382 AND @e1382 IS NOT NULL;

-- ---------------------------------------------------------------------------
-- C1417 -> Claude Code Masterclass
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e1417, 'Claude Code Masterclass' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e1417, 'claude-code-masterclass' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e1417, '<p>Master agentic coding in this hands-on 2-day Claude Code Masterclass. Claude Code is Anthropic&rsquo;s agentic coding tool that works in your terminal and IDE &mdash; it navigates your codebase, edits files, runs commands and tests, and manages git, so you build software by directing an AI collaborator instead of typing every line yourself. You will learn to set up Claude Code, manage persistent project context with CLAUDE.md, and apply planning-first workflows, thinking mode and subagents to dramatically accelerate your development output.</p>
<p>Through practical projects, participants will build features end to end with automated tests, run parallel Claude sessions using Git worktrees, fix GitHub issues and manage pull requests, and extend Claude Code with hooks, slash commands and MCP servers such as Figma and Playwright for AI-driven UI generation and automated browser testing. By the end of the masterclass, you will be able to plan, build, test and ship real-world applications with Claude Code &mdash; positioning yourself at the forefront of the agentic coding revolution.</p>' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e1417, '<h3 class="course-topic-h3">Topic 1: Getting Started with Claude Code</h3>
<ul>
<li>Introduction to Agentic Coding and Claude Code Architecture</li>
<li>Installing and Setting Up Claude Code in Terminal and IDE</li>
<li>How Claude Navigates Codebases and Uses Tools (Filesystem, Terminal, Git)</li>
<li>Creating and Structuring CLAUDE.md for Persistent Project Knowledge</li>
<li>Managing Context with File References, Screenshots, Clear and Compact</li>
<li>Hands-on: Set Up a Project and Ship Your First AI-Built Feature</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Agentic Development Workflows</h3>
<ul>
<li>Planning-First Development to Improve Claude Performance</li>
<li>Using Thinking Mode for Complex Tasks</li>
<li>Brainstorming and Delegating with Subagents</li>
<li>Writing Automated Tests and Refactoring with Confidence</li>
<li>Git Workflows: Worktrees, Parallel Sessions, Issues and Pull Requests</li>
<li>Hands-on: Build a Feature Branch, Test, Create and Merge a PR</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Extending Claude Code with Hooks, Skills and MCP</h3>
<ul>
<li>Using Hooks to Execute Pre/Post Tool Commands</li>
<li>Custom Slash Commands and Reusable Skills</li>
<li>Connecting MCP Servers: Figma, Playwright and More</li>
<li>Importing Mockups and Generating UI with Figma MCP</li>
<li>Automating Browser Testing and Screenshots with Playwright MCP</li>
<li>Hands-on: Wire Up MCP Tools and Auto-Test a UI</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Building Real-World Projects with Claude Code</h3>
<ul>
<li>Building a Full-Stack Application End to End</li>
<li>Refactoring a Jupyter Notebook into a Production Dashboard</li>
<li>Iteratively Improving UI Design with Claude Feedback</li>
<li>Headless and Scripted Claude Code for Automation Pipelines</li>
<li>Best Practices, Security and Scaling Agentic Development</li>
<li>Hands-on: Convert a Notebook to a Dashboard and Ship It</li>
</ul>' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e1417, 'Claude Code Masterclass' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e1417, 'Master Claude Code, Anthropic''s agentic coding tool — CLAUDE.md, planning-first workflows, subagents, Git worktrees, hooks and MCP servers, building real applications hands-on over 2 days.' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e1417, 'Claude Code Masterclass, Claude Code Course, Claude Code Training, Agentic Coding, Anthropic Claude, AI Coding Assistant, AI Pair Programming, MCP, CLAUDE.md, Software Development, Singapore' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-21
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e1417, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1417-20260721-151023.png' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e1417, 'Claude Code Masterclass' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e1417, 'Claude Code Masterclass' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e1417, 'Claude Code Masterclass' FROM DUAL WHERE @e1417 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Claude Code Masterclass'
WHERE g.entity_id = @e1417 AND @e1417 IS NOT NULL;

-- Now a developer course: drop the business/design/content categories (by name)
DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.store_id = 0
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
WHERE cp.product_id = @e1417 AND @e1417 IS NOT NULL
  AND v.value IN ('Business & Soft Skills', 'Media & Design', 'GenAI Content Creation');

-- ---------------------------------------------------------------------------
-- C201 -> Claude Design Masterclass
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e201, 'Claude Design Masterclass' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e201, 'claude-design-masterclass' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e201, '<p>Design faster and better with AI in this hands-on 1-day Claude Design Masterclass. Anthropic&rsquo;s Claude turns plain-English design briefs into working visual output &mdash; interactive UI mockups and prototypes, presentation decks, infographics, posters and social media graphics &mdash; so you can go from idea to polished design in minutes instead of days, with no design software expertise required.</p>
<p>Through guided projects, participants will learn to write effective design briefs, generate and iterate UI mockups and landing pages with Claude artifacts, develop brand elements such as colour palettes and typography directions, and produce marketing collateral, slides and infographics ready for real use. You will also learn to keep designs consistent with a reusable design system, refine output through structured feedback loops, and hand off assets cleanly. By the end of the masterclass, you will be able to use Claude as your everyday design partner for professional-quality visual work.</p>' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e201, '<h3 class="course-topic-h3">Topic 1: Getting Started with Claude for Design</h3>
<ul>
<li>Introduction to Claude&rsquo;s Design Capabilities and Artifacts</li>
<li>Writing Effective Design Briefs and Prompts</li>
<li>Generating UI Mockups, Wireframes and Landing Pages</li>
<li>Iterating Designs with Structured Feedback</li>
<li>Working with Layout, Colour and Typography Principles</li>
<li>Hands-on: Design and Iterate a Landing Page with Claude</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Creating Professional Design Assets with Claude</h3>
<ul>
<li>Developing Brand Elements: Palettes, Typography and Style Guides</li>
<li>Designing Presentation Decks and Infographics</li>
<li>Creating Marketing Collateral: Posters, Flyers and Social Graphics</li>
<li>Building a Reusable Design System for Consistency</li>
<li>Exporting, Handoff and Responsible Use of AI-Generated Design</li>
<li>Hands-on: Produce a Branded Marketing Kit End to End</li>
</ul>' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e201, 'Claude Design Masterclass' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e201, 'Design with Claude AI — generate UI mockups, presentation decks, infographics, brand elements and marketing graphics from plain-English briefs in this hands-on 1-day masterclass.' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e201, 'Claude Design Masterclass, Claude Design Course, AI Design, Anthropic Claude, UI Mockups, AI Graphic Design, Presentation Design, Infographics, Marketing Design, Brand Design, Singapore' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-21
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e201, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C201-20260721-151023.png' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e201, 'Claude Design Masterclass' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e201, 'Claude Design Masterclass' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e201, 'Claude Design Masterclass' FROM DUAL WHERE @e201 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Claude Design Masterclass'
WHERE g.entity_id = @e201 AND @e201 IS NOT NULL;

-- No longer an Excel/data course: drop the Excel/data categories, add
-- Media & Design (by name)
DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.store_id = 0
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
WHERE cp.product_id = @e201 AND @e201 IS NOT NULL
  AND v.value IN ('Microsoft', 'Microsoft Excel', 'Data Management', 'Data Analytics');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e201, 999
FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
WHERE v.store_id = 0 AND v.value = 'Media & Design' AND @e201 IS NOT NULL;

-- ---------------------------------------------------------------------------
-- C197 -> Claude Microsoft 365 Masterclass  (rebrand only, curriculum kept)
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e197, 'Claude Microsoft 365 Masterclass' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e197, 'claude-microsoft-365-masterclass' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e197, '<p>Work smarter across Microsoft 365 in this hands-on 1-day Claude Microsoft 365 Masterclass. Learn how to use Anthropic&rsquo;s Claude to draft, summarise, analyse and create across Word, Excel, PowerPoint, Outlook and Teams. Instead of doing everything manually, you will use Claude as an AI assistant to speed up writing, data analysis, slide creation and email &mdash; while you stay in control of quality and accuracy.</p>
<p>Through practical projects, participants will use Claude to write and refine documents, summarise long content, analyse and explain spreadsheet data, generate slide outlines and content, and draft and reply to emails. You will also learn to prompt effectively, connect Claude to your files, fact-check output, and apply AI responsibly and securely with work data. By the end of the masterclass, you will be able to boost your everyday Microsoft 365 productivity with Claude.</p>' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e197, 'Claude Microsoft 365 Masterclass' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e197, 'Master Claude with Microsoft 365 — draft, summarise, analyse and create across Word, Excel, PowerPoint, Outlook and Teams with Anthropic''s Claude in this hands-on 1-day masterclass.' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e197, 'Claude Microsoft 365 Masterclass, Claude for Microsoft 365, Claude Office Course, Anthropic Claude, AI Productivity, Word, Excel, PowerPoint, Outlook, Teams, AI at Work, Singapore' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-21
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e197, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C197-20260721-151024.png' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e197, 'Claude Microsoft 365 Masterclass' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e197, 'Claude Microsoft 365 Masterclass' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e197, 'Claude Microsoft 365 Masterclass' FROM DUAL WHERE @e197 IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Claude Microsoft 365 Masterclass'
WHERE g.entity_id = @e197 AND @e197 IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Clear per-store overrides so partner store scopes can't shadow store 0,
-- and drop stale url_path rows at every scope so the Catalog URL Rewrites
-- indexer regenerates from the new url_keys.
-- ---------------------------------------------------------------------------

DELETE FROM catalog_product_entity_varchar
WHERE entity_id IN (@e1382, @e1417, @e201, @e197) AND entity_id IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_url, @a_mt, @a_md, @a_il, @a_sil, @a_til, @a_ciu);

DELETE FROM catalog_product_entity_text
WHERE entity_id IN (@e1382, @e1417, @e201, @e197) AND entity_id IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_desc, @a_short, @a_mk);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id IN (@e1382, @e1417, @e201, @e197) AND entity_id IS NOT NULL
  AND attribute_id = @a_up AND @a_up IS NOT NULL;
