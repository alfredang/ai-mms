<?php
/**
 * One-time, CLI-only pilot receiver setup. Read credentials and the shared key
 * from stdin JSON; never print or persist them in source control.
 */
if (PHP_SAPI !== 'cli') {
    exit(1);
}
$input = json_decode(stream_get_contents(STDIN), true);
if (!is_array($input) || !isset($input['database_url'], $input['api_key'])) {
    fwrite(STDERR, "Expected database_url and api_key on stdin.\n");
    exit(1);
}
$parts = parse_url($input['database_url']);
$key = (string) $input['api_key'];
if (!$parts || ($parts['scheme'] ?? '') !== 'mysql' || !isset($parts['host'], $parts['path'], $parts['user'], $parts['pass']) || strlen($key) < 32 || preg_match('/[\r\n]/', $key)) {
    fwrite(STDERR, "Invalid database connection or shared key.\n");
    exit(1);
}
try {
    $pdo = new PDO(
        sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8', $parts['host'], $parts['port'] ?? 3306, ltrim($parts['path'], '/')),
        rawurldecode($parts['user']), rawurldecode($parts['pass']),
        array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION)
    );
    $pdo->beginTransaction();
    $check = $pdo->prepare("SELECT value FROM core_config_data WHERE scope='default' AND scope_id=0 AND path=? FOR UPDATE");
    $check->execute(array('mmd/tms_handover/api_key'));
    $previous = $check->fetchColumn();
    if ($previous !== false && $previous !== '' && !hash_equals((string) $previous, $key)) {
        throw new RuntimeException('An existing MMS handover key differs; setup will not rotate it.');
    }
    $settings = array(
        'enabled' => '1', 'api_key' => $key, 'course_allowlist' => 'C*',
        'provider_id' => 'tertiary-sg', 'calendar_id' => 'sales@tertiarycourses.com.sg',
        'website_id' => '1', 'public_origin' => 'https://www.tertiarycourses.com.sg',
        'pilot_start_date' => '2026-10-23', 'access_verified' => '0',
    );
    $write = $pdo->prepare("INSERT INTO core_config_data (scope,scope_id,path,value) VALUES ('default',0,?,?) ON DUPLICATE KEY UPDATE value=VALUES(value)");
    foreach ($settings as $name => $value) {
        $write->execute(array('mmd/tms_handover/'.$name, $value));
    }
    $pdo->commit();
    echo "MMS pilot receiver configured; participant access verification remains pending.\n";
} catch (Throwable $error) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    fwrite(STDERR, "MMS pilot receiver setup failed: ".$error->getMessage()."\n");
    exit(1);
}
