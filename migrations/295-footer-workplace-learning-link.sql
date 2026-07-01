-- 295: Footer "Our Websites" (SG footer CMS block, block_id = 1):
--      add Tertiary Workplace Learning immediately after Tertiary LMS/TMS.
--      The label is kept on one line per requested footer presentation.

UPDATE cms_block
SET content = REPLACE(
    content,
    '<li><a target="_blank" href="https://lms-tms.tertiaryinfotech.com/">Tertiary LMS/TMS</a></li>',
    '<li><a target="_blank" href="https://lms-tms.tertiaryinfotech.com/">Tertiary LMS/TMS</a></li>
<li><a target="_blank" style="white-space:nowrap" href="https://workplacelearning.tertiaryinfotech.com/">Tertiary Workplace Learning</a></li>'
)
WHERE block_id = 1
  AND content LIKE '%https://lms-tms.tertiaryinfotech.com/%'
  AND content NOT LIKE '%https://workplacelearning.tertiaryinfotech.com/%';
