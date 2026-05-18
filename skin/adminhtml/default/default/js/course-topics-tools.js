/**
 * Course Topics editor tools (developer course-editing form).
 *
 * Adds, above the "Course Topics" textarea (name="learning_outcomes"):
 *   • Editor / HTML mode toggle — Editor = a rendered contenteditable
 *     view; HTML = the raw markup textarea (the form field of record).
 *   • Clean Up — strips the noise the Lesson serializer injects
 *     (`<!-- LSN_DATA:[…] -->` and any HTML comments), plus
 *     <script>/<style> and disallowed tags/attributes, leaving plain
 *     clean HTML (p / strong / em / ul / li / a / headings / …).
 *
 * Persistence note: the Lesson card editor re-serializes its topics[]
 * into this textarea on submit, but ONLY when it still has topics
 * (`if (!topics.length) return;`). So Clean Up also clears the Lesson
 * topic cards (via the page's window.lsnDeleteTopic) — otherwise the
 * cleaned HTML would be overwritten on save. That's intentional: Clean
 * Up means "drop the structured LSN_DATA, keep plain HTML", so it
 * confirms first.
 *
 * Self-gating (no learning_outcomes textarea → no-op), idempotent,
 * re-inits after instant-nav PJAX swaps.
 */
(function () {
    'use strict';

    var ALLOWED = { P:1, BR:1, STRONG:1, B:1, EM:1, I:1, U:1, UL:1, OL:1,
                    LI:1, H1:1, H2:1, H3:1, H4:1, A:1, SPAN:1, BLOCKQUOTE:1 };

    function cleanHtml(html) {
        // Drop every HTML comment first (covers <!-- LSN_DATA:[…] -->).
        html = String(html).replace(/<!--[\s\S]*?-->/g, '');
        var doc  = new DOMParser().parseFromString(
            '<div id="__ct">' + html + '</div>', 'text/html');
        var root = doc.getElementById('__ct');
        if (!root) return '';
        var n = root.querySelectorAll('script,style,meta,link,iframe,object,embed');
        for (var i = 0; i < n.length; i++) n[i].parentNode.removeChild(n[i]);
        // Unwrap any non-whitelisted element (keep its text/children).
        for (var pass = 0; pass < 80; pass++) {
            var bad = null, all = root.getElementsByTagName('*');
            for (var j = 0; j < all.length; j++) {
                if (!ALLOWED[all[j].tagName]) { bad = all[j]; break; }
            }
            if (!bad) break;
            while (bad.firstChild) bad.parentNode.insertBefore(bad.firstChild, bad);
            bad.parentNode.removeChild(bad);
        }
        // Strip attributes (keep only href/target/rel on <a>).
        var els = root.getElementsByTagName('*');
        for (var k = 0; k < els.length; k++) {
            var el = els[k];
            var keep = el.tagName === 'A' ? { href:1, target:1, rel:1 } : {};
            var attrs = Array.prototype.slice.call(el.attributes);
            for (var a = 0; a < attrs.length; a++) {
                if (!keep[attrs[a].name.toLowerCase()]) el.removeAttribute(attrs[a].name);
            }
        }
        return root.innerHTML.replace(/[ \t]+\n/g, '\n')
                              .replace(/\n{3,}/g, '\n\n').trim();
    }

    function btn(label, primary) {
        var b = document.createElement('button');
        b.type = 'button';
        b.textContent = label;
        b.style.cssText = 'font:600 12px/1 inherit;padding:6px 12px;border-radius:6px;' +
            'cursor:pointer;border:1px solid ' + (primary ? '#2563eb' : '#475569') + ';' +
            'background:' + (primary ? '#2563eb' : '#1b2638') + ';color:' +
            (primary ? '#fff' : '#cbd5e1') + ';text-transform:none;letter-spacing:0;';
        return b;
    }

    function enhance(ta) {
        if (ta.getAttribute('data-ct-tools')) return;
        ta.setAttribute('data-ct-tools', '1');

        var bar = document.createElement('div');
        bar.style.cssText = 'display:flex;gap:8px;align-items:center;margin:0 0 8px;';
        var bEditor = btn('Editor');
        var bHtml   = btn('HTML', true);
        var bClean  = btn('Clean Up');
        bClean.style.marginLeft = 'auto';
        bar.appendChild(bEditor); bar.appendChild(bHtml); bar.appendChild(bClean);
        ta.parentNode.insertBefore(bar, ta);

        // Contenteditable "Editor" view.
        var ed = document.createElement('div');
        ed.contentEditable = 'true';
        ed.className = 'dcf-textarea dcf-textarea-rich ct-editor';
        ed.style.cssText = 'display:none;min-height:220px;overflow:auto;white-space:normal;';
        ta.parentNode.insertBefore(ed, ta.nextSibling);

        function setMode(html) {
            var on = html;
            bHtml.style.background = on ? '#2563eb' : '#1b2638';
            bHtml.style.color      = on ? '#fff' : '#cbd5e1';
            bHtml.style.borderColor = on ? '#2563eb' : '#475569';
            bEditor.style.background = on ? '#1b2638' : '#2563eb';
            bEditor.style.color      = on ? '#cbd5e1' : '#fff';
            bEditor.style.borderColor = on ? '#475569' : '#2563eb';
            if (on) {                 // HTML mode: textarea is source
                ta.value = ed.style.display === 'none' ? ta.value : ed.innerHTML;
                ta.style.display = '';
                ed.style.display = 'none';
            } else {                  // Editor mode: render textarea HTML
                ed.innerHTML = ta.value.replace(/<!--[\s\S]*?-->/g, '');
                ed.style.display = '';
                ta.style.display = 'none';
            }
        }
        bHtml.addEventListener('click', function () { setMode(true); });
        bEditor.addEventListener('click', function () { setMode(false); });
        ed.addEventListener('input', function () { ta.value = ed.innerHTML; });

        bClean.addEventListener('click', function () {
            if (!window.confirm(
                'Clean Up converts Course Topics to plain HTML — it removes ' +
                'the embedded LSN_DATA marker and the structured Lesson ' +
                'cards. Continue?')) return;
            var cleaned = cleanHtml(ta.value);
            ta.value = cleaned;
            ed.innerHTML = cleaned;
            // Drop the Lesson topic cards so the submit serializer
            // (guarded by topics.length) doesn't re-inject LSN_DATA.
            if (typeof window.lsnDeleteTopic === 'function') {
                var guard = 0;
                while (document.querySelector('#lsn-topics .lsn-topic') && guard++ < 200) {
                    try { window.lsnDeleteTopic(0); } catch (e) { break; }
                }
            }
            setMode(true);
        });

        // Keep the textarea (form field of record) in sync if the user
        // submits while in Editor mode.
        var form = ta.form || document.getElementById('dcf-form');
        if (form) form.addEventListener('submit', function () {
            if (ed.style.display !== 'none') ta.value = ed.innerHTML;
        }, true);
    }

    function run() {
        var tas = document.querySelectorAll(
            '#dcf-form textarea[name="learning_outcomes"], textarea[name="learning_outcomes"]');
        for (var i = 0; i < tas.length; i++) enhance(tas[i]);
    }

    function init() {
        run();
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
