-- 237: Point the "Download SSG SOA" link at the foreigner download-cert page.
UPDATE cms_block SET content = REPLACE(content, 'content/portal/en/public/download-cert.html', 'content/portal/en/foreigner/download-cert.html') WHERE content LIKE '%content/portal/en/public/download-cert.html%';
