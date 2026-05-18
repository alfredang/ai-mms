<?php

declare(strict_types=1);

function fail(string $msg): void {
    fwrite(STDERR, "FAIL: {$msg}\n");
    exit(1);
}

function ok(string $msg): void {
    fwrite(STDOUT, "PASS: {$msg}\n");
}

function expectContains(string $haystack, string $needle, string $msg): void {
    if (strpos($haystack, $needle) === false) {
        fail($msg . " (missing: {$needle})");
    }
    ok($msg);
}

$root = dirname(__DIR__, 2);
$template = $root . '/app/design/adminhtml/default/default/template/dashboard/index.phtml';
$controller = $root . '/app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php';

if (!is_file($template)) fail('template file not found: ' . $template);
if (!is_file($controller)) fail('controller file not found: ' . $controller);

$t = file_get_contents($template);
$c = file_get_contents($controller);
if ($t === false) fail('unable to read scheduler template');
if ($c === false) fail('unable to read scheduler controller');

// UI: course scheduler container + controls
expectContains($t, 'Course Scheduler', 'course scheduler section exists');
expectContains($t, 'id="dcf-scheduler-date-select"', 'current sessions dropdown exists');
expectContains($t, 'id="dcf-scheduler-update-btn"', 'edit button exists');
expectContains($t, 'id="dcf-scheduler-add-date"', 'add date input exists');
expectContains($t, 'id="dcf-scheduler-add-btn"', 'add date button exists');
expectContains($t, 'id="dcf-scheduler-auto-start"', 'auto scheduler from-date exists');
expectContains($t, 'id="dcf-scheduler-auto-end"', 'auto scheduler to-date exists');
expectContains($t, 'id="dcf-scheduler-auto-btn"', 'auto scheduler action button exists');

// Format normalization expectations
expectContains($t, "date('j M Y (D)'", 'server-side dropdown date format uses j M Y (D)');
expectContains($t, "return day + ' ' + mon + ' ' + yr + ' (' + wk + ')';", 'client-side formatSessionDate uses j M Y (D)');

// Range guard expectations (to cannot be earlier than from)
expectContains($t, 'autoEndEl.min = from;', 'detail scheduler enforces to-date min');
expectContains($t, 'rangeEnd.getTime() < rangeStart.getTime()', 'detail scheduler guards invalid date range');
expectContains($t, 'csSyncRange', 'schedule tab has range sync function');

// Save pipeline expectations
expectContains($c, "getParam('schedule_remove'", 'controller handles schedule_remove');
expectContains($c, "getParam('schedule_value'", 'controller handles schedule_value');
expectContains($c, "getParam('schedule_new'", 'controller handles schedule_new');
expectContains($c, 'insert($_optTypeTitle', 'controller inserts new schedule titles');
expectContains($c, "update(\n                            \$_optTypeTitle", 'controller updates existing schedule titles');

ok('course scheduler structure tests completed');
