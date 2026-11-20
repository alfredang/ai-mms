#!/usr/bin/env node
// Whole-admin theme review: every page a role can reach, checked in light (or dark) mode.
//
// Why: the 14-page contrast gate missed whole areas (2026-11-19: the Marketing "Newsletters"
// pipeline cards stayed dark navy in light mode, and text darkened for light mode became
// unreadable on them). This crawls each role's sidebar / header / dashboard links and reports
//   - TEXT  : text under WCAG AA (4.5:1, 3:1 large), disabled controls exempt
//   - DARK  : large near-black neutral surfaces painted while the theme is light
// READ-ONLY: GET navigations only; links that look like actions are never followed.
//
// Usage:
//   node scripts/audit/admin-theme-crawl.mjs collect <out.json> role=<adminhtml cookie> [role=cookie ...]
//   node scripts/audit/admin-theme-crawl.mjs scan <pages.json> <out.json> [shard i/n] [shotDir]
// Env: CHROME, PUPPETEER_CORE, BASE (default http://localhost:8080), THEME (light|dark).
import { createRequire } from 'module';
import os from 'os'; import path from 'path'; import fs from 'fs';
const require = createRequire(import.meta.url);
const puppeteer = require(process.env.PUPPETEER_CORE || path.join(os.homedir(), '.hermes/node/lib/node_modules/hyperframes/node_modules/puppeteer-core'));
const CHROME = process.env.CHROME || (() => { const root = path.join(os.homedir(), 'Library/Caches/ms-playwright');
  const d = fs.existsSync(root) && fs.readdirSync(root).filter(x => x.startsWith('chromium_headless_shell')).sort().pop();
  return d ? path.join(root, d, 'chrome-headless-shell-mac-arm64/chrome-headless-shell') : ''; })();
const BASE = process.env.BASE || 'http://localhost:8080';
const THEME = process.env.THEME || 'light';
const UNSAFE = /logout|delete|remove|massDelete|export|flush|clean|reindex|sync|send|generate|\/run\b|backup|approve|reject|cancel|unhold|hold|invoice|refund|duplicate|\/save|switch|impersonat|download|print|rollback|reset|install|\/key\/[a-f0-9]+\/.*(id|_id)\/\d+\/.*status/i;
const norm = u => u.replace(/\/key\/[a-f0-9]+\/?/, '/').replace(/([?&])key=[a-f0-9]+/, '$1').replace(/[?&]$/, '');

async function open(sid) {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'mms-crawl-'));
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, userDataDir: profile, args: ['--no-sandbox'] });
  const page = await browser.newPage(); await page.setViewport({ width: 1440, height: 900 });
  await page.setCookie({ name: 'adminhtml', value: sid, domain: new URL(BASE).hostname, path: '/' });
  await page.evaluateOnNewDocument(t => { try { localStorage.setItem('admin-theme', t); localStorage.setItem('admin-theme-v', '3'); } catch (e) {} }, THEME);
  return { browser, page, profile };
}

const [mode, ...rest] = process.argv.slice(2);
if (mode === 'collect') {
  const out = rest[0]; const pages = []; const seen = new Set();
  for (const spec of rest.slice(1)) {
    const [role, sid] = spec.split('=');
    const { browser, page, profile } = await open(sid);
    await page.goto(BASE + '/index.php/adminlogin/dashboard/', { waitUntil: 'networkidle2', timeout: 120000 });
    const links = await page.evaluate(() => [...document.querySelectorAll('a[href]')].map(a => a.href).filter(h => h.startsWith(location.origin) && h.includes('/adminlogin/')));
    const add = u => { const n = norm(u); if (UNSAFE.test(n)) return; const isDash = /\/dashboard\/?([?#]|$)/.test(n);
      const key = isDash ? role + '|' + n : n; if (seen.has(key)) return; seen.add(key); pages.push({ role, sid, url: n.replace(BASE, '') }); };
    add(BASE + '/index.php/adminlogin/dashboard/'); links.forEach(add);
    console.log(role, links.length, 'links');
    await browser.close(); fs.rmSync(profile, { recursive: true, force: true });
  }
  fs.writeFileSync(out, JSON.stringify(pages, null, 0)); console.log('views:', pages.length);
} else if (mode === 'scan') {
  const all = JSON.parse(fs.readFileSync(rest[0])); const outFile = rest[1];
  const [si, sn] = (rest[2] || '0/1').split('/').map(Number); const shotDir = rest[3];
  const mine = all.filter((_, i) => i % sn === si); const results = []; let cur = null, sess = null;
  for (const p of mine) {
    if (!sess || cur !== p.sid) { if (sess) { await sess.browser.close(); fs.rmSync(sess.profile, { recursive: true, force: true }); } sess = await open(p.sid); cur = p.sid;
      sess.errs = []; sess.page.on('pageerror', e => sess.errs.push(String(e.message).slice(0, 140))); }
    const { page } = sess; sess.errs.length = 0; let res = { role: p.role, url: p.url };
    try {
      await page.goto('about:blank'); const r = await page.goto(BASE + p.url, { waitUntil: 'networkidle2', timeout: 90000 });
      await new Promise(r => setTimeout(r, 900));
      res.status = r ? r.status() : 0; res.final = norm(page.url()).replace(BASE, '');
      Object.assign(res, await page.evaluate(() => {
        const parse = c => { const m = c.match(/rgba?\(([^)]+)\)/); if (!m) return null; const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number); return { r: p[0], g: p[1], b: p[2], a: p[3] === undefined ? 1 : p[3] }; };
        const lum = ({ r, g, b }) => { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b); };
        const blend = (t, b) => ({ r: t.r * t.a + b.r * (1 - t.a), g: t.g * t.a + b.g * (1 - t.a), b: t.b * t.a + b.b * (1 - t.a), a: 1 });
        const bgOf = el => { const st = []; for (let n = el; n && n.nodeType === 1; n = n.parentElement) { const cs = getComputedStyle(n); if (cs.backgroundImage !== 'none' && !cs.backgroundImage.startsWith('url')) return null; const c = parse(cs.backgroundColor); if (c && c.a > 0) { st.push(c); if (c.a >= 1) break; } } let b = { r: 255, g: 255, b: 255, a: 1 }; for (let i = st.length - 1; i >= 0; i--) b = blend(st[i], b); return b; };
        const label = el => { const c = n => (typeof n.className === 'string' && n.className.trim()) ? '.' + n.className.trim().split(/\s+/).slice(0, 2).join('.') : (n.id ? '#' + n.id.replace(/[0-9a-f]{32}|\d{5,}.*/g, '*') : ''); const p = el.parentElement; return (p ? p.tagName.toLowerCase() + c(p) + ' > ' : '') + el.tagName.toLowerCase() + c(el); };
        const vis = el => { const r = el.getBoundingClientRect(); if (r.width < 2 || r.height < 2) return null; const cs = getComputedStyle(el); if (cs.visibility === 'hidden' || cs.display === 'none') return null; return { r, cs }; };
        const text = [], seen = new Set(), dark = [], darkEls = [];
        for (const el of document.querySelectorAll('body *')) {
          const v = vis(el); if (!v) continue; const { r, cs } = v;
          // DARK surfaces: near-black neutral fill, sizeable, not inside an allow-listed dark area
          const c = parse(cs.backgroundColor);
          if (c && c.a >= 0.85 && r.width * r.height >= 5000 && !el.closest('pre, code, .ql-syntax, #mmd-wa-root, .mmd-processing-overlay, [class*="preview"], [class*="tooltip"], iframe, img, video, canvas')) {
            const chroma = (Math.max(c.r, c.g, c.b) - Math.min(c.r, c.g, c.b)) / 255;
            if (lum(c) < 0.07 && chroma < 0.3 && !darkEls.some(d => d.contains(el))) { darkEls.push(el); dark.push(label(el) + '  ' + cs.backgroundColor + '  ' + Math.round(r.width) + 'x' + Math.round(r.height)); }
          }
          const txt = [...el.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent.trim()).join(' ').trim();
          if (!txt || el.closest('[disabled], .disabled, [aria-disabled="true"]')) continue;
          let fg = parse(cs.color); const bg = bgOf(el); if (!fg || !bg) continue;
          let op = 1; for (let n = el; n && n.nodeType === 1; n = n.parentElement) op *= +getComputedStyle(n).opacity; if (op === 0) continue;
          fg = blend({ ...fg, a: fg.a * op }, bg);
          const L1 = lum(fg), L2 = lum(bg), ratio = (Math.max(L1, L2) + 0.05) / (Math.min(L1, L2) + 0.05);
          const size = parseFloat(cs.fontSize), need = (size >= 24 || (size >= 18.66 && +cs.fontWeight >= 600)) ? 3 : 4.5;
          if (ratio < need) { const k = label(el) + cs.color; if (seen.has(k)) continue; seen.add(k); text.push(ratio.toFixed(2) + '  ' + cs.color + ' on rgb(' + (bg.r | 0) + ',' + (bg.g | 0) + ',' + (bg.b | 0) + ')  ' + label(el) + '  "' + txt.slice(0, 32) + '"'); }
        }
        // the shared stylesheet must parse to its last rule (a malformed rule silently drops everything after it)
        const sheet = [...document.styleSheets].find(x => (x.href || '').includes('admin-dashboard.css'));
        let truncated = false; try { truncated = !!sheet && ![...sheet.cssRules].some(r => r.selectorText === '.mmd-css-eof'); } catch (e) {}
        if (truncated) text.push('0.00  CSS-TRUNCATED  admin-dashboard.css did not parse to its EOF sentinel');
        return { text, dark, title: document.title.slice(0, 50), fatal: /Fatal error|Uncaught Exception/.test(document.body.innerText.slice(0, 4000)) };
      }));
      res.errs = [...sess.errs];
      if (shotDir) { res.shot = (p.role + '_' + p.url.replace(/^\/index\.php\/adminlogin\//, '').replace(/[^a-zA-Z0-9]+/g, '_')).slice(0, 90) + '.jpg'; await page.screenshot({ path: path.join(shotDir, res.shot), type: 'jpeg', quality: 55 }); }
    } catch (e) { res.error = String(e.message).slice(0, 120); }
    results.push(res);
  }
  if (sess) { await sess.browser.close(); fs.rmSync(sess.profile, { recursive: true, force: true }); }
  fs.writeFileSync(outFile, JSON.stringify(results));
  console.log('shard', si, 'scanned', results.length, 'text-fails', results.reduce((a, r) => a + (r.text || []).length, 0), 'dark', results.reduce((a, r) => a + (r.dark || []).length, 0));
} else { console.error('usage: collect|scan (see header)'); process.exit(2); }
