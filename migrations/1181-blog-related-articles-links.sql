-- 1181: Related Articles — link blog posts to courses.
--
-- New table mmd_blog_post_product maps blog posts (mmd_blog_post) to courses
-- (catalog_product_entity). Populated from Edit Course -> Marketing ->
-- Related Articles; the storefront course page shows a random sample of the
-- linked published posts in the right column under the Photo Gallery.
--
-- Seed: link every hydroponics / urban-farming blog post to the
-- "Basic Urban Farming with Hydroponics" course (TGS-2025053916).
--
-- Partner-safe: matching is by SKU + post url_key/title, so the seed no-ops
-- on sites that lack the course or the posts. Idempotent via INSERT IGNORE.

CREATE TABLE IF NOT EXISTS `mmd_blog_post_product` (
    `post_id`    INT UNSIGNED NOT NULL,
    `product_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`post_id`, `product_id`),
    KEY `IDX_MMD_BLOG_POST_PRODUCT` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `mmd_blog_post_product` (`post_id`, `product_id`) SELECT p.`post_id`, e.`entity_id` FROM `mmd_blog_post` p JOIN `catalog_product_entity` e ON e.`sku` = 'TGS-2025053916' WHERE p.`title` LIKE '%hydroponic%' OR p.`url_key` LIKE '%hydroponic%' OR p.`url_key` LIKE '%urban-farming%';
