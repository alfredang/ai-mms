#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

php "$ROOT_DIR/scripts/tests/course_scheduler_logic_test.php"
php "$ROOT_DIR/scripts/tests/course_scheduler_structure_test.php"

echo "All course scheduler tests passed."
