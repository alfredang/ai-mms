/**
 * Instant navigation — hover-prefetch + top-of-page progress bar.
 *
 * - Prefetches internal links 65ms after hover so the next page is in the
 *   browser cache by the time the user clicks. Skips URLs that look like
 *   side-effect actions (delete/remove/logout/save/etc.) so we don't
 *   accidentally trigger them by hovering.
 * - Shows a CSS-animated cyan bar across the top of the page on click /
 *   form submit. The bar runs until DOMContentLoaded of the next page,
 *   then snaps to 100% and fades out.
 *
 * Pure vanilla, no framework. Loaded on every admin page via main.xml.
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

    function maybeStart(a) {
        if (!isInternalNav(a)) return;
        startBar();
    }
    document.addEventListener('click', function(e){
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
        if (e.button !== undefined && e.button !== 0) return;
        var a = e.target.closest && e.target.closest('a');
        if (a) maybeStart(a);
    });
    document.addEventListener('submit', function(){
        startBar();
    });

    // Finish on DOMContentLoaded — the new page calling this script flushes
    // its own bar to 100%.
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        finishBar();
    } else {
        document.addEventListener('DOMContentLoaded', finishBar);
    }
    // Back/forward cache restore — bfcache reuses the old DOM, so the bar
    // might still be visible. Clear it.
    window.addEventListener('pageshow', function(e){
        if (e.persisted) finishBar();
    });
})();
