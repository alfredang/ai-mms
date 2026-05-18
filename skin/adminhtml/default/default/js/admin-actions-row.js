/**
 * Generic admin edit-page alignment: put the header action buttons on
 * the SAME horizontal row as the tab strip, with the page title left
 * on its own row above.
 *
 * Every Magento adminhtml edit page built from
 * widget/form/container.phtml renders:
 *
 *   <div class="content-header">
 *       <h3 …>Title</h3>
 *       <p class="form-buttons">…Save / Back / Reset / …</p>
 *   </div>
 *   …
 *   <ul id="<x>_tabs" class="tabs">…Information / … tabs…</ul>
 *
 * The buttons (in .content-header) and the tabs (a separate sibling
 * <ul>) are two unrelated block elements, so they render on two rows
 * that look "close but misaligned". CSS alone can't co-line two
 * arbitrary siblings, so wrap the tabs <ul> and the buttons <p> into
 * one flex row (#adminActionsRow); dark-theme.css styles it (tabs
 * left, buttons right, one shared underline). The title <h3> stays in
 * .content-header on its own row above.
 *
 * One generic handler replaces the former per-page scripts
 * (order-view / category): it auto-detects the pattern, so it fixes
 * EVERY tabbed edit page — CMS Page, Category, Product, Product
 * Attribute, Customer, Order View, Catalog/Cart Price Rule, Newsletter
 * Template, Admin User/Role, the MMD custom-module edit pages, etc. —
 * and no-ops on pages without the pattern (grids, single-form pages).
 *
 * Idempotent and self-healing: re-asserts after the concurrent
 * sidebar-nav-v2.js / Branchscope re-renders via DOMContentLoaded, a
 * MutationObserver, and a short bounded interval.
 */
(function () {
    'use strict';

    var TABS_SEL = 'ul.tabs, ul.tabs-horiz';

    function findButtons(tabs) {
        // Anchor on the tabs: the matching header buttons are the
        // .content-header .form-buttons/.content-buttons block that sits
        // immediately BEFORE the tabs in document order. Some pages have
        // several .content-header blocks (e.g. catalog_category has a
        // tree-panel header AND the form header) and container.phtml also
        // emits a FOOTER <p class="form-buttons"> after the form — both
        // are excluded by the "closest one preceding the tabs" rule.
        var cands = document.querySelectorAll(
            '.content-header .content-buttons, .content-header .form-buttons');
        var best = null;
        for (var i = 0; i < cands.length; i++) {
            var p = cands[i];
            if (!p.querySelector('button, input[type="submit"], input[type="button"], a.scalable')) {
                continue; // nothing to align
            }
            // Keep it only if the tabs come AFTER this block in the DOM.
            var rel = p.compareDocumentPosition(tabs);
            if (rel & Node.DOCUMENT_POSITION_FOLLOWING) {
                best = p; // later matches are closer-preceding → win
            }
        }
        return best;
    }

    function findTabs() {
        var uls = document.querySelectorAll(TABS_SEL);
        for (var i = 0; i < uls.length; i++) {
            // A real varienTabs container has tab links; skip stray .tabs.
            if (uls[i].querySelector('a')) return uls[i];
        }
        return null;
    }

    function arrange() {
        var tabs = findTabs();
        if (!tabs) return;            // not a tabbed edit page → no-op
        var btns = findButtons(tabs);
        if (!btns) return;

        var row = document.getElementById('adminActionsRow');
        if (!row) {
            row = document.createElement('div');
            row.id = 'adminActionsRow';
            // Drop the row where the tabs currently are so the title
            // <h3> (still in .content-header) stays on its own row above.
            tabs.parentNode.insertBefore(row, tabs);
        }
        if (tabs.parentNode !== row) row.appendChild(tabs);
        if (btns.parentNode !== row || btns.previousElementSibling !== tabs) {
            row.appendChild(btns); // buttons after the tabs
        }
    }

    function init() {
        arrange();
        var host = document.querySelector('.main-col-inner') ||
                   document.querySelector('.main-col') ||
                   document.getElementById('anchor-content') || document.body;
        if (window.MutationObserver && host) {
            new MutationObserver(function () { arrange(); })
                .observe(host, { childList: true, subtree: true });
        }
        // Also re-run after instant-nav PJAX swaps.
        document.addEventListener('instant-nav:after-swap', arrange);
        var ticks = 0;
        var iv = window.setInterval(function () {
            arrange();
            if (++ticks >= 20) window.clearInterval(iv); // 20 × 500ms = 10s
        }, 500);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
