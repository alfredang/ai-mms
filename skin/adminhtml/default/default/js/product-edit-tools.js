/**
 * Developer course-editing page (dcf editor, body.adminhtml-dashboard-
 * index, mode=editing) tools:
 *   • Collapse toggle for the left .dcf-edit-sidebar ("Course
 *     Information" rail) — toggles body.dcf-rail-collapsed (styling in
 *     admin-dashboard.css).
 *   • Each form section (.dcf-section, header = .dcf-section-title)
 *     becomes collapsible by clicking its header.
 *
 * NOTE: the earlier version targeted catalog_product/edit
 * (.side-col / body.adminhtml-catalog-product-edit) — that is NOT the
 * page developers use; the "Edit Course" flow is this dcf editor on
 * the dashboard controller. Re-scoped accordingly.
 *
 * Self-gating (only when .dcf-edit-sidebar exists), idempotent,
 * re-inits after instant-nav PJAX swaps + DOM re-renders.
 */
(function () {
    'use strict';

    function caret(cls) {
        var ns = 'http://www.w3.org/2000/svg';
        var s = document.createElementNS(ns, 'svg');
        s.setAttribute('viewBox', '0 0 24 24');
        s.setAttribute('width', '16'); s.setAttribute('height', '16');
        s.setAttribute('fill', 'none'); s.setAttribute('stroke', 'currentColor');
        s.setAttribute('stroke-width', '2'); s.setAttribute('class', cls);
        var p = document.createElementNS(ns, 'polyline');
        p.setAttribute('points', '6 9 12 15 18 9');
        s.appendChild(p);
        return s;
    }

    var RAIL_KEY = 'dcfRailCollapsed';

    function railSaved() {
        try { return window.localStorage &&
            localStorage.getItem(RAIL_KEY) === '1'; } catch (e) { return false; }
    }

    // Standard sidebar chevron ("<", points left; rotates 180° when
    // collapsed) — matches page.phtml's .sidebar-toggle .sidebar-chevron.
    function chevron(cls) {
        var ns = 'http://www.w3.org/2000/svg';
        var s = document.createElementNS(ns, 'svg');
        s.setAttribute('viewBox', '0 0 24 24');
        s.setAttribute('width', '18'); s.setAttribute('height', '18');
        s.setAttribute('fill', 'none'); s.setAttribute('stroke', 'currentColor');
        s.setAttribute('stroke-width', '2.5');
        s.setAttribute('stroke-linecap', 'round');
        s.setAttribute('stroke-linejoin', 'round');
        s.setAttribute('class', cls);
        var p = document.createElementNS(ns, 'polyline');
        p.setAttribute('points', '15 18 9 12 15 6');
        s.appendChild(p);
        return s;
    }

    // Keep the toggle's chevron in sync with the body class so a
    // re-render (or restored localStorage state) shows the right affordance.
    function syncRailToggle(btn) {
        var collapsed = document.body.classList.contains('dcf-rail-collapsed');
        btn.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
        var c = btn.querySelector('.dcf-rail-caret');
        if (c) c.style.transform = collapsed ? 'rotate(180deg)' : '';
    }

    function wireRailToggle() {
        var rail = document.querySelector('.dcf-edit-sidebar');
        if (!rail) return;
        // Restore the persisted collapsed state (mirrors the standard
        // sidebar's localStorage behaviour) before the toggle is wired.
        if (railSaved()) document.body.classList.add('dcf-rail-collapsed');
        var existing = rail.querySelector('.dcf-rail-toggle');
        if (existing) { syncRailToggle(existing); return; }
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'dcf-rail-toggle';
        btn.title = 'Toggle sidebar';
        btn.setAttribute('aria-label', 'Toggle sidebar');
        btn.appendChild(chevron('dcf-rail-caret'));
        btn.addEventListener('click', function () {
            var collapsed = document.body.classList.toggle('dcf-rail-collapsed');
            try {
                if (window.localStorage) {
                    localStorage.setItem(RAIL_KEY, collapsed ? '1' : '0');
                }
            } catch (e) {}
            syncRailToggle(btn);
        });
        syncRailToggle(btn);
        // Put the toggle right under the "Course Information" title.
        var title = rail.querySelector('.dcf-edit-sidebar-title');
        if (title && title.nextSibling) {
            rail.insertBefore(btn, title.nextSibling);
        } else {
            rail.insertBefore(btn, rail.firstChild);
        }
    }

    function wireSections() {
        var secs = document.querySelectorAll('.dcf-section');
        for (var i = 0; i < secs.length; i++) {
            var sec = secs[i];
            if (sec.getAttribute('data-dcf-coll')) continue;
            var title = null, c = sec.firstElementChild;
            while (c) {
                if (c.classList && c.classList.contains('dcf-section-title')) { title = c; break; }
                c = c.nextElementSibling;
            }
            if (!title) continue;
            sec.setAttribute('data-dcf-coll', '1');
            // Wrap everything after the title so one element toggles.
            var body = document.createElement('div');
            body.className = 'dcf-section-body';
            var n = title.nextSibling;
            while (n) { var nx = n.nextSibling; body.appendChild(n); n = nx; }
            sec.appendChild(body);
            if (!title.querySelector('.dcf-coll-caret')) {
                title.style.cursor = 'pointer';
                title.style.display = 'flex';
                title.style.alignItems = 'center';
                var cr = caret('dcf-coll-caret');
                cr.style.marginLeft = 'auto';
                cr.style.transition = 'transform .2s ease';
                title.appendChild(cr);
            }
            title.addEventListener('click', function (e) {
                if (e.target.closest &&
                    e.target.closest('a,button,input,select,textarea,label')) return;
                var s = this.parentNode;
                var b = s.querySelector(':scope > .dcf-section-body');
                if (!b) return;
                var hidden = b.style.display === 'none';
                b.style.display = hidden ? '' : 'none';
                var k = this.querySelector('.dcf-coll-caret');
                if (k) k.style.transform = hidden ? '' : 'rotate(-90deg)';
            });
        }
    }

    function run() {
        if (!document.querySelector('.dcf-edit-sidebar')) return;
        wireRailToggle();
        wireSections();
    }

    function init() {
        run();
        var host = document.querySelector('.dcf-wrap') ||
                   document.getElementById('anchor-content') || document.body;
        if (window.MutationObserver && host) {
            new MutationObserver(function () { run(); })
                .observe(host, { childList: true, subtree: true });
        }
        document.addEventListener('instant-nav:after-swap', run);
        var t = 0, iv = window.setInterval(function () {
            run(); if (++t >= 12) window.clearInterval(iv);
        }, 500);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
