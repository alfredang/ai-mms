<?php

$installer = $this;

$installer->startSetup();

$methods = [
  "cryozonic_stripe" => "stripe_payments",
  "cryozonic_achpayments_ach" => "stripe_payments_ach",
  "cryozonic_europayments_bancontact" => "stripe_payments_bancontact",
  "cryozonic_europayments_giropay" => "stripe_payments_giropay",
  "cryozonic_europayments_ideal" => "stripe_payments_ideal",
  "cryozonic_europayments_multibanco" => "stripe_payments_multibanco",
  "cryozonic_europayments_eps" => "stripe_payments_eps",
  "cryozonic_europayments_p24" => "stripe_payments_p24",
  "cryozonic_europayments_sepa" => "stripe_payments_sepa",
  "cryozonic_europayments_sofort" => "stripe_payments_sofort",
  "cryozonic_chinapayments_alipay" => "stripe_payments_alipay",
  "cryozonic_chinapayments_wechat" => "stripe_payments_wechat"
];

$connection = $installer->getConnection();
$table = $installer->getTable('sales_flat_order_payment');

foreach ($methods as $fromMethod => $toMethod)
{
  $fields = array();
  $fields['method'] = $toMethod;
  $condition = array($connection->quoteInto('method=?', $fromMethod));
  $result = $connection->update($table, $fields, $condition);
}

$installer->endSetup();
