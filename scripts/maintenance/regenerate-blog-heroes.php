<?php
/**
 * Regenerate auto-generated blog hero images through the editorial renderer
 * (mmd_blog/hero), replacing the old course-cover-styled ones.
 *
 * Only touches posts whose hero_image_url contains "/blog/auto-" — that prefix
 * marks a pipeline-generated hero. Admin-uploaded heroes (no prefix) and
 * external heroes (e.g. a YouTube thumbnail) are never overwritten, matching
 * the contract in MMD_Blog_Helper_Image.
 *
 * Usage (inside the web container):
 *   php scripts/maintenance/regenerate-blog-heroes.php [--dry-run]
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

$posts = Mage::getModel('mmd_blog/post')->getCollection()
    ->addFieldToFilter('hero_image_url', array('like' => '%/blog/auto-%'));

printf("%d post(s) with auto-generated heroes%s\n\n", count($posts), $dryRun ? ' (DRY RUN)' : '');

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
