<?php

namespace HitPay;

/**
 * Class Request
 * @package HitPay
 */
class Request
{
    const API_ENDPOINT = '';

    const SANDBOX_API_ENDPOINT = '';

    const TYPE_CONTENT = '';

    /**
     * @var string
     */
    protected $privateApiKey = '';

    /**
     * @var bool
     */
    protected $isLive = false;

    private $ch;

    /**
     * List of errors - https://staging.hit-pay.com/docs.html?shell#errors
     *
     * @var string[]
     */
    protected $errors = array(
        400 => 'Bad Request -- Your request is invalid.',
        401 => 'Unauthorized -- Your API key is wrong.',
        404 => 'Not Found -- The payment request could not be found.',
        500 => 'Internal Server Error -- We had a problem with our server. Try again later.',
    );

    /**
     * Request constructor.
     * @param $privateApiKey
     * @param bool $live
     * @throws \Exception
     */
    public function __construct($privateApiKey, $live = false)
    {
        if (!extension_loaded('curl')) {
            $this->ch = curl_init2();
        } else {
            $this->ch = curl_init();
        }

        $this->privateApiKey = $privateApiKey;
        $this->isLive = $live;
    }

    /**
     * @param $type PUT, DELETE, GET, POST
     * @param $path
     * @param array $request
     * @return bool
     * @throws \Exception
     */
    protected function request($type, $path, $request = array())
    {
        $endpoint = $this->isLive ? static::API_ENDPOINT : static::SANDBOX_API_ENDPOINT;
        if (!extension_loaded('curl')) {
            curl_setopt2($this->ch, CURLOPT_URL2, $endpoint . $path);
            curl_setopt2($this->ch, CURLOPT_HEADER2, false);
            curl_setopt2($this->ch, CURLOPT_SSL_VERIFYPEER2, false); 
            curl_setopt2($this->ch, CURLOPT_RETURNTRANSFER2, true);
            curl_setopt2($this->ch, CURLOPT_CUSTOMREQUEST2, $type);

            if (!empty($request)) {
                $request = http_build_query($request);
                curl_setopt2($this->ch, CURLOPT_POSTFIELDS2, $request);
            }

            curl_setopt2($this->ch, CURLOPT_HTTPHEADER2, $this->getHeaders());

            $result = curl_exec2($this->ch);
        } else {
            curl_setopt($this->ch, CURLOPT_URL, $endpoint . $path);
            curl_setopt($this->ch, CURLOPT_HEADER, false);
            curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, false); 
            curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, $type);

            if (!empty($request)) {
                $request = http_build_query($request);
                curl_setopt($this->ch, CURLOPT_POSTFIELDS, $request);
            }
            curl_setopt($this->ch, CURLOPT_HTTPHEADER, $this->getHeaders());

            $result = curl_exec($this->ch);
        }
        $result = !empty($result) ? json_decode($result) : null;

        $this->checkError($result);

        return $result;
    }

    /**
     * @param null $response
     * @return void
     * @throws \Exception
     */
    protected function checkError($response = null)
    {
        if (!extension_loaded('curl')) {
            $error = curl_error2($this->ch);
            $httpCode = curl_getinfo2($this->ch, CURLINFO_HTTP_CODE2);
        } else {
            $error = curl_error($this->ch);
            $httpCode = curl_getinfo($this->ch, CURLINFO_HTTP_CODE);
        }
        
        if (!empty($error)) {
            throw new \Exception($error);
        } elseif (isset($response->detail)) {
            throw new \Exception($response->detail);
        } elseif (isset($response->message)) {
            throw new \Exception($response->message.'.');
        } elseif ($httpCode != 200 && $httpCode != 201) {
            $message = isset($this->errors[$httpCode])
                ? $this->errors[$httpCode]
                : 'Error message does not exists.';
            throw new \Exception($message, $httpCode);
        }
    }

    /**
     * @return string[]
     */
    protected function getHeaders()
    {
        return [
            'Content-Type: ' . static::TYPE_CONTENT,
            'X-BUSINESS-API-KEY: ' . $this->privateApiKey,
            'X-Requested-With: XMLHttpRequest'
        ];
    }

    /**
     *
     */
    public function __destruct()
    {
        if (!extension_loaded('curl')) {
            curl_close2($this->ch);
        } else {
            curl_close($this->ch);
        }
    }
}