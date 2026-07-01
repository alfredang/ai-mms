<?php
/**
 * Bidirectional Redis object-cache configurator for local.xml.
 *
 * Runs at every container start (via entrypoint.sh) when REDIS_HOST env is set
 * on non-country instances (SG prod). Country instances use generate-local-xml.sh.
 *
 * Bidirectional logic:
 *   - Cache block already in local.xml → verify Redis is still reachable.
 *       Healthy   → leave as-is (Redis cache stays active).
 *       Unhealthy → REMOVE the block so Magento falls back to file cache.
 *   - Cache block absent → verify Redis is reachable, then inject it.
 *       Healthy   → inject block (switch from file cache to Redis).
 *       Unhealthy → leave as-is (Magento stays on file cache).
 *
 * This guarantees the site degrades gracefully to file cache if Redis goes
 * down, and re-activates Redis automatically on the next deploy once it's back.
 *
 * Env vars:
 *   REDIS_HOST     — required (e.g. "redis")
 *   REDIS_PORT     — optional (default: 6379)
 *   REDIS_PASSWORD — optional (default: empty)
 */

$localXml = '/var/www/html/app/etc/local.xml';

if (!file_exists($localXml)) {
    fwrite(STDERR, "patch-redis-cache: local.xml not found, skipping\n");
    exit(0);
}

$xml = file_get_contents($localXml);
if ($xml === false) {
    fwrite(STDERR, "patch-redis-cache: could not read local.xml\n");
    exit(1);
}

$host    = getenv('REDIS_HOST')     ?: 'redis';
$port    = (int)(getenv('REDIS_PORT') ?: 6379);
$rawPass = getenv('REDIS_PASSWORD') ?: '';

// Verify Redis connection (used in both code paths below).
require_once '/var/www/html/vendor/autoload.php';
function redis_is_healthy(string $host, int $port, string $pass): bool {
    try {
        $redis = new Credis_Client($host, $port, 2.5);
        $redis->forceStandalone();
        if ($pass) {
            $redis->auth($pass);
        }
        $pong = $redis->ping();
        $redis->close();
        return ($pong === '+PONG' || $pong === true || $pong === 'PONG');
    } catch (Throwable $e) {
        return false;
    }
}

$blockPresent = strpos($xml, 'Cm_Cache_Backend_Redis') !== false;

if ($blockPresent) {
    // Block already in local.xml — verify Redis is still reachable.
    if (redis_is_healthy($host, $port, $rawPass)) {
        echo "patch-redis-cache: Redis healthy ({$host}:{$port}), cache block in place — no change\n";
        exit(0);
    }

    // Redis is gone or misconfigured — remove the block so Magento falls back
    // to file cache. The block will be re-added automatically on the next deploy
    // once Redis is reachable again.
    echo "patch-redis-cache: Redis unreachable — removing cache block, falling back to file cache\n";
    $stripped = preg_replace(
        '|\s*<cache>\s*<backend>Cm_Cache_Backend_Redis</backend>.*?</cache>|s',
        '',
        $xml
    );
    if ($stripped === null || $stripped === $xml) {
        fwrite(STDERR, "patch-redis-cache: WARNING — could not strip cache block from local.xml\n");
        exit(0); // non-fatal
    }
    file_put_contents($localXml, $stripped);
    exit(0);
}

// Block absent — try to add it.
if (!redis_is_healthy($host, $port, $rawPass)) {
    echo "patch-redis-cache: Redis unreachable or auth failed — leaving file cache in place\n";
    exit(0);
}

echo "patch-redis-cache: Redis connection verified ({$host}:{$port})\n";

$passXml = $rawPass ? htmlspecialchars($rawPass, ENT_XML1, 'UTF-8') : '';

$cacheBlock = <<<XML

        <cache>
            <backend>Cm_Cache_Backend_Redis</backend>
            <backend_options>
                <server><![CDATA[{$host}]]></server>
                <port>{$port}</port>
                <password><![CDATA[{$passXml}]]></password>
                <database>0</database>
                <persistent></persistent>
                <force_standalone>0</force_standalone>
                <connect_retries>1</connect_retries>
                <timeout>2.5</timeout>
                <read_timeout>2.5</read_timeout>
                <automatic_cleaning_factor>0</automatic_cleaning_factor>
                <compress_data>1</compress_data>
                <compress_tags>1</compress_tags>
                <compress_threshold>20480</compress_threshold>
                <compression_lib>gzip</compression_lib>
                <use_lua>0</use_lua>
            </backend_options>
        </cache>
XML;

$patched = str_replace('</global>', $cacheBlock . "\n    </global>", $xml);

if ($patched === $xml) {
    fwrite(STDERR, "patch-redis-cache: </global> not found in local.xml — cannot patch\n");
    exit(1);
}

if (file_put_contents($localXml, $patched) === false) {
    fwrite(STDERR, "patch-redis-cache: failed to write local.xml\n");
    exit(1);
}

echo "patch-redis-cache: Cm_Cache_Backend_Redis block injected (host={$host}:{$port}, db:0)\n";
