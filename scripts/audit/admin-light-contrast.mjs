#!/usr/bin/env node
// Light-theme text-contrast gate for the admin (localhost).
//
// Why: light mode was fixed one rule at a time, so every new admin component
// shipped with dark-only colours and rendered invisible in light mode (2026-11-17:
// the class page's course title was #f1f5f9 on a pale tint, 1.01:1, and the
// "Course Details" card head was #fff on #fff). This renders real pages in an
// ISOLATED headless Chrome with data-theme=light and reports every visible text
// element under WCAG AA (4.5:1, or 3:1 for large text). Disabled controls are
// exempt (WCAG), so the faded "← Prev" on page 1 is not a failure.
//
// Usage:
//   1. Log in with curl (see memory feedback_headless_admin_e2e_via_puppeteer_core):
//      the `adminhtml` cookie value from the cookie jar is the session.
//   2. ADMIN_SID=<cookie> node scripts/audit/admin-light-contrast.mjs [name|/path ...]
//      With no page args it checks the default page set below.
//   Env: CHROME=<chrome-headless-shell binary>, PUPPETEER_CORE=<puppeteer-core dir>,
//        BASE=http://localhost:8080, THEME=light (or dark).
// Exit: 0 = no failures, 1 = failures listed, 2 = setup error.
import { createRequire } from 'module';
import os from 'os';
import path from 'path';
import fs from 'fs';

const require = createRequire(import.meta.url);
const PUPPETEER = process.env.PUPPETEER_CORE
  || path.join(os.homedir(), '.hermes/node/lib/node_modules/hyperframes/node_modules/puppeteer-core');
const CHROME = process.env.CHROME || (() => {
  const root = path.join(os.homedir(), 'Library/Caches/ms-playwright');
  const dir = fs.existsSync(root) && fs.readdirSync(root).filter(d => d.startsWith('chromium_headless_shell')).sort().pop();
  return dir ? path.join(root, dir, 'chrome-headless-shell-mac-arm64/chrome-headless-shell') : '';
})();
const BASE = process.env.BASE || 'http://localhost:8080';
const THEME = process.env.THEME || 'light';
const SID = process.env.ADMIN_SID;
if (!SID || !CHROME) { console.error('Set ADMIN_SID (and CHROME if not auto-found).'); process.exit(2); }

const DEFAULT_PAGES = [
  'home|/index.php/adminlogin/dashboard/',
  'courses|/index.php/adminlogin/dashboard/index/panel/courses/',
  'users|/index.php/adminlogin/rolemanagement/index/',
  'classes|/index.php/adminlogin/classes/index/',
  'calendar|/index.php/adminlogin/calendar/',
  'orders|/index.php/adminlogin/sales_order/index/',
  'customers|/index.php/adminlogin/customer/index/',
  'attendance|/index.php/adminlogin/attendance/index/',
  'cache|/index.php/adminlogin/cache/index/',
  'config|/index.php/adminlogin/system_config/edit/section/general/',
  'reviews|/index.php/adminlogin/catalog_product_review/index/',
  'searchterms|/index.php/adminlogin/catalog_search/index/',
];
const pages = (process.argv.slice(2).length ? process.argv.slice(2) : DEFAULT_PAGES)
  .map(p => p.includes('|') ? p.split('|') : [p, p]);

const puppeteer = require(PUPPETEER);
const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'mms-contrast-'));
const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, userDataDir: profile, args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setViewport({ width: 1440, height: 900 });
await page.setCookie({ name: 'adminhtml', value: SID, domain: new URL(BASE).hostname, path: '/' });
await page.evaluateOnNewDocument(t => { try { localStorage.setItem('admin-theme', t); } catch (e) {} }, THEME);

let total = 0;
for (const [name, url] of pages) {
  await page.goto(BASE + url, { waitUntil: 'networkidle2', timeout: 120000 });
  await new Promise(r => setTimeout(r, 1000));
  const fails = await page.evaluate(() => {
    const parse = c => { const m = c.match(/rgba?\(([^)]+)\)/); if (!m) return null; const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number); return { r: p[0], g: p[1], b: p[2], a: p[3] === undefined ? 1 : p[3] }; };
    const lum = ({ r, g, b }) => { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b); };
    const blend = (t, b) => ({ r: t.r * t.a + b.r * (1 - t.a), g: t.g * t.a + b.g * (1 - t.a), b: t.b * t.a + b.b * (1 - t.a), a: 1 });
    const bgOf = el => { const st = []; for (let n = el; n && n.nodeType === 1; n = n.parentElement) { const cs = getComputedStyle(n); if (cs.backgroundImage !== 'none' && !cs.backgroundImage.startsWith('url')) return null; const c = parse(cs.backgroundColor); if (c && c.a > 0) { st.push(c); if (c.a >= 1) break; } } let b = { r: 255, g: 255, b: 255, a: 1 }; for (let i = st.length - 1; i >= 0; i--) b = blend(st[i], b); return b; };
    const disabled = el => !!el.closest('[disabled], .disabled, [aria-disabled="true"]');
    const label = el => { const p = el.parentElement; const c = n => (typeof n.className === 'string' && n.className.trim()) ? '.' + n.className.trim().split(/\s+/).slice(0, 2).join('.') : ''; return (p ? p.tagName.toLowerCase() + c(p) + ' > ' : '') + el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') + c(el); };
    const out = [], seen = new Set();
    for (const el of document.querySelectorAll('body *')) {
      const txt = [...el.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent.trim()).join(' ').trim();
      if (!txt || disabled(el)) continue;
      const r = el.getBoundingClientRect(); if (r.width < 2 || r.height < 2) continue;
      const cs = getComputedStyle(el); if (cs.visibility === 'hidden' || cs.display === 'none') continue;
      let fg = parse(cs.color); const bg = bgOf(el); if (!fg || !bg) continue;
      let op = 1; for (let n = el; n && n.nodeType === 1; n = n.parentElement) op *= +getComputedStyle(n).opacity;
      if (op === 0) continue;
      fg = blend({ ...fg, a: fg.a * op }, bg);
      const L1 = lum(fg), L2 = lum(bg), ratio = (Math.max(L1, L2) + 0.05) / (Math.min(L1, L2) + 0.05);
      const size = parseFloat(cs.fontSize), bold = +cs.fontWeight >= 600;
      const need = (size >= 24 || (size >= 18.66 && bold)) ? 3 : 4.5;
      if (ratio < need) { const k = label(el) + cs.color; if (seen.has(k)) continue; seen.add(k); out.push(`${ratio.toFixed(2)}  ${cs.color} on rgb(${bg.r | 0},${bg.g | 0},${bg.b | 0})  ${label(el)}  "${txt.slice(0, 40)}"`); }
    }
    return out;
  });
  total += fails.length;
  console.log(`${fails.length ? 'FAIL' : 'ok  '} ${name} (${fails.length})`);
  fails.forEach(f => console.log('      ' + f));
}
await browser.close();
fs.rmSync(profile, { recursive: true, force: true });
console.log(total ? `\n${total} low-contrast text element(s) in ${THEME} mode.` : `\nAll pages pass in ${THEME} mode.`);
process.exit(total ? 1 : 0);
