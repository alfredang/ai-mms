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

    // Icon-only buttons (eye / pencil / trash style — same look as
    // .mmd-grid-action). Inline !important styles win against the global
    // `body button { background: blue }` rule in dark-theme.css without
    // needing a stylesheet edit.
    var ICONS = {
        editor: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>',
        html:   '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>',
        clean:  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-2 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>'
    };

    function applyBtnStyle(b, active) {
        b.style.cssText =
            'background:transparent !important;background-image:none !important;' +
            'border:1px solid ' + (active ? '#60a5fa' : '#475569') + ' !important;' +
            'border-radius:5px !important;' +
            'width:28px !important;min-width:28px !important;max-width:28px !important;' +
            'height:28px !important;min-height:28px !important;max-height:28px !important;' +
            'box-sizing:border-box !important;line-height:1 !important;' +
            'padding:0 !important;margin:0 !important;display:inline-flex !important;flex:0 0 28px !important;' +
            'align-items:center !important;justify-content:center !important;' +
            'color:' + (active ? '#60a5fa' : '#cbd5e1') + ' !important;' +
            'box-shadow:none !important;text-shadow:none !important;cursor:pointer;' +
            'transform:none !important;font-size:0 !important;';
    }

    function btn(iconKey, title) {
        var b = document.createElement('button');
        b.type = 'button';
        b.title = title;
        b.setAttribute('aria-label', title);
        b.innerHTML = ICONS[iconKey];
        applyBtnStyle(b, false);
        return b;
    }

    function enhance(ta) {
        if (ta.getAttribute('data-ct-tools')) return;
        ta.setAttribute('data-ct-tools', '1');

        var bar = document.createElement('div');
        bar.style.cssText = 'display:flex;gap:8px;align-items:center;margin:0 0 8px;';
        var bEditor = btn('editor', 'Editor');
        var bHtml   = btn('html',   'HTML');
        var bClean  = btn('clean',  'Clean Up');
        applyBtnStyle(bHtml, true);
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
            applyBtnStyle(bHtml,   on);
            applyBtnStyle(bEditor, !on);
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
            '#dcf-form textarea[name="learning_outcomes"], textarea[name="learning_outcomes"],' +
            '#dcf-form textarea[name="course_description"], textarea[name="course_description"],' +
            '#dcf-form textarea[name="trainer_profile"], textarea[name="trainer_profile"],' +
            '#dcf-form textarea[name="prerequisite"], textarea[name="prerequisite"],' +
            '#dcf-form textarea[name="who_should_attend"], textarea[name="who_should_attend"],' +
            '#dcf-form textarea[name="additional_note"], textarea[name="additional_note"]');
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
