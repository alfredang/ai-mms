-- C437 Claude Certified Architect - Foundations (CCAR-F) Exam Prep: the prerequisite is now
-- C1417 Claude Code Masterclass (user, 2026-11-15); it was C991 (CCAO-F Exam Prep).
-- Only the Prerequisite card (cms/block course_C437_prerequisite) changes. SG-only (store guard).
-- Peer-safe: replaced only while the card still names C991, so a later edit is never reverted.
-- Applied live on SG on 2026-11-15; on deploy this is a no-op there.

SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

UPDATE cms_block
   SET content = CONCAT('<p>You should complete <a href="https://www.tertiarycourses.com.sg/claude-code-masterclass.html" title="Claude Code Masterclass">Claude Code Masterclass (C1417)</a> before taking this course.</p>\n',
                        '<p>C1417 gives you the hands-on Claude Code experience that this exam prep course builds on.</p>'),
       update_time = NOW()
 WHERE @ok
   AND identifier = 'course_C437_prerequisite'
   AND content LIKE '%(C991)</a>%';
