# Changelog

## 1.1.7 - 2020-10-23

- Fixed an integration issue with Xtendo TrackingImport
- Fixed Apple Pay issue with countries that do not provide a city through the PRAPI (i.e. Japan)

## 1.1.6 - 2020-08-07

- Added support for GoMage LightChekcout

## 1.1.5 - 2020-07-15

- Fixed order migrations issue from the old Cryozonic modules

## 1.1.4 - 2020-07-06

- Fixed a CSRF issue

## 1.1.3 - 2020-05-13

- Added orders migration script when migrating from the former Cryozonic modules

## 1.1.2 - 2020-04-27

- Fixed an integration issue with some OneStepCheckout modules
- Fixed a webhooks configuration crash when table prefixes are used in the database

## 1.1.0 - 2020-02-28

- Added automatic webhook configuration support through the Magento admin area
- Added support for EcommerceTeam Tcheckout 1.0
- Integration fix with Magestore OSC

## 1.0.0 - 2019-11-13

Accept payments in Magento using the following payment methods:
- All major card networks, in 130+ currencies
- Apple Pay, Google Pay and Microsoft Pay
- Bancontact, available for customers in Belgium
- Giropay, available for customers in Germany
- iDEAL, available for customers in the Netherlands
- SEPA Direct Debit, Single Euro Payments Area cross-border bank transfers within the Economic and Monetary Union
- SOFORT, German, available in Austria, Belgium, Germany, Netherlands, Spain and Italy
- Multibanco, available for customers in Portugal
- Przelewy24 (P24), available for customers in Poland
- EPS (Electronic Payment Standard), available for customers in Austria (equivalent of iDEAL)
- Alipay
- WeChat Pay
- ACH (Automated Clearing House) bank transfers
