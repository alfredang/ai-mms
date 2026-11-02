-- SEO: rank the SG AI pages for the "AI training Singapore" keyword family (user directive 2026-10-30).
--
-- Audit (2026-10-30): tertiarycourses.com.sg is not in Google's top 60 for "ai training singapore". The SERP is
-- hub pages (SMU, NUS-ISS, Kaplan, JCI, Info-Tech) titled "AI Training/Courses in Singapore". Our AI pages had
-- generic filler copy (identical template text on every category), "AI training" absent from the body, and no
-- internal links between the AI Series.
--
-- Keyword -> page map (one focused page per keyword cluster; plurals/typos need no separate targeting):
--   252 AI Courses           /artificial-intelligence-courses.html  ai training / ai courses (in) singapore
--   189 Agentic AI Series    /agentic-ai-series.html                agentic ai training / courses (in) singapore
--   433 Generative AI Series /generative-ai-series.html             generative ai training (in) singapore
--   415 AI Agents Series     /ai-agents-series.html                 ai agents training / courses (in) singapore
--
-- New values: meta_title BARE (MMD_Seotitle appends "| Tertiary Courses Singapore"), meta_description 130-160
-- chars keyword-first, meta_keywords <= 8 phrases, description = the existing banner paragraph + keyword-led
-- H2 sections written from the courses actually listed, cross-links between the four pages + WSQ sub-categories.
-- Root-relative links; every target verified 200 on SG. Store-view overrides (the store-1 description copies)
-- are removed so the store-0 value renders. Name / url_key / is_active untouched.
--
-- SG-only (store guard) and keyed on entity id + current name -> no-op on MY/GH (category ids differ per
-- partner; their copy is applied DB-only) and on a renamed category. Idempotent. Post-deploy:
-- catalog_category_flat reindex + cache flush.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @c_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @c_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description' AND backend_type = 'text');
SET @c_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords' AND backend_type = 'text');
SET @c_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description' AND backend_type = 'text');
SET @ok := (@sg = 1 AND @c_name IS NOT NULL AND @c_mtitle IS NOT NULL AND @c_mdesc IS NOT NULL AND @c_mkey IS NOT NULL AND @c_desc IS NOT NULL);

DROP TABLE IF EXISTS mms_seo_ai_kw_stage;

CREATE TABLE mms_seo_ai_kw_stage (
  id     INT UNSIGNED NOT NULL PRIMARY KEY,
  name   VARCHAR(255) NOT NULL,
  mt     VARCHAR(255) NOT NULL,
  md     TEXT NOT NULL,
  mk     TEXT NOT NULL,
  body   TEXT NOT NULL,
  banner TEXT NULL,
  full   MEDIUMTEXT NULL
) DEFAULT CHARSET = utf8;

INSERT INTO mms_seo_ai_kw_stage (id, name, mt, md, mk, body) VALUES
(252, 'AI Courses', 'AI Training & AI Courses in Singapore', 'AI training in Singapore for professionals and teams: hands-on generative AI, agentic AI, Claude, Copilot and AI coding courses. WSQ-funded and short courses.', 'ai training Singapore, ai courses Singapore, ai training in Singapore, ai courses in Singapore, corporate ai training Singapore, generative ai training, agentic ai training, wsq ai courses', '<h2>AI Training in Singapore for Professionals and Teams</h2>
<p>Tertiary Courses runs hands-on <strong>AI training in Singapore</strong> for working professionals, developers and corporate teams. Choose from more than 200 instructor-led <strong>AI courses</strong>, from generative AI for everyday work to agentic AI, AI agents and AI coding for technical staff. Every course is built around practical exercises you can apply at work the next day. Whether you need <strong>AI training</strong> for yourself or a whole team, start with the track that fits your role.</p>
<h2>Choose Your AI Training Track</h2>
<ul>
<li><a href="/generative-ai-series.html">Generative AI courses</a>: content, SEO, presentations, image and video creation with generative AI.</li>
<li><a href="/microsoft-copilot-series.html">Microsoft Copilot courses</a>: Copilot in Word, Excel, PowerPoint, Outlook and Teams.</li>
<li><a href="/claude-ai-series.html">Claude AI courses</a>: Claude and Claude Code for writing, analysis and development.</li>
<li><a href="/gemini-ai-series.html">Gemini AI courses</a>: Google Gemini for productivity and app development.</li>
<li><a href="/codex-ai-series.html">Codex AI courses</a>: OpenAI Codex for AI-assisted software development.</li>
<li><a href="/agentic-ai-series.html">Agentic AI courses</a>: AI workflow automation with n8n, Codex and agent frameworks.</li>
<li><a href="/ai-agents-series.html">AI Agents courses</a>: build AI agents with Copilot Studio, OpenClaw and Gemini.</li>
<li><a href="/multi-agents-series.html">Multi AI Agents courses</a>: design multi-agent systems that plan and work together.</li>
<li><a href="/ai-vibe-coding-series.html">AI Vibe Coding courses</a>: build web, mobile and data apps by prompting AI coding tools.</li>
<li><a href="/ai-applications-series.html">AI Applications courses</a>: machine learning, computer vision and reinforcement learning.</li>
<li><a href="/ai-infrastructure-series.html">AI Infrastructure courses</a>: deploy, run and operate AI models and pipelines.</li>
<li><a href="/ai-security-series.html">AI Security courses</a>: secure AI systems, AI for cybersecurity and responsible AI.</li>
</ul>
<h2>Funded AI Courses</h2>
<p>Singapore Citizens and PRs can take <a href="/wsq-ai-courses.html">WSQ AI courses</a> with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Singaporeans who attend selected courses can also redeem a free 6-month premium AI tool subscription: see our <a href="/free-ai-subscription-courses.html">free AI subscription courses</a>. Each course page shows its own funding and claim options.</p>
<h2>Corporate AI Training</h2>
<p>We also run <a href="/corporate-training.html">corporate AI training</a> and <a href="/in-house-training.html">in-house AI workshops</a> for companies in Singapore, customised to your team''s tools and workflows. <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a> to plan an AI training programme.</p>
<h2>AI Training FAQs</h2>
<p><strong>Do I need coding experience?</strong> Not for most generative AI and Microsoft Copilot courses. Technical tracks such as agentic AI, AI vibe coding and AI applications list their prerequisites on each course page.</p>
<p><strong>Are classes online or in person?</strong> Classes run in person in Singapore or live online with a trainer. Each course schedule shows the options available.</p>
<p><strong>How do I choose the right AI course?</strong> Start with the track above that matches your role, then compare course outlines, duration and fees. Our team can recommend a learning pathway for you or your whole team.</p>'),
(189, 'Agentic AI Series', 'Agentic AI Training & Courses in Singapore', 'Agentic AI training in Singapore: build AI workflows and agents with n8n, Claude Code and Codex to automate marketing and business tasks. WSQ-funded options.', 'agentic ai training Singapore, agentic ai courses Singapore, agentic ai training in Singapore, agentic ai course, n8n ai automation course, ai workflow automation training, wsq agentic ai courses', '<h2>Agentic AI Training in Singapore</h2>
<p><strong>Agentic AI</strong> goes beyond chat. You design AI workflows and agents that plan steps, call tools and complete business tasks with less manual effort. Our <strong>agentic AI training in Singapore</strong> is hands-on: you build working automations in class with tools such as n8n, Claude Code, Codex and CrewAI.</p>
<h2>What You Will Learn in Our Agentic AI Courses</h2>
<ul>
<li>Automate business processes with agentic AI workflows</li>
<li>Build a RAG chatbot and voice and video agents with n8n</li>
<li>Apply agentic AI to digital marketing, Google Ads, email marketing, affiliate marketing and market research</li>
<li>Create agentic AI applications with Codex, or with no-code and low-code tools</li>
<li>Prepare for the AB-100 Microsoft Certified Agentic AI Business Solutions Architect exam</li>
</ul>
<h2>Who Should Attend</h2>
<p>Marketers, operations and business teams who want to automate repetitive work, and developers who want to build agentic AI applications. No-code courses need no programming; developer courses list their prerequisites on each course page.</p>
<p>Singapore Citizens and PRs can take <a href="/wsq-agentic-ai-courses.html">WSQ agentic AI courses</a> with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/ai-agents-series.html">AI agents training</a>, <a href="/multi-agents-series.html">multi AI agents courses</a> and <a href="/artificial-intelligence-courses.html">all AI training courses in Singapore</a>.</p>
<p>Need help choosing, or want agentic AI training for your company in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(433, 'Generative AI Series', 'Generative AI Training Courses in Singapore', 'Generative AI training in Singapore for content, SEO, presentations, video, Photoshop and project management. For professionals. WSQ-funded and short courses.', 'generative ai training Singapore, generative ai courses Singapore, generative ai training in Singapore, generative ai course, generative ai for content creation, generative ai for seo, wsq generative ai courses', '<h2>Generative AI Training in Singapore</h2>
<p>Learn to use <strong>generative AI</strong> tools to produce content, images, video and presentations faster, and to apply AI to project management, design thinking and problem solving. Our <strong>generative AI training in Singapore</strong> is practical: you work on real tasks from your own role during class.</p>
<h2>What You Will Learn in Our Generative AI Courses</h2>
<ul>
<li>Content creation, script development and storytelling, and social media marketing</li>
<li>Generative AI for SEO</li>
<li>Business presentations, strategic planning and sustainability reporting</li>
<li>Project management, agile design thinking, problem solving and creativity</li>
<li>Image, video and 3D work with Adobe Photoshop, Adobe Illustrator, AI video creation and 3D modeling</li>
<li>Instructional design and interviewing with generative AI</li>
</ul>
<h2>Who Should Attend</h2>
<p>Professionals in marketing, project management, design, HR and training who want to save time on everyday work. Most generative AI courses need no coding background.</p>
<p>Singapore Citizens and PRs can take <a href="/wsq-generative-ai-courses.html">WSQ generative AI courses</a> with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/microsoft-copilot-series.html">Microsoft Copilot courses</a>, <a href="/claude-ai-series.html">Claude AI courses</a> and <a href="/artificial-intelligence-courses.html">all AI training courses in Singapore</a>.</p>
<p>Need help choosing, or want generative AI training for your company in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(415, 'AI Agents Series', 'AI Agents Training & Courses in Singapore', 'AI agents training in Singapore: build agents with Copilot Studio, OpenClaw and Gemini, from beginner fundamentals to agent security. WSQ-funded options.', 'ai agents training Singapore, ai agents courses Singapore, ai agents training in Singapore, ai agents course, copilot studio agents course, ai agent security training, wsq ai agents courses', '<h2>AI Agents Training in Singapore</h2>
<p>AI agents answer questions, take actions and work alongside your team. Our <strong>AI agents training in Singapore</strong> takes you from beginner <strong>AI agent training</strong> fundamentals to building, running and securing your own agents.</p>
<h2>What You Will Learn in Our AI Agents Courses</h2>
<ul>
<li>AI agent fundamentals for beginners</li>
<li>Build AI agents and chatbots with Microsoft Copilot Studio</li>
<li>Run autonomous AI agents with OpenClaw, Hermes Agent and Gemini Spark</li>
<li>Build a multi AI agents workflow</li>
<li>Secure and govern AI agents in your organisation</li>
<li>Prepare for the Microsoft AB-620, AB-731 and AI-103 certification exams</li>
</ul>
<h2>Who Should Attend</h2>
<p>Business users and team leads who want AI agents to take on routine work, and developers and IT staff who build and manage them. Beginner courses need no programming; technical courses list their prerequisites on each course page.</p>
<p>Singapore Citizens and PRs can take <a href="/wsq-ai-agents-courses.html">WSQ AI agents courses</a> with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/agentic-ai-series.html">agentic AI training</a>, <a href="/multi-agents-series.html">multi AI agents courses</a> and <a href="/artificial-intelligence-courses.html">all AI training courses in Singapore</a>.</p>
<p>Need help choosing, or want AI agents training for your company in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>');

-- keep only categories whose current (store-view else store-0) name still matches
DELETE s FROM mms_seo_ai_kw_stage s
  LEFT JOIN catalog_category_entity_varchar n0 ON n0.entity_id = s.id AND n0.attribute_id = @c_name AND n0.store_id = 0
  LEFT JOIN catalog_category_entity_varchar n1 ON n1.entity_id = s.id AND n1.attribute_id = @c_name AND n1.store_id = 1
 WHERE TRIM(COALESCE(n1.value, n0.value, '')) <> s.name;

-- keep the existing banner paragraph (first <p class="category-image">...</p>) and replace the copy after it
UPDATE mms_seo_ai_kw_stage s
  LEFT JOIN catalog_category_entity_text t ON t.entity_id = s.id AND t.attribute_id = @c_desc AND t.store_id = 0
   SET s.banner = IF(t.value LIKE '<p class="category-image">%', SUBSTRING(t.value, 1, LOCATE('</p>', t.value) + 3), '');

UPDATE mms_seo_ai_kw_stage SET full = IF(banner = '', body, CONCAT(banner, '\n', body));

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mtitle, 0, s.id, s.mt FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mdesc, 0, s.id, s.md FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mkey, 0, s.id, s.mk FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_desc, 0, s.id, s.full FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE v FROM catalog_category_entity_varchar v JOIN mms_seo_ai_kw_stage s ON s.id = v.entity_id
 WHERE @ok AND v.attribute_id = @c_mtitle AND v.store_id <> 0;

DELETE t FROM catalog_category_entity_text t JOIN mms_seo_ai_kw_stage s ON s.id = t.entity_id
 WHERE @ok AND t.attribute_id IN (@c_mdesc, @c_mkey, @c_desc) AND t.store_id <> 0;

-- mirror into the store category flat table when it exists (reindex would do the same)
SET @has_flat := (SELECT COUNT(*) FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
                     AND COLUMN_NAME IN ('meta_title', 'meta_description', 'meta_keywords', 'description'));
SET @q := IF(@ok AND @has_flat = 4,
  'UPDATE catalog_category_flat_store_1 f JOIN mms_seo_ai_kw_stage s ON s.id = f.entity_id SET f.meta_title = s.mt, f.meta_description = s.md, f.meta_keywords = s.mk, f.description = s.full',
  'DO 0');
PREPARE st FROM @q;
EXECUTE st;
DEALLOCATE PREPARE st;

DROP TABLE IF EXISTS mms_seo_ai_kw_stage;
