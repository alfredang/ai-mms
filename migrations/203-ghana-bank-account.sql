-- Add Ghana (website scope_id=3) bank account details for BankPayment module.
-- The customtext field already exists with Ecobank payment instructions;
-- this adds the structured bank_accounts field used in PDF invoices.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES (
    'websites',
    3,
    'payment/bankpayment/bank_accounts',
    'a:7:{s:14:"account_holder";a:2:{i:0;s:0:"";i:1;s:30:"Tertiary Courses Ghana Co. Ltd";}s:14:"account_number";a:2:{i:0;s:0:"";i:1;s:13:"1441002423045";}s:9:"bank_name";a:2:{i:0;s:0:"";i:1;s:13:"Ecobank Ghana";}s:9:"sort_code";a:2:{i:0;s:0:"";i:1;s:0:"";}s:11:"branch_code";a:2:{i:0;s:0:"";i:1;s:0:"";}s:4:"iban";a:2:{i:0;s:0:"";i:1;s:0:"";}s:3:"bic";a:2:{i:0;s:0:"";i:1;s:8:"ECOCGHAC";}}'
)
ON DUPLICATE KEY UPDATE value = VALUES(value);
