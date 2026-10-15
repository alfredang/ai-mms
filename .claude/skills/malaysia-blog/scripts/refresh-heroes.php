<?php
/** Malaysia-only banner refresh: stage locally, inspect, then publish verified PNGs. */
require '/var/www/html/app/Mage.php';
Mage::app('admin');
$resource = Mage::getSingleton('core/resource');
$db = $resource->getConnection('core_write');
$stores = $db->fetchCol("SELECT code FROM core_store WHERE store_id <> 0");
if (getenv('MMS_COUNTRY_CODE') !== 'MY' || $stores !== ['malaysia']) {
    throw new RuntimeException('Refusing to run outside the isolated Malaysia installation.');
}
$mode = $argv[1] ?? 'audit';
$dir = $argv[2] ?? '/tmp/my-blog-heroes';
$rendererHash = hash_file('sha256', '/var/www/html/app/code/local/MMD/Blog/Model/Hero.php');
$posts = $db->fetchAll('SELECT * FROM mmd_blog_post WHERE status = 1 ORDER BY post_id');
if ($mode === 'audit') {
    echo json_encode(['renderer_sha256' => $rendererHash, 'posts' => array_map(function ($p) {
        return array_intersect_key($p, array_flip(['post_id', 'title', 'url_key', 'hero_image_url']));
    }, $posts)], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES), "\n";
    exit;
}
if ($mode === 'stage') {
    if (file_exists($dir)) { throw new RuntimeException('Use a fresh staging directory.'); }
    if (!mkdir($dir, 0700, true)) { throw new RuntimeException('Cannot create staging directory.'); }
    $manifest = ['renderer_sha256' => $rendererHash, 'posts' => $posts, 'images' => []];
    foreach ($posts as $post) {
        $kicker = 'Article';
        foreach (Mage::helper('mmd_blog')->getPostTags($post['post_id']) as $tag) {
            if (!in_array(strtoupper($tag), ['WSQ', 'SKILLSFUTURE', 'SKILLSFUTURE CREDIT', 'CORPORATE TRAINING', 'ARTIFICIAL INTELLIGENCE', 'HRD CORP'], true)) {
                $kicker = $tag;
                break;
            }
        }
        $png = Mage::getModel('mmd_blog/hero')->render($post['title'], $kicker);
        $size = getimagesizefromstring($png);
        if (!$size || $size[0] !== 1600 || $size[1] !== 900 || $size['mime'] !== 'image/png') {
            throw new RuntimeException('Invalid render for post ' . $post['post_id']);
        }
        $file = $post['post_id'] . '.png';
        if (file_put_contents($dir . '/' . $file, $png) === false) { throw new RuntimeException('Cannot store preview.'); }
        $manifest['images'][] = ['post_id' => $post['post_id'], 'file' => $file, 'sha256' => hash('sha256', $png), 'kicker' => $kicker];
        echo 'STAGED ', $post['post_id'], ' ', $post['title'], "\n";
    }
    file_put_contents($dir . '/manifest.json', json_encode($manifest, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR));
    echo 'STAGED COUNT=', count($posts), ' RENDERER=', $rendererHash, "\n";
    exit;
}
if ($mode !== 'publish') { throw new RuntimeException('Use audit, stage or publish.'); }
$manifest = json_decode(file_get_contents($dir . '/manifest.json'), true, 512, JSON_THROW_ON_ERROR);
if ($manifest['renderer_sha256'] !== $rendererHash || $manifest['posts'] !== $posts) {
    throw new RuntimeException('Renderer or published posts changed after staging; stage again.');
}
$updates = [];
foreach ($manifest['images'] as $image) {
    $png = file_get_contents($dir . '/' . $image['file']);
    if (hash('sha256', $png) !== $image['sha256']) { throw new RuntimeException('Preview checksum changed.'); }
    // Country-specific immutable objects: never overwrite shared SG image keys.
    $key = 'blog/auto-my-' . substr($rendererHash, 0, 12) . '-' . $image['post_id'] . '-' . substr($image['sha256'], 0, 16) . '.png';
    $result = Mage::helper('mmd_courseimage/r2')->putObject($key, $png, 'image/png');
    $ch = curl_init($result['url']);
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 30, CURLOPT_FOLLOWLOCATION => true]);
    $bytes = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $mime = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    curl_close($ch);
    if ($code !== 200 || strpos((string) $mime, 'image/png') !== 0 || hash('sha256', (string) $bytes) !== $image['sha256']) {
        throw new RuntimeException('Uploaded banner failed public checksum verification for ' . $image['post_id']);
    }
    $updates[$image['post_id']] = $result['url'];
    echo 'VERIFIED UPLOAD ', $image['post_id'], "\n";
}
$db->beginTransaction();
try {
    $current = $db->fetchAll('SELECT * FROM mmd_blog_post WHERE status = 1 ORDER BY post_id FOR UPDATE');
    if ($current !== $manifest['posts']) { throw new RuntimeException('Posts changed during upload; refusing DB changes.'); }
    foreach ($updates as $id => $url) {
        $db->update('mmd_blog_post', ['hero_image_url' => $url], $db->quoteInto('post_id = ?', $id));
    }
    $after = $db->fetchAll('SELECT * FROM mmd_blog_post WHERE status = 1 ORDER BY post_id');
    foreach ($after as $i => $row) {
        $row['hero_image_url'] = $manifest['posts'][$i]['hero_image_url'];
        if ($row !== $manifest['posts'][$i]) { throw new RuntimeException('Unrelated post fields changed.'); }
    }
    $db->commit();
} catch (Throwable $e) {
    $db->rollBack();
    throw $e;
}
file_put_contents($dir . '/published.json', json_encode($updates, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
Mage::app()->getCacheInstance()->flush();
echo 'PUBLISHED COUNT=', count($updates), ' PRESERVED ALL OTHER POST FIELDS', "\n";
