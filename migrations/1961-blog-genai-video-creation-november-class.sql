-- Publish the 25-26 November 2026 GenAI video class recap on the SG storefront.
-- Evaluation source: class 1367290. The embedded image is the supplied class photo.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
SET @slug := 'genai-video-creation-november-2026-class-recap';

INSERT INTO `mmd_blog_post` (
    `title`, `url_key`, `excerpt`, `content`, `hero_image_url`, `author`,
    `status`, `published_at`, `related_skus`, `linkedin_urn`, `facebook_post_id`,
    `meta_title`, `meta_description`, `meta_keywords`, `likes`, `created_at`, `updated_at`
)
SELECT
    'GenAI Video Creation in Practice',
    @slug,
    'Janrius Rogers led our 25-26 November WSQ GenAI video class. All 30 evaluation ratings were 4 or 5 out of 5. See how the free AI subscription works.',
    '<p>On <strong>25 and 26 November 2026</strong>, trainer <strong>Janrius Rogers</strong> led our two-day <strong>WSQ &ndash; Creating Engaging Videos with Generative AI (GenAI)</strong> class in Singapore. One participant singled out the way Janrius structured the class. The group tackled the key tasks early, leaving time to experiment with the tools and build confidence.</p>

<figure style="max-width:960px;margin:24px auto;text-align:center;">
<img src="https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/20261126-genai-video-creation-class-6a1d96caa118788f.jpg" width="1600" height="1226" loading="lazy" decoding="async" alt="Group photo from the November 2026 WSQ Generative AI video creation class in Singapore" style="display:block;width:100%;height:auto;border-radius:10px;">
<figcaption style="margin-top:8px;">The GenAI video creation class, 25&ndash;26 November 2026.</figcaption>
</figure>

<h2>What learners said about the two days</h2>
<p><strong>All 30 ratings were 4 or 5 out of 5.</strong> Ten learners answered three evaluation questions.</p>
<ul>
<li><strong>4.8/5</strong> for how well the course met its learning objectives</li>
<li><strong>4.9/5</strong> for the trainer&rsquo;s subject knowledge</li>
<li><strong>4.7/5</strong> for the training environment</li>
</ul>
<blockquote><p>&ldquo;Super impressed with the trainer! Janrius designed the course structure really well; he got us to focus on clearing the key deliverables of the class early, so that we could spend more time (not under pressure) exploring with the tools. This no-stakes exploration built my confidence in this new technical skill.&rdquo;</p></blockquote>
<p>&mdash; Course participant, <a href="https://www.tertiarycourses.com.sg/testimonials/">learner testimonials</a></p>

<h2>From a video idea to a finished clip</h2>
<p>The course teaches an end-to-end workflow with Higgsfield, from writing a script and planning shots to generating footage, improving the cut and preparing it for publication. Learners explore how camera angles, character consistency, sound and pacing affect the story. The same workflow can help you plan a product teaser, a micro-drama or a short film.</p>
<p>For a 15-second product teaser, you could open with the problem, cut to a close-up of the product in action and end with a call to action. A short draft gives you a chance to check whether the audience can follow the story before you spend time polishing it.</p>

<h2>Keep practising with a free six-month AI subscription</h2>
<p><strong>Eligible Singapore Citizens aged 18 and above</strong> can redeem <strong>one free six-month subscription</strong> to a participating AI tool after completing this course. Current options include ChatGPT Plus and Google AI Pro, which can help you keep practising tasks like refining a script or drafting a storyboard.</p>
<p>After the course, eligible learners receive redemption instructions by email and have 60 days from the notification to submit their request. The offer is limited to one subscription per person and applies to eligible courses ending on or after 16 September 2026. <a href="https://www.myskillsfuture.gov.sg/content/portal/en/career-resources/career-resources/education-career-personal-development/redeem-ai-subscription.html">See the official redemption steps and participating AI tools.</a></p>

<h2>Join the next WSQ GenAI video creation class</h2>
<p>Visit the course page for upcoming dates, software requirements and registration details. Eligible learners may receive up to 70% WSQ course fee funding, subject to the applicable funding conditions.</p>
<p><a href="https://www.tertiarycourses.com.sg/wsq-creating-engaging-videos-with-generative-ai-genai.html" style="display:inline-block;padding:12px 18px;border-radius:6px;background:#8b2d48;color:#fff;font-weight:700;text-decoration:none;">View course dates and register &rarr;</a></p>',
    'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20261126-genai-video-creation-40d386d8ea57cb49.png',
    'Tertiary Infotech Academy',
    1,
    UTC_TIMESTAMP(),
    'TGS-2024043855',
    'manual-skip',
    'manual-skip',
    'WSQ GenAI Video Creation with Janrius Rogers',
    'Read the 25-26 November WSQ GenAI video class recap, learner feedback, and how eligible Singapore Citizens can redeem a free six-month AI subscription.',
    'WSQ GenAI video creation, generative AI video, Janrius Rogers, Higgsfield, free AI subscription',
    100 + MOD(CRC32(@slug), 101),
    UTC_TIMESTAMP(),
    UTC_TIMESTAMP()
WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM `mmd_blog_post` WHERE `url_key` = @slug);

INSERT INTO `tag` (`name`, `status`)
SELECT labels.`name`, 1
FROM (
    SELECT 'Generative AI' AS `name`
    UNION ALL SELECT 'AI Video'
    UNION ALL SELECT 'HiggsField'
    UNION ALL SELECT 'WSQ'
) labels
WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM `tag` t WHERE t.`name` = labels.`name`);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id`
FROM `mmd_blog_post` p
JOIN `tag` t ON t.`name` IN ('Generative AI', 'AI Video', 'HiggsField', 'WSQ')
WHERE @is_sg = 1 AND p.`url_key` = @slug AND p.`related_skus` = 'TGS-2024043855';
