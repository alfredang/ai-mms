-- Credit the trainer and record the workshop date in the Singapore recap.
SET @intro_before := 'tackled that question in our <strong>Agentic AI for Finance</strong> workshop.';
SET @intro_after := 'tackled that question in our <strong>Agentic AI for Finance</strong> workshop, led by <strong>Dr. Alfred Ang</strong> on <time datetime="2026-11-24">24 November 2026</time>.';

UPDATE `mmd_blog_post`
SET `content` = REPLACE(`content`, @intro_before, @intro_after),
    `updated_at` = UTC_TIMESTAMP()
WHERE @mms_instance = 'SG'
  AND `url_key` = 'agentic-ai-finance-iia-ghana'
  AND LOCATE(BINARY @intro_before, `content`) > 0;
