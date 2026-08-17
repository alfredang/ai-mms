<?php
/**
 * Blog hero-image storage. Primary target is Cloudflare R2 (same bucket the
 * catalog media lives in, via the existing mmd_courseimage/r2 SigV4 client);
 * when R2 env keys are absent (e.g. a bare local checkout) it falls back to
 * media/blog/ on local disk so the feature still works end-to-end.
 */
class MMD_Blog_Helper_Image extends Mage_Core_Helper_Abstract
{
    private const ALLOWED = array(
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'webp' => 'image/webp',
        'gif'  => 'image/gif',
    );

    /**
     * @param string $tmpPath  uploaded temp file
     * @param string $origName original client filename (for the extension)
     * @return string public URL of the stored image
     */
    public function storeHeroImage($tmpPath, $origName)
    {
        $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
        if (!isset(self::ALLOWED[$ext])) {
            Mage::throwException('Unsupported image type: ' . $ext . ' (use jpg, png, webp or gif)');
        }
        $bytes = @file_get_contents($tmpPath);
        if ($bytes === false || $bytes === '') {
            Mage::throwException('Could not read the uploaded image.');
        }
        $base = Mage::helper('mmd_blog')->slugify(pathinfo($origName, PATHINFO_FILENAME));
        $key  = 'blog/' . date('Ymd-His') . '-' . ($base !== '' ? $base : 'hero') . '.' . $ext;

        try {
            $result = Mage::helper('mmd_courseimage/r2')->putObject($key, $bytes, self::ALLOWED[$ext]);
            return $result['url'];
        } catch (Exception $e) {
            Mage::log('Blog hero R2 upload failed, using local media/: ' . $e->getMessage(), null, 'mmd_blog.log');
        }

        $dir = Mage::getBaseDir('media') . DS . 'blog';
        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }
        $file = $dir . DS . basename($key);
        if (@file_put_contents($file, $bytes) === false) {
            Mage::throwException('Could not store the image locally.');
        }
        return Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_MEDIA) . 'blog/' . basename($key);
    }

    /**
     * Auto-generated EDITORIAL hero for a pipeline post, stored under
     * blog/auto-* — the prefix marks it as replaceable by the pipeline, unlike
     * an admin-uploaded hero.
     *
     * Renders through mmd_blog/hero, NOT the course cover: a blog card is an
     * article, not a product. The course cover carries the Tertiary logo
     * lockup and the "FUNDING AVAILABLE / WSQ / SkillsFuture Credit" chip row,
     * which on the blog listing made posts read as ad tiles sitting among
     * editorial cards. The editorial renderer instead picks a topic-specific
     * palette + motif so each post is visually distinct at thumbnail size.
     *
     * @param string $title  post title
     * @param string $sku    source course SKU (kept for signature compatibility;
     *                       no longer drives funding chips)
     * @param string $kicker category label for the pill, e.g. "GENERATIVE AI"
     * @return string public URL ('' only if even the local fallback failed)
     */
    public function generateHero($title, $sku = '', $kicker = '')
    {
        $png  = Mage::getModel('mmd_blog/hero')->render((string) $title, (string) $kicker);
        $base = Mage::helper('mmd_blog')->slugify(mb_substr((string) $title, 0, 60));
        $key  = 'blog/auto-' . date('Ymd-His') . '-' . ($base !== '' ? $base : 'hero') . '.png';

        try {
            $result = Mage::helper('mmd_courseimage/r2')->putObject($key, $png, 'image/png');
            return $result['url'];
        } catch (Exception $e) {
            Mage::log('Blog auto-hero R2 upload failed, using local media/: ' . $e->getMessage(), null, 'mmd_blog.log');
        }

        $dir = Mage::getBaseDir('media') . DS . 'blog';
        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }
        $file = $dir . DS . basename($key);
        if (@file_put_contents($file, $png) === false) {
            return '';
        }
        return Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_MEDIA) . 'blog/' . basename($key);
    }
}
