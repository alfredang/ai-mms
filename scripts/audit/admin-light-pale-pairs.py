#!/usr/bin/env python3
"""Static light-theme check: admin CSS rules (skin CSS + <style> blocks in admin templates) that set a
pale text colour (< 4.5:1 on white) and have NO [data-theme="light"] pair for the same selector.

Why: dark-only colours render invisible in light mode (2026-11-17: the My Classes "Confirmed" pill
was #6ee7b7 on a pale tint). Light mode is the default on every site, so every pale colour needs a pair.

Usage:  python3 scripts/audit/admin-light-pale-pairs.py          # report (exit 1 if any unpaired)
        python3 scripts/audit/admin-light-pale-pairs.py --emit   # print generated light rules (hue-mapped)
Paste --emit output into the "LIGHT THEME v2" block at the end of admin-dashboard.css, or better,
write a hand-made light pair / use a token. Skips white text, rules that paint their own solid
background, pseudo-elements, @media rules, and the standalone login / role-select pages."""
import re, sys, glob, colorsys, collections, json
import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')) + '/'
CSS = ['admin-dashboard','dark-theme','sidebar-nav','auditfix','rolemanager','admin-header','admin-components','admin-layout','instant-nav']
LIGHT = '[data-theme="light"]'

def blocks_from(text):
    """yield (selector, body, depth_at_media) for every style rule; skips @keyframes/@font-face."""
    out = []
    def walk(s, in_media):
        pos = 0
        while pos < len(s):
            if s.startswith('/*', pos):
                e = s.find('*/', pos + 2); pos = len(s) if e < 0 else e + 2; continue
            j = pos
            while j < len(s) and s[j] not in '{}':
                if s.startswith('/*', j):
                    e = s.find('*/', j + 2); j = len(s) if e < 0 else e + 2; continue
                j += 1
            if j >= len(s): break
            if s[j] == '}': pos = j + 1; continue
            sel = re.sub(r'/\*.*?\*/', '', s[pos:j], flags=re.S).strip()
            depth, k = 1, j + 1
            while k < len(s) and depth:
                if s.startswith('/*', k):
                    e = s.find('*/', k + 2); k = len(s) if e < 0 else e + 2; continue
                depth += (s[k] == '{') - (s[k] == '}'); k += 1
            body = s[j + 1:k - 1]
            if sel.startswith('@media') or sel.startswith('@supports'): walk(body, True)
            elif sel.startswith('@'): pass
            else: out.append((sel, body, in_media))
            pos = k
    walk(text, False)
    return out

def lum(h):
    c = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    c = [x / 12.92 if x <= .03928 else ((x + .055) / 1.055) ** 2.4 for x in c]
    return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]
def norm(h):
    h = h.lower(); return '#' + ''.join(ch * 2 for ch in h[1:]) if len(h) == 4 else h
def contrast_white(h): return 1.05 / (lum(h) + .05)

def target(h):
    r, g, b = (int(h[i:i+2], 16) / 255 for i in (1, 3, 5))
    hh, l, _s = colorsys.rgb_to_hls(r, g, b); hue = hh * 360
    chroma = max(r, g, b) - min(r, g, b)
    if chroma < 0.2: return 'var(--t1)' if l > 0.9 else ('var(--t2)' if l > 0.72 else 'var(--t4)')
    if hue < 15 or hue >= 345: return 'var(--red)'
    if hue < 40: return 'var(--orange)'
    if hue < 65: return 'var(--yellow)'
    if hue < 170: return 'var(--green)'
    if hue < 200: return 'var(--lt-cyan, #0e7490)'
    if hue < 250: return 'var(--blue)'
    if hue < 295: return 'var(--lt-violet, #6d28d9)'
    return '#be185d'

sources = {}
for n in CSS: sources['css/' + n] = open(ROOT + 'skin/adminhtml/default/default/' + n + '.css', encoding='utf-8').read()
for f in glob.glob(ROOT + 'app/design/adminhtml/default/default/template/**/*.phtml', recursive=True):
    t = open(f, encoding='utf-8', errors='ignore').read()
    st = ''.join(m.group(1) for m in re.finditer(r'<style[^>]*>(.*?)</style>', t, re.S))
    rel = f.split('/template/')[1]
    if rel in ('login.phtml','forgotpassword.phtml','resetforgottenpassword.phtml','rolemanager/role-select.phtml','rolemanager/learner-login.phtml','page/menu.phtml') or 'preview' in rel or 'marketing/templates/' in rel: continue
    if st: sources['tpl/' + rel] = re.sub(r'<\?php.*?\?>', '', st, flags=re.S)

rules = []
for src, text in sources.items():
    for sel, body, in_media in blocks_from(text): rules.append((src, sel, body, in_media))

def last_compound(s):
    s = re.sub(r':(hover|focus|active|focus-visible|focus-within|visited)\b', '', s.strip())
    return re.split(r'\s+|>|\+|~', s.strip())[-1]

paired = set()
for src, sel, body, _ in rules:
    for part in sel.split(','):
        if LIGHT in part and ':not(' + LIGHT not in part: paired.add(last_compound(part))

SKIP_SEL = re.compile(r'::?(before|after|placeholder|selection|-webkit)|\[data-theme|:root|^html|mmd-wa|mmd-tip|sidebar|tooltip|\.mmd-processing|#mmd-wa|lcd-detail-img|cover|hero|preview|email|print')
gen = collections.defaultdict(list); stats = collections.Counter()
for src, sel, body, in_media in rules:
    if in_media: continue
    m = re.search(r'(?:^|;|\s)color\s*:\s*(#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b)', body)
    if not m: continue
    h = norm(m.group(1))
    if h in ('#ffffff',) or contrast_white(h) >= 4.5: continue
    if re.search(r'background(-color)?\s*:\s*(#|rgb\((?!.*,\s*0?\.[0-4]\d*\s*\))|linear|var\(--(d[2-6]|blue|brand|btn))', body): stats['own-bg'] += 1; continue
    for part in [p.strip() for p in sel.split(',') if p.strip()]:
        if LIGHT in part: continue
        if SKIP_SEL.search(part): stats['skip-sel'] += 1; continue
        if last_compound(part) in paired: stats['paired'] += 1; continue
        pre = ':root[data-theme="light"] ' if part.startswith('body') else ':root[data-theme="light"] body '
        gen[target(h)].append((pre + part, src, h))
        stats['generated'] += 1

if '--emit' in sys.argv:
    out = ['', '/* 10. Generated (tools: pale_pairs) — dark-only rules that set a pale text colour (< 4.5:1 on white)',
           '   with no light-theme pair anywhere, mapped by hue to the light palette. Colour only. */']
    for tgt, items in sorted(gen.items()):
        sels = sorted(set(s for s, _, _ in items))
        out.append(',\n'.join(sels) + ' { color: %s !important; }' % tgt)
    print('\n'.join(out))
else:
    print(dict(stats))
    print('unpaired pale selectors:', stats['generated'])
    by_src = collections.Counter(src for items in gen.values() for _, src, _ in items)
    print(by_src.most_common(25))
    for tgt, items in sorted(gen.items()): print(tgt, len(items), sorted(set(h for _, _, h in items))[:12])
    sys.exit(1 if stats['generated'] else 0)
