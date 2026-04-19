<?php
/**
 * Migration runner for ai-mms.
 *
 * Applies any .sql file in migrations/ that hasn't been recorded in the
 * schema_migrations tracking table. Files run in filename-sorted order.
 *
 * Reads DB credentials from app/etc/local.xml — same config the app uses,
 * so it targets whichever environment is running it (local or production).
 *
 * Usage:
 *   php migrations/apply.php              # apply pending migrations
 *   php migrations/apply.php --bootstrap  # mark ALL existing files as
 *                                         # already-applied without running.
 *                                         # Use once per DB before the first
 *                                         # deploy so pre-existing migrations
 *                                         # don't re-run.
 */

declare(strict_types=1);

$isBootstrap = in_array('--bootstrap', $argv, true);
$migrationsDir = __DIR__;
$localXmlPath = dirname(__DIR__) . '/app/etc/local.xml';

if (!is_file($localXmlPath)) {
    fwrite(STDERR, "error: local.xml not found at $localXmlPath\n");
    exit(1);
}

$xml = simplexml_load_file($localXmlPath);
$conn = $xml->global->resources->default_setup->connection;

$host = (string)$conn->host;
$port = ((string)$conn->port !== '') ? (int)$conn->port : 3306;
$user = (string)$conn->username;
$pass = (string)$conn->password;
$dbname = (string)$conn->dbname;

$dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8', $host, $port, $dbname);

try {
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    fwrite(STDERR, "db connection failed: " . $e->getMessage() . "\n");
    exit(1);
}

echo "connected: $user@$host:$port/$dbname\n";

// Detect "existing DB without migration ledger" — this happens on the first
// entrypoint run against a long-lived production DB where the .sql files
// were originally applied by hand. In that scenario we run in tolerant mode
// for this session only: DDL idempotency errors (column/table already
// exists, etc.) are swallowed so a rerun of ALTER TABLE ADD COLUMN etc.
// doesn't abort the whole chain. Data migrations (INSERT IGNORE,
// ON DUPLICATE KEY UPDATE) are already idempotent at the SQL level.
$ledgerExistedBefore = (bool)$pdo->query("SHOW TABLES LIKE 'schema_migrations'")->fetchColumn();

$pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (
    filename VARCHAR(255) NOT NULL PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8");

$tolerantMode = false;
if (!$ledgerExistedBefore) {
    try {
        $existingUsers = (int)$pdo->query("SELECT COUNT(*) FROM admin_user")->fetchColumn();
        if ($existingUsers > 0) {
            $tolerantMode = true;
            echo "bootstrap: schema_migrations table was missing and admin_user has "
               . "$existingUsers row(s) — enabling tolerant mode for this run\n";
        }
    } catch (PDOException $e) {
        // admin_user table doesn't exist — truly fresh DB, strict mode is correct.
    }
}

// MySQL error codes we treat as "already applied, safe to ignore" in tolerant mode.
$tolerantErrors = [
    1050, // ER_TABLE_EXISTS_ERROR
    1051, // ER_BAD_TABLE_ERROR (DROP TABLE on missing table)
    1060, // ER_DUP_FIELDNAME (ALTER TABLE ADD COLUMN on existing column)
    1061, // ER_DUP_KEYNAME (CREATE INDEX on existing index)
    1068, // ER_MULTIPLE_PRI_KEY
    1091, // ER_CANT_DROP_FIELD_OR_KEY (dropping missing column/key)
];

$files = glob($migrationsDir . '/*.sql') ?: [];
sort($files);

$appliedRows = $pdo->query("SELECT filename FROM schema_migrations")
    ->fetchAll(PDO::FETCH_COLUMN) ?: [];
$applied = array_flip($appliedRows);

if ($isBootstrap) {
    $count = 0;
    $insert = $pdo->prepare("INSERT INTO schema_migrations (filename) VALUES (?)");
    foreach ($files as $f) {
        $name = basename($f);
        if (!isset($applied[$name])) {
            $insert->execute([$name]);
            echo "bootstrap: $name\n";
            $count++;
        }
    }
    echo "bootstrapped $count migration(s) as already-applied\n";
    exit(0);
}

$pending = array_values(array_filter(
    $files,
    fn(string $f): bool => !isset($applied[basename($f)])
));

if (empty($pending)) {
    echo "no pending migrations\n";
    writeStatus($pdo, $tolerantMode);
    exit(0);
}

echo "pending: " . count($pending) . " migration(s)\n";

$insert = $pdo->prepare("INSERT INTO schema_migrations (filename) VALUES (?)");

foreach ($pending as $f) {
    $name = basename($f);
    echo "applying: $name ... ";

    $sql = file_get_contents($f);
    $statements = preg_split('/;\s*$/m', $sql);

    try {
        $tolerated = 0;
        foreach ($statements as $stmt) {
            $stmt = trim($stmt);
            if ($stmt === '') continue;
            try {
                $pdo->exec($stmt);
            } catch (PDOException $stmtErr) {
                $code = (int)($stmtErr->errorInfo[1] ?? 0);
                if ($tolerantMode && in_array($code, $tolerantErrors, true)) {
                    $tolerated++;
                    continue;
                }
                throw $stmtErr;
            }
        }
        $insert->execute([$name]);
        echo $tolerated > 0 ? "OK (tolerated $tolerated)\n" : "OK\n";
    } catch (PDOException $e) {
        echo "FAILED\n";
        fwrite(STDERR, "error in $name: " . $e->getMessage() . "\n");
        fwrite(STDERR, "aborting — later migrations will not run\n");
        exit(1);
    }
}

writeStatus($pdo, $tolerantMode);

echo "done\n";

// Post-run status file so external verification doesn't need DB access.
// Written to media/ which Apache serves, so a curl GET can confirm state.
// Always runs — even when there were no pending migrations — so the file
// reflects the *current* deploy, not the last one that had changes.
function writeStatus(PDO $pdo, bool $tolerantMode): void
{
    try {
        $userCount = (int)$pdo->query("SELECT COUNT(*) FROM admin_user")->fetchColumn();
        $roleMapCount = (int)$pdo->query("SELECT COUNT(*) FROM mmd_user_role_map")->fetchColumn();
        $distinctRoles = (int)$pdo->query("SELECT COUNT(DISTINCT role_code) FROM mmd_user_role_map")->fetchColumn();
        $usersWithoutRole = (int)$pdo->query(
            "SELECT COUNT(*) FROM admin_user u
             LEFT JOIN mmd_user_role_map m ON m.user_id = u.user_id
             WHERE m.user_id IS NULL"
        )->fetchColumn();
        $appliedCount = (int)$pdo->query("SELECT COUNT(*) FROM schema_migrations")->fetchColumn();

        // Hash a handful of frequently-edited admin templates so curl can
        // confirm remote picked up template changes (catches stale volume
        // mounts or cached output).
        $trackedFiles = [
            'management.phtml' => dirname(__DIR__) . '/app/design/adminhtml/default/default/template/rolemanager/management.phtml',
            'header.phtml'     => dirname(__DIR__) . '/app/design/adminhtml/default/default/template/page/header.phtml',
            'role_select.phtml'=> dirname(__DIR__) . '/app/design/adminhtml/default/default/template/rolemanager/role-select.phtml',
            'helper_data.php'  => dirname(__DIR__) . '/app/code/local/MMD/RoleManager/Helper/Data.php',
        ];
        $fileHashes = [];
        foreach ($trackedFiles as $label => $path) {
            $fileHashes[$label] = is_file($path) ? substr(md5_file($path), 0, 10) : null;
        }

        $status = [
            'timestamp'         => gmdate('c'),
            'tolerant_mode'     => $tolerantMode,
            'applied_count'     => $appliedCount,
            'admin_user_count'  => $userCount,
            'role_map_count'    => $roleMapCount,
            'distinct_roles'    => $distinctRoles,
            'users_without_role'=> $usersWithoutRole,
            'file_hashes'       => $fileHashes,
        ];

        $statusDir = dirname(__DIR__) . '/media';
        if (is_dir($statusDir) && is_writable($statusDir)) {
            file_put_contents(
                $statusDir . '/migrations-status.json',
                json_encode($status, JSON_PRETTY_PRINT) . "\n"
            );
        }
        echo "status: " . json_encode($status) . "\n";
    } catch (PDOException $e) {
        fwrite(STDERR, "status report failed (non-fatal): " . $e->getMessage() . "\n");
    }
}
