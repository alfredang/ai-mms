-- 1067: Seed the "Complimentary Exam Voucher" card for WSQ DevOps Foundation
-- Training (TGS-2024049184) — a new per-course cms/block section
-- `course_<sku>_exam_voucher`, rendered by the Complimentary Exam Voucher card
-- right after the About IBF Certification card on the product page.
--
-- The card is block-driven and block-gated: a course with no (or an empty)
-- `exam_voucher` block renders nothing, so this migration only lights it up on
-- the one SKU below. Editable afterwards in Course Edit → Course Details.
--
-- Idempotent: cms_block has NO unique index on `identifier`, so
-- INSERT ... ON DUPLICATE KEY UPDATE would silently insert a second row on
-- every re-apply. Guarded INSERT (NOT EXISTS) + unconditional UPDATE instead —
-- converges to exactly one row and also heals a pre-existing row.
--
-- Partner-safe: the INSERT is keyed on the SKU's identifier only and the block
-- is store-0 (all stores), matching every other per-course section block. On a
-- partner DB without this SKU the block is still created but never rendered,
-- since no product resolves `course_TGS-2024049184_exam_voucher`.
--
-- Literals are hex-encoded for apply.php's utf8 connection (the title carries a
-- U+2014 em dash).

-- title:   Course TGS-2024049184 — Complimentary Exam Voucher
-- ident:   course_TGS-2024049184_exam_voucher
-- content: <p>A complimentary exam voucher will be issued to you after the class.</p>

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
  SELECT 0x436f75727365205447532d3230323430343931383420e2809420436f6d706c696d656e74617279204578616d20566f7563686572,
         0x636f757273655f5447532d323032343034393138345f6578616d5f766f7563686572,
         0x3c703e4120636f6d706c696d656e74617279206578616d20766f75636865722077696c6c2062652069737375656420746f20796f752061667465722074686520636c6173732e3c2f703e,
         NOW(), NOW(), 1
    FROM DUAL
   WHERE NOT EXISTS (
       SELECT 1 FROM (
           SELECT block_id FROM cms_block
            WHERE identifier = 0x636f757273655f5447532d323032343034393138345f6578616d5f766f7563686572
       ) x
   );

-- Heal / converge an existing row (e.g. a partially-applied earlier run).
UPDATE cms_block
   SET title       = 0x436f75727365205447532d3230323430343931383420e2809420436f6d706c696d656e74617279204578616d20566f7563686572,
       content     = 0x3c703e4120636f6d706c696d656e74617279206578616d20766f75636865722077696c6c2062652069737375656420746f20796f752061667465722074686520636c6173732e3c2f703e,
       is_active   = 1,
       update_time = NOW()
 WHERE identifier = 0x636f757273655f5447532d323032343034393138345f6578616d5f766f7563686572;

-- Store scope: all stores (store_id 0). cms_block_store DOES have a composite
-- PRIMARY KEY (block_id, store_id), so INSERT IGNORE is genuinely safe here.
INSERT IGNORE INTO cms_block_store (block_id, store_id)
  SELECT block_id, 0 FROM cms_block
   WHERE identifier = 0x636f757273655f5447532d323032343034393138345f6578616d5f766f7563686572;
