-- 224: Remove the legacy "Certification Exam at Pearson Vue" voucher section from
--      per-course certification blocks (course_<sku>_certification). It rendered
--      inside the Certification card on Cert Prep course pages; it is replaced by
--      a dedicated "Free Certificate Practice Exams" card (product/view.phtml,
--      scoped to the Cert Prep category). The section is always the trailing part
--      of the block, so SUBSTRING_INDEX(...,1) keeps everything before it.
--      Idempotent (WHERE-guarded); the 2nd statement also clears the interim
--      "Free Certificate Prep Exams" text left by an earlier pass of this file.

UPDATE cms_block SET content = TRIM(SUBSTRING_INDEX(content, '<p><strong>Certification Exam at Pearson Vue</strong></p>', 1)) WHERE content LIKE '%<p><strong>Certification Exam at Pearson Vue</strong></p>%';
UPDATE cms_block SET content = TRIM(SUBSTRING_INDEX(content, '<p><strong>Free Certificate Prep Exams</strong></p>', 1)) WHERE content LIKE '%<p><strong>Free Certificate Prep Exams</strong></p>%';
