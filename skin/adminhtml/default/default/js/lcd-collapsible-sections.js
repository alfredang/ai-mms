/**
 * Course-detail view (learner / trainer / developer "View Course"
 * dashboard panel) — make EVERY .lcd-section box collapsible, like the
 * Lesson / Certificate-Delivery sections already are.
 *
 * The course-detail panel renders the same .lcd-section / .lcd-section-
 * title boxes three times (one variant per role) inside the ~12k-line
 * dashboard template. Only a couple of titles carry an inline collapse
 * onclick + caret; the rest (Google Meet, Courseware, Assessment,
 * Assessment Grading, Assessment Summary Record, Course Sessions,
 * Additional Documents, …) are static. Editing every header by hand
 * across all three role blocks in a file the other dev churns is
 * fragile — instead, one idempotent enhancer wraps each section's body
 * and adds a click-to-collapse header + caret. Sections that already
 * have their own inline toggle are left as-is (body still wrapped so
 * their `this.nextElementSibling` keeps working).
 *
 * Self-gating: no-ops unless .lcd-section elements exist. Idempotent;
 * re-applies after instant-nav PJAX swaps and DOM re-renders.
 */
(function () {
    'use strict';

    function caret() {
        var ns = 'http://www.w3.org/2000/svg';
        var s = document.createElementNS(ns, 'svg');
        s.setAttribute('viewBox', '0 0 24 24');
        s.setAttribute('width', '18');
        s.setAttribute('height', '18');
        s.setAttribute('fill', 'none');
        s.setAttribute('stroke', 'currentColor');
        s.setAttribute('stroke-width', '2');
        s.setAttribute('class', 'lcd-auto-caret');
        s.style.transition = 'transform .2s';
        s.style.flex = '0 0 auto';
        s.style.marginLeft = '12px';
        var p = document.createElementNS(ns, 'polyline');
        p.setAttribute('points', '6 9 12 15 18 9');
        s.appendChild(p);
        return s;
    }

    function enhance(sec) {
        if (sec.getAttribute('data-lcd-collapsible')) return;
        var title = null, c = sec.firstElementChild;
        // first direct child with class lcd-section-title
        while (c) {
            if (c.classList && c.classList.contains('lcd-section-title')) { title = c; break; }
            c = c.nextElementSibling;
        }
        if (!title) return;
        sec.setAttribute('data-lcd-collapsible', '1');

        // Wrap everything after the title into one toggle target.
        var body = document.createElement('div');
        body.className = 'lcd-section-body';
        var n = title.nextSibling;
        while (n) { var nx = n.nextSibling; body.appendChild(n); n = nx; }
        sec.appendChild(body);

        // Lay the title out as a row and give it a caret (unless it
        // already has one from an inline-collapsing section).
        if (!title.querySelector('.lcd-caret') && !title.querySelector('.lcd-auto-caret')) {
            var cs = window.getComputedStyle(title);
            if (cs.display.indexOf('flex') === -1) {
                title.style.display = 'flex';
                title.style.alignItems = 'center';
            }
            if (!title.style.justifyContent) title.style.justifyContent = 'space-between';
            title.appendChild(caret());
        }
        title.style.cursor = 'pointer';

        // If the section already toggles itself via an inline onclick,
        // don't add a second handler — the body wrapper above keeps its
        // `this.nextElementSibling` toggle working.
        if (title.hasAttribute('onclick')) return;

        title.addEventListener('click', function (e) {
            // Ignore clicks on interactive controls inside the header.
            if (e.target.closest &&
                e.target.closest('button,a,input,select,textarea,label,.lmc-view-toggle')) {
                return;
            }
            var collapsed = sec.classList.toggle('lcd-collapsed');
            body.style.display = collapsed ? 'none' : '';
            var car = title.querySelector('.lcd-auto-caret') || title.querySelector('.lcd-caret');
            if (car) car.style.transform = collapsed ? 'rotate(180deg)' : '';
        });
    }

    function run() {
        var secs = document.querySelectorAll('.lcd-section');
        for (var i = 0; i < secs.length; i++) enhance(secs[i]);
    }

    function init() {
        run();
        var host = document.getElementById('dash-panel-course-detail') || document.body;
        if (window.MutationObserver) {
            new MutationObserver(function () { run(); })
                .observe(host, { childList: true, subtree: true });
        }
        document.addEventListener('instant-nav:after-swap', run);
        var ticks = 0;
        var iv = window.setInterval(function () {
            run();
            if (++ticks >= 12) window.clearInterval(iv); // 12 × 500ms = 6s
        }, 500);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
