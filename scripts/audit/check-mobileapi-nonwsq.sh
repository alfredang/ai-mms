#!/usr/bin/env bash
# HARD RULE (user rule 2026-11-22): the TC LMS apps (SG / MY / GH) and their API
# (MMD_MobileApi) are for NON-WSQ, C-prefix courses only. WSQ classes, SSG
# attendance and the TRAQOM survey belong to the TIA app (ai-lms-tms).
#
# Static guardrail: fails when the C-prefix filter is dropped from a class
# query, or WSQ-only features come back into the mobile API.
#
# Usage: scripts/audit/check-mobileapi-nonwsq.sh   (exit 0 = clean, 1 = a problem was found)
set -u
cd "$(dirname "$0")/../.." || exit 1
DIR="app/code/local/MMD/MobileApi"
fail=0
say() { echo "check-mobileapi-nonwsq: $*"; fail=1; }

count() { grep -c "$1" "$2" 2>/dev/null || true; }

# 1. The rule itself: one constant, C followed by a digit.
grep -q 'const RUN_SKU_SQL = "^C\[0-9\]";' "$DIR/Helper/Learner.php" \
    || say "Helper/Learner.php: RUN_SKU_SQL must stay \"^C[0-9]\" (non-WSQ course codes)"

# 2. Every class / order query keeps the filter.
[ "$(count 'RUN_SKU_SQL' "$DIR/Helper/Learner.php")" -ge 3 ] \
    || say "Helper/Learner.php: a learner query lost the RUN_SKU_SQL (C-prefix) filter"
awk '/function _runSelect/,/^    }/' "$DIR/Helper/Trainer.php" | grep -q 'RUN_SKU_SQL' \
    || say "Helper/Trainer.php: _runSelect must filter course_sku with RUN_SKU_SQL (trainer classes are non-WSQ only)"
awk '/function payouts/,/^    }/' "$DIR/Helper/Trainer.php" | grep -q 'RUN_SKU_SQL' \
    || say "Helper/Trainer.php: payouts() must keep only non-WSQ payouts"
[ "$(count 'nonWsq\|_nonWsqOrder' "$DIR/Helper/Staff.php")" -ge 8 ] \
    || say "Helper/Staff.php: a class, registration or course figure lost the non-WSQ filter"

# 3. WSQ-only features stay out of the mobile API.
if grep -rniE 'traqom|tpgateway|ssg[-_ ]?attendance|skillsfuture' "$DIR" --include='*.php' --include='*.xml' | grep -v '^$'; then
    say "WSQ / SSG feature found in MMD_MobileApi (lines above). It belongs to the TIA app, not here."
fi

[ "$fail" -eq 0 ] && echo "check-mobileapi-nonwsq: clean"
exit "$fail"
