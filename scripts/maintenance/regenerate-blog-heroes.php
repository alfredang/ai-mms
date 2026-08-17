<?php
/**
 * Regenerate auto-generated blog hero images through the editorial renderer
 * (mmd_blog/hero), replacing the old course-cover-styled ones.
 *
 * Targets two groups:
 *   1. hero_image_url LIKE '%/blog/auto-%' — pipeline-generated heroes, safe to
 *      re-render (that prefix is the replaceable marker).
 *   2. hero_image_url NULL/'' — posts that fell back to the CSS gradient card.
 *      Giving them a real hero is what makes the listing consistent.
 *
 * Admin-uploaded heroes (a /blog/ URL without the auto- prefix) and external
 * heroes (e.g. a YouTube thumbnail) are NEVER overwritten, matching the
 * contract in MMD_Blog_Helper_Image.
 *
 * Usage (inside the web container):
 *   php scripts/maintenance/regenerate-blog-heroes.php [--dry-run] [--only-empty]
 */

require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app('admin');

$dryRun = in_array('--dry-run', $argv, true);

/** Derive a short category kicker from the post's tags, else a topic guess. */
function kickerFor($post)
{
    $tags = Mage::helper('mmd_blog')->getPostTags($post->getId());
    if ($tags) {
        // Prefer a specific tag over the generic "WSQ" funding label.
        foreach ($tags as $t) {
            if (!in_array(strtoupper($t), array('WSQ', 'SKILLSFUTURE'), true)) {
                return $t;
            }
        }
        return $tags[0];
    }
    return 'Article';
}

$onlyEmpty = in_array('--only-empty', $argv, true);

// mmd_blog_post is a FLAT table, so the EAV-style array-of-['attribute'=>...]
// OR syntax is not available (it fatals in prepareSqlCondition). Passing one
// field name with an array of conditions is the flat-collection OR form.
$conds = array(array('null' => true), array('eq' => ''));
if (!$onlyEmpty) {
    array_unshift($conds, array('like' => '%/blog/auto-%'));
}
$posts = Mage::getModel('mmd_blog/post')->getCollection()
    ->addFieldToFilter('hero_image_url', $conds);

printf("%d post(s) to render%s\n\n", count($posts), $dryRun ? ' (DRY RUN)' : '');

$done = 0;
$failed = 0;
foreach ($posts as $post) {
    $title  = (string) $post->getTitle();
    $kicker = kickerFor($post);

    printf("#%-3d %-58s [%s]\n", $post->getId(), mb_substr($title, 0, 58), $kicker);

    if ($dryRun) {
        continue;
    }

    try {
        $url = Mage::helper('mmd_blog/image')->generateHero($title, '', $kicker);
        if (!$url) {
            throw new Exception('renderer returned empty URL');
        }
        $post->setHeroImageUrl($url)->save();
        printf("     -> %s\n", $url);
        $done++;
    } catch (Exception $e) {
        printf("     !! FAILED: %s\n", $e->getMessage());
        $failed++;
    }
}

printf("\nregenerated: %d   failed: %d\n", $done, $failed);
