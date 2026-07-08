-- 309: Replace the blog star-rating with a thumbs-up "like" counter.
--   * Adds mmd_blog_post.likes (guarded ADD COLUMN so re-runs are safe).
--   * Seeds each existing post a random like count between 10 and 300 so the
--     thumbs-up reads as an established, social-proofed post (only fills rows
--     still at 0/NULL, so re-runs never re-randomise or clobber real likes).
-- The mmd_blog_post_vote table (created in 303) still enforces one like per
-- visitor via UNIQUE(post_id, voter_hash); the rating column is now unused.

-- Guarded ADD COLUMN (idempotent — no error if the column already exists).
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_blog_post' AND COLUMN_NAME = 'likes');
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE `mmd_blog_post` ADD COLUMN `likes` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `rating_count`', 'DO 0');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Seed a random like count 10..300 for posts that have none yet.
UPDATE `mmd_blog_post` SET `likes` = FLOOR(10 + RAND() * 291) WHERE `likes` = 0 OR `likes` IS NULL;
