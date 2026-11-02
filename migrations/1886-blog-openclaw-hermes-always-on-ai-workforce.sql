-- 1886: SG course marketing article based on the user-supplied v3.9 PDF.
-- User explicitly requested LinkedIn and Facebook sharing; empty dedup fields permit the scoped share operation after live verification.
-- Designed editorial hero rendered, inspected at both crops, and uploaded to R2.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
INSERT INTO mmd_blog_post (title, url_key, excerpt, content, author, status, published_at, related_skus, source_sku, hero_image_url, meta_title, meta_description, meta_keywords, linkedin_urn, linkedin_org_urn, facebook_post_id, created_at, updated_at)
SELECT 'From OpenClaw to Hermes: Build Your Always-On AI Workforce', 'openclaw-hermes-always-on-ai-workforce', 'Build one Hermes agent, then a team. Explore five always-on agents and redeem a free six-month AI subscription if eligible.', '<p><strong>Imagine starting your day with your priorities already organised, your research ready to review and your next campaign moving through a team of AI agents.</strong> You set the direction. Your agents take on defined jobs, bring back evidence and ask for decisions when your judgement matters.</p>
<p>That is the opportunity behind <a href="https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html"><strong>WSQ - Build a Human&ndash;AI Workforce with Autonomous AI Agents</strong></a>. Learn the journey from <strong>OpenClaw to Hermes to always-on AI agents</strong>, build your first Hermes assistant, then coordinate multiple Hermes agents around a shared business goal.</p>
<p><strong>Keep practising after class: eligible Singapore Citizens aged 18 and above can redeem one free six-month AI tools subscription after attending this eligible course.</strong> Learn the skills, then continue applying them with a premium AI tool. Eligibility and redemption details are explained below.</p>
<p><a href="https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html"><strong>View course dates, funding and registration &rarr;</strong></a></p>
<h2>From OpenClaw to Hermes to always-on AI agents</h2>
<p>The useful question is what work you can entrust to an agent. A weekly briefing, a researched presentation or a campaign with several deliverables each needs context, tools and a clear definition of completion.</p>
<p>This course uses <strong>OpenClaw &rarr; Hermes &rarr; hosted always-on agents</strong> as a learning progression through deployment choices. OpenClaw introduces a configurable agent harness with tools and communication channels. Hermes brings the focus to your working environment, memory and reusable skills. Hosted personal agents show how ongoing responsibilities can run in a managed cloud environment. These are different approaches you learn to assess for your work.</p>
<p>Always-on capability depends on the environment staying available, authorised connections and the agent''s configuration. A local Hermes setup needs its host and relevant services running for scheduled work; a hosted agent runs on its provider''s infrastructure. You learn to choose the arrangement that fits your tasks and oversight needs.</p>
<h2>Topic 1: Meet Cue, Dots, Muse, Duet and Grok Bot</h2>
<p>Begin with the landscape of human&ndash;AI collaboration: how agents reason, use tools, follow instructions and return to people for decisions. Topic 1 introduces <strong>five always-on AI agents</strong> and helps you compare them by the job you want done.</p>
<ul>
<li><strong>Manus Cue:</strong> explore the idea of personal agents with their own identity and responsibilities, including how you set permissions and review boundaries.</li>
<li><strong>OpenAI Dots:</strong> understand an ongoing agent that works across connected tools and projects, bringing back results and decisions that need your input.</li>
<li><strong>Meta Muse:</strong> explore personal assistance for email, schedules and longer-term goals, with attention to the connections and actions you authorise.</li>
<li><strong>Claude Duet:</strong> examine proactive briefings and follow-ups, and how an assistant decides when to ask for human attention. Access is subject to its research preview and regional availability.</li>
<li><strong>Grok Bot:</strong> explore named bots working on a persistent cloud computer, including the implications of shared files and signed-in sessions across bots on the same account.</li>
</ul>
<p>The hands-on starting point in the current course materials is <strong>Meta Muse or OpenAI Dots</strong>, subject to account access. You practise giving a useful brief, checking source evidence, reviewing a proposed action and stopping or correcting the agent. The five-platform comparison helps you choose tools; access to every platform is subject to its own plan, region and invitation requirements.</p>
<h2>Topic 2: Build one capable Hermes agent</h2>
<p>Next, put the ideas to work with <strong>a single Hermes agent</strong>. Using the course''s fictional Kopi Kaki business scenario, you develop one assistant with a clear role, working files, instructions and the tools needed to produce useful outputs.</p>
<p>You learn how the parts fit together: the model provides reasoning, tools perform actions, skills capture reusable procedures and context tells the agent what matters. Hermes becomes a practical environment for testing how one assistant handles a real brief.</p>
<ul>
<li>Set up Hermes Desktop and connect it to your project folder.</li>
<li>Configure a supported model provider and understand the account or usage requirements.</li>
<li>Connect the agent through Telegram with access restricted to approved users.</li>
<li>Apply tools and skills to research, website work and presentation creation.</li>
<li>Explore scheduled jobs for recurring briefings and repeatable work.</li>
<li>Check files, sources and finished outputs against the brief before accepting the result.</li>
</ul>
<p>The goal is to give one agent a responsibility it can carry through, with a visible result you can inspect. You build confidence by seeing which instructions help, where context is missing and when the agent should come back to you.</p>
<h2>Topic 3: Coordinate a team of Hermes agents</h2>
<p>Once you can supervise one assistant, learn to organise <strong>multiple Hermes agents</strong>. Topic 3 introduces specialist roles, task decomposition, subagents and coordination, with people setting goals and approving the important outcomes.</p>
<p>In the social campaign activity, named bots work in one group chat with distinct responsibilities for LinkedIn, Facebook, Instagram and visual content. A coordinator manages the brief and handoffs while you review the proposed posts. You learn how to get platform-specific work from specialists and keep the campaign consistent.</p>
<p>The video activity extends the workflow into <strong>research &rarr; script &rarr; production &rarr; review &rarr; human approval</strong>. A Kanban board makes responsibilities, dependencies and progress visible. You practise spotting a stalled task, improving a handoff and checking whether each output gives the next agent what it needs.</p>
<p>You also explore recurring jobs that prepare future work. The benefit comes from a clear operating model: every agent has a job, every handoff has an expected output and a person remains accountable for what goes public.</p>
<h2>Redeem a free six-month AI tools subscription</h2>
<p><strong>This course carries the Free AI Subscription label.</strong> Under the national initiative, Singapore Citizens aged 18 and above who attend an eligible course ending on or after <strong>16 September 2026</strong> can redeem <strong>one free six-month AI subscription per person</strong>.</p>
<p>The course page lists options including <strong>ChatGPT Plus, Google AI Pro, Manus AI, Microsoft 365 Personal and Singtel AI Pass</strong>. Choose from the options available in the official redemption process.</p>
<ol>
<li>Check that your chosen course carries the <strong>Free AI sub</strong> label on MySkillsFuture.</li>
<li>Attend the eligible course and complete its requirements.</li>
<li>Look out for the official notification email with redemption details.</li>
<li>Submit the request form within <strong>60 days of that email</strong>, selecting your preferred subscription.</li>
<li>Follow the activation instructions sent with the request outcome.</li>
</ol>
<p>You can redeem only one subscription under the initiative, regardless of how many eligible courses you attend. Your selection cannot be changed after submitting the request. A redeemed subscription gives access under that product''s own terms; it does not establish eligibility for every agent platform discussed in class.</p>
<p>Check the <a href="https://www.myskillsfuture.gov.sg/content/portal/en/career-resources/career-resources/education-career-personal-development/redeem-ai-subscription.html" target="_blank" rel="noopener">official MySkillsFuture redemption guide</a> for the current conditions.</p>
<h2>Bring a business goal and build your AI workforce</h2>
<p>This course suits professionals, business owners, marketers and operations teams who want to turn everyday work into clear agent responsibilities. Bring a goal such as preparing a weekly briefing, building a launch campaign or producing a reviewed presentation, and use the exercises to develop a repeatable approach.</p>
<p><strong>Learn the landscape. Build one Hermes agent. Coordinate a Hermes team.</strong> That progression gives you a practical foundation for deciding what to delegate, how to inspect the work and when to step in.</p>
<p>Eligible learners can also explore the course''s WSQ funding and SkillsFuture Credit arrangements. The amount payable depends on your eligibility and selected course run; check the current course page before registration.</p>
<p><a href="https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html"><strong>Start building your human&ndash;AI workforce: view the course and register your interest &rarr;</strong></a></p>
<h2>Frequently asked questions</h2>
<h3>Will I learn all five agents in equal depth?</h3>
<p>Topic 1 compares Cue, Dots, Muse, Duet and Grok Bot, with a practical starting activity using Muse or Dots where account access permits. Topics 2 and 3 focus on building a single Hermes agent and coordinating multiple Hermes agents.</p>
<h3>Is the free subscription available to everyone?</h3>
<p>The initiative is for Singapore Citizens aged 18 and above who attend an eligible course ending on or after 16 September 2026. One subscription is available per person, subject to the official redemption conditions.</p>
<h3>Can my agents publish business content automatically?</h3>
<p>Publishing depends on the tools, permissions and workflow you configure. The course activities teach you to prepare and review outputs, set approval points and verify results before authorising public actions.</p>
<p><em>Based on the course''s v3.9 learning materials dated 1 November 2026. Tool access and subscription conditions checked on 2 November 2026.</em></p>
<p><strong>Further reading:</strong> <a href="https://hermes-agent.nousresearch.com/" target="_blank" rel="noopener">Hermes Agent</a>; <a href="https://openai.com/index/introducing-dots/" target="_blank" rel="noopener">OpenAI Dots</a>; <a href="https://about.fb.com/news/2026/10/muse-is-now-available-in-singapore-the-worlds-first-personal-ai-agent-built-for-everyone/" target="_blank" rel="noopener">Meta Muse</a>; <a href="https://claude.com/resources/articles/claude-duet" target="_blank" rel="noopener">Claude Duet</a>; <a href="https://docs.x.ai/grok-bot/computer-and-apps" target="_blank" rel="noopener">Grok Bot</a>; <a href="https://cue.im/" target="_blank" rel="noopener">Cue</a>.</p>', 'Tertiary Infotech Academy', 1, '2026-11-02', 'TGS-2024043854', 'TGS-2024043854', 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20261101-185006-from-openclaw-to-hermes-build-your-always-on-ai-workforce.png', 'OpenClaw to Hermes: Build an Always-On AI Workforce', 'Explore Cue, Dots, Muse, Duet and Grok Bot. Build single and multi-agent Hermes workflows. Eligible learners can redeem a free six-month AI subscription.', 'Hermes Agent course Singapore, OpenClaw, always-on AI agents, Cue, Dots, Muse, Duet, Grok Bot, human AI workforce, free AI subscription', NULL, NULL, NULL, UTC_TIMESTAMP(), UTC_TIMESTAMP()
FROM DUAL WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT post_id FROM mmd_blog_post WHERE url_key = 'openclaw-hermes-always-on-ai-workforce') existing);
INSERT INTO tag (name, status, first_store_id) SELECT 'AI Agents', 1, 0 FROM DUAL WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'AI Agents') existing);
INSERT INTO tag (name, status, first_store_id) SELECT 'Agentic AI', 1, 0 FROM DUAL WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'Agentic AI') existing);
INSERT INTO tag (name, status, first_store_id) SELECT 'WSQ', 1, 0 FROM DUAL WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM (SELECT tag_id FROM tag WHERE name = 'WSQ') existing);
INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id) SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name IN ('AI Agents', 'Agentic AI', 'WSQ') WHERE @is_sg = 1 AND p.url_key = 'openclaw-hermes-always-on-ai-workforce';
