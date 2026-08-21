-- 1075: Seed the Learning Outcomes cms/block for TGS-2026064536
-- (CASL - Video Editing with Premiere Pro).
--
-- Purely ADDITIVE. Probed prod 2026-08-21: entity_id 1275 exists, NO
-- `course_TGS-2026064536_learning_outcomes` block, and short_description
-- carries NO inline Learning Outcomes section (LOCATE('Learning Outcome')
-- = 0, LOCATE('LO1') = 0 -- it is a two-paragraph narrative only). So
-- unlike migration 1073 there is nothing to strip: the "move the section
-- out of the narrative" half does not apply and adding it would be a
-- no-op REPLACE against bytes that were never there.
--
-- Storefront: view.phtml line ~349 reads the block FIRST
-- ($_courseSectionHtml('learning_outcomes')) and only falls back to regex
-- extraction from short_description when the block is empty. With no
-- inline section to extract, the Learning Outcomes card was rendering
-- nothing at all -- seeding the block is what makes it appear.
--
-- Block content is the section BODY only, no <h2> heading: the card
-- supplies its own. Shape + "LOn: " label convention copied from the
-- sibling CASL block course_TGS-2026064173_learning_outcomes.
--
-- Idempotent per [[feedback_cms_block_identifier_has_no_unique_key]]:
-- cms_block has ONLY PRIMARY KEY(block_id) -- there is NO unique index on
-- `identifier`, so ON DUPLICATE KEY UPDATE would never fire and each
-- re-apply would insert a DUPLICATE row. Hence guarded INSERT (NOT EXISTS,
-- via the derived-table wrapper MySQL requires when the subquery names the
-- INSERT target) + an unconditional UPDATE, which converges to exactly one
-- correct row no matter how many times it runs and also heals a row that
-- already exists with stale content.
--
-- Partner-safe: TGS- SKUs exist only on SG. @e is NULL on MY/GH, the
-- guarded INSERT is gated on @e IS NOT NULL so it inserts nothing, and the
-- UPDATE matches no row. cms_block_store gets store_id 0 (all stores),
-- matching every sibling course block.

SET @sku   := 'TGS-2026064536';
SET @e     := (SELECT entity_id FROM catalog_product_entity WHERE sku = @sku LIMIT 1);
SET @ident := CONCAT('course_', @sku, '_learning_outcomes');
SET @title := CONCAT('Course ', @sku, ' Learning Outcomes');

-- Body as UNHEX so the exact bytes are pinned and no client-charset or
-- quoting layer can mangle them in transit.
SET @lo_body := UNHEX('3C703E42792074686520656E64206F662074686520636F757273652C206C6561726E6572732077696C6C2062652061626C6520746F3C2F703E3C756C3E3C6C693E4C4F313A20416E616C797A6520616E6420617272616E67652074686520666F6F7461676520696E2061206C6F676963616C2073657175656E636520666F722065646974696E673C2F6C693E3C6C693E4C4F323A204372656174652065646974696E67206C6F677320616E642065646974207468652073686F74733C2F6C693E3C6C693E4C4F333A205265736F6C766520617564696F20616E64207374696C6C206973737565733C2F6C693E3C6C693E4C4F343A20436F6C6C61626F7261746520776974682070726F64756374696F6E207465616D7320746F206564697420636C697020616E6420636F6C6F723C2F6C693E3C6C693E4C4F353A20506572666F726D2066696E616C20746F75636820757020746F20636C65616E20757020696D70657266656374696F6E733C2F6C693E3C2F756C3E');

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT @title, @ident, @lo_body, NOW(), NOW(), 1
FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = @ident) x
  );

UPDATE cms_block
   SET title       = @title,
       content     = @lo_body,
       is_active   = 1,
       update_time = NOW()
 WHERE identifier = @ident
   AND @e IS NOT NULL;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b WHERE b.identifier = @ident;
