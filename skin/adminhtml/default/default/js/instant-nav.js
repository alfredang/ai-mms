/**
 * Instant navigation — hover-prefetch + top-of-page progress bar + PJAX swap.
 *
 * - Prefetches internal links 65ms after hover so the next page is in the
 *   browser cache by the time the user clicks. Skips URLs that look like
 *   side-effect actions (delete/remove/logout/save/etc.) so we don't
 *   accidentally trigger them by hovering.
 * - Shows a CSS-animated cyan bar across the top of the page on click /
 *   form submit. The bar runs until DOMContentLoaded of the next page (or
 *   until the PJAX swap completes), then snaps to 100% and fades out.
 * - On internal click, instead of doing a full page navigation, fetches the
 *   target URL, parses its HTML, and swaps just #anchor-content's contents.
 *   The header, sidebar, and any persistent JS state survive. Inline and
 *   src= scripts in the swapped HTML are re-executed manually because
 *   innerHTML doesn't run them.
 *
 * Pure vanilla, no framework. Loaded on every admin page via main.xml.
 * Opt out per link with data-no-pjax / data-no-prefetch attributes.
 */
(function(){
    if (typeof document === 'undefined') return;

    // ---------- 1. Hover-prefetch ----------

    var prefetched = new Set();
    var DANGEROUS = ['/delete', '/remove', '/cancel', '/destroy', '/logout',
                     '/save',   '/disable','/enable',  '/clone',  '/duplicate',
                     '/reset',  '/refresh','/clear'];

    function isInternalNav(a) {
        if (!a || !a.href) return false;
        if (a.target && a.target !== '_self') return false;
        if (a.hasAttribute('download')) return false;
        if (a.dataset.noPrefetch !== undefined) return false;
        var href = a.getAttribute('href') || '';
        if (href.charAt(0) === '#') return false;
        if (href.indexOf('javascript:') === 0) return false;
        if (href.indexOf('mailto:') === 0) return false;
        if (href.indexOf('tel:') === 0) return false;
        try {
            var url = new URL(a.href, location.href);
            if (url.host !== location.host) return false;
            return true;
        } catch (e) { return false; }
    }
    function isSafeForPrefetch(a) {
        if (!isInternalNav(a)) return false;
        var path = '';
        try { path = (new URL(a.href, location.href)).pathname.toLowerCase(); } catch (e) {}
        for (var i = 0; i < DANGEROUS.length; i++) {
            if (path.indexOf(DANGEROUS[i]) !== -1) return false;
        }
        return true;
    }
    function prefetch(url) {
        if (prefetched.has(url)) return;
        prefetched.add(url);
        var link = document.createElement('link');
        link.rel = 'prefetch';
        link.as = 'document';
        link.href = url;
        document.head.appendChild(link);
    }
    var hoverTimers = new WeakMap();
    document.addEventListener('mouseover', function(e){
        var a = e.target.closest && e.target.closest('a');
        if (!a || hoverTimers.has(a)) return;
        if (!isSafeForPrefetch(a)) return;
        var t = setTimeout(function(){
            prefetch(a.href);
            hoverTimers.delete(a);
        }, 65);
        hoverTimers.set(a, t);
    }, { passive: true });
    document.addEventListener('mouseout', function(e){
        var a = e.target.closest && e.target.closest('a');
        if (!a) return;
        var t = hoverTimers.get(a);
        if (t) { clearTimeout(t); hoverTimers.delete(a); }
    }, { passive: true });

    // Note: bulk-prefetch on first paint was tried and removed — it floods
    // Apache prefork with 30+ background requests per pageload, which then
    // queue ahead of the user's actual click. Hover-prefetch alone is enough.

    // ---------- 2. Top-of-page progress bar ----------

    var bar = null;
    function ensureBar(){
        if (bar) return bar;
        bar = document.createElement('div');
        bar.id = 'instant-nav-bar';
        bar.setAttribute('role', 'presentation');
        (document.body || document.documentElement).appendChild(bar);
        return bar;
    }
    function startBar(){
        var b = ensureBar();
        b.style.transition = 'none';
        b.style.opacity = '1';
        b.style.width = '0%';
        b.offsetWidth; // force layout flush so the next transition starts from 0
        b.style.transition = 'width 8s cubic-bezier(0.1, 0.5, 0.1, 1), opacity 0.3s';
        b.style.width = '92%';
    }
    function finishBar(){
        if (!bar) return;
        bar.style.transition = 'width 0.2s ease-out, opacity 0.4s ease-out';
        bar.style.width = '100%';
        setTimeout(function(){ if (bar) bar.style.opacity = '0'; }, 180);
    }

    // ---------- 3. PJAX swap ----------

    var SWAP_SELECTOR = '#anchor-content';
    var pjaxBusy = false;

    function executeScripts(container) {
        // innerHTML doesn't execute <script> nodes — clone-and-replace each
        // so the browser parses them fresh. Maintain DOM order.
        container.querySelectorAll('script').forEach(function(oldScript) {
            var newScript = document.createElement('script');
            for (var i = 0; i < oldScript.attributes.length; i++) {
                var attr = oldScript.attributes[i];
                newScript.setAttribute(attr.name, attr.value);
            }
            newScript.textContent = oldScript.textContent;
            oldScript.parentNode.replaceChild(newScript, oldScript);
        });
    }

    function pjaxNavigate(url, opts) {
        if (pjaxBusy) return false;
        opts = opts || {};
        pjaxBusy = true;
        startBar();
        return fetch(url, {
            credentials: 'same-origin',
            redirect: 'follow',
            headers: { 'X-Pjax': '1', 'Accept': 'text/html' }
        }).then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            var ct = res.headers.get('Content-Type') || '';
            if (ct.indexOf('text/html') === -1) throw new Error('Non-HTML response');
            return res.text().then(function(html) {
                return { html: html, url: res.url || url };
            });
        }).then(function(data) {
            var doc = new DOMParser().parseFromString(data.html, 'text/html');
            var oldNode = document.querySelector(SWAP_SELECTOR);
            var newNode = doc.querySelector(SWAP_SELECTOR);
            if (!oldNode || !newNode) {
                // Page doesn't have our swap target (e.g., login page) —
                // fall back to a normal full navigation.
                window.location.href = data.url;
                return;
            }
            if (doc.title) document.title = doc.title;
            // Sync body class — Magento sets per-page body classes (e.g.
            // `adminhtml-catalog-product`) that some CSS selectors depend on.
            if (doc.body && doc.body.className) {
                document.body.className = doc.body.className;
            }
            oldNode.innerHTML = newNode.innerHTML;
            executeScripts(oldNode);
            if (!opts.fromPopState) {
                history.pushState({ pjax: true }, '', data.url);
            }
            // Scroll: anchor in URL → jump to it; otherwise top.
            try {
                var hash = (new URL(data.url, location.href)).hash;
                if (hash && hash.length > 1) {
                    var anchor = document.querySelector(hash);
                    if (anchor) anchor.scrollIntoView();
                    else window.scrollTo(0, 0);
                } else {
                    window.scrollTo(0, 0);
                }
            } catch (e) { window.scrollTo(0, 0); }
            // Let custom code rebind to the swapped DOM.
            document.dispatchEvent(new CustomEvent('instant-nav:after-swap', {
                detail: { url: data.url }
            }));
            finishBar();
        }).catch(function() {
            // Anything goes wrong — fall back to a full navigation so the
            // user still ends up where they intended.
            finishBar();
            window.location.href = url;
        }).then(function(){
            pjaxBusy = false;
        });
    }

    // ---------- 4. Click + popstate wiring ----------

    document.addEventListener('click', function(e){
        if (e.defaultPrevented) return;
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
        if (e.button !== undefined && e.button !== 0) return;
        var a = e.target.closest && e.target.closest('a');
        if (!a || !isInternalNav(a)) return;
        if (a.dataset.noPjax !== undefined) {
            startBar();
            return; // let the browser do a normal navigation
        }
        // Same-page anchor — let the browser handle it.
        try {
            var url = new URL(a.href, location.href);
            if (url.pathname === location.pathname &&
                url.search === location.search && url.hash) return;
        } catch (e2) { return; }
        e.preventDefault();
        pjaxNavigate(a.href, {});
    });

    // Forms still do a full submit (we'd need to handle GET/POST + multipart
    // properly to PJAX them). Just paint the bar.
    document.addEventListener('submit', function(){
        startBar();
    });

    window.addEventListener('popstate', function(e){
        // Magento's first load doesn't push a state, so e.state is null on
        // the very first back. Always try PJAX — if the swap target is
        // missing, pjaxNavigate will full-reload as fallback.
        pjaxNavigate(location.href, { fromPopState: true });
    });

    // ---------- 5. Bar lifecycle on first paint / bfcache ----------

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        finishBar();
    } else {
        document.addEventListener('DOMContentLoaded', finishBar);
    }
    window.addEventListener('pageshow', function(e){
        if (e.persisted) finishBar();
    });
})();
