<?php

/**
 * Minimal Cloudflare R2 (S3-compatible) PutObject client.
 *
 * Pure PHP + cURL + hash_hmac. Avoids pulling aws/aws-sdk-php (which would add
 * ~30MB of vendor code for a single PutObject call). If the project ever needs
 * full S3 bucket management (list/copy/multipart), swap this out for the SDK.
 *
 * Signs SigV4 against region "auto" / service "s3" per Cloudflare R2 docs.
 *
 * Reference: https://developers.cloudflare.com/r2/api/s3/api/
 */
class MMD_CourseImage_Helper_R2 extends Mage_Core_Helper_Abstract
{
    private const REGION = 'auto';
    private const SERVICE = 's3';

    /**
     * @return array{url:string,bytes:int}
     */
    public function putObject(string $key, string $body, string $contentType = 'application/octet-stream'): array
    {
        /** @var MMD_CourseImage_Helper_Data $cfg */
        $cfg = Mage::helper('mmd_courseimage');

        $accessKey = $cfg->env('R2_ACCESS_KEY_ID');
        $secretKey = $cfg->env('R2_SECRET_ACCESS_KEY');
        $endpoint  = rtrim((string) $cfg->env('R2_ENDPOINT', ''), '/');
        $bucket    = $cfg->env('R2_BUCKET');
        $publicUrl = rtrim((string) $cfg->env('R2_PUBLIC_URL', ''), '/');

        if (!$accessKey || !$secretKey || !$endpoint || !$bucket || !$publicUrl) {
            Mage::throwException(
                'R2 not configured. Required: R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, '
                . 'R2_ENDPOINT, R2_BUCKET, R2_PUBLIC_URL.'
            );
        }

        $key  = ltrim($key, '/');
        $host = parse_url($endpoint, PHP_URL_HOST);
        if (!$host) {
            Mage::throwException("Invalid R2_ENDPOINT: {$endpoint}");
        }

        // Path-style addressing: PUT https://<accountid>.r2.cloudflarestorage.com/<bucket>/<key>
        $url     = "{$endpoint}/{$bucket}/" . $this->encodeKey($key);
        $payload = $body;
        $hash    = hash('sha256', $payload);
        $now     = gmdate('Ymd\THis\Z');
        $date    = substr($now, 0, 8);

        $headers = [
            'host'                 => $host,
            'x-amz-content-sha256' => $hash,
            'x-amz-date'           => $now,
            'content-type'         => $contentType,
        ];
        ksort($headers);

        $canonicalHeaders = '';
        $signedHeaders    = [];
        foreach ($headers as $k => $v) {
            $canonicalHeaders .= $k . ':' . trim($v) . "\n";
            $signedHeaders[]   = $k;
        }
        $signedHeadersStr = implode(';', $signedHeaders);

        $canonicalUri = '/' . rawurlencode($bucket) . '/' . $this->encodeKey($key);
        $canonicalReq = "PUT\n{$canonicalUri}\n\n{$canonicalHeaders}\n{$signedHeadersStr}\n{$hash}";

        $scope         = "{$date}/" . self::REGION . '/' . self::SERVICE . '/aws4_request';
        $stringToSign  = "AWS4-HMAC-SHA256\n{$now}\n{$scope}\n" . hash('sha256', $canonicalReq);

        $kDate    = hash_hmac('sha256', $date, 'AWS4' . $secretKey, true);
        $kRegion  = hash_hmac('sha256', self::REGION, $kDate, true);
        $kService = hash_hmac('sha256', self::SERVICE, $kRegion, true);
        $kSigning = hash_hmac('sha256', 'aws4_request', $kService, true);
        $signature = hash_hmac('sha256', $stringToSign, $kSigning);

        $authHeader = sprintf(
            'AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s',
            $accessKey,
            $scope,
            $signedHeadersStr,
            $signature
        );

        $curlHeaders = [
            'Authorization: ' . $authHeader,
            'Content-Type: ' . $contentType,
            'x-amz-content-sha256: ' . $hash,
            'x-amz-date: ' . $now,
            // Force libcurl to send only what we signed — it likes to add Expect.
            'Expect:',
        ];

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST  => 'PUT',
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => $curlHeaders,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_FAILONERROR    => false,
        ]);
        $resp = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($code < 200 || $code >= 300) {
            $snippet = is_string($resp) ? substr($resp, 0, 400) : '';
            Mage::throwException("R2 upload failed (HTTP {$code}): {$err} {$snippet}");
        }

        return [
            'url'   => "{$publicUrl}/{$key}",
            'bytes' => strlen($payload),
        ];
    }

    /**
     * Delete one object. Used to clean up superseded uploads (e.g. a hero PNG
     * replaced by a re-render under a new timestamped key) so the bucket does
     * not accumulate orphans.
     *
     * S3 DELETE is idempotent: a missing key returns 204, so re-running is safe.
     *
     * @return array{deleted:bool,status:int}
     */
    public function deleteObject(string $key): array
    {
        /** @var MMD_CourseImage_Helper_Data $cfg */
        $cfg = Mage::helper('mmd_courseimage');

        $accessKey = $cfg->env('R2_ACCESS_KEY_ID');
        $secretKey = $cfg->env('R2_SECRET_ACCESS_KEY');
        $endpoint  = rtrim((string) $cfg->env('R2_ENDPOINT', ''), '/');
        $bucket    = $cfg->env('R2_BUCKET');

        if (!$accessKey || !$secretKey || !$endpoint || !$bucket) {
            Mage::throwException(
                'R2 not configured. Required: R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, '
                . 'R2_ENDPOINT, R2_BUCKET.'
            );
        }

        $key  = ltrim($key, '/');
        $host = parse_url($endpoint, PHP_URL_HOST);
        if (!$host) {
            Mage::throwException("Invalid R2_ENDPOINT: {$endpoint}");
        }

        // DELETE carries no body, so the payload hash is the hash of the empty string.
        $hash = hash('sha256', '');
        $now  = gmdate('Ymd\THis\Z');
        $date = substr($now, 0, 8);

        $headers = [
            'host'                 => $host,
            'x-amz-content-sha256' => $hash,
            'x-amz-date'           => $now,
        ];
        ksort($headers);

        $canonicalHeaders = '';
        $signedHeaders    = [];
        foreach ($headers as $k => $v) {
            $canonicalHeaders .= $k . ':' . trim($v) . "\n";
            $signedHeaders[]   = $k;
        }
        $signedHeadersStr = implode(';', $signedHeaders);

        $canonicalUri = '/' . rawurlencode($bucket) . '/' . $this->encodeKey($key);
        $canonicalReq = "DELETE\n{$canonicalUri}\n\n{$canonicalHeaders}\n{$signedHeadersStr}\n{$hash}";

        $scope        = "{$date}/" . self::REGION . '/' . self::SERVICE . '/aws4_request';
        $stringToSign = "AWS4-HMAC-SHA256\n{$now}\n{$scope}\n" . hash('sha256', $canonicalReq);

        $kDate     = hash_hmac('sha256', $date, 'AWS4' . $secretKey, true);
        $kRegion   = hash_hmac('sha256', self::REGION, $kDate, true);
        $kService  = hash_hmac('sha256', self::SERVICE, $kRegion, true);
        $kSigning  = hash_hmac('sha256', 'aws4_request', $kService, true);
        $signature = hash_hmac('sha256', $stringToSign, $kSigning);

        $authHeader = sprintf(
            'AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s',
            $accessKey,
            $scope,
            $signedHeadersStr,
            $signature
        );

        $ch = curl_init("{$endpoint}/{$bucket}/" . $this->encodeKey($key));
        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST  => 'DELETE',
            CURLOPT_HTTPHEADER     => [
                'Authorization: ' . $authHeader,
                'x-amz-content-sha256: ' . $hash,
                'x-amz-date: ' . $now,
                'Expect:',
            ],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_FAILONERROR    => false,
        ]);
        $resp = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($code < 200 || $code >= 300) {
            $snippet = is_string($resp) ? substr($resp, 0, 400) : '';
            Mage::throwException("R2 delete failed (HTTP {$code}): {$err} {$snippet}");
        }

        return ['deleted' => true, 'status' => $code];
    }

    /**
     * Percent-encode each path segment but keep the slashes between them.
     * S3 SigV4 requires this — rawurlencode would escape '/'.
     */
    private function encodeKey(string $key): string
    {
        $segments = explode('/', $key);
        return implode('/', array_map('rawurlencode', $segments));
    }
}
