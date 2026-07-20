-- C789 "Funding and Grant" block pointed at the WSQ smart contract course via
-- an OLD url_key (wsq-smart-contract-programming-for-ethereum-blockchain) that
-- now 301s. Rewrite the link to the direct URL:
--   https://www.tertiarycourses.com.sg/wsq-develop-blockchain-and-web3-app-with-vibe-coding.html
--   (target validated 200 on SG prod, 2026-07-17)
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. No-op on sites without the block (partners hide the
-- funding card via CSS anyway). Idempotent. Invisible on prod until
-- block_html / full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-develop-blockchain-and-web3-app-with-vibe-coding.html" title="WSQ - Develop Blockchain and Web3 App with Vibe Coding">WSQ - Develop Blockchain and Web3 App with Vibe Coding</a></span></p>'
WHERE identifier = 'course_C789_funding_and_grant';
