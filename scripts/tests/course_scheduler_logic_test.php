<?php

declare(strict_types=1);

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

function parseSessionDate(string $raw): ?DateTimeImmutable {
    $clean = preg_replace('/\([^)]*\)/', '', $raw);
    $clean = trim((string)preg_replace('/\s+/', ' ', (string)$clean));
    $dt = DateTimeImmutable::createFromFormat('j M Y', $clean);
    if (!$dt) {
        $ts = strtotime($clean);
        if ($ts === false) return null;
        $dt = (new DateTimeImmutable('@' . $ts))->setTimezone(new DateTimeZone(date_default_timezone_get()));
    }
    return $dt->setTime(0, 0, 0);
}

function formatSessionDate(DateTimeImmutable $d): string {
    return $d->format('j M Y (D)');
}

function inferStepDays(array $dates): int {
    if (count($dates) < 2) return 7;
    usort($dates, fn($a, $b) => $a <=> $b);
    $freq = [];
    for ($i = 1; $i < count($dates); $i++) {
        $diff = (int) round(($dates[$i]->getTimestamp() - $dates[$i - 1]->getTimestamp()) / 86400);
        if ($diff <= 0) continue;
        $freq[$diff] = ($freq[$diff] ?? 0) + 1;
    }
    $best = 7;
    $bestN = -1;
    foreach ($freq as $k => $v) {
        if ($v > $bestN) {
            $best = (int)$k;
            $bestN = $v;
        }
    }
    return $best;
}

function generateAutoDates(array $existingTitles, ?string $rangeStartYmd, ?string $rangeEndYmd, int $count = 24): array {
    $known = [];
    foreach ($existingTitles as $title) {
        $d = parseSessionDate($title);
        if ($d) $known[] = $d;
    }
    if (!$known) return [];

    usort($known, fn($a, $b) => $a <=> $b);
    $step = inferStepDays($known);
    $cursor = end($known);

    $rangeStart = $rangeStartYmd ? DateTimeImmutable::createFromFormat('Y-m-d', $rangeStartYmd)?->setTime(0, 0, 0) : null;
    $rangeEnd = $rangeEndYmd ? DateTimeImmutable::createFromFormat('Y-m-d', $rangeEndYmd)?->setTime(0, 0, 0) : null;
    if ($rangeStart && $rangeEnd && $rangeEnd < $rangeStart) {
        return [];
    }

    $out = [];
    $guard = 0;
    while (count($out) < $count && $guard < 365) {
        $guard++;
        $cursor = $cursor->modify("+{$step} days");
        if ($rangeStart && $cursor < $rangeStart) continue;
        if ($rangeEnd && $cursor > $rangeEnd) break;
        $out[] = formatSessionDate($cursor);
    }

    return $out;
}

// 1) formatting / parsing
$d = parseSessionDate('21 Mar 2026 (Sat)');
assertTrue($d !== null, 'parse formatted session date');
assertTrue(formatSessionDate($d) === '21 Mar 2026 (Sat)', 'format session date to j M Y (D)');

// 2) inferred cadence: weekly
$step = inferStepDays([
    new DateTimeImmutable('2026-03-07'),
    new DateTimeImmutable('2026-03-14'),
    new DateTimeImmutable('2026-03-21'),
]);
assertTrue($step === 7, 'infer 7-day cadence from existing sessions');

// 3) auto-generation within range
$generated = generateAutoDates(
    ['07 Mar 2026 (Sat)', '14 Mar 2026 (Sat)', '21 Mar 2026 (Sat)'],
    '2026-03-22',
    '2026-04-30',
    24
);
assertTrue(count($generated) >= 1, 'auto scheduler generates at least one date in range');
assertTrue($generated[0] === '28 Mar 2026 (Sat)', 'first generated date follows inferred cadence');

// 4) invalid range should generate nothing
$badRange = generateAutoDates(['21 Mar 2026 (Sat)'], '2026-05-10', '2026-05-01', 24);
assertTrue(count($badRange) === 0, 'invalid range (to < from) returns no dates');

// 5) default behavior with one date -> 7-day cadence
$single = generateAutoDates(['21 Mar 2026 (Sat)'], null, null, 3);
assertTrue($single === ['28 Mar 2026 (Sat)', '4 Apr 2026 (Sat)', '11 Apr 2026 (Sat)'], 'single seed date defaults to 7-day cadence');

ok('course scheduler logic tests completed');
