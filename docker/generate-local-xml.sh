#!/bin/bash
# Generates app/etc/local.xml from environment variables.
# Called by entrypoint.sh in country mode (MMS_MODE=country) to replace the
# SG-specific local.xml baked into the image with one pointing at the bundled
# MySQL service ('db') and including Redis session/cache blocks.
#
# Crypt key priority: MMS_CRYPT_KEY env → /var/www/html/media/.crypt_key
# (persisted on the media volume across deploys) → generate new + warn.
#
# Required env: MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD
# Optional env: MYSQL_HOST (default: db), MMS_CRYPT_KEY, MMS_MODE (default: country)
#
# Admin frontName is NOT env-driven — it is a fixed 'adminlogin' literal below,
# matching SG (whose local.xml hardcodes it). In Magento/OpenMage the admin
# route name lives in local.xml <admin>/<routers>/<adminhtml>/<args>/<frontName>
# (never .htaccess — that's Apache rewrite config with no concept of the admin
# route). Keeping it a literal means MY/GH follow SG exactly, with no per-instance
# Coolify env var to drift out of sync. Change it in ONE place (here + SG's
# local.xml) if the admin URL ever moves again.

set -e

LOCAL_XML=/var/www/html/app/etc/local.xml

php << 'PHPEOF'
<?php
$localXml    = '/var/www/html/app/etc/local.xml';
$cryptKeyFile = '/var/www/html/media/.crypt_key';

$dbHost    = getenv('MYSQL_HOST')           ?: 'db';
$dbName    = getenv('MYSQL_DATABASE')       ?: '';
$dbUser    = getenv('MYSQL_USER')           ?: '';
$dbPass    = getenv('MYSQL_PASSWORD')       ?: '';
$frontName = 'adminlogin'; // fixed, matches SG's local.xml — NOT env-driven
$mode      = getenv('MMS_MODE')             ?: 'country';
$cryptKey  = getenv('MMS_CRYPT_KEY')        ?: '';

foreach (['MYSQL_DATABASE' => $dbName, 'MYSQL_USER' => $dbUser, 'MYSQL_PASSWORD' => $dbPass] as $var => $val) {
    if (empty($val)) {
        fwrite(STDERR, "generate-local-xml: ERROR — {$var} env var is required\n");
        exit(1);
    }
}

// Crypt key: env → persisted volume file → generate new
if (empty($cryptKey)) {
    if (file_exists($cryptKeyFile)) {
        $cryptKey = trim(file_get_contents($cryptKeyFile));
        echo "generate-local-xml: loaded crypt key from persistent volume\n";
    } else {
        $cryptKey = bin2hex(random_bytes(16));
        @mkdir(dirname($cryptKeyFile), 0755, true);
        file_put_contents($cryptKeyFile, $cryptKey);
        @chmod($cryptKeyFile, 0600);
        echo "generate-local-xml: *** WARNING — generated new crypt key ***\n";
        echo "generate-local-xml: Pin it permanently: set MMS_CRYPT_KEY='{$cryptKey}' in Coolify env.\n";
    }
}

$e = fn(string $s): string => htmlspecialchars($s, ENT_XML1 | ENT_COMPAT, 'UTF-8');

// Country instances bundle Redis (P7) — include session + cache blocks.
$redisBlocks = '';
if ($mode === 'country') {
    $redisBlocks = <<<XML

        <redis_session>
            <host>redis</host>
            <port>6379</port>
            <password></password>
            <timeout>2.5</timeout>
            <persistent></persistent>
            <db>1</db>
            <compression_threshold>2048</compression_threshold>
            <compression_lib>gzip</compression_lib>
            <log_level>1</log_level>
            <max_concurrency>6</max_concurrency>
            <break_after_frontend>5</break_after_frontend>
            <break_after_adminhtml>30</break_after_adminhtml>
            <first_lifetime>600</first_lifetime>
            <bot_first_lifetime>60</bot_first_lifetime>
            <bot_lifetime>7200</bot_lifetime>
            <disable_locking>0</disable_locking>
            <min_lifetime>60</min_lifetime>
            <max_lifetime>2592000</max_lifetime>
        </redis_session>
        <cache>
            <backend>Cm_Cache_Backend_Redis</backend>
            <backend_options>
                <server>redis</server>
                <port>6379</port>
                <database>0</database>
                <persistent></persistent>
                <password></password>
                <force_standalone>0</force_standalone>
                <connect_retries>1</connect_retries>
                <read_timeout>10</read_timeout>
                <automatic_cleaning_factor>0</automatic_cleaning_factor>
                <compress_data>1</compress_data>
                <compress_tags>1</compress_tags>
                <compress_threshold>20480</compress_threshold>
                <compression_lib>gzip</compression_lib>
                <use_lua>0</use_lua>
            </backend_options>
        </cache>
XML;
}

$installDate = gmdate('D, d M Y H:i:s') . ' +0000';

$xml = <<<XML
<?xml version="1.0"?>
<config>
    <global>
        <install>
            <date><![CDATA[{$installDate}]]></date>
        </install>
        <crypt>
            <key><![CDATA[{$cryptKey}]]></key>
        </crypt>
        <disable_local_modules>false</disable_local_modules>
        <resources>
            <db>
                <table_prefix><![CDATA[]]></table_prefix>
            </db>
            <default_setup>
                <connection>
                    <host><![CDATA[{$e($dbHost)}]]></host>
                    <username><![CDATA[{$e($dbUser)}]]></username>
                    <password><![CDATA[{$e($dbPass)}]]></password>
                    <dbname><![CDATA[{$e($dbName)}]]></dbname>
                    <initStatements><![CDATA[SET NAMES utf8]]></initStatements>
                    <model><![CDATA[mysql4]]></model>
                    <type><![CDATA[pdo_mysql]]></type>
                    <pdoType><![CDATA[]]></pdoType>
                    <active>1</active>
                </connection>
            </default_setup>
        </resources>
        <session_save><![CDATA[db]]></session_save>{$redisBlocks}
        <mmd_marketing>
            <api>
                <anthropic_key><![CDATA[]]></anthropic_key>
                <anthropic_model><![CDATA[claude-sonnet-4-6]]></anthropic_model>
                <mailerlite_key><![CDATA[]]></mailerlite_key>
                <from_name><![CDATA[Tertiary Infotech Academy]]></from_name>
                <from_email><![CDATA[noreply@tertiaryinfotech.com]]></from_email>
            </api>
        </mmd_marketing>
    </global>
    <admin>
        <routers>
            <adminhtml>
                <args>
                    <frontName><![CDATA[{$e($frontName)}]]></frontName>
                </args>
            </adminhtml>
        </routers>
    </admin>
</config>
XML;

file_put_contents($localXml, $xml);
@chown($localXml, 'www-data');
@chmod($localXml, 0640);
echo "generate-local-xml: generated {$localXml} (mode={$mode}, db={$dbHost}/{$dbName})\n";
PHPEOF
