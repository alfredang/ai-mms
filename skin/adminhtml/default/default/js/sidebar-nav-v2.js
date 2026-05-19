/**
 * Sidebar Navigation — Accordion toggle, collapse, hover handler cleanup
 * Uses Prototype.js (loaded globally in Magento admin)
 */

// Stamp <html> with a page-context class as early as possible so CSS
// scoped to specific pages applies on the very first paint without
// waiting for dom:loaded. Used by the Order View horizontal-tabs layout.
(function () {
    var p = (window.location.pathname || '').toLowerCase();
    // Order View drives the horizontal-tabs relocation + the dense,
    // readable styling (bigger fonts, outlined toolbar buttons).
    // Invoice View and Transaction View are the same
    // Widget_Form_Container layout — identical .form-buttons /
    // .form-list / .box-head / .order-totals markup — so they reuse
    // the same marker. The tab-relocation code self-guards on
    // #sales_order_view_tabs (which those two pages don't have), so
    // it's an inert no-op there; only the styling carries over.
    if (p.indexOf('/sales_order/view/') !== -1
        || p.indexOf('/sales_invoice/view/') !== -1
        || p.indexOf('/sales_order_invoice/view/') !== -1
        || p.indexOf('/sales_transactions/view/') !== -1
        || p.indexOf('/sales_transaction/view/') !== -1) {
        document.documentElement.classList.add('is-order-view');
    }
})();

// On Order View detail pages, physically move the tabs UL out of the
// left rail (.side-col) and into the main column right after the
// action-buttons row (.content-header). This places the tabs below
// the Back/Edit/Cancel/... buttons and above the Order / Account
// info cards — what the user actually expects from "tabs at the top
// of the page". CSS alone can't reorder across .side-col / .main-col
// because each column has its own children.
document.addEventListener('DOMContentLoaded', function relocateOrderTabs() {
    if (!document.documentElement.classList.contains('is-order-view')) return;
    var tabs = document.getElementById('sales_order_view_tabs');
    if (!tabs) return;
    var mainInner = document.querySelector('.main-col-inner') || document.querySelector('.main-col');
    if (!mainInner) return;
    // Insert right after the content-header (action buttons row). If
    // there's no content-header (some sub-actions render without one),
    // fall back to the top of the main column.
    var contentHeader = mainInner.querySelector('.content-header');
    var anchor = contentHeader || mainInner.firstChild;
    if (anchor && anchor.nextSibling) {
        mainInner.insertBefore(tabs, anchor.nextSibling);
    } else {
        mainInner.appendChild(tabs);
    }
    tabs.classList.add('tabs-relocated');
    document.body.classList.add('has-relocated-tabs');
    // Hide the now-empty side-col entirely so it doesn't reserve
    // vertical space (it still has the "Order View" h3 etc.).
    var sideCol = document.querySelector('.side-col');
    if (sideCol) sideCol.style.display = 'none';
});

// Helper: register a handler to run on initial DOMContentLoaded AND on
// every instant-nav PJAX swap (instant-nav.js doesn't refire
// DOMContentLoaded, so plain listeners miss the new page entirely).
function onPageReady(fn) {
    document.addEventListener('DOMContentLoaded', fn);
    document.addEventListener('instant-nav:after-swap', fn);
}

// Generic: relocate any varienTabs ul.tabs sitting in .side-col into
// the top of .main-col-inner, then hide the side-col so the page is a
// 2-column layout (global sidebar + main). Old Magento puts a section
// nav in the side-col, which gives us a 3rd column on edit pages —
// not what we want.
//
// Skip:
//  - Categories admin (.side-col holds the category tree, not tabs)
//  - Already-handled Order View (handled above with its own logic)
//  - System > Configuration: this generic relocator grabs the config
//    nav ul.tabs and hides .side-col, but the dedicated config styling
//    never applies (relocateConfigAccordion's body-class check uses the
//    wrong "adminhtml-system-config" hyphen vs the real
//    "adminhtml-system_config" underscore, and its CSS is scoped the
//    same wrong way + requires a .config-accordion class that is never
//    added). Result: a completely unstyled, unusable Config page.
//    Until that refactor is finished, skip System Config here so it
//    renders in its original, working side-col layout.
onPageReady(function relocateSideColTabs() {
    var body = document.body;
    if (/adminhtml-catalog-category|catalog-categories|is-order-view|adminhtml-system_config|adminhtml-system-config/.test(body.className)) return;
    if (document.documentElement.classList.contains('is-order-view')) return;

    var sideCol = document.querySelector('.side-col');
    if (!sideCol) return;
    var tabsList = sideCol.querySelector('ul.tabs');
    if (!tabsList) return;

    var mainInner = document.querySelector('.main-col-inner') || document.querySelector('.main-col');
    if (!mainInner) return;

    // Some pages wrap the tabs in a container with header text — keep
    // just the <ul> so the relocated bar stays clean.
    var anchor = mainInner.querySelector('.content-header');
    var nextNode = anchor && anchor.nextSibling ? anchor.nextSibling : null;
    if (nextNode) {
        mainInner.insertBefore(tabsList, nextNode);
    } else {
        mainInner.appendChild(tabsList);
    }
    tabsList.classList.add('tabs-relocated');
    body.classList.add('has-relocated-tabs');
    sideCol.style.display = 'none';
});

// Phase 2: System → Configuration uses dl.accordion in .side-col instead
// of ul.tabs. Relocate the whole accordion to the top of .main-col-inner
// as a horizontal section bar (dt headers as pills, active dd's sub-items
// as a second row). Keeps the existing accordion JS untouched — we only
// reflow the markup.
// System Configuration's native side-col dl.accordion has section-specific
// JS behaviour (open/close state, scroll-to-active) that did not survive
// being reflowed into a horizontal bar — dd contents stayed visible for
// every section, producing a wall of overlapping links. Leave the page
// alone and let it render with its standard 3-column layout.
onPageReady(function relocateConfigAccordion() { /* intentionally disabled */ });

// Phase 3+4: Categories tree and Permissions Roles tree live in .side-col.
// They are interactive pickers, not navigation, so they can't be hidden
// outright. Wrap the side-col in a slide-in overlay panel and inject a
// toggle button into the content-header. Main column expands to full
// width when the overlay is closed.
onPageReady(function wrapSideColTree() {
    var body = document.body;
    var isCategories = /adminhtml-catalog-category|catalog-categories/.test(body.className);
    var isRolesEdit  = /adminhtml-permissions-role-(edit|new)/.test(body.className);
    if (!isCategories && !isRolesEdit) return;
    var sideCol = document.querySelector('.side-col');
    if (!sideCol) return;
    // Only convert if there's a tree/picker in the side-col
    var hasTree = sideCol.querySelector('#tree-div, .tree, .categories-side-col, #permissionRolesAcl, #role_users');
    if (!hasTree && !sideCol.querySelector('.entry-edit')) return;

    sideCol.classList.add('side-col-overlay');
    body.classList.add('has-overlay-sidecol');

    // Toggle button — insert into the MAIN column's content-header, NOT
    // any header nested inside a side-col. Categories admin has multiple
    // content-headers and the side-col one is also under .main-col. The
    // main-col header may be added by JS after DOMContentLoaded, so we
    // retry a few times.
    // Categories page re-renders the form's content-header on every
    // category selection, which wipes any button we placed there. Use
    // a dedicated, persistent wrapper at the top of .main-col-inner
    // instead — it survives form re-renders and PJAX swaps.
    function placeToggle() {
        if (document.querySelector('.side-col-overlay-toggle')) return true;
        var mainInner = document.querySelector('.main-col-inner') || document.querySelector('.main-col');
        if (!mainInner) return false;
        var wrap = document.createElement('div');
        wrap.className = 'side-col-overlay-toggle-wrap';
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'side-col-overlay-toggle';
        btn.textContent = isCategories ? 'Browse Categories' : 'Edit Resources';
        btn.addEventListener('click', function () {
            body.classList.toggle('side-col-overlay-open');
        });
        wrap.appendChild(btn);
        mainInner.insertBefore(wrap, mainInner.firstChild);
        return true;
    }
    placeToggle();
    // Belt-and-braces in case the wrap gets clobbered by category form JS.
    setTimeout(placeToggle, 800);
    setTimeout(placeToggle, 2000);

    // Click-outside / Esc closes
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') body.classList.remove('side-col-overlay-open');
    });
    document.addEventListener('click', function (e) {
        if (!body.classList.contains('side-col-overlay-open')) return;
        if (sideCol.contains(e.target)) return;
        if (e.target.classList && e.target.classList.contains('side-col-overlay-toggle')) return;
        body.classList.remove('side-col-overlay-open');
    });
});

// Phase 5: Reports often put their filter form in .side-col. Move the
// form to the top of .main-col-inner so the page becomes 2-col.
onPageReady(function relocateReportsFilter() {
    var body = document.body;
    if (!/adminhtml-report-/.test(body.className)) return;
    var sideCol = document.querySelector('.side-col');
    if (!sideCol) return;
    var form = sideCol.querySelector('form, fieldset');
    if (!form) return;
    var mainInner = document.querySelector('.main-col-inner') || document.querySelector('.main-col');
    if (!mainInner) return;

    var anchor = mainInner.querySelector('.content-header');
    var nextNode = anchor && anchor.nextSibling ? anchor.nextSibling : null;
    // Move the whole side-col content node (entry-edit wrapper if present)
    var moveNode = sideCol.querySelector('.entry-edit') || form;
    if (nextNode) {
        mainInner.insertBefore(moveNode, nextNode);
    } else {
        mainInner.appendChild(moveNode);
    }
    moveNode.classList.add('reports-filter-relocated');
    body.classList.add('has-relocated-reports-filter');
    sideCol.style.display = 'none';
});

// Phase 7: catch-all fallback — any remaining .side-col that didn't
// match a known pattern (no ul.tabs, no dl.accordion, no tree, no form,
// no overlay marker). Hide it so the page becomes 2-col. Run AFTER the
// pattern-specific handlers above (DOMContentLoaded order).
onPageReady(function hideUnhandledSideCol() {
    var body = document.body;
    // Skip pages already processed
    if (body.classList.contains('has-relocated-tabs')) return;
    if (body.classList.contains('has-relocated-accordion')) return;
    if (body.classList.contains('has-overlay-sidecol')) return;
    if (body.classList.contains('has-relocated-reports-filter')) return;
    if (document.documentElement.classList.contains('is-order-view')) return;
    if (/adminhtml-catalog-category|catalog-categories/.test(body.className)) return;

    var sideCols = document.querySelectorAll('.side-col');
    if (!sideCols.length) return;
    var anyHidden = false;
    sideCols.forEach(function (sc) {
        // Don't hide an empty placeholder or a side-col that's already
        // managed (e.g. has explicit width or display).
        if (sc.children.length === 0) return;
        sc.style.display = 'none';
        anyHidden = true;
    });
    if (anyHidden) body.classList.add('has-hidden-sidecol');
});

document.observe('dom:loaded', function() {
    var sidebar = $('admin-sidebar');
    var toggleBtn = $('sidebar-toggle');
    if (!sidebar) return;

    // 1. Strip inline hover handlers from parent items
    //    getMenuLevel() adds onmouseover/onmouseout for dropdown behavior
    $$('#nav li.parent').each(function(li) {
        li.writeAttribute('onmouseover', null);
        li.writeAttribute('onmouseout', null);
    });

    // 2. Auto-expand active menu path
    $$('#nav li.active').each(function(activeLi) {
        var parent = activeLi.up('li.parent');
        while (parent) {
            parent.addClassName('submenu-open');
            parent = parent.up('li.parent');
        }
    });
    // Also expand if the active item IS a parent
    $$('#nav li.parent.active').each(function(li) {
        li.addClassName('submenu-open');
    });
    // Expand parent that contains an active child link
    $$('#nav li.parent').each(function(parentLi) {
        if (parentLi.down('a.active') || parentLi.down('li.active')) {
            parentLi.addClassName('submenu-open');
        }
    });

    // 3. Accordion toggle — click parent item to expand/collapse
    $$('#nav li.parent > a').each(function(link) {
        var li = link.up('li');
        var href = link.readAttribute('href');
        var isRealLink = href && href !== '#' && href !== 'javascript:void(0)';

        if (!isRealLink) {
            // No real URL — entire link toggles submenu
            link.observe('click', function(e) {
                e.stop();
                li.toggleClassName('submenu-open');
            });
        } else {
            // Has a real URL — add a toggle button so user can both navigate and expand
            var toggleSpan = new Element('span', {
                'class': 'submenu-toggle-btn',
                'title': 'Expand submenu'
            });
            link.insert({ after: toggleSpan });
            toggleSpan.observe('click', function(e) {
                e.stop();
                li.toggleClassName('submenu-open');
            });
            // Also allow clicking the link itself to toggle if it's a top-level parent
            // that doesn't navigate (some themes set href to first child)
        }
    });

    // 4. Sidebar collapse toggle
    var STORAGE_KEY = 'admin_sidebar_collapsed';

    // Restore saved state
    if (window.localStorage) {
        var saved = localStorage.getItem(STORAGE_KEY);
        if (saved === '1') {
            document.body.addClassName('sidebar-collapsed');
        }
    }

    if (toggleBtn) {
        toggleBtn.observe('click', function(e) {
            e.stop();
            var isCollapsed = document.body.hasClassName('sidebar-collapsed');
            if (isCollapsed) {
                document.body.removeClassName('sidebar-collapsed');
                if (window.localStorage) localStorage.setItem(STORAGE_KEY, '0');
            } else {
                document.body.addClassName('sidebar-collapsed');
                if (window.localStorage) localStorage.setItem(STORAGE_KEY, '1');
            }
        });
    }

    // 5. Mobile: hamburger toggle (for <768px)
    //    Add a hamburger button to the top bar for mobile
    var topbar = document.body.down('.admin-topbar');
    if (topbar) {
        var mobileToggle = new Element('button', {
            'class': 'sidebar-mobile-toggle',
            'id': 'sidebar-mobile-toggle',
            'type': 'button',
            'title': 'Toggle menu'
        });
        mobileToggle.update('<span class="mobile-toggle-icon"></span>');
        topbar.insert({ top: mobileToggle });

        mobileToggle.observe('click', function(e) {
            e.stop();
            document.body.toggleClassName('sidebar-mobile-open');
        });

        // Close sidebar when clicking overlay (the body::after pseudo-element)
        document.observe('click', function(e) {
            if (document.body.hasClassName('sidebar-mobile-open')) {
                var target = e.element();
                if (!target.up('.admin-sidebar') && !target.up('.sidebar-mobile-toggle') && target.id !== 'sidebar-mobile-toggle') {
                    document.body.removeClassName('sidebar-mobile-open');
                }
            }
        });
    }

    // 6. Collapsed flyout positioning
    //    For collapsed mode, position flyout submenu next to the hovered item
    if (sidebar) {
        $$('#nav > li.parent').each(function(li) {
            li.observe('mouseenter', function() {
                if (document.body.hasClassName('sidebar-collapsed') || window.innerWidth <= 1024) {
                    var ul = li.down('ul');
                    if (ul) {
                        var rect = li.getBoundingClientRect();
                        ul.setStyle({ top: rect.top + 'px' });
                    }
                }
            });
        });
    }

    // 7. Advanced Filters Panel
    //    Extract inline tr.filter inputs and build a collapsible panel above each grid
    //    Grid content is loaded via AJAX after dom:loaded, so we wait for it
    //
    //    Skip detail-view pages — their inner grids (e.g. order items,
    //    invoice line items) shouldn't surface stray Filters toggles in
    //    the page header. Detect via URL: `/view/` or `/edit/` segments.
    function isDetailViewPage() {
        var p = (window.location.pathname || '').toLowerCase();
        return p.indexOf('/view/') !== -1
            || p.indexOf('/edit/') !== -1
            || p.indexOf('/new/')  !== -1
            || p.indexOf('/order_id/') !== -1;
    }
    function initAdvancedFilters() {
        if (isDetailViewPage()) return;
        var grids = $$('.grid');
        var anyFilterFound = false;
        grids.each(function(grid) {
            if (grid.down('tr.filter')) anyFilterFound = true;
        });
        if (!anyFilterFound) {
            // Grid not loaded yet, retry
            setTimeout(initAdvancedFilters, 300);
            return;
        }
        // Already initialized?
        if ($$('.advanced-filter-panel').length > 0) return;
        buildFilterPanels();
    }
    setTimeout(initAdvancedFilters, 500);

    // tr.filter is hidden by sidebar-nav.css with the assumption that
    // buildFilterPanels() will extract its inputs into a collapsible
    // panel + Filters toggle. If any step below fails (no Search button
    // anchor, no extractable fields, missing content-header to host the
    // toggle, etc.), un-hide the original inline filter row so the user
    // still has a way to filter the grid.
    function unhideInlineFilters(grid) {
        var row = grid.down('tr.filter');
        if (row) row.style.setProperty('display', 'table-row', 'important');
    }

    function buildFilterPanels() {
    $$('.grid').each(function(grid) {
        try {
        var filterRow = grid.down('tr.filter');
        if (!filterRow) return;

        var headingRow = grid.down('tr.headings');
        var filterCells = filterRow.childElements();
        var headingCells = headingRow ? headingRow.childElements() : [];

        // Find the grid JS object name from Search/Reset buttons.
        // The Search button lives outside <div class="grid"> (in the top action bar),
        // so we walk up ancestors until we find it, then fall back to document-wide.
        var gridJsName = null;
        var searchBtn = null;
        var resetBtn = null;
        var scope = grid;
        for (var depth = 0; depth < 8 && !searchBtn; depth++) {
            var btns = scope.select('button');
            for (var bi = 0; bi < btns.length; bi++) {
                var oc = btns[bi].readAttribute('onclick') || '';
                if (!searchBtn && oc.indexOf('.doFilter') !== -1) searchBtn = btns[bi];
                if (!resetBtn && oc.indexOf('.resetFilter') !== -1) resetBtn = btns[bi];
            }
            if (searchBtn) break;
            var parent = scope.up();
            if (!parent || parent === document.body) break;
            scope = parent;
        }
        // Last-ditch fallback: search whole document
        if (!searchBtn) {
            var allBtns = $$('button');
            for (var ai = 0; ai < allBtns.length; ai++) {
                var oc2 = allBtns[ai].readAttribute('onclick') || '';
                if (!searchBtn && oc2.indexOf('.doFilter') !== -1) searchBtn = allBtns[ai];
                if (!resetBtn && oc2.indexOf('.resetFilter') !== -1) resetBtn = allBtns[ai];
            }
        }
        if (searchBtn) {
            var match = (searchBtn.readAttribute('onclick') || '').match(/(\w+)\.doFilter/);
            if (match) gridJsName = match[1];
        }
        // Fallback: try deriving from grid id (e.g. cmsPageGrid_table → cmsPageGridJsObject
        // or plain cmsPageGrid — varienGrid assigns window[jsObjectName])
        if (!gridJsName) {
            var gridTable = grid.down('table[id$="_table"]');
            if (gridTable) {
                var tid = (gridTable.readAttribute('id') || '').replace(/_table$/, '');
                if (tid) {
                    if (window[tid + 'JsObject'] && window[tid + 'JsObject'].doFilter) gridJsName = tid + 'JsObject';
                    else if (window[tid] && window[tid].doFilter) gridJsName = tid;
                }
            }
        }

        // Collect filter fields with their labels
        var fields = [];
        filterCells.each(function(cell, index) {
            var inputs = cell.select('input:not([type=hidden]), select');
            if (inputs.length === 0) return;

            var headerText = '';
            if (headingCells[index]) {
                headerText = headingCells[index].textContent.strip();
            }
            // Skip the massaction checkbox column
            if (cell.down('.head-massaction') || headerText === '') return;

            // Detect range fields (From/To)
            var rangeLines = cell.select('.range-line, .range div');
            var isRange = rangeLines.length > 0 || inputs.length > 1;

            fields.push({
                label: headerText,
                inputs: inputs,
                cell: cell,
                isRange: isRange
            });
        });

        if (fields.length === 0) {
            unhideInlineFilters(grid);
            return;
        }

        // Build the filter panel
        var panel = new Element('div', { 'class': 'advanced-filter-panel' });
        var panelGrid = new Element('div', { 'class': 'filter-panel-grid' });

        fields.each(function(field) {
            var fieldDiv = new Element('div', { 'class': 'filter-field' });
            var label = new Element('div', { 'class': 'filter-field-label' });
            label.update(field.label);
            fieldDiv.insert(label);

            if (field.isRange && field.inputs.length >= 2) {
                var rangeDiv = new Element('div', { 'class': 'filter-range' });
                // Group inputs into From/To
                var fromInputs = [];
                var toInputs = [];
                var otherInputs = [];
                field.inputs.each(function(inp) {
                    var name = inp.readAttribute('name') || '';
                    if (name.indexOf('[from]') !== -1 || inp.readAttribute('placeholder') === 'From' || name.indexOf('_from') !== -1) {
                        fromInputs.push(inp);
                    } else if (name.indexOf('[to]') !== -1 || inp.readAttribute('placeholder') === 'To' || name.indexOf('_to') !== -1) {
                        toInputs.push(inp);
                    } else {
                        otherInputs.push(inp);
                    }
                });

                if (fromInputs.length > 0) {
                    var fromGroup = new Element('div', { 'class': 'filter-range-group' });
                    var fromLabel = new Element('div', { 'class': 'filter-range-label' });
                    fromLabel.update('From');
                    fromGroup.insert(fromLabel);
                    fromInputs.each(function(inp) { fromGroup.insert(inp); });
                    // Move associated calendar images
                    var nextSib = fromInputs[0].next('img');
                    if (nextSib && nextSib.readAttribute('src') && nextSib.readAttribute('src').indexOf('calendar') !== -1) {
                        fromGroup.insert(nextSib);
                    }
                    rangeDiv.insert(fromGroup);
                }
                if (toInputs.length > 0) {
                    var toGroup = new Element('div', { 'class': 'filter-range-group' });
                    var toLabel = new Element('div', { 'class': 'filter-range-label' });
                    toLabel.update('To');
                    toGroup.insert(toLabel);
                    toInputs.each(function(inp) { toGroup.insert(inp); });
                    var nextSib2 = toInputs[0].next('img');
                    if (nextSib2 && nextSib2.readAttribute('src') && nextSib2.readAttribute('src').indexOf('calendar') !== -1) {
                        toGroup.insert(nextSib2);
                    }
                    rangeDiv.insert(toGroup);
                }
                otherInputs.each(function(inp) { rangeDiv.insert(inp); });
                fieldDiv.insert(rangeDiv);
            } else {
                field.inputs.each(function(inp) {
                    fieldDiv.insert(inp);
                });
            }

            // Also move hidden inputs
            var hiddenInputs = field.cell.select('input[type=hidden]');
            hiddenInputs.each(function(inp) { fieldDiv.insert(inp); });

            panelGrid.insert(fieldDiv);
        });

        panel.insert(panelGrid);

        // Action buttons
        var actions = new Element('div', { 'class': 'filter-panel-actions' });
        var searchBtnNew = new Element('button', {
            'type': 'button',
            'class': 'filter-search-btn scalable'
        });
        searchBtnNew.update('<span>Apply Filters</span>');
        var resetBtnNew = new Element('button', {
            'type': 'button',
            'class': 'filter-reset-btn scalable'
        });
        resetBtnNew.update('<span>Reset</span>');

        // Wire Apply/Reset by serializing the panel inputs directly.
        // varienGrid.doFilter() expects inputs inside "#<gridId> .filter", but we
        // moved them into a panel outside that scope. Rather than fight with move-back
        // tricks (which break when the grid AJAX-replaces tr.filter), we serialize the
        // panel inputs ourselves and call grid.reload() with the encoded filter URL.
        function panelInputsWithValues() {
            var all = panel.select('input[name], select[name], textarea[name]');
            var withValue = [];
            all.each(function(el) {
                // Skip the buttons we added (type=button doesn't carry values; name is absent anyway)
                if (el.tagName === 'BUTTON') return;
                if (el.disabled) return;
                // Checkbox/radio: only include if checked
                if (el.type === 'checkbox' || el.type === 'radio') {
                    if (el.checked) withValue.push(el);
                    return;
                }
                if (el.value && el.value.length) withValue.push(el);
            });
            return withValue;
        }

        searchBtnNew.observe('click', function() {
            var gridObj = (gridJsName && window[gridJsName]) ? window[gridJsName] : null;
            if (gridObj && typeof gridObj.reload === 'function' && gridObj.filterVar) {
                var els = panelInputsWithValues();
                var serialized = els.length ? Form.serializeElements(els) : '';
                var encoded = serialized ? encode_base64(serialized) : '';
                gridObj.reload(gridObj.addVarToUrl(gridObj.filterVar, encoded));
                return;
            }
            // Fallback: the original Search button is still in the DOM (just hidden).
            if (searchBtn) { searchBtn.click(); return; }
            console.warn('[Filter] No grid JS object or Search button found for grid', grid.readAttribute('id'));
        });

        resetBtnNew.observe('click', function() {
            // Clear all panel inputs so the UI matches the reset state
            panel.select('input[name], select[name], textarea[name]').each(function(el) {
                if (el.tagName === 'BUTTON') return;
                if (el.type === 'checkbox' || el.type === 'radio') { el.checked = false; return; }
                if (el.tagName === 'SELECT') { el.selectedIndex = 0; return; }
                el.value = '';
            });
            var gridObj = (gridJsName && window[gridJsName]) ? window[gridJsName] : null;
            if (gridObj && typeof gridObj.reload === 'function' && gridObj.filterVar) {
                gridObj.reload(gridObj.addVarToUrl(gridObj.filterVar, ''));
                return;
            }
            if (resetBtn) { resetBtn.click(); return; }
            console.warn('[Filter] No grid JS object or Reset button found');
        });

        actions.insert(searchBtnNew);
        actions.insert(resetBtnNew);
        panel.insert(actions);

        // Create toggle button
        var toggleBtn = new Element('button', {
            'type': 'button',
            'class': 'advanced-filter-toggle'
        });
        toggleBtn.update('<span>Filters</span><span class="filter-chevron"></span>');

        toggleBtn.observe('click', function(e) {
            e.stop();
            toggleBtn.toggleClassName('active');
            panel.toggleClassName('open');
        });

        // Find the best place to insert the panel and toggle
        // Walk up from the grid to find the grid wrapper (e.g. #sales_order_grid)
        var gridWrapper = grid.up();

        // Find the content-header in the page
        var contentHeader = null;
        var mainContainer = document.body.down('#page\\:main-container');
        if (mainContainer) {
            contentHeader = mainContainer.down('.content-header');
        }

        // Insert toggle button into content-header or before the grid area
        var togglePlaced = false;
        if (contentHeader) {
            // Find or create a buttons area
            var btnContainer = contentHeader.down('.content-buttons');
            if (!btnContainer) {
                // Try last td
                var tds = contentHeader.select('td');
                if (tds.length > 1) {
                    btnContainer = tds[tds.length - 1];
                }
            }
            if (btnContainer) {
                btnContainer.insert({ top: toggleBtn });
                togglePlaced = true;
            } else {
                contentHeader.insert(toggleBtn);
                togglePlaced = true;
            }
        } else if (gridWrapper && gridWrapper.parentNode) {
            gridWrapper.parentNode.insertBefore(toggleBtn, gridWrapper);
            togglePlaced = true;
        }

        // Insert panel before the grid wrapper (which contains massaction + grid)
        var panelRef = gridWrapper || grid;
        if (panelRef && panelRef.parentNode) {
            panelRef.parentNode.insertBefore(panel, panelRef);
        }

        // No Filters toggle ended up anywhere on the page — fall back
        // to showing the original inline filter row so the user can
        // still search.
        if (!togglePlaced) {
            unhideInlineFilters(grid);
        }
        } catch (e) {
            // Anything unexpected (DOM shape we didn't anticipate) — fall
            // back to the inline filter row rather than leaving the user
            // with no filter UI at all.
            unhideInlineFilters(grid);
            if (window.console && console.warn) console.warn('[buildFilterPanels]', e);
        }
    });
    } // end buildFilterPanels

    // 8. Optimize grid column widths (shrink Thumbnail, expand Name)
    function optimizeGridColumns() {
        $$('.grid table.data').each(function(table) {
            var cols = table.select('col');
            var headings = table.select('tr.headings th');
            for (var i = 0; i < headings.length; i++) {
                var text = headings[i].textContent.strip().toLowerCase();
                if (text === 'thumbnail' || text === 'image') {
                    if (cols[i]) cols[i].setAttribute('width', '56');
                }
            }
        });
    }
    setTimeout(optimizeGridColumns, 600);

    // 9. Remove RSS links from DOM completely
    function removeRssLinks() {
        $$('a[href*="/rss/"]').each(function(a) {
            // Remove parent container if it's a small wrapper (span, div, td)
            var parent = a.up();
            if (parent && (parent.tagName === 'SPAN' || parent.tagName === 'DIV') && parent.childElements().length <= 2) {
                parent.remove();
            } else {
                a.remove();
            }
        });
        $$('.link-rss').each(function(el) { el.remove(); });
        // Only the actual feed icons in pagers / link rows. The bare
        // `[src*="rss"]` form was over-broad — any user-uploaded image
        // whose URL happened to contain "rss" (e.g. assets/rss-feed.png)
        // would be deleted from the page.
        $$('img[src*="/rss/"], img[src$="rss.gif"], img[src$="rss.png"], .pager img[src*="rss"]').each(function(img) { img.remove(); });
    }
    removeRssLinks();
    // Also run after grid loads since RSS links can be in AJAX-loaded pagers
    setTimeout(removeRssLinks, 600);
    setTimeout(removeRssLinks, 2000);

    // 9. Modern Pagination
    function initModernPagination() {
        var grids = $$('.grid');
        if (grids.length === 0) {
            return;
        }
        // Remove any existing pagination (handles grid AJAX reloads)
        $$('.modern-pagination').each(function(el) { el.remove(); });

        grids.each(function(grid) {
            buildPagination(grid);
        });
    }
    // Initial load: try a few times because grid markup can render late
    // (varienGrid sometimes does its own setup post-DOM-ready).
    [120, 400, 900, 1800].each(function(d) { setTimeout(initModernPagination, d); });

    // Re-run on grid AJAX reloads inside #page:main-container.
    // The observer is RE-ATTACHED whenever instant-nav PJAX swaps the
    // content area (the old #page:main-container node is destroyed by
    // the swap, so its observer would otherwise become orphaned).
    var paginationObserver = null;
    function attachPaginationObserver() {
        if (paginationObserver) {
            try { paginationObserver.disconnect(); } catch (e) {}
        }
        paginationObserver = new MutationObserver(function(mutations) {
            var gridChanged = false;
            mutations.each(function(m) {
                if (m.addedNodes.length > 0) {
                    for (var i = 0; i < m.addedNodes.length; i++) {
                        var node = m.addedNodes[i];
                        if (node.nodeType === 1 && (
                            (node.classList && node.classList.contains('grid')) ||
                            (node.querySelector && node.querySelector('.grid'))
                        )) {
                            gridChanged = true;
                        }
                    }
                }
            });
            if (gridChanged) {
                setTimeout(function() {
                    initModernPagination();
                    removeRssLinks();
                    if (!isDetailViewPage() && $$('.advanced-filter-panel').length === 0) {
                        buildFilterPanels();
                    }
                }, 200);
            }
        });
        var mainContainer = document.body.down('#page\\:main-container');
        if (mainContainer) {
            paginationObserver.observe(mainContainer, { childList: true, subtree: true });
        }
    }
    attachPaginationObserver();

    // PJAX swap (instant-nav.js) replaces #anchor-content's children
    // wholesale, destroying the old #page:main-container node our observer
    // was bound to. Re-init pagination + filter panel + observer after
    // every swap. Without re-running initAdvancedFilters, any grid that
    // gets PJAX-loaded ends up with no filter UI at all (the inline
    // tr.filter is hidden by CSS, and the JS replacement only ran on
    // the initial page load).
    document.addEventListener('instant-nav:after-swap', function() {
        // Stagger because varienGrid may build its DOM after the swap completes.
        [80, 400, 900].each(function(d) {
            setTimeout(function() {
                initModernPagination();
                attachPaginationObserver();
                initAdvancedFilters();
            }, d);
        });
    });

    function buildPagination(grid) {
        // Find the pager associated with this grid
        var gridWrapper = grid.up();
        var pager = null;

        // Search in siblings and parent for .pager
        if (gridWrapper) {
            pager = gridWrapper.down('.pager');
            if (!pager && gridWrapper.up()) {
                pager = gridWrapper.up().down('.pager');
            }
        }
        if (!pager) {
            // Search broadly
            pager = document.body.down('.pager');
        }
        if (!pager) return;

        // Extract pager data
        var pageInput = pager.down('input.page');
        var pagerText = pager.textContent;

        var currentPage = pageInput ? parseInt(pageInput.value) || 1 : 1;
        var totalPagesMatch = pagerText.match(/of\s+([\d,]+)\s+pages/);
        var totalPages = totalPagesMatch ? parseInt(totalPagesMatch[1].replace(/,/g, '')) : 1;
        var totalRecordsMatch = pagerText.match(/Total\s+([\d,]+)\s+records/);
        var totalRecords = totalRecordsMatch ? parseInt(totalRecordsMatch[1].replace(/,/g, '')) : 0;

        // Find per-page select (first select that's not an export format select)
        var selects = pager.select('select');
        var perPageSelect = null;
        var exportSelect = null;
        selects.each(function(sel) {
            var opts = Array.from(sel.options).map(function(o) { return o.value; });
            if (opts.indexOf('20') !== -1 || opts.indexOf('30') !== -1 || opts.indexOf('50') !== -1) {
                perPageSelect = sel;
            } else {
                exportSelect = sel;
            }
        });
        var perPage = perPageSelect ? parseInt(perPageSelect.value) : 20;

        // Find the grid JS object name
        var gridJsName = null;
        var searchScopes = [grid];
        if (gridWrapper) searchScopes.push(gridWrapper);
        if (gridWrapper && gridWrapper.up()) searchScopes.push(gridWrapper.up());

        for (var si = 0; si < searchScopes.length && !gridJsName; si++) {
            var btns = searchScopes[si].select('button');
            for (var bi = 0; bi < btns.length; bi++) {
                var oc = btns[bi].readAttribute('onclick') || '';
                var match = oc.match(/(\w+JsObject)\./);
                if (match) { gridJsName = match[1]; break; }
            }
        }
        // Also try to find from pager links
        if (!gridJsName) {
            var pagerLinks = pager.select('a');
            pagerLinks.each(function(a) {
                var oc = a.readAttribute('onclick') || '';
                var m = oc.match(/(\w+JsObject)\./);
                if (m) gridJsName = m[1];
            });
        }

        // Build pagination bar
        var bar = new Element('div', { 'class': 'modern-pagination' });

        // Left: info
        var startRecord = (currentPage - 1) * perPage + 1;
        var endRecord = Math.min(currentPage * perPage, totalRecords);
        var info = new Element('div', { 'class': 'pagination-info' });
        info.update('Showing <strong>' + startRecord.toLocaleString() + '-' + endRecord.toLocaleString() + '</strong> of <strong>' + totalRecords.toLocaleString() + '</strong> records');
        bar.insert(info);

        // Center: page buttons
        var pages = new Element('div', { 'class': 'pagination-pages' });

        function goToPage(page) {
            if (page < 1 || page > totalPages || page === currentPage) return;
            if (gridJsName && window[gridJsName]) {
                var gridObj = window[gridJsName];
                if (gridObj.setPage) {
                    gridObj.setPage(page);
                } else if (gridObj.reload) {
                    if (pageInput) pageInput.value = page;
                    gridObj.reload();
                }
            }
        }

        function addBtn(label, page, extraClass) {
            var btn = new Element('button', {
                'type': 'button',
                'class': 'pagination-btn' + (extraClass ? ' ' + extraClass : '')
            });
            btn.update('<span>' + label + '</span>');
            if (!extraClass || extraClass.indexOf('disabled') === -1) {
                btn.observe('click', function(e) { e.stop(); goToPage(page); });
            }
            pages.insert(btn);
            return btn;
        }

        // First + Prev
        addBtn('First', 1, currentPage <= 1 ? 'disabled' : '');
        addBtn('&lsaquo; Prev', currentPage - 1, currentPage <= 1 ? 'disabled' : '');

        // Page numbers with ellipsis
        var pageNumbers = getPageNumbers(currentPage, totalPages);
        var lastNum = 0;
        pageNumbers.each(function(num) {
            if (lastNum > 0 && num - lastNum > 1) {
                var ellipsis = new Element('span', { 'class': 'pagination-ellipsis' });
                ellipsis.update('&hellip;');
                pages.insert(ellipsis);
            }
            addBtn(String(num), num, num === currentPage ? 'active' : '');
            lastNum = num;
        });

        // Next + Last
        addBtn('Next &rsaquo;', currentPage + 1, currentPage >= totalPages ? 'disabled' : '');
        addBtn('Last', totalPages, currentPage >= totalPages ? 'disabled' : '');

        bar.insert(pages);

        // Right: per-page + export
        var rightControls = new Element('div', { 'class': 'pagination-perpage' });

        if (perPageSelect) {
            var perPageClone = perPageSelect.cloneNode(true);
            perPageClone.observe('change', function() {
                perPageSelect.value = perPageClone.value;
                // Trigger the original change event
                if (perPageSelect.onchange) {
                    perPageSelect.onchange();
                }
            });
            var showLabel = new Element('span');
            showLabel.update('Show ');
            rightControls.insert(showLabel);
            rightControls.insert(perPageClone);
            var perPageLabel = new Element('span');
            perPageLabel.update(' per page');
            rightControls.insert(perPageLabel);
        }

        bar.insert(rightControls);

        // Export controls
        if (exportSelect) {
            var exportDiv = new Element('div', { 'class': 'pagination-export' });
            var exportClone = exportSelect.cloneNode(true);
            exportDiv.insert(exportClone);
            // Find export button
            var exportBtn = pager.down('button.scalable');
            if (!exportBtn) {
                var allBtns = pager.select('button');
                allBtns.each(function(b) {
                    if (b.textContent.strip().indexOf('Export') !== -1) exportBtn = b;
                });
            }
            if (exportBtn) {
                var newExportBtn = new Element('button', {
                    'type': 'button',
                    'class': 'pagination-btn'
                });
                newExportBtn.update('<span>Export</span>');
                newExportBtn.observe('click', function() {
                    exportSelect.value = exportClone.value;
                    exportBtn.click();
                });
                exportDiv.insert(newExportBtn);
            }
            bar.insert(exportDiv);
        }

        // Insert after the grid
        if (grid.nextSibling) {
            grid.parentNode.insertBefore(bar, grid.nextSibling);
        } else {
            grid.parentNode.appendChild(bar);
        }
    }

    // Generate page numbers array with smart ellipsis
    function getPageNumbers(current, total) {
        if (total <= 7) {
            var all = [];
            for (var i = 1; i <= total; i++) all.push(i);
            return all;
        }
        var pages = [];
        // Always show page 1
        pages.push(1);
        // Show range around current page
        var start = Math.max(2, current - 2);
        var end = Math.min(total - 1, current + 2);
        // Adjust if near the start
        if (current <= 4) {
            end = Math.min(total - 1, 5);
        }
        // Adjust if near the end
        if (current >= total - 3) {
            start = Math.max(2, total - 4);
        }
        for (var j = start; j <= end; j++) {
            pages.push(j);
        }
        // Always show last page
        if (total > 1) pages.push(total);
        return pages;
    }

    // ============================================================
    // Per-row action dropdowns for Magento admin grids
    // Replaces the bulk mass-action bar with individual row actions
    // ============================================================
    // If we can't successfully replace the mass-action bar with per-row
    // dropdowns (no .massaction in DOM, no grids, no rows got a dropdown),
    // un-hide the original mass-action bar so the user still has a way
    // to perform bulk actions. Without this fallback any grid that
    // doesn't fit our injection assumptions becomes effectively
    // read-only — see the Orphaned Role Resources page for the symptom.
    function unhideMassactionFallback() {
        document.querySelectorAll('.admin-main .massaction, .admin-main .grid .massaction').forEach(function(el) {
            el.style.setProperty('display', 'block', 'important');
        });
    }

    function injectRowActions() {
        var massSelect = document.querySelector('.massaction select');
        if (!massSelect) {
            // Some pages render no .massaction at all (e.g. Orphaned
            // Resources). Nothing to inject — but also nothing to hide,
            // so just bail. The block-level override on those pages
            // adds a real top-right button.
            return;
        }

        var actions = [];
        for (var i = 0; i < massSelect.options.length; i++) {
            var opt = massSelect.options[i];
            if (opt.value && opt.value !== '') {
                actions.push({ label: opt.text, value: opt.value });
            }
        }
        if (actions.length === 0) {
            unhideMassactionFallback();
            return;
        }

        var tables = document.querySelectorAll('.grid table.data');
        if (tables.length === 0) {
            unhideMassactionFallback();
            return;
        }

        var injectedAny = false;
        tables.forEach(function(table) {
            // Leave the Cache Management grid on its native mass-action
            // workflow (Select All + Actions + Submit). Skipping it here
            // means injectedAny stays false and unhideMassactionFallback()
            // restores the original bar.
            if (table.id === 'cache_grid_table') return;
            if (table.id === 'indexer_processes_grid_table') return;
            // Invoices grid has its own merged View+PDF icon column
            // (see consolidateInvoiceActions below).
            if (table.id === 'sales_invoice_grid_table') return;
            // Add ACTIONS header
            var headings = table.querySelector('tr.headings');
            if (headings && !headings.querySelector('.row-actions-th')) {
                var th = document.createElement('th');
                th.className = 'row-actions-th';
                th.textContent = 'ACTIONS';
                th.style.cssText = 'text-align:center !important;';
                headings.appendChild(th);
            }

            // Add empty cell to filter row
            var filterRow = table.querySelector('tr.filter');
            if (filterRow && !filterRow.querySelector('.row-actions-filter')) {
                var ftd = document.createElement('td');
                ftd.className = 'row-actions-filter';
                filterRow.appendChild(ftd);
            }

            // Add action dropdown to each data row
            var rows = table.querySelectorAll('tbody tr');
            for (var r = 0; r < rows.length; r++) {
                var row = rows[r];
                if (row.classList.contains('headings') || row.classList.contains('filter') || row.querySelector('.row-action-wrap')) continue;

                // Find the checkbox in this row to get the order ID
                var cb = row.querySelector('input[type="checkbox"]');
                if (!cb) continue;

                var td = document.createElement('td');
                td.style.cssText = 'text-align:center; white-space:nowrap;';

                var wrap = document.createElement('div');
                wrap.className = 'row-action-wrap';

                var btn = document.createElement('button');
                btn.className = 'row-action-btn';
                btn.type = 'button';
                btn.innerHTML = 'Actions <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>';
                btn.onclick = function(e) {
                    e.stopPropagation();
                    // Close all other menus
                    document.querySelectorAll('.row-action-wrap.open').forEach(function(w) { w.classList.remove('open'); });
                    this.parentNode.classList.toggle('open');
                };

                var menu = document.createElement('div');
                menu.className = 'row-action-menu';

                for (var a = 0; a < actions.length; a++) {
                    (function(action, checkbox) {
                        var item = document.createElement('div');
                        item.className = 'row-action-item';
                        item.textContent = action.label;
                        item.onclick = function(e) {
                            e.stopPropagation();
                            // Uncheck all, check only this row
                            table.querySelectorAll('input[type="checkbox"]').forEach(function(c) { c.checked = false; });
                            checkbox.checked = true;
                            // Set the mass action value and submit
                            massSelect.value = action.value;
                            // Find and click the submit button
                            var submitBtn = document.querySelector('.massaction button[onclick]') ||
                                           document.querySelector('.massaction button[title="Submit"]') ||
                                           document.querySelector('.massaction .entry-edit button');
                            if (submitBtn) {
                                submitBtn.click();
                            } else {
                                // Fallback: trigger the form
                                var form = massSelect.closest('form') || document.querySelector('#sales_order_grid_massaction-form');
                                if (form) form.submit();
                            }
                        };
                        menu.appendChild(item);
                    })(actions[a], cb);
                }

                wrap.appendChild(btn);
                wrap.appendChild(menu);
                td.appendChild(wrap);
                row.appendChild(td);
                injectedAny = true;
            }
        });

        // No data rows actually got a dropdown (empty grid, all rows
        // already have one, or row checkboxes are missing). Fall back
        // to showing the original mass-action bar so users can still
        // invoke bulk actions manually.
        if (!injectedAny) {
            unhideMassactionFallback();
        }

        // Close menus on outside click
        document.addEventListener('click', function() {
            document.querySelectorAll('.row-action-wrap.open').forEach(function(w) { w.classList.remove('open'); });
        });
    }

    // Fix content-header button alignment — push to far right
    function fixHeaderButtons() {
        var headers = document.querySelectorAll('.content-header');
        headers.forEach(function(header) {
            var tr = header.querySelector('tr');
            if (!tr) return;
            var cells = tr.querySelectorAll('td');
            if (cells.length < 2) return;
            // First td = title, rest = buttons — force flex layout
            tr.style.cssText = 'display:flex!important;width:100%!important;align-items:center!important;';
            cells[0].style.cssText += 'flex:1!important;';
            for (var i = 1; i < cells.length; i++) {
                cells[i].style.cssText += 'flex-shrink:0!important;margin-left:8px!important;';
            }
        });
    }
    setTimeout(fixHeaderButtons, 300);

    // Remove checkbox column from all grids
    function removeCheckboxColumn() {
        var tables = document.querySelectorAll('.grid table.data');
        tables.forEach(function(table) {
            // Keep the native checkbox column on the Cache Management grid —
            // bulk select/refresh/flush there depends on the real
            // mass-action checkboxes (see scoped CSS in sidebar-nav.css).
            if (table.id === 'cache_grid_table') return;
            if (table.id === 'indexer_processes_grid_table') return;
            // Only hide the first column if it's actually a checkbox column.
            // Detect by inspecting the first body row: if its first cell has
            // an <input type="checkbox">, then the entire first column (head
            // + body + col) is the mass-action checkbox column. The previous
            // heuristic also hid first columns that were just empty or
            // centered, which over-fired on grids whose intentional first
            // column happened to be narrow/blank.
            var firstBodyRow = table.querySelector('tbody tr');
            if (!firstBodyRow || !firstBodyRow.children.length) return;
            if (!firstBodyRow.children[0].querySelector('input[type="checkbox"]')) return;

            var rows = table.querySelectorAll('tr');
            for (var r = 0; r < rows.length; r++) {
                var cells = rows[r].children;
                if (cells.length === 0) continue;
                cells[0].style.display = 'none';
            }
            var cols = table.querySelectorAll('col');
            if (cols.length > 0 && cols[0]) {
                cols[0].style.width = '0';
                cols[0].style.display = 'none';
            }
        });
    }

    // Inject a "select all" checkbox into the header of any grid whose
    // first column is mass-action checkboxes but whose header cell is
    // empty. Replaces the 4 Select All / Unselect All text links in the
    // toolbar with the more familiar header-checkbox toggle.
    function injectHeaderSelectAll() {
        var tables = document.querySelectorAll('.grid table.data');
        tables.forEach(function (table) {
            var firstBodyRow = table.querySelector('tbody tr');
            if (!firstBodyRow || !firstBodyRow.children.length) return;
            var firstBodyCell = firstBodyRow.children[0];
            if (!firstBodyCell || !firstBodyCell.querySelector('input[type="checkbox"]')) return;
            var headerRow = table.querySelector('thead tr');
            if (!headerRow || !headerRow.children.length) return;
            var headerCell = headerRow.children[0];
            if (!headerCell) return;
            // If Magento already rendered a select-all checkbox there, leave it.
            if (headerCell.querySelector('input[type="checkbox"]')) return;

            var cb = document.createElement('input');
            cb.type = 'checkbox';
            cb.className = 'mmd-select-all';
            cb.title = 'Select all';
            cb.style.cursor = 'pointer';
            cb.addEventListener('change', function () {
                // Prefer Magento's native selectAll/unselectAll on the
                // grid's massaction JS object — it updates the internal
                // selection set, the "N items selected" counter, and any
                // dependent UI in one call. The object name follows the
                // toolbar id: e.g. #cache_grid_massaction → window['cache_grid_massactionJsObject'].
                var massDiv = document.querySelector('[id$="_massaction"]');
                var massObj = massDiv && window[massDiv.id + 'JsObject'];
                if (massObj) {
                    if (cb.checked && typeof massObj.selectAll === 'function') {
                        massObj.selectAll();
                        return;
                    }
                    if (!cb.checked && typeof massObj.unselectAll === 'function') {
                        massObj.unselectAll();
                        return;
                    }
                }
                // Fallback for grids without a varienGridMassaction object:
                // simulate a click on each row checkbox that needs to flip.
                // .click() triggers both the inline onclick handler and the
                // native change event, so Magento's selection state updates
                // exactly as if the user had clicked manually.
                var rows = table.querySelectorAll('tbody tr');
                rows.forEach(function (row) {
                    var rowCb = row.querySelector('input[type="checkbox"]');
                    if (!rowCb || rowCb.disabled) return;
                    if (rowCb.checked !== cb.checked) rowCb.click();
                });
            });
            // Keep header checkbox in sync if user toggles individual rows.
            table.addEventListener('change', function (e) {
                if (!e.target || e.target === cb) return;
                if (e.target.type !== 'checkbox') return;
                if (!table.contains(e.target)) return;
                var rowCbs = table.querySelectorAll('tbody input[type="checkbox"]');
                if (!rowCbs.length) return;
                var all = true;
                rowCbs.forEach(function (rc) { if (!rc.checked) all = false; });
                cb.checked = all;
            });
            headerCell.innerHTML = '';
            headerCell.appendChild(cb);
            headerCell.style.textAlign = 'center';
        });
    }
    // Run immediately + on a few checkpoints for grids that paint late.
    injectHeaderSelectAll();
    [200, 800, 2000].forEach(function (delay) {
        setTimeout(injectHeaderSelectAll, delay);
    });
    // Also re-run whenever the DOM changes — Magento's grid AJAX (filter,
    // sort, paginate) replaces table.data with fresh HTML, which wipes any
    // checkbox we injected. A MutationObserver on document.body catches:
    //   • grids that render >2s after page load (heavy reports)
    //   • grids that reload via AJAX after the user filters/sorts
    //   • any other DOM mutation that touches a .grid table.data
    // injectHeaderSelectAll is idempotent (skips cells that already have a
    // checkbox), so being called repeatedly is harmless. Throttled so a
    // burst of mutations only triggers one re-run.
    (function () {
        if (typeof MutationObserver !== 'function') return;
        var pending = false;
        var obs = new MutationObserver(function (records) {
            // Only react if a record involves a grid table.
            var relevant = records.some(function (r) {
                if (!r.addedNodes) return false;
                for (var i = 0; i < r.addedNodes.length; i++) {
                    var n = r.addedNodes[i];
                    if (n.nodeType !== 1) continue;
                    if (n.matches && (n.matches('.grid table.data') || n.querySelector('.grid table.data'))) {
                        return true;
                    }
                    if (n.matches && (n.matches('tbody, thead, tr') && n.closest && n.closest('.grid table.data'))) {
                        return true;
                    }
                }
                return false;
            });
            if (!relevant || pending) return;
            pending = true;
            requestAnimationFrame(function () {
                pending = false;
                injectHeaderSelectAll();
            });
        });
        obs.observe(document.body, { childList: true, subtree: true });
    })();

    // Processing overlay — show a spinner while a mass-action submit
    // (reindex, flush, mass-update) is in flight. Magento submits the form
    // synchronously and the page navigates, so we show the overlay on
    // click and let the navigation tear it down naturally.
    function buildOverlay(label) {
        var ov = document.createElement('div');
        ov.className = 'mmd-processing-overlay';
        var stack = document.createElement('div');
        stack.className = 'mmd-spinner-stack';
        var spin = document.createElement('div');
        spin.className = 'mmd-spinner';
        var lbl = document.createElement('div');
        lbl.className = 'mmd-spinner-label';
        lbl.textContent = label || 'Processing…';
        stack.appendChild(spin);
        stack.appendChild(lbl);
        ov.appendChild(stack);
        return ov;
    }
    function wireMassactionSpinner() {
        document.querySelectorAll('[id$="_massaction"] button, .massaction button').forEach(function (btn) {
            if (btn.__mmdSpinnerWired) return;
            btn.__mmdSpinnerWired = true;
            btn.addEventListener('click', function () {
                // Only show on grids where there's actually a selection,
                // otherwise Magento's JS alerts "no items selected" and
                // doesn't navigate — overlay would hang. Check selection
                // count by looking at the visible counter (<strong> in the
                // toolbar) — it ticks as the user clicks rows.
                var massDiv = btn.closest('[id$="_massaction"], .massaction');
                if (massDiv) {
                    var count = massDiv.querySelector('strong');
                    if (count && /^\s*0\s*$/.test(count.textContent)) return;
                }
                // Index Management runs mass-action in a hidden iframe so
                // the admin can keep working — skip the blocking overlay.
                if (document.body.classList.contains('adminhtml-process-list')) return;
                // Label by action: Reindex/Flush/Refresh → use that verb.
                var sel = massDiv && massDiv.querySelector('select');
                var verb = 'Processing';
                if (sel && sel.options[sel.selectedIndex]) {
                    var optText = sel.options[sel.selectedIndex].text.trim();
                    if (optText) verb = optText;
                }
                document.body.appendChild(buildOverlay(verb + '…'));
            });
        });
    }
    [300, 1000, 2200].forEach(function (delay) {
        setTimeout(wireMassactionSpinner, delay);
    });

    // Background mass-action on Index Management — reindex can take a
    // while, and freezing the whole admin while it runs is unfriendly.
    // Redirect the mass-action form to a hidden iframe so the page stays
    // alive; show a non-blocking toast that updates when the iframe loads.
    function wireIndexBackgroundReindex() {
        if (!document.body.classList.contains('adminhtml-process-list')) return;
        var form = document.querySelector('form[id$="_massaction-form"]');
        if (!form || form.__mmdBgWired) return;
        var massDiv = form.closest('[id$="_massaction"], .massaction');
        if (!massDiv) return;
        form.__mmdBgWired = true;

        var frame = document.getElementById('mmd-bg-frame');
        if (!frame) {
            frame = document.createElement('iframe');
            frame.id = 'mmd-bg-frame';
            frame.name = 'mmd-bg-frame';
            frame.style.cssText = 'position:absolute;width:0;height:0;border:0;left:-9999px;top:-9999px;';
            document.body.appendChild(frame);
        }
        form.setAttribute('target', 'mmd-bg-frame');

        function showToast(text, kind) {
            var t = document.getElementById('mmd-bg-toast');
            if (!t) {
                t = document.createElement('div');
                t.id = 'mmd-bg-toast';
                t.className = 'mmd-bg-toast';
                document.body.appendChild(t);
            }
            t.className = 'mmd-bg-toast' + (kind ? ' is-' + kind : '');
            t.innerHTML = '<span class="mmd-bg-toast-dot"></span><span class="mmd-bg-toast-text"></span>';
            t.querySelector('.mmd-bg-toast-text').textContent = text;
            t.classList.add('is-visible');
        }
        function hideToastSoon() {
            var t = document.getElementById('mmd-bg-toast');
            if (!t) return;
            setTimeout(function () { t.classList.remove('is-visible'); }, 4000);
        }

        // Magento's varienGridMassaction.apply() calls form.submit()
        // programmatically — which does NOT fire the 'submit' event. Wrap
        // the native submit() method so we run before the actual POST.
        var submitBtn = massDiv.querySelector('button');
        var submitLabel = submitBtn && submitBtn.querySelector('span span');
        var origLabelText = submitLabel ? submitLabel.textContent : '';

        function setButtonProcessing(on) {
            if (!submitBtn) return;
            if (on) {
                submitBtn.classList.add('mmd-btn-processing');
                submitBtn.disabled = true;
                if (submitLabel) submitLabel.textContent = 'Processing…';
            } else {
                submitBtn.classList.remove('mmd-btn-processing');
                submitBtn.disabled = false;
                if (submitLabel) submitLabel.textContent = origLabelText || 'Submit';
            }
        }

        var origSubmit = form.submit.bind(form);
        form.submit = function () {
            var sel = massDiv.querySelector('select');
            var verb = 'Mass action';
            if (sel && sel.options[sel.selectedIndex]) {
                verb = sel.options[sel.selectedIndex].text.trim() || verb;
            }
            showToast(verb + ' running in background — you can keep working', 'running');
            setButtonProcessing(true);
            frame.onload = function () {
                showToast(verb + ' complete', 'done');
                hideToastSoon();
                setButtonProcessing(false);
                if (window.indexer_processes_grid && typeof indexer_processes_grid.reload === 'function') {
                    try { indexer_processes_grid.reload(); } catch (e) {}
                }
            };
            return origSubmit();
        };
    }
    [300, 1000, 2200].forEach(function (delay) {
        setTimeout(wireIndexBackgroundReindex, delay);
    });

    // Inject KPI summary cards above grid tables.
    // Restricted to the Dashboard — every other backend page renders bare
    // grids without the KPI summary clutter.
    function injectGridKPIs() {
        if (!document.body.classList.contains('adminhtml-dashboard-index')) return;

        // Find all grids on the page
        var grids = document.querySelectorAll('.grid, .grid-container, [id$="_grid"]');
        if (grids.length === 0) return;

        // Get page title for context
        var pageTitle = document.querySelector('.content-header h3');
        var titleText = pageTitle ? pageTitle.textContent.trim().toLowerCase() : '';
        // Also check URL for context
        var url = window.location.href.toLowerCase();

        grids.forEach(function(grid) {
            // Skip if already has KPI cards anywhere nearby
            var parent = grid.parentNode;
            while (parent && parent !== document.body) {
                if (parent.querySelector('.grid-kpi-cards')) return;
                parent = parent.parentNode;
            }

            var table = grid.querySelector('table.data') || grid.querySelector('table');
            if (!table || !table.querySelector('tbody')) return;
            // No KPI summary cards on Cache Management — the grid speaks
            // for itself and the cards just add vertical clutter there.
            if (table.id === 'cache_grid_table') return;
            if (table.id === 'indexer_processes_grid_table') return;

            var rows = table.querySelectorAll('tbody tr');
            var total = 0, statusCounts = {};
            rows.forEach(function(row) {
                if (row.classList.contains('headings') || row.classList.contains('filter') || row.cells.length < 2) return;
                total++;
                row.querySelectorAll('td').forEach(function(td) {
                    var t = td.textContent.trim().toLowerCase();
                    if (['complete','processing','pending','canceled','closed','holded','enabled','disabled','active','inactive'].indexOf(t) !== -1) {
                        var k = t.charAt(0).toUpperCase() + t.slice(1);
                        statusCounts[k] = (statusCounts[k] || 0) + 1;
                    }
                });
            });

            if (total === 0) return;

            // Try to get real total from pagination
            var allPagerTexts = document.querySelectorAll('.pagination-info, .pager .results');
            allPagerTexts.forEach(function(el) {
                var m = el.textContent.match(/of\s+([\d,]+)/i);
                if (m) {
                    var realTotal = parseInt(m[1].replace(/,/g,''), 10);
                    if (realTotal > total) total = realTotal;
                }
            });

            var confirmed = (statusCounts['Complete'] || 0) + (statusCounts['Processing'] || 0);
            var pending = statusCounts['Pending'] || 0;
            var canceled = statusCounts['Canceled'] || statusCounts['Closed'] || 0;
            var enabled = statusCounts['Enabled'] || 0;
            var disabled = statusCounts['Disabled'] || 0;
            var active = statusCounts['Active'] || 0;
            var inactive = statusCounts['Inactive'] || 0;

            var cards;
            if (titleText.indexOf('order') !== -1 || url.indexOf('sales_order') !== -1) {
                cards = [
                    { num: total, label: 'Total Registrations', color: '#22d3ee' },
                    { num: confirmed, label: 'Confirmed', color: '#10b981' },
                    { num: pending, label: 'Pending', color: '#f59e0b' }
                ];
            } else if (titleText.indexOf('invoice') !== -1 || url.indexOf('sales_invoice') !== -1) {
                cards = [
                    { num: total, label: 'Total Invoices', color: '#22d3ee' },
                    { num: total, label: 'Paid', color: '#10b981' },
                    { num: 0, label: 'Unpaid', color: '#f59e0b' }
                ];
            } else if (titleText.indexOf('transaction') !== -1 || url.indexOf('sales_transaction') !== -1) {
                cards = [
                    { num: total, label: 'Total Transactions', color: '#22d3ee' },
                    { num: total, label: 'Completed', color: '#10b981' },
                    { num: 0, label: 'Pending', color: '#f59e0b' }
                ];
            } else if (url.indexOf('tax_rule') !== -1 || url.indexOf('tax_rate') !== -1) {
                cards = [
                    { num: total, label: 'Total Tax Rules', color: '#22d3ee' },
                    { num: total, label: 'Active', color: '#10b981' },
                    { num: 0, label: 'Inactive', color: '#f59e0b' }
                ];
            } else if (titleText.indexOf('product') !== -1 || titleText.indexOf('course') !== -1 || titleText.indexOf('manage') !== -1 || url.indexOf('catalog_product') !== -1) {
                cards = [
                    { num: total, label: 'Total Courses', color: '#22d3ee' },
                    { num: enabled || total, label: 'Enabled', color: '#10b981' },
                    { num: disabled, label: 'Disabled', color: '#f59e0b' }
                ];
            } else if (titleText.indexOf('categor') !== -1 || url.indexOf('catalog_category') !== -1) {
                cards = [
                    { num: total, label: 'Total Categories', color: '#22d3ee' },
                    { num: active || total, label: 'Active', color: '#10b981' },
                    { num: inactive, label: 'Inactive', color: '#f59e0b' }
                ];
            } else if (titleText.indexOf('customer') !== -1 || titleText.indexOf('learner') !== -1 || url.indexOf('customer') !== -1) {
                cards = [
                    { num: total, label: 'Total Learners', color: '#22d3ee' },
                    { num: active || total, label: 'Active', color: '#10b981' },
                    { num: inactive, label: 'Inactive', color: '#ef4444' }
                ];
            } else if (url.indexOf('cms_page') !== -1) {
                cards = [
                    { num: total, label: 'Total Pages', color: '#22d3ee' },
                    { num: enabled || total, label: 'Enabled', color: '#10b981' },
                    { num: disabled, label: 'Disabled', color: '#f59e0b' }
                ];
            } else if (url.indexOf('cms_block') !== -1) {
                cards = [
                    { num: total, label: 'Total Blocks', color: '#22d3ee' },
                    { num: active || total, label: 'Active', color: '#10b981' },
                    { num: inactive, label: 'Inactive', color: '#f59e0b' }
                ];
            } else if (url.indexOf('promo') !== -1) {
                cards = [
                    { num: total, label: 'Total Rules', color: '#22d3ee' },
                    { num: active || total, label: 'Active', color: '#10b981' },
                    { num: inactive, label: 'Inactive', color: '#f59e0b' }
                ];
            } else if (url.indexOf('search') !== -1) {
                cards = [
                    { num: total, label: 'Total Search Terms', color: '#22d3ee' },
                    { num: total, label: 'Tracked', color: '#10b981' },
                    { num: 0, label: 'Pending Review', color: '#f59e0b' }
                ];
            } else if (url.indexOf('review') !== -1) {
                cards = [
                    { num: total, label: 'Total Reviews', color: '#22d3ee' },
                    { num: total, label: 'Approved', color: '#10b981' },
                    { num: pending, label: 'Pending', color: '#f59e0b' }
                ];
            } else {
                cards = [
                    { num: total, label: 'Total Records', color: '#22d3ee' },
                    { num: confirmed || active || enabled || total, label: 'Active', color: '#10b981' },
                    { num: pending || inactive || disabled || canceled, label: 'Other', color: '#f59e0b' }
                ];
            }

            var wrapper = document.createElement('div');
            wrapper.className = 'grid-kpi-cards';
            wrapper.style.cssText = 'display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-bottom:18px;';
            cards.forEach(function(c) {
                var d = document.createElement('div');
                d.style.cssText = 'background:#1e293b;border:1px solid rgba(34,211,238,0.1);border-radius:12px;padding:22px 20px;text-align:center;box-shadow:0 0 20px rgba(34,211,238,0.02);';
                d.innerHTML = '<div style="font-size:36px;font-weight:700;color:'+c.color+';line-height:1.1;margin-bottom:6px;">'+c.num+'</div><div style="font-size:13px;color:#94a3b8;font-weight:500;">'+c.label+'</div>';
                wrapper.appendChild(d);
            });

            // Insert before the grid, at the closest content container level
            var insertTarget = grid;
            if (grid.parentNode.classList.contains('box') || grid.parentNode.classList.contains('entry-edit')) {
                insertTarget = grid.parentNode;
            }
            insertTarget.parentNode.insertBefore(wrapper, insertTarget);
        });
    }

    // For grids without a massaction bar (e.g. System → Permissions →
    // Users / Roles), Magento makes the whole row clickable to navigate
    // to the edit page. That's invisible — users don't know rows are
    // clickable, and there's no obvious delete affordance. Inject an
    // ACTIONS column with explicit Edit + Delete buttons, derived from
    // the row's existing title="…/edit/…" URL.
    function injectEditDeleteActions() {
        document.querySelectorAll('.grid table.data').forEach(function (table) {
            // Skip grids that already got the massaction-based dropdowns,
            // or that opt out explicitly.
            if (table.id === 'cache_grid_table') return;
            if (table.id === 'indexer_processes_grid_table') return;
            // CMS pages grid has its own merged Preview+Edit+Delete cell —
            // handled by consolidateCmsPageActions() below.
            if (table.id === 'cmsPageGrid_table') return;
            if (table.querySelector('.row-action-wrap')) return;
            if (table.querySelector('.row-edit-actions')) return;

            // Sample a real data row to confirm rows are edit-linked.
            var dataRows = [];
            table.querySelectorAll('tbody tr').forEach(function (r) {
                if (r.classList.contains('headings') || r.classList.contains('filter')) return;
                dataRows.push(r);
            });
            if (!dataRows.length) return;
            var sampleTitle = dataRows[0].getAttribute('title') || '';
            if (sampleTitle.indexOf('/edit/') === -1) return;

            // Header
            var headings = table.querySelector('tr.headings');
            if (headings && !headings.querySelector('.row-edit-th')) {
                var th = document.createElement('th');
                th.className = 'row-edit-th';
                th.textContent = 'ACTIONS';
                th.style.cssText = 'text-align:center !important; width:120px;';
                headings.appendChild(th);
            }
            var filterRow = table.querySelector('tr.filter');
            if (filterRow && !filterRow.querySelector('.row-edit-filter')) {
                var ftd = document.createElement('td');
                ftd.className = 'row-edit-filter';
                filterRow.appendChild(ftd);
            }

            dataRows.forEach(function (row) {
                var editUrl = row.getAttribute('title');
                if (!editUrl || editUrl.indexOf('/edit/') === -1) return;
                var deleteUrl = editUrl.replace('/edit/', '/delete/');

                var td = document.createElement('td');
                td.className = 'row-edit-actions';
                td.style.cssText = 'text-align:center; white-space:nowrap;';

                var edit = document.createElement('a');
                edit.href = editUrl;
                edit.className = 'row-edit-btn';
                edit.title = 'Edit';
                edit.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
                edit.onclick = function (e) { e.stopPropagation(); };

                var del = document.createElement('a');
                del.href = deleteUrl;
                del.className = 'row-delete-btn';
                del.title = 'Delete';
                del.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>';
                del.onclick = function (e) {
                    e.stopPropagation();
                    if (!confirm('Delete this record? This cannot be undone.')) {
                        e.preventDefault();
                        return false;
                    }
                };

                td.appendChild(edit);
                td.appendChild(del);
                row.appendChild(td);
                // Row-click navigation still works — these buttons stop
                // propagation so a button click doesn't double-fire it.
            });
        });
    }

    // CMS Pages grid: merge the renderer-provided "Preview" link column
    // with Edit + Delete into a single Actions cell, all rendered as
    // icons. Skips the generic injectEditDeleteActions path above.
    // Find the index of a header column by its visible text.
    function findColumnIndex(table, headerText) {
        var headings = table.querySelector('tr.headings');
        if (!headings) return -1;
        var ths = headings.querySelectorAll('th');
        for (var i = 0; i < ths.length; i++) {
            if (ths[i].textContent.trim() === headerText) return i;
        }
        return -1;
    }

    // CMS Pages "Store View" column renders the full Website → Store → Store
    // View hierarchy on three lines, which bloats every row. Rename the
    // column to "Branch" and reduce each cell to just the deepest level
    // (the actual storefront the page belongs to), with " Store View"
    // stripped so it matches the Registrations branch labels.
    function simplifyCmsPageStoreColumn() {
        // Kept as a thin wrapper for clarity; the generalised walker below
        // covers cmsPageGrid_table too.
        simplifyAllStoreViewColumns();
    }

    // Generalised: walk every grid table on the page, find any column
    // whose header text is "Store View" (or "Store Views" / "Stores" /
    // "Website") rendered by Mage_Adminhtml_Block_Widget_Grid_Column_
    // Renderer_Store, rename it "Branch", and reduce each cell to the
    // deepest level with " Store View" stripped — so a cell that says
    //   "Main Website / Main Website Store / Singapore Store View"
    // collapses to "Singapore" (matching the branch-pill labels).
    function simplifyAllStoreViewColumns() {
        var STORE_HEADERS = ['Store View', 'Store Views', 'Stores', 'Purchase Point', 'Purchased From'];
        document.querySelectorAll('.grid table.data').forEach(function (table) {
            var headings = table.querySelector('tr.headings');
            if (!headings) return;
            var ths = headings.querySelectorAll('th');
            for (var i = 0; i < ths.length; i++) {
                var th = ths[i];
                var rawHeader = (th.textContent || '').trim();
                if (STORE_HEADERS.indexOf(rawHeader) === -1) continue;
                if (th.dataset.branchRenamed === '1') continue;

                th.innerHTML = '<span class="nobr">Branch</span>';
                th.dataset.branchRenamed = '1';
                var idx = i;

                table.querySelectorAll('tbody tr').forEach(function (row) {
                    if (row.classList.contains('headings') || row.classList.contains('filter')) return;
                    var cells = row.querySelectorAll('td');
                    if (!cells[idx]) return;
                    var cell = cells[idx];
                    if (cell.dataset.branchSimplified === '1') return;
                    // The store renderer outputs lines like
                    //   "Main Website / Main Website Store / Singapore Store View"
                    // separated by <br>, with leading &nbsp; chars used as
                    // a tree-indent on each line. Convert <br>/block tags to
                    // newlines, then read innerText so &nbsp; decodes to a
                    // real non-breaking space; collapse those + trim to get
                    // a clean leaf label.
                    // Read innerText so the browser handles <br>→\n and
                    // &nbsp;→U+00A0 — that's the only reliable way to avoid
                    // ending up with literal "&nbsp;" text on grids whose
                    // renderer double-escapes the entity.
                    var raw = cell.innerText || cell.textContent || '';
                    var lines = raw.split(/[\r\n]+/).map(function (s) {
                        return s.replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
                    }).filter(Boolean);
                    var leaf = lines.length ? lines[lines.length - 1] : '';
                    leaf = leaf.replace(/\s*Store View\s*$/i, '');
                    leaf = leaf.replace(/\s*Store\s*$/i, '');
                    cell.textContent = leaf;
                    cell.dataset.branchSimplified = '1';
                });
            }
        });
    }

    function consolidateCmsPageActions() {
        var table = document.getElementById('cmsPageGrid_table');
        if (!table) return;
        // Re-run on AJAX reloads — if the data rows changed but our flag
        // is still set, the merged cells are stale and need rebuilding.
        var firstRow = table.querySelector('tbody tr:not(.headings):not(.filter)');
        if (firstRow && !firstRow.querySelector('.row-edit-actions')) {
            table.dataset.cmsActionsMerged = '';
        }
        if (table.dataset.cmsActionsMerged === '1') return;

        var headings = table.querySelector('tr.headings');
        if (!headings) return;
        var ths = headings.querySelectorAll('th');
        if (!ths.length) return;
        // Last column is the renderer-driven "Action" column.
        var lastTh = ths[ths.length - 1];
        lastTh.innerHTML = '<span class="nobr">Actions</span>';
        lastTh.style.textAlign = 'center';
        lastTh.style.width = '110px';

        var filterRow = table.querySelector('tr.filter');
        if (filterRow) {
            var filterCells = filterRow.querySelectorAll('th, td');
            if (filterCells.length) {
                filterCells[filterCells.length - 1].innerHTML = '';
            }
        }

        var iconEye    = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>';
        var iconEdit   = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
        var iconDelete = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>';

        var dataRows = table.querySelectorAll('tbody tr');
        dataRows.forEach(function (row) {
            if (row.classList.contains('headings') || row.classList.contains('filter')) return;
            var cells = row.querySelectorAll('td');
            if (!cells.length) return;
            var actionCell = cells[cells.length - 1];
            var editUrl = row.getAttribute('title') || '';
            var previewLink = actionCell.querySelector('a[target="_blank"]');
            var previewUrl = previewLink ? previewLink.getAttribute('href') : '';
            var deleteUrl = editUrl.indexOf('/edit/') !== -1 ? editUrl.replace('/edit/', '/delete/') : '';

            actionCell.innerHTML = '';
            actionCell.className = 'row-edit-actions';
            actionCell.style.cssText = 'text-align:center; white-space:nowrap;';

            if (previewUrl) {
                var preview = document.createElement('a');
                preview.href = previewUrl;
                preview.target = '_blank';
                preview.className = 'row-edit-btn';
                preview.title = 'Preview';
                preview.innerHTML = iconEye;
                preview.onclick = function (e) { e.stopPropagation(); };
                actionCell.appendChild(preview);
            }
            if (editUrl) {
                var edit = document.createElement('a');
                edit.href = editUrl;
                edit.className = 'row-edit-btn';
                edit.title = 'Edit';
                edit.innerHTML = iconEdit;
                edit.onclick = function (e) { e.stopPropagation(); };
                actionCell.appendChild(edit);
            }
            if (deleteUrl) {
                var del = document.createElement('a');
                del.href = deleteUrl;
                del.className = 'row-delete-btn';
                del.title = 'Delete';
                del.innerHTML = iconDelete;
                del.onclick = function (e) {
                    e.stopPropagation();
                    if (!confirm('Delete this page? This cannot be undone.')) {
                        e.preventDefault();
                        return false;
                    }
                };
                actionCell.appendChild(del);
            }
        });
        table.dataset.cmsActionsMerged = '1';
    }

    // Invoices grid: merge the renderer-provided "View" link column with
    // a per-row "Print PDF" icon into a single Actions cell, all rendered
    // as icons. Hides the legacy "Actions ▾" dropdown for this grid
    // (skipped explicitly in injectRowActions above).
    function consolidateInvoiceActions() {
        var table = document.getElementById('sales_invoice_grid_table');
        if (!table) return;

        // Re-run on AJAX reloads if rows lost their merged cell.
        var firstRow = table.querySelector('tbody tr:not(.headings):not(.filter)');
        if (firstRow && !firstRow.querySelector('.row-edit-actions')) {
            table.dataset.invoiceActionsMerged = '';
        }
        if (table.dataset.invoiceActionsMerged === '1') return;

        var headings = table.querySelector('tr.headings');
        if (!headings) return;
        var ths = headings.querySelectorAll('th');
        if (!ths.length) return;

        var lastTh = ths[ths.length - 1];
        lastTh.innerHTML = '<span class="nobr">Actions</span>';
        lastTh.style.textAlign = 'center';
        lastTh.style.width = '150px';

        var filterRow = table.querySelector('tr.filter');
        if (filterRow) {
            var filterCells = filterRow.querySelectorAll('th, td');
            if (filterCells.length) {
                filterCells[filterCells.length - 1].innerHTML = '';
            }
        }

        var iconEye    = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>';
        var iconEdit   = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
        var iconDelete = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>';
        var iconPdf    = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="15" x2="15" y2="15"/></svg>';

        var dataRows = table.querySelectorAll('tbody tr');
        dataRows.forEach(function (row) {
            if (row.classList.contains('headings') || row.classList.contains('filter')) return;
            var cells = row.querySelectorAll('td');
            if (!cells.length) return;
            var actionCell = cells[cells.length - 1];

            // Prefer the row's title attribute (Magento sets it to the
            // view URL for sales_invoice_grid). Fall back to any <a>
            // already in the action cell for safety.
            var viewUrl = row.getAttribute('title') || '';
            if (!viewUrl) {
                var existingLink = actionCell.querySelector('a');
                viewUrl = existingLink ? existingLink.getAttribute('href') : '';
            }
            if (!viewUrl) return;

            // Edit on an invoice = open invoice for editing (the view page
            // is the only editor — you add comments, send email, etc.
            // there). Delete = void / cancel. Both go via Magento's stock
            // controllers; pdf opens the print endpoint in a new tab.
            var editUrl   = viewUrl;
            var deleteUrl = viewUrl.replace('/view/', '/cancel/');
            var pdfUrl    = viewUrl.replace('/view/', '/print/');

            actionCell.innerHTML = '';
            actionCell.className = 'row-edit-actions';
            actionCell.style.cssText = 'text-align:center; white-space:nowrap;';

            var view = document.createElement('a');
            view.href = viewUrl;
            view.className = 'row-edit-btn';
            view.title = 'View';
            view.innerHTML = iconEye;
            view.onclick = function (e) { e.stopPropagation(); };
            actionCell.appendChild(view);

            var edit = document.createElement('a');
            edit.href = editUrl;
            edit.className = 'row-edit-btn';
            edit.title = 'Edit';
            edit.innerHTML = iconEdit;
            edit.onclick = function (e) { e.stopPropagation(); };
            actionCell.appendChild(edit);

            var del = document.createElement('a');
            del.href = deleteUrl;
            del.className = 'row-delete-btn';
            del.title = 'Cancel / Void';
            del.innerHTML = iconDelete;
            del.onclick = function (e) {
                e.stopPropagation();
                if (!confirm('Cancel this invoice? Pending invoices will be voided; settled invoices cannot be cancelled.')) {
                    e.preventDefault();
                    return false;
                }
            };
            actionCell.appendChild(del);

            var pdf = document.createElement('a');
            pdf.href = pdfUrl;
            pdf.target = '_blank';
            pdf.className = 'row-edit-btn';
            pdf.title = 'Print PDF';
            pdf.innerHTML = iconPdf;
            pdf.onclick = function (e) { e.stopPropagation(); };
            actionCell.appendChild(pdf);
        });
        table.dataset.invoiceActionsMerged = '1';
    }

    // Final pass: on every grid, if both a renderer-driven "Action"
    // column (text links: View / Edit / etc.) AND a JS-injected
    // "ACTIONS" column (icon buttons) exist, drop the Action column —
    // single Actions cell with icons only.
    function mergeDuplicateActionColumns() {
        document.querySelectorAll('.grid table.data').forEach(function (table) {
            if (table.dataset.actionsMerged === '1') return;
            var headings = table.querySelector('tr.headings');
            if (!headings) return;
            var ths = headings.querySelectorAll('th');

            // Locate the indexes of both columns.
            var textActionIdx = -1;
            var iconActionIdx = -1;
            for (var i = 0; i < ths.length; i++) {
                var label = (ths[i].textContent || '').trim();
                if (label === 'Action' && textActionIdx === -1) {
                    textActionIdx = i;
                } else if ((label === 'ACTIONS' || label === 'Actions') && iconActionIdx === -1) {
                    iconActionIdx = i;
                }
            }

            // Need both to merge.
            if (textActionIdx === -1 || iconActionIdx === -1) return;
            if (textActionIdx === iconActionIdx) return;

            // Rename the icon column to "Actions" (sentence case) and drop
            // the text Action column entirely (header, filter cell, body
            // cells). Iterate rows by index of the text column — easier
            // than tracking after a header removal.
            ths[iconActionIdx].innerHTML = '<span class="nobr">Actions</span>';

            // Remove text Action column from header.
            ths[textActionIdx].remove();

            // Remove the same column from filter row.
            var filterRow = table.querySelector('tr.filter');
            if (filterRow) {
                var fcells = filterRow.querySelectorAll('th, td');
                if (fcells[textActionIdx]) {
                    fcells[textActionIdx].remove();
                }
            }

            // Remove from each data row.
            table.querySelectorAll('tbody tr').forEach(function (row) {
                if (row.classList.contains('headings') || row.classList.contains('filter')) return;
                var cells = row.querySelectorAll('td');
                if (cells[textActionIdx]) {
                    cells[textActionIdx].remove();
                }
            });

            table.dataset.actionsMerged = '1';
        });
    }

    // Apply all grid enhancements
    function applyGridEnhancements() {
        // Remove old KPI cards first
        document.querySelectorAll('.grid-kpi-cards').forEach(function(el) { el.remove(); });
        removeCheckboxColumn();
        injectRowActions();
        injectEditDeleteActions();
        simplifyCmsPageStoreColumn();
        consolidateCmsPageActions();
        consolidateInvoiceActions();
        mergeDuplicateActionColumns();
        injectGridKPIs();
    }

    // Run on initial load. Retries cover slow first paints where the
    // grid's tbody isn't laid out yet at the 500ms mark — without these,
    // injectGridKPIs bails at total === 0 and the cards never appear
    // until a pagination/filter AJAX retriggers it.
    setTimeout(applyGridEnhancements, 200);
    setTimeout(applyGridEnhancements, 800);
    setTimeout(applyGridEnhancements, 1800);

    // Watch for grid rows arriving late (e.g. AJAX-loaded grids that
    // don't go through Prototype's Ajax.Responders). When the tbody
    // gains rows after the retries above, inject immediately. Also
    // re-armable for PJAX swaps where the old tbody is replaced.
    var kpiObserver = null;
    var kpiObsScheduled = false;
    function attachKpiObserver() {
        if (typeof MutationObserver === 'undefined') return;
        if (!kpiObserver) {
            kpiObserver = new MutationObserver(function() {
                if (kpiObsScheduled) return;
                kpiObsScheduled = true;
                setTimeout(function() {
                    kpiObsScheduled = false;
                    applyGridEnhancements();
                }, 150);
            });
        }
        document.querySelectorAll('.grid table.data tbody, [id$="_grid"] tbody').forEach(function(tbody) {
            kpiObserver.observe(tbody, { childList: true });
        });
    }
    attachKpiObserver();

    // PJAX swap (instant-nav.js) replaces the grid wholesale, so the
    // observer above is now watching detached nodes and the cards we
    // injected earlier are gone. Re-arm the observer on the new tbody
    // and rerun the enhancements at the same staggered intervals as
    // initial load.
    document.addEventListener('instant-nav:after-swap', function () {
        [80, 400, 900, 1800].each(function (d) {
            setTimeout(function () {
                attachKpiObserver();
                applyGridEnhancements();
            }, d);
        });
    });

    // Re-run after every AJAX request (covers grid pagination/sort/filter)
    if (typeof Ajax !== 'undefined' && Ajax.Responders) {
        Ajax.Responders.register({
            onComplete: function() {
                setTimeout(applyGridEnhancements, 300);
            }
        });
    }

    // ============================================================
    // Product Options → Table Conversion (Order Detail Page)
    // Transforms text-block options into a structured table
    // ============================================================
    function transformProductOptions() {
        // Find all product options blocks on order detail pages
        var optionDls = document.querySelectorAll('.order-tables .item-options, dl.item-options');
        if (optionDls.length === 0) {
            // Fallback: look for the text-based options inside order item rows
            var cells = document.querySelectorAll('td');
            var optBlocks = [];
            cells.forEach(function(td) {
                var text = td.innerHTML || '';
                if (text.indexOf('<strong>') !== -1 && (text.indexOf('Mode of Training') !== -1 || text.indexOf('Course Date') !== -1 || text.indexOf('Sponsorship') !== -1)) {
                    optBlocks.push(td);
                }
            });
            if (optBlocks.length === 0) return;

            optBlocks.forEach(function(td) {
                transformOptionCell(td);
            });
            return;
        }

        optionDls.forEach(function(dl) {
            transformOptionDl(dl);
        });
    }

    function transformOptionCell(td) {
        var html = td.innerHTML;
        // Parse "key: value" lines from bold tags
        var pairs = [];
        var regex = /<strong[^>]*>([^<]+)<\/strong>\s*:\s*([^<\n]+)/gi;
        var match;
        while ((match = regex.exec(html)) !== null) {
            pairs.push({ label: match[1].trim(), value: match[2].trim() });
        }
        if (pairs.length === 0) return;

        // Build a clean table
        var table = document.createElement('table');
        table.style.cssText = 'width:100%;border-collapse:collapse;font-size:12px;margin:4px 0;';
        pairs.forEach(function(p) {
            var tr = document.createElement('tr');
            var tdLabel = document.createElement('td');
            tdLabel.style.cssText = 'padding:4px 10px 4px 0;color:#22d3ee;font-weight:600;white-space:nowrap;vertical-align:top;font-size:11.5px;';
            tdLabel.textContent = p.label;
            var tdValue = document.createElement('td');
            tdValue.style.cssText = 'padding:4px 0;color:#cbd5e1;font-size:12px;';
            tdValue.textContent = p.value;
            tr.appendChild(tdLabel);
            tr.appendChild(tdValue);
            table.appendChild(tr);
        });

        td.innerHTML = '';
        td.appendChild(table);
    }

    function transformOptionDl(dl) {
        var dts = dl.querySelectorAll('dt');
        var dds = dl.querySelectorAll('dd');
        if (dts.length === 0) return;

        var pairs = [];
        for (var i = 0; i < dts.length; i++) {
            pairs.push({
                label: (dts[i].textContent || '').trim(),
                value: (dds[i] ? dds[i].textContent : '').trim()
            });
        }

        var table = document.createElement('table');
        table.style.cssText = 'width:100%;border-collapse:collapse;font-size:12px;margin:4px 0;';
        pairs.forEach(function(p) {
            var tr = document.createElement('tr');
            var tdLabel = document.createElement('td');
            tdLabel.style.cssText = 'padding:4px 10px 4px 0;color:#22d3ee;font-weight:600;white-space:nowrap;vertical-align:top;font-size:11.5px;';
            tdLabel.textContent = p.label;
            var tdValue = document.createElement('td');
            tdValue.style.cssText = 'padding:4px 0;color:#cbd5e1;font-size:12px;';
            tdValue.textContent = p.value;
            tr.appendChild(tdLabel);
            tr.appendChild(tdValue);
            table.appendChild(tr);
        });

        dl.parentNode.replaceChild(table, dl);
    }

    setTimeout(transformProductOptions, 600);
});

// CMS Pages — inject a single search input above the grid, wired to the
// existing Title column filter so Enter triggers Magento's grid search.
document.addEventListener('DOMContentLoaded', function injectCmsPagesSearch() {
    if (!/adminhtml-cms-page-index/.test(document.body.className)) return;
    var titleInput = document.querySelector('.grid tr.filter input[name="title"]');
    if (!titleInput) return;
    var gridContainer = titleInput.closest('.grid');
    if (!gridContainer || document.querySelector('.cms-grid-search-wrap')) return;

    var wrap = document.createElement('div');
    wrap.className = 'cms-grid-search-wrap';
    var input = document.createElement('input');
    input.type = 'search';
    input.placeholder = 'Search pages by title…';
    input.value = titleInput.value || '';
    wrap.appendChild(input);
    gridContainer.parentNode.insertBefore(wrap, gridContainer);

    function applyFilter() {
        titleInput.value = input.value;
        if (typeof cmsPageGrid !== 'undefined' && cmsPageGrid && cmsPageGrid.doFilter) {
            cmsPageGrid.doFilter();
        }
    }
    input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') { e.preventDefault(); applyFilter(); }
    });
    input.addEventListener('search', applyFilter);
});
