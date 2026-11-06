-- 1905: SG blog updates and new Singtel AI Pass / Canva guide.

-- Public sources verified 6 Nov 2026; do not publish the private source email.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE mmd_blog_post SET content = REPLACE(content, 'Six AI tools (Manus, Hailuo AI, Otter.ai, MiniMax Code, MiniMax Audio and AKOOL) for three months, then one of them for three more', 'Seven AI tools (Canva Pro, Manus, Hailuo AI, Otter.ai, MiniMax Code, MiniMax Audio and Akool) for three months, then one selected tool for another three months'), updated_at = UTC_TIMESTAMP() WHERE @is_sg = 1 AND url_key = 'how-to-claim-free-ai-subscription-singapore-eligibility-steps-courses' AND content LIKE '%Six AI tools (Manus,%';

UPDATE mmd_blog_post SET content = CONCAT('<section id="singtel-canva-update-20261106"><h2>November 2026 update: Canva Pro joins Singtel AI Pass</h2>
<p><strong>Singtel AI Pass now includes seven premium AI tools: Canva Pro, Manus, Hailuo AI, Otter.ai, MiniMax Code, MiniMax Audio and Akool.</strong> Singtel''s current overview describes around S$600 in tool value. Try the suite for three months, then choose one tool for another three months. Canva adds AI-assisted design, presentations and video to the offering.</p>
<p>Read our <a href="https://www.tertiarycourses.com.sg/blog/singtel-ai-pass-canva-pro-seven-ai-tools-singapore">Singtel AI Pass and Canva Pro guide</a> for the tool list and redemption steps, and check the <a href="https://www.singtel.com/personal/products-services/lifestyle-services/ai-pass">current Singtel offer</a>. Eligibility for the wider subscription initiative is unchanged.</p></section>', content), updated_at = UTC_TIMESTAMP() WHERE @is_sg = 1 AND url_key IN ('how-to-claim-free-ai-subscription-singapore-eligibility-steps-courses', 'free-ai-subscription-now-live-swda-eligible-courses') AND content NOT LIKE '%id="singtel-canva-update-20261106"%';

INSERT INTO mmd_blog_post (title, url_key, excerpt, content, author, status, published_at, related_skus, source_sku, hero_image_url, meta_title, meta_description, meta_keywords, linkedin_urn, linkedin_org_urn, facebook_post_id, created_at, updated_at) SELECT 'Singtel AI Pass Now Includes Canva Pro: Seven AI Tools to Try', 'singtel-ai-pass-canva-pro-seven-ai-tools-singapore', 'Singtel AI Pass now includes Canva Pro. Explore seven AI tools, the three-plus-three-month offer, eligibility and redemption after an eligible AI course.', '<p><strong>Canva Pro now joins Singtel AI Pass</strong>, giving eligible learners seven premium AI tools to explore after their AI course. The expanded suite spans design, research, video, meetings, automation and audio, with around <strong>S$600 in stated tool value</strong> on Singtel''s current overview.</p>
<p>For someone learning to create content or improve everyday work, the appeal is practical: try different tools on a real project before deciding which deserves a place in your routine. Start with an <a href="https://www.tertiarycourses.com.sg/free-ai-subscription-courses.html">eligible AI course</a>, then use the subscription to keep practising.</p>
<h2>What is Singtel AI Pass?</h2>
<p>Singtel AI Pass is one of the subscription choices under the SkillsFuture AI Subscription initiative. It provides access to the seven participating tools for <strong>three months</strong>, followed by <strong>one chosen tool for another three months</strong>. The whole bundle does not continue for six months. Participating tools and allowances can change; check <a href="https://www.singtel.com/personal/products-services/lifestyle-services/ai-pass">Singtel''s current offer</a> before redeeming.</p>
<h2>Seven tools, including Canva Pro</h2>
<table><thead><tr><th>Tool</th><th>Included plan</th><th>Where to try it</th></tr></thead><tbody>
<tr><td>Canva</td><td>Canva Pro</td><td>AI-assisted designs, presentations and video</td></tr>
<tr><td>Manus</td><td>Manus Pro Standard Monthly Usage</td><td>Research and multi-step project work</td></tr>
<tr><td>Hailuo AI</td><td>Hailuo AI Standard</td><td>Video from text or images</td></tr>
<tr><td>Otter.ai</td><td>Otter Pro</td><td>Meeting notes and summaries</td></tr>
<tr><td>MiniMax Code</td><td>MiniMax Code Plus</td><td>Task automation and agent work</td></tr>
<tr><td>MiniMax Audio</td><td>MiniMax Audio Creator</td><td>Voice and music generation</td></tr>
<tr><td>Akool</td><td>Akool Pro</td><td>AI video and image content</td></tr>
</tbody></table>
<p>The plan names come from <a href="https://www.singtel.com/personal/products-services/lifestyle-services/ai-pass/faqs">Singtel''s AI Pass FAQ</a>. Each has usage limits; check the relevant account dashboard.</p>
<h2>Why Canva AI is a useful addition</h2>
<p>Canva puts the design stage alongside the writing, video and audio tools already in the bundle. That makes it easier to turn a practice exercise into something you can review and use: a presentation, a social post or a short explainer.</p>
<p>For example, build a small campaign for a fictional business. Draft a brief, prepare three visual ideas in Canva, and compare how clearly each communicates the same message. If video is relevant, experiment with a short clip and a voice track. Keep the exercise small enough to finish, then ask a colleague which version makes the offer easiest to understand.</p>
<p>This is a suggested practice workflow. Choose tools according to the task, check generated facts and assets, and use material you have permission to upload.</p>
<h2>Who can redeem the subscription?</h2>
<p>Under the <a href="https://www.myskillsfuture.gov.sg/content/portal/en/career-resources/career-resources/education-career-personal-development/redeem-ai-subscription.html">official MySkillsFuture rules</a>, you must be a <strong>Singapore Citizen aged 18 or above</strong> who attends an eligible AI course ending on or after <strong>16 September 2026</strong>. Look for the <em>Free AI sub</em> label on MySkillsFuture. Each eligible person can redeem only one subscription, regardless of the number of courses attended.</p>
<p>Submit your preferred subscription through the official request form within <strong>60 days of the notification email</strong>. The selection is final. Course fees and course-funding eligibility are separate from the complimentary subscription.</p>
<h2>How to redeem Singtel AI Pass and Canva</h2>
<ol>
<li>After your eligible course, select Singtel AI Pass through the official subscription request process.</li>
<li>Use the emailed voucher on CAST.SG, signing in or creating an account.</li>
<li>Follow the separate activation email for each tool. Singtel says this arrives within 48 hours of successful redemption.</li>
<li>For Canva, visit <a href="https://www.canva.com/redeem">Canva''s redemption page</a>, sign in to a free account or create one, then enter the supplied code.</li>
<li>Watch for the extension email after two months and follow it to select one tool for another three months.</li>
</ol>
<p>Use the same email for the pass and tools. Check the dates in your emails. For existing paid Canva accounts, consult Singtel before redeeming.</p>
<h2>Choose a course around the work you want to do</h2>
<p>A useful course gives you a method for using the tools, reviewing the result and improving it. Compare these Tertiary Courses programmes:</p>
<ul>
<li><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-content-creation.html">WSQ - Generative AI for Content Creation</a>: explore content planning and AI-assisted production.</li>
<li><a href="https://www.tertiarycourses.com.sg/multi-ai-agents-workflow-for-content-creation.html">WSQ - Multi AI Agents Workflow for Content Creation</a>: explore coordinated content workflows.</li>
<li><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-automation-with-n8n.html">WSQ - Agentic AI Automation with n8n</a>: explore automation for repeatable tasks.</li>
</ul>
<p>Check the exact course run''s current MySkillsFuture label, prerequisites and fees before enrolling. <a href="https://www.tertiarycourses.com.sg/free-ai-subscription-courses.html">Browse our free AI subscription courses</a>, or <a href="https://www.tertiarycourses.com.sg/contacts">contact our team</a> for help choosing. Our <a href="https://www.tertiarycourses.com.sg/blog/how-to-claim-free-ai-subscription-singapore-eligibility-steps-courses">step-by-step claim guide</a> explains the wider subscription process.</p>
<h2>Frequently asked questions</h2>
<h3>Is Canva included?</h3>
<p>Yes. Singtel''s current FAQ lists Canva Pro in the seven-tool suite.</p>
<h3>Do all seven tools last six months?</h3>
<p>No. The initial suite lasts three months; the extension covers one selected tool for three more.</p>
<h3>Which tool should I extend?</h3>
<p>Keep a short practice log. Record what you completed, the time spent reviewing outputs and whether you would repeat the task. Choose the tool that proved useful in your own work.</p>
<p><em>Offer information checked 6 November 2026. Sources: <a href="https://www.singtel.com/personal/products-services/lifestyle-services/ai-pass">Singtel AI Pass overview</a>, <a href="https://www.singtel.com/personal/products-services/lifestyle-services/ai-pass/faqs">Singtel AI Pass FAQ</a> and <a href="https://www.myskillsfuture.gov.sg/content/portal/en/career-resources/career-resources/education-career-personal-development/redeem-ai-subscription.html">MySkillsFuture eligibility and redemption guidance</a>.</em></p>', 'Tertiary Infotech Academy', '1', '2026-11-06', 'TGS-2023037589,TGS-2023036153,TGS-2023035977', 'TGS-2023037589', 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20261106-091305-singtel-ai-pass-now-with-canva-pro.png', 'Singtel AI Pass with Canva Pro: 7 AI Tools in Singapore', 'Explore Singtel AI Pass with Canva Pro: seven AI tools, eligibility, redemption steps and eligible AI courses in Singapore.', 'Singtel AI Pass,Canva Pro,Canva AI,free AI subscription Singapore,SkillsFuture AI', 'manual-skip', 'manual-skip', 'manual-skip', UTC_TIMESTAMP(), UTC_TIMESTAMP() WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM mmd_blog_post WHERE url_key = 'singtel-ai-pass-canva-pro-seven-ai-tools-singapore');

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id) SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name IN ('Canva', 'Generative AI', 'SkillsFuture') WHERE @is_sg = 1 AND p.url_key = 'singtel-ai-pass-canva-pro-seven-ai-tools-singapore';
