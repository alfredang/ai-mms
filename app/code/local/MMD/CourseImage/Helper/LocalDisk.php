<?php
/**
 * Local-disk media store for country instances (MMS_MODE=country).
 *
 * Country instances do not use Cloudflare R2. Instead, images are written to
 * the instance's own media/ volume and served directly by Apache. This helper
 * mirrors the interface of MMD_CourseImage_Helper_R2::putObject() so callers
 * can swap drivers with a single mode check.
 *
 * The returned URL is instance-relative: it uses the store's base_url so the
 * URL works whether the country domain is http://localhost:8082/ or
 * the country storefront. The country instance NEVER ends up with
 * an R2 or SG URL in course_image_url.
 */
class MMD_CourseImage_Helper_LocalDisk extends Mage_Core_Helper_Abstract
{
    const MEDIA_SUBDIR = 'course-covers';

    /**
     * Write $body bytes to media/course-covers/<key> and return the public URL.
     *
     * @param string $key          Relative path inside media/course-covers/ (e.g. "c814.jpg")
     * @param string $body         Raw bytes
     * @param string $contentType  MIME type (unused for disk write, kept for interface parity)
     * @return array{url:string,bytes:int}
     */
    public function putObject(string $key, string $body, string $contentType = 'image/jpeg'): array
    {
        $mediaDir = Mage::getBaseDir('media') . DS . self::MEDIA_SUBDIR;
        if (!is_dir($mediaDir)) {
            @mkdir($mediaDir, 0755, true);
        }

        $key      = ltrim($key, '/');
        $filePath = $mediaDir . DS . $key;

        // Ensure subdirectory exists (key may include a subfolder)
        $subDir = dirname($filePath);
        if (!is_dir($subDir)) {
            @mkdir($subDir, 0755, true);
        }

        $written = file_put_contents($filePath, $body);
        if ($written === false) {
            Mage::throwException("LocalDisk: failed to write media file: $filePath");
        }

        // Build the public URL using the current store's base URL (instance-relative)
        $baseUrl = rtrim((string) Mage::getStoreConfig('web/unsecure/base_url'), '/');
        $url     = $baseUrl . '/media/' . self::MEDIA_SUBDIR . '/' . $key;

        return array('url' => $url, 'bytes' => $written);
    }

    /**
     * Download an image from a remote URL and write it to local media/.
     * Used by CourseSyncService to cache SG course images locally.
     *
     * @param string $remoteUrl  Source URL (SG R2 or any public URL)
     * @param string $key        Destination key inside media/course-covers/
     * @return array{url:string,bytes:int}
     */
    public function fetchAndStore(string $remoteUrl, string $key): array
    {
        $ch = curl_init($remoteUrl);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS      => 3,
            CURLOPT_USERAGENT      => 'MMS-CourseSync/1.0',
        ));
        $body = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $mime = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($body === false || $body === '') {
            throw new Exception("LocalDisk: failed to fetch $remoteUrl: " . ($err ?: "empty response"));
        }
        if ($code < 200 || $code >= 300) {
            throw new Exception("LocalDisk: remote returned HTTP $code for $remoteUrl");
        }

        return $this->putObject($key, $body, $mime ?: 'image/jpeg');
    }
}
