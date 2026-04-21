/**
 * Sidebar Navigation — Accordion toggle, collapse, hover handler cleanup
 * Uses Prototype.js (loaded globally in Magento admin)
 */
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
    function initAdvancedFilters() {
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

    function buildFilterPanels() {
    $$('.grid').each(function(grid) {
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

        if (fields.length === 0) return;

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

        // Wire Apply/Reset. Magento's varienGrid.doFilter() only reads inputs inside
        // "#<gridId> .filter" — but we moved them into the panel. So we temporarily
        // reparent the inputs back into their original tr.filter cells, run doFilter,
        // then move them back into the panel.
        function withInputsInGrid(cb) {
            var movedBack = [];
            fields.each(function(field) {
                field.inputs.each(function(inp) {
                    var currentParent = inp.parentNode;
                    if (currentParent !== field.cell) {
                        movedBack.push({ inp: inp, from: currentParent });
                        field.cell.appendChild(inp);
                    }
                });
            });
            try { cb(); } finally {
                movedBack.each(function(entry) {
                    entry.from.appendChild(entry.inp);
                });
            }
        }

        searchBtnNew.observe('click', function() {
            if (gridJsName && window[gridJsName] && window[gridJsName].doFilter) {
                withInputsInGrid(function() { window[gridJsName].doFilter(); });
                return;
            }
            if (searchBtn) {
                withInputsInGrid(function() { searchBtn.click(); });
                return;
            }
            console.warn('[Filter] No grid JS object or Search button found for grid', grid.readAttribute('id'));
        });
        resetBtnNew.observe('click', function() {
            // Reset: clear all panel inputs first, then delegate to grid
            fields.each(function(field) {
                field.inputs.each(function(inp) {
                    if (inp.tagName === 'SELECT') inp.selectedIndex = 0;
                    else inp.value = '';
                });
            });
            if (gridJsName && window[gridJsName] && window[gridJsName].resetFilter) {
                withInputsInGrid(function() { window[gridJsName].resetFilter(); });
                return;
            }
            if (resetBtn) {
                withInputsInGrid(function() { resetBtn.click(); });
                return;
            }
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
            } else {
                contentHeader.insert(toggleBtn);
            }
        } else if (gridWrapper && gridWrapper.parentNode) {
            gridWrapper.parentNode.insertBefore(toggleBtn, gridWrapper);
        }

        // Insert panel before the grid wrapper (which contains massaction + grid)
        var panelRef = gridWrapper || grid;
        if (panelRef && panelRef.parentNode) {
            panelRef.parentNode.insertBefore(panel, panelRef);
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
        $$('img[src*="rss"]').each(function(img) { img.remove(); });
    }
    removeRssLinks();
    // Also run after grid loads since RSS links can be in AJAX-loaded pagers
    setTimeout(removeRssLinks, 600);
    setTimeout(removeRssLinks, 2000);

    // 9. Modern Pagination
    function initModernPagination() {
        var grids = $$('.grid');
        if (grids.length === 0) {
            setTimeout(initModernPagination, 300);
            return;
        }
        // Remove any existing pagination (handles grid AJAX reloads)
        $$('.modern-pagination').each(function(el) { el.remove(); });

        grids.each(function(grid) {
            buildPagination(grid);
        });
    }
    setTimeout(initModernPagination, 600);

    // Re-run after grid AJAX reloads: observe DOM changes in grid wrappers
    // and also re-run RSS removal
    (function() {
        var observer = new MutationObserver(function(mutations) {
            var gridChanged = false;
            mutations.each(function(m) {
                if (m.addedNodes.length > 0) {
                    for (var i = 0; i < m.addedNodes.length; i++) {
                        var node = m.addedNodes[i];
                        if (node.nodeType === 1 && (node.classList.contains('grid') || node.querySelector && node.querySelector('.grid'))) {
                            gridChanged = true;
                        }
                    }
                }
            });
            if (gridChanged) {
                setTimeout(function() {
                    initModernPagination();
                    removeRssLinks();
                    // Also re-init filters if they got lost
                    if ($$('.advanced-filter-panel').length === 0) {
                        buildFilterPanels();
                    }
                }, 200);
            }
        });
        // Observe grid wrapper areas
        var mainContainer = document.body.down('#page\\:main-container');
        if (mainContainer) {
            observer.observe(mainContainer, { childList: true, subtree: true });
        }
    })();

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
    function injectRowActions() {
        // Find the mass action bar to get available actions
        var massSelect = document.querySelector('.massaction select');
        if (!massSelect) return;

        var actions = [];
        for (var i = 0; i < massSelect.options.length; i++) {
            var opt = massSelect.options[i];
            if (opt.value && opt.value !== '') {
                actions.push({ label: opt.text, value: opt.value });
            }
        }
        if (actions.length === 0) return;

        // Find the grid table
        var tables = document.querySelectorAll('.grid table.data');
        if (tables.length === 0) return;

        tables.forEach(function(table) {
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
            }
        });

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
            var rows = table.querySelectorAll('tr');
            for (var r = 0; r < rows.length; r++) {
                var cells = rows[r].children;
                if (cells.length === 0) continue;
                var first = cells[0];
                // Check if first cell is the checkbox column (contains checkbox, is empty, or is narrow)
                var hasCheckbox = first.querySelector('input[type="checkbox"]');
                var isEmpty = first.textContent.trim() === '' && !first.querySelector('img');
                if (hasCheckbox || (isEmpty && first.tagName === 'TH') || (first.classList.contains('a-center') && (hasCheckbox || isEmpty))) {
                    first.style.display = 'none';
                }
            }
            // Also hide first col element if it exists
            var cols = table.querySelectorAll('col');
            if (cols.length > 0 && cols[0]) {
                cols[0].style.width = '0';
                cols[0].style.display = 'none';
            }
        });
    }

    // Inject KPI summary cards above grid tables
    function injectGridKPIs() {
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

    // Apply all grid enhancements
    function applyGridEnhancements() {
        // Remove old KPI cards first
        document.querySelectorAll('.grid-kpi-cards').forEach(function(el) { el.remove(); });
        removeCheckboxColumn();
        injectRowActions();
        injectGridKPIs();
    }

    // Run on initial load
    setTimeout(applyGridEnhancements, 500);

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
