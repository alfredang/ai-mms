#!/usr/bin/env python3
"""PreToolUse hook (Edit|Write|MultiEdit|Bash): a person approves every course change.

HARD RULE (user rule 2026-11-20): the TMS availability sync cannot edit, hide or
disable a course, and nothing automated disables or hides one without a human
approving it. Incident: the sync hid 42 enabled courses and closed their
registration; a search for TGS-2026066894 could not find the course.

This hook does not block. It turns the tool call into a permission prompt
("ask"), so the admin sees exactly what is about to run and approves or rejects
it. The approver is angch@tertiaryinfotech.com: when the admin is not at the
keyboard, email the proposed change there and wait for the answer.

"""
import json
import re
import sys

SYNC_FILES = re.compile(r"MMD/Courses/(controllers/Api/AvailabilityController|Helper/Changenotice)\.php$")
CODE_PATHS = re.compile(r"/(app|migrations|scripts)/")

# Any catalogue write inside the sync code.
SYNC_WRITES = re.compile(
    r"updateAttributes\s*\(|product_action|->\s*setStatus\s*\(|->\s*setVisibility\s*\(|setIsSalable"
    r"|catalog_product_entity|cataloginventory|->\s*delete\s*\(",
    re.I,
)

# Disabling or hiding a course, in code, a migration or a shell command.
DISABLE = [
    (re.compile(r"(setStatus\s*\(|['\"]status['\"]\s*=>)\s*(2\b|[\w:]*STATUS_DISABLED)", re.I), "sets a course to Disabled"),
    (re.compile(r"(setVisibility\s*\(|['\"]visibility['\"]\s*=>)\s*(1\b|[\w:]*VISIBILITY_NOT_VISIBLE)", re.I), "sets a course to Not Visible Individually"),
    (re.compile(r"UPDATE\s+[`\w.{}$]*catalog_product_entity_int\b", re.I), "updates course status / visibility rows by SQL"),
    (re.compile(r"DELETE\s+FROM\s+[`\w.{}$]*catalog_product_entity\b", re.I), "deletes courses by SQL"),
]


def ask(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": (
                "COURSE CHANGE NEEDS HUMAN APPROVAL: " + reason + ". Rule 2026-11-20: the sync cannot "
                "edit, hide or disable a course, and no course is disabled or hidden without a person "
                "approving it (approver: angch@tertiaryinfotech.com). Approve only if you asked for this change."
            ),
        }
    }))
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    tool = data.get("tool_name", "")
    ti = data.get("tool_input") or {}

    if tool == "Bash":
        text = ti.get("command", "") or ""
        path = ""
    else:
        path = ti.get("file_path", "") or ""
        parts = [ti.get("new_string", ""), ti.get("content", "")]
        parts += [e.get("new_string", "") for e in (ti.get("edits") or []) if isinstance(e, dict)]
        text = "\n".join(p for p in parts if p)
        if "/.claude/" in path or path.endswith(".md"):
            sys.exit(0)

    if not text:
        sys.exit(0)

    if path and SYNC_FILES.search(path):
        m = SYNC_WRITES.search(text)
        if m:
            ask("this edit gives the availability sync a write to the catalogue (" + m.group(0).strip() + ")")

    if tool == "Bash" or CODE_PATHS.search(path):
        for rx, what in DISABLE:
            if rx.search(text):
                ask("this " + ("command" if tool == "Bash" else "edit to " + path.split("/ai-mms/")[-1]) + " " + what)
    sys.exit(0)


if __name__ == "__main__":
    main()
