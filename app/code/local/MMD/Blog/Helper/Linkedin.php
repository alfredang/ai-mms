<?php
/**
 * LinkedIn share client — port of ai-cms src/lib/social/linkedin.ts.
 *
 * Publishes a post on the configured member/organisation feed via the
 * versioned REST API. For text+link posts LinkedIn auto-renders an OpenGraph
 * card from the URL (the blog view page emits og: meta tags for this).
 * When an image URL is supplied it goes through the 3-step flow:
 * initializeUpload -> PUT binary -> reference the image URN in /rest/posts.
 *
 * Credentials — resolved in order:
 *   1. env LINKEDIN_ACCESS_TOKEN + LINKEDIN_AUTHOR_URN (container-level)
 *   2. core_config_data mmd_marketing/linkedin/access_token (core-encrypted)
 *      + author_urn — the SAME credentials the newsletter pipeline posts with
 *      (see MMD_Marketing_Helper_Linkedin), so configuring LinkedIn once
 *      covers both the flyer and the blog.
 */
class MMD_Blog_Helper_Linkedin extends Mage_Core_Helper_Abstract
{
    private const REST_BASE = 'https://api.linkedin.com/rest';
    // LinkedIn retires monthly API versions after ~12 months — bump periodically.
    private const REST_VERSION = '202604';

    public function isConfigured()
    {
        return $this->_token() !== null && $this->_author() !== null;
    }

    /**
     * Organisation author URN (urn:li:organization:NNNN) for company-page
     * posts, or null when unset. Posting as the org additionally requires the
     * token to carry w_organization_social — callers should treat a failure as
     * cosmetic, exactly like the member share.
     */
    public function orgUrn()
    {
        $env = $this->_env('LINKEDIN_ORG_URN');
        if ($env !== null) {
            return $env;
        }
        $urn = trim((string) Mage::getStoreConfig('mmd_marketing/linkedin/org_urn'));
        return $urn !== '' ? $urn : null;
    }

    /**
     * Token for company-page posts — the dedicated org app's credential
     * (mmd_marketing/linkedin/org_access_token, core-encrypted). Falls back to
     * the member token when unset.
     */
    private function _orgToken()
    {
        $enc = trim((string) Mage::getStoreConfig('mmd_marketing/linkedin/org_access_token'));
        if ($enc !== '') {
            $dec = trim((string) Mage::helper('core')->decrypt($enc));
            if ($dec !== '') {
                return $dec;
            }
        }
        return $this->_token();
    }

    /**
     * @param string|null $author author URN override (e.g. orgUrn() for the
     *                            company page); null = the configured member.
     * @return array{externalId:string,externalUrl:string}
     */
    public function share($commentary, $linkUrl = null, $imageUrl = null, $author = null)
    {
        if ($author === null || $author === '') { $author = $this->_author(); }
        $token = ($author !== null && $author === $this->orgUrn()) ? $this->_orgToken() : $this->_token();
        if (!$token || !$author) {
            Mage::throwException('LinkedIn not configured: set LINKEDIN_ACCESS_TOKEN and LINKEDIN_AUTHOR_URN.');
        }

        if ($linkUrl && strpos($commentary, $linkUrl) === false) {
            $commentary .= "\n\n" . $linkUrl;
        }
        $commentary = $this->escapeLittleText($commentary);

        $body = array(
            'author'       => $author,
            'commentary'   => $commentary,
            'visibility'   => 'PUBLIC',
            'distribution' => array(
                'feedDistribution'               => 'MAIN_FEED',
                'targetEntities'                 => array(),
                'thirdPartyDistributionChannels' => array(),
            ),
            'lifecycleState'             => 'PUBLISHED',
            'isReshareDisabledByAuthor'  => false,
        );

        if ($imageUrl) {
            try {
                $imageUrn = $this->_uploadImage($token, $author, $imageUrl);
                $body['content'] = array('media' => array('id' => $imageUrn, 'altText' => ''));
            } catch (Exception $e) {
                // Image is decoration — fall back to a text+link post.
                Mage::log('LinkedIn image upload failed: ' . $e->getMessage(), null, 'mmd_blog.log');
            }
        }

        list($code, $resp, $headers) = $this->_request('POST', self::REST_BASE . '/posts', $token, json_encode($body));
        if ($code < 200 || $code >= 300) {
            Mage::throwException("LinkedIn post failed (HTTP {$code}): " . substr((string) $resp, 0, 400));
        }
        $urn = '';
        if (preg_match('/^x-restli-id:\s*(\S+)/mi', $headers, $m)) {
            $urn = trim($m[1]);
        }
        return array(
            'externalId'  => $urn,
            'externalUrl' => $urn
                ? 'https://www.linkedin.com/feed/update/' . rawurlencode($urn) . '/'
                : 'https://www.linkedin.com/',
        );
    }

    private function _uploadImage($token, $author, $imageUrl)
    {
        list($code, $resp) = $this->_request(
            'POST',
            self::REST_BASE . '/images?action=initializeUpload',
            $token,
            json_encode(array('initializeUploadRequest' => array('owner' => $author)))
        );
        if ($code < 200 || $code >= 300) {
            Mage::throwException("image initializeUpload failed (HTTP {$code}): " . substr((string) $resp, 0, 300));
        }
        $init = json_decode($resp, true);
        $uploadUrl = $init['value']['uploadUrl'] ?? null;
        $imageUrn  = $init['value']['image'] ?? null;
        if (!$uploadUrl || !$imageUrn) {
            Mage::throwException('image initializeUpload returned no uploadUrl/image URN');
        }

        $bytes = @file_get_contents($imageUrl);
        if ($bytes === false) {
            Mage::throwException('could not fetch image ' . $imageUrl);
        }

        $ch = curl_init($uploadUrl);
        curl_setopt_array($ch, array(
            CURLOPT_CUSTOMREQUEST  => 'PUT',
            CURLOPT_POSTFIELDS     => $bytes,
            // Content-Type is required — without it curl sends x-www-form-urlencoded
            // and LinkedIn 400s the binary PUT (newsletter helper had this right).
            CURLOPT_HTTPHEADER     => array('Authorization: Bearer ' . $token, 'Content-Type: image/png'),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 60,
        ));
        curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code < 200 || $code >= 300) {
            Mage::throwException("image binary upload failed (HTTP {$code})");
        }
        return $imageUrn;
    }

    /** @return array{0:int,1:string,2:string} [httpCode, body, rawResponseHeaders] */
    private function _request($method, $url, $token, $payload)
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_CUSTOMREQUEST  => $method,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HEADER         => true,
            CURLOPT_TIMEOUT        => 60,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $token,
                'LinkedIn-Version: ' . self::REST_VERSION,
                'X-Restli-Protocol-Version: 2.0.0',
                'Content-Type: application/json',
            ),
        ));
        $raw        = (string) curl_exec($ch);
        $code       = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        curl_close($ch);
        return array($code, substr($raw, $headerSize), substr($raw, 0, $headerSize));
    }

    /**
     * LinkedIn /rest/posts commentary is "little text" — (, ), {, }, [, ], <, >,
     * *, _, ~, | and @ are markup and MUST be backslash-escaped or LinkedIn
     * silently truncates the post at the first unescaped char (real incident:
     * everything after "(up to 70% subsidy" vanished, taking the course link
     * and hashtags with it). '#' is deliberately NOT escaped so hashtags work.
     */
    public function escapeLittleText($text)
    {
        return preg_replace('/([\\\\|{}@\[\]()<>*_~])/', '\\\\$1', (string) $text);
    }

    private function _token()
    {
        $env = $this->_env('LINKEDIN_ACCESS_TOKEN');
        if ($env !== null) {
            return $env;
        }
        $enc = trim((string) Mage::getStoreConfig('mmd_marketing/linkedin/access_token'));
        if ($enc === '') {
            return null;
        }
        $dec = trim((string) Mage::helper('core')->decrypt($enc));
        return $dec !== '' ? $dec : null;
    }

    private function _author()
    {
        $env = $this->_env('LINKEDIN_AUTHOR_URN');
        if ($env !== null) {
            return $env;
        }
        $urn = trim((string) Mage::getStoreConfig('mmd_marketing/linkedin/author_urn'));
        return $urn !== '' ? $urn : null;
    }

    private function _env($key)
    {
        $val = getenv($key);
        return ($val === false || trim($val) === '') ? null : trim($val);
    }
}
