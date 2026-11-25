-- Publish the IIA Ghana workshop recap on the Singapore storefront.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
SET @slug := 'agentic-ai-finance-iia-ghana';

INSERT INTO `mmd_blog_post` (
    `title`, `url_key`, `excerpt`, `content`, `hero_image_url`, `author`,
    `status`, `published_at`, `related_skus`, `linkedin_urn`, `facebook_post_id`,
    `meta_title`, `meta_description`, `meta_keywords`, `likes`, `created_at`, `updated_at`
)
SELECT
    'Agentic AI for Finance with IIA Ghana',
    @slug,
    'Nine IIA Ghana participants used Microsoft 365 Copilot to build an Excel audit dashboard, a PowerPoint briefing and a Word report. Workshop rating: 4.7/5.',
    '<p>How do you turn a spreadsheet full of transactions into an audit finding that management can act on? Nine participants from the <strong>Institute of Internal Auditors Ghana (IIA Ghana)</strong> tackled that question in our <strong>Agentic AI for Finance</strong> workshop. The training was tailored to the Ghanaian finance and internal audit context, with Microsoft 365 Copilot supporting three connected tasks in Excel, PowerPoint and Word.</p>

<p style="padding:16px 20px;border-left:4px solid #4338a0;background:#f4f2ff;color:#221957;border-radius:6px;"><strong>4.7 out of 5 overall</strong> from nine workshop feedback responses. Participants rated the trainer&rsquo;s subject knowledge <strong>4.9 out of 5</strong>.</p>

<figure style="max-width:480px;margin:24px auto;text-align:center;">
<img src="https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/20261125-033617-iia-ghana-agentic-ai-finance-workshop.jpeg" width="900" height="1600" loading="lazy" decoding="async" alt="Participants from IIA Ghana and their trainer in the Agentic AI for Finance workshop classroom" style="display:block;width:100%;height:auto;border-radius:10px;">
<figcaption style="margin-top:8px;">Participants and trainer at the Agentic AI for Finance workshop.</figcaption>
</figure>

<h2>Build an interactive audit dashboard in Excel</h2>
<p>The group used Copilot in Excel to build an interactive dashboard for reviewing financial data. In a Ghanaian audit scenario, a dashboard can show the number and value of flagged transactions in Ghanaian cedis (GHS), with filters for reporting period or department. An auditor can use those filters to see where exceptions cluster and trace a flagged item back to the source rows before drawing a conclusion.</p>

<h2>Turn the dashboard into a PowerPoint briefing</h2>
<p>Participants used Copilot in PowerPoint to turn the analysis into a presentation for management. A clear briefing starts with the finding, shows the chart that supports it and ends with the decision or follow-up needed. For example, a concentration of payment exceptions can prompt a targeted review of supporting records and approval controls.</p>

<h2>Draft a Word report backed by evidence</h2>
<p>The workshop also covered using Copilot in Word to draft an audit report. A report can carry forward the same evidence from the dashboard and briefing, then document the scope, findings, implications and recommended actions. Review the figures, references and conclusions against the source material before the report is circulated.</p>

<h2>How the three outputs fit together</h2>
<p>The Excel dashboard helps the auditor decide which exceptions to investigate. The PowerPoint briefing helps management understand the finding and decide how to respond. The Word report records the evidence and the actions for follow-up. Copilot helps prepare each output, while the auditor checks the evidence and signs off on the conclusions.</p>

<h2>What participants said</h2>
<blockquote><p>&ldquo;Excellent delivery&rdquo;</p></blockquote>
<blockquote><p>&ldquo;We have learnt a lot&rdquo;</p></blockquote>
<p>Participants scored how well the workshop met its learning objectives <strong>4.7 out of 5</strong> and the training environment <strong>4.6 out of 5</strong>. One respondent described the training time as short.</p>

<h2>Learn the Microsoft 365 Copilot workflow in Singapore</h2>
<p>Our related Singapore course, <strong>WSQ &ndash; Enhance Work Productivity with Microsoft 365 Copilot (TGS-2024043856)</strong>, teaches a connected workflow across Excel, Word, PowerPoint and Outlook. It includes building an interactive dashboard, preparing a management presentation and exploring Microsoft 365 Agent Builder.</p>
<p><a href="https://www.tertiarycourses.com.sg/wsq-enhance-work-productivity-with-microsoft-365-copilot.html" style="display:inline-block;padding:12px 18px;border-radius:6px;background:#382881;color:#fff;font-weight:700;text-decoration:none;">View the WSQ Microsoft 365 Copilot course &rarr;</a></p>',
    'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20261125-033616-agentic-ai-for-finance-with-iia-ghana.png',
    'Tertiary Infotech Academy',
    1,
    UTC_TIMESTAMP(),
    'TGS-2024043856',
    'manual-skip',
    'manual-skip',
    'Agentic AI for Finance and Auditing with IIA Ghana',
    'See how nine IIA Ghana participants used Copilot for an interactive Excel audit dashboard, a PowerPoint briefing and a Word report. Rated 4.7/5.',
    'agentic AI for finance, IIA Ghana, Microsoft 365 Copilot, Excel audit dashboard, internal audit',
    100 + MOD(CRC32(@slug), 101),
    UTC_TIMESTAMP(),
    UTC_TIMESTAMP()
WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM `mmd_blog_post` WHERE `url_key` = @slug);

INSERT INTO `tag` (`name`, `status`)
SELECT labels.`name`, 1
FROM (
    SELECT 'Agentic AI' AS `name`
    UNION ALL SELECT 'Microsoft 365 Copilot'
    UNION ALL SELECT 'Internal Audit'
    UNION ALL SELECT 'Finance'
) labels
WHERE @is_sg = 1
  AND NOT EXISTS (SELECT 1 FROM `tag` t WHERE t.`name` = labels.`name`);

INSERT IGNORE INTO `mmd_blog_post_tag` (`post_id`, `tag_id`)
SELECT p.`post_id`, t.`tag_id`
FROM `mmd_blog_post` p
JOIN `tag` t ON t.`name` IN ('Agentic AI', 'Microsoft 365 Copilot', 'Internal Audit', 'Finance')
WHERE @is_sg = 1 AND p.`url_key` = @slug;
