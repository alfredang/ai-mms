#!/usr/bin/env python3
"""Check a storefront trainer profile and emit its trainerprofile blob chunk.

Input file: plain text, exactly two paragraphs separated by one blank line.

  trainer_bio.py check bio.txt
  trainer_bio.py html  bio.txt "Dr. Alfred Ang" [--shared-profile]

Rules (user rule 2026-11-20): two paragraphs, about 500 characters in total
(450-550, spaces and any LinkedIn line included, name label excluded).
Exit 0 = pass, 1 = fail.
"""
import html
import re
import sys

MIN_CHARS, MAX_CHARS = 450, 550
HYPE = ("unlock", "elevate", "comprehensive", "cutting-edge", "seamless",
        "world-class", "passionate", "renowned", "seasoned", "leverage")


def load(path):
    text = open(path, encoding="utf-8").read().strip()
    return [re.sub(r"\s+", " ", p).strip() for p in re.split(r"\n\s*\n", text) if p.strip()]


def check(paras):
    errors = []
    if len(paras) != 2:
        errors.append("needs exactly 2 paragraphs, found %d" % len(paras))
    total = sum(len(p) for p in paras)
    if not MIN_CHARS <= total <= MAX_CHARS:
        errors.append("total %d characters, allowed %d-%d" % (total, MIN_CHARS, MAX_CHARS))
    joined = " ".join(paras)
    if re.search(r"[^\x20-\x7e]", joined):
        errors.append("non-ASCII character (em dash, curly quote, nbsp)")
    if re.search(r"<[a-z/]", joined, re.I):
        errors.append("HTML tag in the text; the tab shows plain text only")
    for word in HYPE:
        if re.search(r"\b%s" % re.escape(word), joined, re.I):
            errors.append("hype word: %s" % word)
    for i, p in enumerate(paras, 1):
        print("paragraph %d: %d characters" % (i, len(p)))
    print("total: %d characters" % total)
    for e in errors:
        print("FAIL: " + e)
    if not errors:
        print("OK")
    return not errors


def to_html(paras, name, shared):
    marker = "" if shared else " data-course-bio"
    # The newline pair between the paragraphs is what the Trainers tab renders
    # as the paragraph gap (it strips the tags and keeps the line breaks).
    return ("<p><strong%s>%s:</strong> %s</p>\n\n<p>%s</p>"
            % (marker, html.escape(name), html.escape(paras[0]), html.escape(paras[1])))


def main(argv):
    if len(argv) < 3 or argv[1] not in ("check", "html"):
        print(__doc__)
        return 1
    paras = load(argv[2])
    if not check(paras):
        return 1
    if argv[1] == "html":
        if len(argv) < 4:
            print("FAIL: html needs the trainer name")
            return 1
        print(to_html(paras, argv[3], "--shared-profile" in argv))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
