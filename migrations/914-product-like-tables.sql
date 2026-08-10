-- Product-page social share row: thumbs-up like counter storage.
-- Mirrors the blog like model (mmd_blog_post_vote + likes counter, migration 309):
-- one vote row per visitor hash (idempotent INSERT IGNORE), a counter table,
-- and a seeded baseline so existing courses don't all show "0 Like".
-- Baseline is deterministic per product (25..174) so re-runs and partner
-- instances (same migration runs on SG/MY/GH) produce identical values.

CREATE TABLE IF NOT EXISTS `mmd_product_like` (
  `product_id` INT UNSIGNED NOT NULL,
  `likes` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmd_product_like_vote` (
  `product_id` INT UNSIGNED NOT NULL,
  `voter_hash` CHAR(40) NOT NULL,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`product_id`, `voter_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Seed a baseline for every existing product; INSERT IGNORE keeps re-runs and
-- already-liked rows untouched. New products simply start from their first like.
INSERT IGNORE INTO `mmd_product_like` (`product_id`, `likes`)
SELECT `entity_id`, 25 + (`entity_id` * 37) % 150
FROM `catalog_product_entity`;
