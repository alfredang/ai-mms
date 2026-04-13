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

        // Find the grid JS object name from Search/Reset buttons
        var gridJsName = null;
        var searchBtn = null;
        // Search in grid first, then parent wrapper
        var searchScopes = [grid];
        var gridParentEl = grid.up();
        if (gridParentEl) searchScopes.push(gridParentEl);
        // Also check grandparent
        if (gridParentEl && gridParentEl.up()) searchScopes.push(gridParentEl.up());

        for (var si = 0; si < searchScopes.length && !searchBtn; si++) {
            var btns = searchScopes[si].select('button');
            for (var bi = 0; bi < btns.length; bi++) {
                var oc = btns[bi].readAttribute('onclick') || '';
                if (oc.indexOf('doFilter') !== -1) {
                    searchBtn = btns[bi];
                    break;
                }
            }
        }
        if (searchBtn) {
            var match = searchBtn.readAttribute('onclick').match(/(\w+)\.doFilter/);
            if (match) gridJsName = match[1];
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

        if (gridJsName) {
            searchBtnNew.observe('click', function() {
                if (window[gridJsName] && window[gridJsName].doFilter) {
                    window[gridJsName].doFilter();
                }
            });
            resetBtnNew.observe('click', function() {
                if (window[gridJsName] && window[gridJsName].resetFilter) {
                    window[gridJsName].resetFilter();
                }
            });
        }

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
});
