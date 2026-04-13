<?php

require_once '../vendor/autoload.php';

$apiKey = 'c0dbc3dd9a09cc4c1e0773e600a212f9f982616c1ddefe3c2f70d56311c6c3e1';
$salt = 'deG6ZBmiNg]9eMaSd]J;)DzKC,4{6^7a^suquQFgl>yfYQ_1r,[lQqr@/VjGs={2';

$hitPayClient = new \HitPay\Client($apiKey, false);

try {
    $request = new \HitPay\Request\CreatePayment();

    $request->setAmount(66)
        ->setCurrency('SGD');
    $result = $hitPayClient->createPayment($request);

    print_r($result);

    $data = $hitPayClient->getPaymentStatus($result->getId());
    print_r($data);

    $data = $hitPayClient->deletePaymentRequest($data->getId());
    print_r($data);

} catch (\Exception $e) {
    print_r($e->getMessage());
}