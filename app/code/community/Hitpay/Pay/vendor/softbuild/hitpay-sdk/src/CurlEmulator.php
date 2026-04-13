<?php
if (!extension_loaded('curl')) {
    // The curl option constants
    define ('CURLOPT_RETURNTRANSFER2', 19913);
    define ('CURLOPT_SSL_VERIFYPEER2', 64);
    define ('CURLOPT_SSL_VERIFYHOST2', 81);
    define ('CURLOPT_USERAGENT2', 10018);
    define ('CURLOPT_HEADER2', 42);
    define ('CURLOPT_CUSTOMREQUEST2', 10036);
    define ('CURLOPT_POST2', 47);
    define ('CURLOPT_POSTFIELDS2', 10015);
    define ('CURLOPT_HTTPHEADER2', 10023);
    define ('CURLOPT_URL2', 10002);
    define ('CURLOPT_HTTPGET2', 80); // this could be a good idea to handle params as array
    define ('CURLOPT_CONNECTTIMEOUT2', 78);
    define ('CURLOPT_TIMEOUT2', 13);
    define ('CURLOPT_CAINFO2', 10065);
    define ('CURLOPT_SSLVERSION2', 32);
    define ('CURLOPT_FOLLOWLOCATION2', 52);
    define ('CURLOPT_FORBID_REUSE2', 75);
    define ('CURLOPT_HTTP_VERSION2', 84);
    define ('CURLOPT_MAXREDIRS2', 68);
    define ('CURLOPT_ENCODING2', 10102);

    // curl info constants
    define ('CURLINFO_HEADER_SIZE2', 2097163);
    define ('CURLINFO_HTTP_CODE2', 2097154);
    define ('CURLINFO_HEADER_OUT2', 2); // This seems to be an option?
    define ('CURLINFO_TOTAL_TIME2', 3145731);

    define ('CURLE_SSL_CACERT2', 60);
    define ('CURLE_SSL_PEER_CERTIFICATE2', 51);
    define ('CURLE_SSL_CACERT_BADFILE2', 77);

    define ('CURLE_COULDNT_CONNECT2', 7);
    define ('CURLE_OPERATION_TIMEOUTED2', 28);
    define ('CURLE_COULDNT_RESOLVE_HOST2', 6);

    class CurlEmulator
    {
        // Storing the result in here
        private $result;

        // The headers of the result will be stored here
        private $responseHeader;

        // url for request
        private $url;

        // options
        private $options = [];

        public function __construct($url)
        {
            $this->url = $url;
        }

        public function setOpt($option, $value)
        {
            $this->options[$option] = $value;
        }

        public function getInfo($opt = 0)
        {
            if (!$this->result) {
                $this->fetchResult();
            }

            $responseHeaderSize = 0;
            foreach ($this->responseHeader as $header)
                $responseHeaderSize += (strlen($header) + 2); // The one is for each newline

            $httpCode = 200;
            if (preg_match('#HTTP/\d+\.\d+ (\d+)#', $this->responseHeader[0], $matches))
                $httpCode = intval($matches[1]);

            // opt
            if ($opt == CURLINFO_HEADER_SIZE2)
                return $responseHeaderSize;

            if ($opt == CURLINFO_HTTP_CODE2)
                return $httpCode;

            return [
                "url" => $this->url,
                "content_type" => "",
                "http_code" => $httpCode,
                "header_size" => $responseHeaderSize,
                "request_size" => 0,
                "filetime" => 0,
                "ssl_verify_result" => null,
                "redirect_count" => 0,
                "total_time" => 0,
                "namelookup_time" => 0,
                "connect_time" => 0,
                "pretransfer_time" => 0,
                "size_upload" => 0,
                "size_download" => 0,
                "speed_download" => 0,
                "speed_upload" => 0,
                "download_content_length" => 0,
                "upload_content_length" => 0,
                "starttransfer_time" => 0,
                "redirect_time" => 0,
                "certinfo" => 0,
                "request_header" => 0
            ];
        }

        public function exec()
        {
            $this->fetchResult();

            $fullResult = $this->result;

            if ($this->getValue(CURLOPT_HEADER2, false)) {
                $headers = implode("\r\n", $this->responseHeader);
                $fullResult = $headers . "\r\n" . $this->result;
            }

            if ($this->getValue(CURLOPT_RETURNTRANSFER2, false) == false) {
                print $fullResult;
            } else {
                return $fullResult;
            }
        }

        private function fetchResult()
        {
            // Create the context for this request based on the curl parameters

            // Determine the method
            if (!$this->getValue(CURLOPT_CUSTOMREQUEST2, false) && $this->getValue(CURLOPT_POST2, false)) {
                $method = 'POST';
            } else {
                $method = $this->getValue(CURLOPT_CUSTOMREQUEST2, 'GET');
            }

            // Add the post header if type is post and it has not been added
            if ($method == 'POST') {
                if (is_array($this->getValue(CURLOPT_HTTPHEADER2))) {
                    $found = false;
                    foreach ($this->getValue(CURLOPT_HTTPHEADER2, array()) as $header) {
                        if (strtolower($header) == strtolower('Content-type: application/x-www-form-urlencoded')) {
                            $found = true;
                        }
                    }

                    // add post header if not found
                    if (!$found) {
                        $headers = $this->getValue(CURLOPT_HTTPHEADER2, array());
                        $headers[] = 'Content-type: application/x-www-form-urlencoded';
                        $this->setOpt(CURLOPT_HTTPHEADER2, $headers);
                    }
                }
            }

            // Determine the content which can be an array or a string
            if (is_array($this->getValue(CURLOPT_POSTFIELDS2))) {
                $content = http_build_query($this->getValue(CURLOPT_POSTFIELDS2, array()));
            } else {
                $content = $this->getValue(CURLOPT_POSTFIELDS2, "");
            }

            // get timeout
            $timeout = $this->getValue(CURLOPT_TIMEOUT2, 60);
            $connectTimeout = $this->getValue(CURLOPT_CONNECTTIMEOUT2, 30);

            // take bigger timeout
            if ($connectTimeout > $timeout)
                $timeout = $connectTimeout;

            $headers = $this->getValue(CURLOPT_HTTPHEADER2, "");
            if (is_array($headers)) {
                $headers = join("\r\n", $headers);
            }

            // 'http' instead of $parsedUrl['scheme']; https doest work atm
            $options = array(
                'http' => array(
                    "timeout" => $timeout,
                    "ignore_errors" => true,
                    'method' => $method,
                    'header' => $headers,
                    'content' => $content
                )
            );

            $options["http"]["follow_location"] = $this->getValue(CURLOPT_FOLLOWLOCATION2, 1);

            // get url from options
            if ($this->getValue(CURLOPT_URL2, false))
                $this->url = $this->getValue(CURLOPT_URL2);

            $context = stream_context_create($options);
            $this->result = file_get_contents($this->url, false, $context);

            $this->responseHeader = $http_response_header;
        }

        private function getValue($value, $default = null)
        {
            if (isset($this->options[$value]) && $this->options[$value]) {
                return $this->options[$value];
            }
            return $default;
        }

        public function errNo()
        {
            return 0;
        }

        public function error()
        {
            return "";
        }

        public function close()
        {

        }
    }

    function curl_init2($url = null)
    {
        return new CurlEmulator($url);
    }

    function curl_setopt2($ch, $option, $value)
    {
        $ch->setOpt($option, $value);
    }

    function curl_exec2($ch)
    {
        return $ch->exec();
    }

    function curl_getinfo2($ch, $option = 0)
    {
        return $ch->getInfo($option);
    }

    function curl_errno2($ch) {
        return $ch->errNo();
    }

    function curl_error2($ch) {
        return $ch->error();
    }

    function curl_close2($ch) {
        return $ch->close();
    }

    function curl_setopt_array2($ch, $options) {
        foreach ($options as $option => $value) {
            curl_setopt2($ch, $option, $value);
        }
    }
}
