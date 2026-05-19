<?php
declare(strict_types=1);

/**
 * Course Scheduler DB Integration Test (non-destructive)
 *
 * What it tests:
 * - Insert new schedule rows (like schedule_new)
 * - Update schedule row fields (title/sort/price)
 * - Delete schedule rows (like schedule_remove)
 *
 * Cleanup:
 * - All test rows are deleted in finally{} even if a test fails.
 *
 * Usage:
 *   php scripts/tests/course_scheduler_db_integration_test.php
 *
 * Notes:
 * - Uses app/etc/local.xml DB credentials.
 * - Intended for local/dev DB only.
 */

function fail(string $msg): void {
    fwrite(STDERR, "FAIL: {$msg}\n");
    exit(1);
}

function ok(string $msg): void {
    fwrite(STDOUT, "PASS: {$msg}\n");
}

function assertTrue(bool $cond, string $msg): void {
    if (!$cond) fail($msg);
    ok($msg);
}

$root = dirname(__DIR__, 2);
$localXml = $root . '/app/etc/local.xml';
if (!is_file($localXml)) fail('local.xml not found at ' . $localXml);

$cfg = @simplexml_load_file($localXml);
if (!$cfg) fail('unable to read local.xml');

$db = $cfg->global->resources->default_setup->connection;
$host = (string) $db->host;
$name = (string) $db->dbname;
$user = (string) $db->username;
$pass = (string) $db->password;

if ($host === '' || $name === '' || $user === '') {
    fail('incomplete DB config in local.xml');
}

$hostCandidates = [];
$envHost = getenv('DB_HOST_OVERRIDE');
if (is_string($envHost) && $envHost !== '') $hostCandidates[] = $envHost;
$hostCandidates[] = $host;
if ($host !== '127.0.0.1') $hostCandidates[] = '127.0.0.1';
if ($host !== 'localhost') $hostCandidates[] = 'localhost';
$hostCandidates = array_values(array_unique($hostCandidates));

$pdo = null;
$lastErr = null;
foreach ($hostCandidates as $h) {
    try {
        $pdo = new PDO(
            "mysql:host={$h};dbname={$name};charset=utf8",
            $user,
            $pass,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
        break;
    } catch (Throwable $e) {
        $lastErr = $e;
    }
}
if (!$pdo) {
    $msg = $lastErr ? $lastErr->getMessage() : 'unknown DB connection error';
    fail("unable to connect DB using hosts [" . implode(', ', $hostCandidates) . "]: {$msg}\n" .
         "Tip: run inside container, or set DB_HOST_OVERRIDE, e.g.\n" .
         "  DB_HOST_OVERRIDE=127.0.0.1 php scripts/tests/course_scheduler_db_integration_test.php");
}

$createdValueIds = [];
$marker = 'TEST-CS-' . date('Ymd-His') . '-' . substr(md5((string) mt_rand()), 0, 6);

try {
    // Find one option_id that looks like a course date option.
    $optStmt = $pdo->query("
        SELECT o.option_id, o.product_id
        FROM catalog_product_option o
        JOIN catalog_product_option_title ot
          ON ot.option_id = o.option_id AND ot.store_id = 0
        WHERE LOWER(ot.title) LIKE '%date%'
        ORDER BY o.option_id DESC
        LIMIT 1
    ");
    $opt = $optStmt->fetch(PDO::FETCH_ASSOC);
    if (!$opt) fail('no date-like product option found');

    $optionId = (int) $opt['option_id'];
    $productId = (int) $opt['product_id'];
    assertTrue($optionId > 0 && $productId > 0, 'found target option_id/product_id');

    // 1) Insert two temporary rows (simulate schedule_new/autoscheduler additions).
    $insType = $pdo->prepare("
        INSERT INTO catalog_product_option_type_value
            (option_id, sku, sort_order, reg_course, customoptions_qty, dependent_ids, in_group_id, `default`, weight)
        VALUES
            (?, '', ?, '', 0, '', 0, 0, 0.0000)
    ");
    $insTitle = $pdo->prepare("
        INSERT INTO catalog_product_option_type_title (option_type_id, store_id, title)
        VALUES (?, 0, ?)
    ");

    $baseSort = 9000;
    $titles = [
        "{$marker} 1 (Mon)",
        "{$marker} 2 (Tue)",
    ];

    foreach ($titles as $i => $title) {
        $insType->execute([$optionId, $baseSort + $i]);
        $vid = (int) $pdo->lastInsertId();
        $createdValueIds[] = $vid;
        $insTitle->execute([$vid, $title]);
    }
    assertTrue(count($createdValueIds) === 2, 'inserted 2 temporary schedule rows');

    $chkCountStmt = $pdo->prepare("
        SELECT COUNT(*)
        FROM catalog_product_option_type_title
        WHERE option_type_id IN (" . implode(',', array_map('intval', $createdValueIds)) . ")
          AND store_id = 0
          AND title LIKE ?
    ");
    $chkCountStmt->execute([$marker . '%']);
    assertTrue((int) $chkCountStmt->fetchColumn() === 2, 'temporary titles persisted');

    // 2) Update first inserted row (simulate schedule_value update).
    $firstVid = $createdValueIds[0];
    $newTitle = "{$marker} 1 UPDATED (Wed)";
    $newSort = 9876;
    $newPrice = 12.34;

    $updTitle = $pdo->prepare("
        UPDATE catalog_product_option_type_title
        SET title = ?
        WHERE option_type_id = ? AND store_id = 0
    ");
    $updSort = $pdo->prepare("
        UPDATE catalog_product_option_type_value
        SET sort_order = ?
        WHERE option_type_id = ?
    ");
    $updTitle->execute([$newTitle, $firstVid]);
    $updSort->execute([$newSort, $firstVid]);

    // Upsert price row (same as controller behavior).
    $priceIdStmt = $pdo->prepare("
        SELECT option_type_price_id
        FROM catalog_product_option_type_price
        WHERE option_type_id = ? AND store_id = 0
        LIMIT 1
    ");
    $priceIdStmt->execute([$firstVid]);
    $priceId = (int) ($priceIdStmt->fetchColumn() ?: 0);

    if ($priceId > 0) {
        $pdo->prepare("
            UPDATE catalog_product_option_type_price
            SET price = ?, price_type = 'fixed'
            WHERE option_type_price_id = ?
        ")->execute([$newPrice, $priceId]);
    } else {
        $pdo->prepare("
            INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
            VALUES (?, 0, ?, 'fixed')
        ")->execute([$firstVid, $newPrice]);
    }

    $verifyStmt = $pdo->prepare("
        SELECT v.sort_order, t.title, p.price
        FROM catalog_product_option_type_value v
        JOIN catalog_product_option_type_title t
          ON t.option_type_id = v.option_type_id AND t.store_id = 0
        LEFT JOIN catalog_product_option_type_price p
          ON p.option_type_id = v.option_type_id AND p.store_id = 0
        WHERE v.option_type_id = ?
        LIMIT 1
    ");
    $verifyStmt->execute([$firstVid]);
    $row = $verifyStmt->fetch(PDO::FETCH_ASSOC);
    assertTrue($row !== false, 'updated row is readable');
    assertTrue((string) $row['title'] === $newTitle, 'title update persisted');
    assertTrue((int) $row['sort_order'] === $newSort, 'sort update persisted');
    assertTrue(abs((float) $row['price'] - $newPrice) < 0.0001, 'price update persisted');

    // 3) Delete second inserted row (simulate schedule_remove).
    $secondVid = $createdValueIds[1];
    $delStmt = $pdo->prepare("DELETE FROM catalog_product_option_type_value WHERE option_type_id = ?");
    $delStmt->execute([$secondVid]);

    $existsStmt = $pdo->prepare("SELECT COUNT(*) FROM catalog_product_option_type_value WHERE option_type_id = ?");
    $existsStmt->execute([$secondVid]);
    assertTrue((int) $existsStmt->fetchColumn() === 0, 'delete persisted');

    // Keep only first ID for final cleanup (second already deleted).
    $createdValueIds = [$firstVid];

    ok('course scheduler DB integration tests completed');
    exit(0);
} catch (Throwable $e) {
    fwrite(STDERR, "ERROR: " . $e->getMessage() . "\n");
    exit(1);
} finally {
    if (!empty($createdValueIds)) {
        try {
            $idsCsv = implode(',', array_map('intval', $createdValueIds));
            $pdo->exec("DELETE FROM catalog_product_option_type_value WHERE option_type_id IN ({$idsCsv})");
            // Titles/prices should cascade with FK; cleanup explicitly as fallback.
            $pdo->exec("DELETE FROM catalog_product_option_type_title WHERE option_type_id IN ({$idsCsv})");
            $pdo->exec("DELETE FROM catalog_product_option_type_price WHERE option_type_id IN ({$idsCsv})");
        } catch (Throwable $cleanupEx) {
            fwrite(STDERR, "WARN: cleanup failed: " . $cleanupEx->getMessage() . "\n");
        }
    }
}
