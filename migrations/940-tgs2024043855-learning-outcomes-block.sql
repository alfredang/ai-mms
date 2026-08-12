-- 940: Restore the Learning Outcomes card on TGS-2024043855
--      (WSQ - Creating Engaging Videos with Generative AI (GenAI)).
--
-- Root cause: the per-course cms/block was created with a stray TAB inside
-- the SKU, so its identifier is `course_TGS-2024043855<TAB>_learning_outcomes`
-- while the product view looks up `course_TGS-2024043855_learning_outcomes`
-- (built from the clean 14-char SKU). The lookup misses, $_learningOutcomesHtml
-- stays empty, and the whole card is suppressed by the `!== ''` guard in
-- app/design/frontend/ultimo/default/template/catalog/product/view.phtml.
-- The short_description carries no <h2>Learning Outcomes</h2> heading either,
-- so the regex fallback finds nothing to render.
--
-- Fix: write the block under the CLEAN identifier with the current LO text
-- (LO1-LO3 supplied by the course owner, superseding the stale wording in the
-- tab-named block), then deactivate the tab-named orphan so it can never be
-- picked up or re-edited by mistake. The same tab taint also affects that
-- course's _brochure block, but a correctly-named `course_TGS-2024043855_brochure`
-- already exists (block 2610) so the brochure card renders - only the orphan is
-- retired here.
--
-- Idempotent: ON DUPLICATE KEY UPDATE on the unique `identifier`, and the
-- deactivate is a no-op once applied. SG-only content, but safe on partner
-- servers: TGS- SKUs do not exist there, so the INSERT simply adds an unused
-- block and the UPDATE matches nothing.

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
VALUES (
    'Course TGS-2024043855 - Learning Outcomes',
    'course_TGS-2024043855_learning_outcomes',
    '<p>By end of the course, learners should be able to:</p>\n<ul>\n<li>LO1: Create video scripts using Generative AI (GAI) and work plans for video production.</li>\n<li>LO2: Edit video footage to improve video quality and ensure technical compliance.</li>\n<li>LO3: Apply new AI technologies to improve efficiency and quality in accordance to industry standards</li>\n</ul>',
    NOW(), NOW(), 1
)
ON DUPLICATE KEY UPDATE
    content     = VALUES(content),
    title       = VALUES(title),
    is_active   = 1,
    update_time = NOW();

-- Map to store 0 (all stores) - matches every other course_* section block.
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
WHERE identifier = 'course_TGS-2024043855_learning_outcomes';

-- Retire the tab-named orphan so the stale copy can never resurface.
UPDATE cms_block
   SET is_active = 0, update_time = NOW()
 WHERE identifier = CONCAT('course_TGS-2024043855', CHAR(9), '_learning_outcomes');
