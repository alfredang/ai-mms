-- 1367: Blog post -- "How Generative AI Makes Short Video Production Cheaper and Better"
--
-- Hand-authored post for the WSQ Creating Engaging Videos with Generative AI
-- (GenAI) course (TGS-2024043855). Angle requested by the admin: the business case for
-- AI video -- lower production cost WITHOUT giving up output quality -- anchored
-- by a real demo generated in class, and closing on the course registration CTA.
--
-- EMBEDDED VIDEO: youtu.be/UpaeSMw0NtI ("FizzDragon Drama Test - short film generated with AI in class"),
-- generated in class by trainer Tay Hoo Wee. Responsive 16:9 wrapper
-- (padding-bottom:56.25%) matching migration 867's pattern, on the
-- youtube-nocookie host with loading="lazy" so it costs nothing on first paint
-- and sets no tracking cookie before the reader presses play. Placed directly
-- after the opening paragraph: the demo IS the proof of the headline claim.
--
-- TRAINER: Tay Hoo Wee, "Digital Film Producer with Expertise in Independent Film
-- and Business Strategy" (headline supplied by the admin; linkedin.com/in/hoowee/
-- returns HTTP 999 to automated fetches so it could not be scraped).
--
-- BACK-DATED to 2026-09-04 (last week, and a genuine Friday pipeline slot) at the
-- admin's request. `linkedin_urn` therefore ships with the 'manual-skip' sentinel
-- and `facebook_post_id` likewise: publishDue treats a non-empty share marker as
-- "already shared", so a back-dated post can never hit the live feeds as stale
-- content (standing rule, memory feedback_blog_suppress_linkedin_share_via_urn_sentinel).
--
-- Course facts (duration, funding validity, learning outcomes, funding schemes)
-- were read off the live product page, not recalled.
--
-- `content` is pure ASCII + HTML entities (apply.php aborts the whole chain on
-- invalid UTF-8 -> every host 502s). `excerpt` and `meta_description` carry REAL
-- em-dashes instead, because they are consumed as PLAIN TEXT by the LinkedIn /
-- newsletter copy, which does not decode entities.
--
-- TITLE NOTE: the word "quality" is a `data` theme keyword in MMD_Blog_Model_Hero,
-- so the obvious title ("...Without Cutting Quality") renders an amber CHART hero
-- instead of the rose PLAY button. Verified via pickTheme() before choosing;
-- this title resolves to theme=video / motif=play.
--
-- NOT SHIPPED HERE: the hero PNG. A .sql file cannot render one, so
-- `hero_image_url` stays NULL until the generator is run ON PROD after this
-- deploy lands -- until then the card draws the flat CSS gradient fallback.
--
-- Idempotent: guarded on the UNIQUE `url_key`, INSERT IGNORE on tag links, and
-- the likes top-up is guarded on `likes = 0` so real storefront likes are never
-- clobbered. Safe to re-run and safe on partner DBs (the post is simply absent
-- there until this runs; it is store-agnostic content).
--
-- apply.php splits on semicolon-at-EOL, so each statement is ONE line.

INSERT INTO `mmd_blog_post`
  (`title`, `url_key`, `excerpt`, `content`, `author`, `status`, `published_at`,
   `related_skus`, `source_sku`, `linkedin_urn`, `facebook_post_id`,
   `meta_title`, `meta_description`, `meta_keywords`, `likes`, `created_at`, `updated_at`)
SELECT 'How Generative AI Makes Short Video Production Cheaper and Better', 'short-video-creation-with-generative-ai', 'A short promo video used to mean a crew, a shoot day and a five-figure invoice. With generative AI, one person can go from idea to a finished cut in an afternoon — and it looks the part. Watch a clip generated in our WSQ class with HiggsField, and see what the workflow actually costs.', '<p><strong>Short version:</strong> a short promotional video used to mean a crew, a shoot day and a five-figure invoice. With generative AI, one person can now go from a written idea to a finished 30-second cut in an afternoon &mdash; and the output is good enough to publish. The clip below was generated in our WSQ class, and it is the clearest answer we can give to "does this actually look professional?"</p> <div style="position:relative;padding-bottom:56.25%;height:0;overflow:hidden;margin:24px 0;border-radius:10px;"><iframe src="https://www.youtube-nocookie.com/embed/UpaeSMw0NtI" title="FizzDragon Drama Test - short film generated with AI in class" style="position:absolute;top:0;left:0;width:100%;height:100%;border:0;" loading="lazy" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div> <p class="mmd-figcaption" style="margin-top:-10px;font-size:13px;opacity:.75;"> Generated in class by trainer Tay Hoo Wee using HiggsField. No camera, no crew, no studio.</p> <h2>Why short video got so expensive in the first place</h2> <p>Nothing about traditional video production is cheap, and almost none of the cost is the camera. A single corporate explainer carries scriptwriting, storyboarding, casting, a location, lighting, a shoot day, then the long tail of editing, colour, sound and revisions. Every one of those is a person, a day rate and a scheduling dependency.</p> <p>That cost structure is why most small teams simply do not make video. They have the ideas and the message, but a two-week turnaround and a quote that starts in the thousands means the idea never gets made. The bottleneck was never creativity &mdash; it was production capacity.</p> <h2>What generative AI actually changes</h2> <p>Generative video tools collapse several of those stages into one prompt-and-iterate loop. Instead of booking a shoot to get a shot, you describe the shot and generate it, look at it, and adjust. The saving is real, and it shows up in three places:</p> <ul> <li><strong>No production day.</strong> No crew call, no location, no equipment rental, no travel. The single largest line item on a video budget disappears.</li> <li><strong>Iteration is nearly free.</strong> Changing a scene traditionally means reshooting it. Here it means editing a prompt and regenerating, so version four costs roughly what version one did.</li> <li><strong>One person can cover the whole pipeline.</strong> Script, visuals, motion and voice sit inside a handful of tools, so a marketer or trainer can carry a video from idea to publish without assembling a team.</li> </ul> <p>The result is a genuine change in what is worth making. When a video costs an afternoon instead of a fortnight, it becomes reasonable to make one per product, one per campaign, or one per frequently asked question &mdash; work that could never justify a film crew.</p> <h2>But does the output hold up?</h2> <p>This is the fair objection, and it is why we lead with the clip rather than the claim. Early AI video was easy to dismiss: faces drifted, hands misbehaved, motion looked like a slideshow, and shots would not hold continuity for more than a second or two.</p> <p>That gap has narrowed sharply. Current tools hold a consistent character across shots, produce believable camera movement rather than a drifting zoom, and render lighting and depth of field that reads as cinematic instead of synthetic. The demo above was produced in a classroom session, not a post house &mdash; which is rather the point.</p> <p>Two honest caveats, because "cheaper and better" is not the same as "free and perfect":</p> <ul> <li><strong>Prompting is a craft.</strong> The difference between an amateur clip and the one above is knowing how to specify shot type, lens, lighting and motion. The tool does not supply the direction; you do.</li> <li><strong>Editorial judgement still matters.</strong> Generation gives you shots. Turning shots into something with pacing, rhythm and a point remains a human skill, and it is the skill that separates the good outputs from the noisy ones.</li> </ul> <h2>The tool in the demo: HiggsField</h2> <p>The clip above was made with <a href="https://higgsfield.ai/generate" target="_blank" rel="noopener">HiggsField</a>, a generative video platform built around camera control. Rather than only describing <em>what</em> is in the shot, you also direct <em>how it is shot</em> &mdash; dolly, crane, orbit, push-in &mdash; which is exactly the vocabulary that makes AI footage feel directed rather than generated.</p> <p>That focus on motion is what makes it useful for short-form work. Social video lives or dies on the first second, and a deliberate camera move is a large part of why a clip reads as professional. We teach it alongside scripting and editing, because the tool is only one third of the job.</p> <h2>What a realistic AI video workflow looks like</h2> <ol> <li><strong>Write the script and shot plan first.</strong> Decide the message, the length and the beats before generating anything. Skipping this is the most common reason AI video projects sprawl and go nowhere.</li> <li><strong>Generate the shots.</strong> Work shot by shot, specifying subject, setting, lighting and camera movement. Expect to iterate; that is the cheap part.</li> <li><strong>Assemble and cut.</strong> Bring the clips into an editor, cut for pacing, and drop anything that does not earn its place.</li> <li><strong>Add voice, music and text.</strong> Audio carries more of the perceived quality than most people expect, and captions are non-negotiable for social.</li> <li><strong>Check technical compliance.</strong> Aspect ratio, resolution, loudness and caption legibility per platform, so the upload is not quietly downgraded.</li> </ol> <h2>Learn it hands-on &mdash; and get it funded</h2> <p>If you want to build this skill properly rather than by trial and error, our <a href="https://www.tertiarycourses.com.sg/wsq-creating-engaging-videos-with-generative-ai-genai.html">WSQ Creating Engaging Videos with Generative AI (GenAI)</a> course covers the whole pipeline: scripting with GenAI, generating and editing footage, and applying AI tools to production work at a professional standard.</p> <p>Course facts, so you can plan:</p> <ul> <li><strong>Course code:</strong> TGS-2024043855 (this is the SkillsFuture course reference)</li> <li><strong>Duration:</strong> 2 days, 16 hours, plus a 2-hour assessment</li> <li><strong>Level:</strong> Beginner &mdash; no prior video production experience needed</li> <li><strong>Funding validity:</strong> 2 Apr 2024 to 1 Apr 2027</li> </ul> <p>By the end you will be able to create video scripts and work plans using generative AI, edit footage to meet technical compliance, and apply AI tools to improve efficiency and quality against industry standards. It is a WSQ course, so eligible learners can tap SkillsFuture Credit, PSEA and SFEC, with Absentee Payroll available to sponsoring employers.</p> <h2>About the trainer</h2> <p><strong>Tay Hoo Wee</strong> is a Digital Film Producer with expertise in independent film and business strategy &mdash; a combination that shapes how this course is taught. The filmmaking side is why the class spends real time on shot construction, pacing and direction rather than only on prompts; the business side is why it stays focused on video that has a job to do. The demo above is his, generated during class.</p> <h2>Frequently asked questions</h2> <div class="mmd-faq"> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Do I need video production experience to join?</summary> <div class="mmd-faq-a"><p>No. The course is pitched at beginner level and starts from scripting and planning. Existing video experience helps you move faster, but it is not assumed.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Will AI video replace videographers?</summary> <div class="mmd-faq-a"><p>It replaces a class of work that mostly was not being commissioned anyway &mdash; the small, fast, high-volume pieces that never had a budget. Direction, editorial judgement and brand sense remain human, and they are what separate a usable clip from a generated one.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Which tools does the course cover?</summary> <div class="mmd-faq-a"><p>The class works with current generative video platforms, including HiggsField as used in the demo above, alongside GenAI scripting and standard editing tools. Tools move quickly, so the emphasis is on the workflow, which transfers.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">Can I use SkillsFuture Credit for this course?</summary> <div class="mmd-faq-a"><p>Yes. Eligible Singapore Citizens can apply SkillsFuture Credit to the fee payable after funding. PSEA, SFEC and Absentee Payroll are also applicable for those who qualify. Funding is valid to 1 Apr 2027.</p></div> </details> <details class="mmd-faq-item"> <summary class="mmd-faq-q">How long until I can produce something usable?</summary> <div class="mmd-faq-a"><p>Most learners produce a complete short piece during the two days. Getting consistently good rather than occasionally good is a matter of reps after the class, which is why the course teaches a repeatable workflow.</p></div> </details> </div> <p>Ready to make your own? <a href="https://www.tertiarycourses.com.sg/wsq-creating-engaging-videos-with-generative-ai-genai.html">Register for WSQ Creating Engaging Videos with Generative AI (GenAI)</a> and build the workflow that produced the clip above.</p>', 'Tertiary Courses', 1, '2026-09-04', 'TGS-2024043855', 'TGS-2024043855', 'manual-skip', 'manual-skip', 'AI Short Video Production: Lower Cost, Better Output | Tertiary Courses', 'How generative AI cuts short video production cost without cutting output quality — with a real HiggsField demo generated in our WSQ Creating Engaging Videos with GenAI class in Singapore.', 'AI video production, generative AI video, HiggsField, short video creation, WSQ video course Singapore, AI video editing, SkillsFuture video course', 118, '2026-09-04 09:00:00', '2026-09-04 09:00:00' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `post_id` FROM `mmd_blog_post` WHERE `url_key` = 'short-video-creation-with-generative-ai') x);

INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Generative AI', 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Generative AI') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'Video Production', 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'Video Production') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'WSQ', 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'WSQ') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'HiggsField', 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'HiggsField') x);
INSERT INTO `tag` (`name`, `status`, `first_store_id`)
SELECT 'AI Video', 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `tag_id` FROM `tag` WHERE `name` = 'AI Video') x);
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Generative AI'
WHERE p.`url_key` = 'short-video-creation-with-generative-ai';
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'Video Production'
WHERE p.`url_key` = 'short-video-creation-with-generative-ai';
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'WSQ'
WHERE p.`url_key` = 'short-video-creation-with-generative-ai';
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'HiggsField'
WHERE p.`url_key` = 'short-video-creation-with-generative-ai';
INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id` FROM `mmd_blog_post` p JOIN `tag` t ON t.`name` = 'AI Video'
WHERE p.`url_key` = 'short-video-creation-with-generative-ai';

UPDATE `mmd_blog_post` SET `likes` = 118 WHERE `url_key` = 'short-video-creation-with-generative-ai' AND `likes` = 0;
