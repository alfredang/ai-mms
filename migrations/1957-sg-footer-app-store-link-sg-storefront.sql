-- 1957-sg-footer-app-store-link-sg-storefront.sql
-- SG footer "Contact Us Information" (cms_block block_footer_column5): the App Store badge
-- linked to https://apps.apple.com/app/tertiary-courses/id6787036413, which has no
-- country code, so Apple opens the US store, where TC LMS SG is not listed (404). Point
-- it at the Singapore store listing, and name the app (TC LMS SG) in both badge titles.
-- Data-only, idempotent, SG-only (@mms_instance and the SG app id).

UPDATE cms_block
SET content = REPLACE(REPLACE(REPLACE(content,
      'https://apps.apple.com/app/tertiary-courses/id6787036413',
      'https://apps.apple.com/sg/app/tc-lms-sg-tertiary-courses/id6787036413'),
      'title="Download Tertiary Courses on the App Store"',
      'title="Download TC LMS SG on the App Store"'),
      'title="Get Tertiary Courses on Google Play"',
      'title="Get TC LMS SG on Google Play"')
WHERE identifier = 'block_footer_column5'
  AND @mms_instance = 'SG'
  AND content LIKE '%apps.apple.com/app/tertiary-courses/id6787036413%';
