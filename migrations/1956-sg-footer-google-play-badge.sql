-- 1956-sg-footer-google-play-badge.sql
-- SG storefront footer, "Contact Us Information" column (cms_block block_footer_column5):
-- add a "Get it on Google Play" badge beside the App Store badge that migration 339 added,
-- linking to the live TC LMS SG Android app. Same size as the App Store badge (44px high),
-- inline SVG so nothing depends on the media volume.
-- Data-only, idempotent (no-op once the block links to Google Play), and SG-only twice over:
-- @mms_instance = 'SG' and the SG App Store id in the content.
-- After deploy, flush the CMS/full cache (Redis) for the change to show.

UPDATE cms_block
SET content = REPLACE(
      REPLACE(content,
        '<div class="app-store-badge" style="margin-top:14px;">',
        '<div class="app-store-badge" style="margin-top:14px;display:flex;flex-wrap:wrap;align-items:center;gap:10px;">'),
      '</svg></a></div>',
      CONCAT('</svg></a>',
        '<a href="https://play.google.com/store/apps/details?id=com.tertiaryinfotech.tertiarycoursesapp" target="_blank" rel="noopener" title="Get Tertiary Courses on Google Play" aria-label="Get it on Google Play">',
        '<svg xmlns="http://www.w3.org/2000/svg" width="135" height="40" viewBox="0 0 135 40" style="height:44px;width:auto;display:block;" aria-hidden="true">',
        '<rect x="0.5" y="0.5" width="134" height="39" rx="6" fill="#000" stroke="#a6a6a6"/>',
        '<svg x="9" y="8" width="24" height="24" viewBox="0 0 512 512">',
        '<path fill="#00D9FF" d="M47.6 24.6C41.2 31.3 37.5 41.7 37.5 55.2v401.6c0 13.5 3.7 23.9 10.1 30.6l1.3 1.3 225-225v-5.3l-225-225-1.3 1.2z"/>',
        '<path fill="#FFD400" d="M348.2 336.9l-75-75v-5.3l75.1-75.1 1.7 1 88.9 50.5c25.4 14.4 25.4 38 0 52.5l-88.9 50.5-1.8.9z"/>',
        '<path fill="#FF3A44" d="M349.9 335.9l-76.7-76.7L47.6 484.8c8.4 8.9 22.2 10 37.8 1.1l264.5-150z"/>',
        '<path fill="#00C244" d="M349.9 176.1L85.4 26.1C69.8 17.2 56 18.3 47.6 27.2l225.6 225.6 76.7-76.7z"/>',
        '</svg>',
        '<text x="41" y="15" fill="#fff" font-family="Arial,Helvetica,sans-serif" font-size="7.5" letter-spacing="0.4">GET IT ON</text>',
        '<text x="40.5" y="31" fill="#fff" font-family="Arial,Helvetica,sans-serif" font-size="15.5">Google Play</text>',
        '</svg></a></div>'))
WHERE identifier = 'block_footer_column5'
  AND @mms_instance = 'SG'
  AND content LIKE '%apps.apple.com/app/tertiary-courses/id6787036413%'
  AND content NOT LIKE '%play.google.com%';
