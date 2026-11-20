/**
 * Rich-text editor for the developer course-editing form's six
 * dcf-textarea-rich fields (Course Description, Course Topics,
 * Course Info, Job Roles, Additional Note, Trainer Profile).
 *
 * UX: a 3-button toolbar above each textarea — Editor (Quill WYSIWYG)
 * / HTML (raw markup, the form field of record) / Clean Up (drops
 * the Lesson serializer's `<!-- LSN_DATA:[…] -->` marker + any
 * non-whitelisted tags/attributes). Editor mode shows a Quill 2.x
 * surface with the toolbar the old Magento TinyMCE editor exposed:
 * paragraph/heading style, font family, bold/italic/underline/strike,
 * bullet + numbered lists, blockquote, code block, color, alignment,
 * link, clear formatting, undo/redo.
 *
 * Persistence: the underlying <textarea> stays in the DOM and is
 * written from Quill on every text-change (and again on form submit),
 * so the existing dcf-form POST sees the same HTML it always did.
 *
 * Lesson-card conflict: the structured Lesson topic editor
 * (lsn-topics) re-serializes its topics[] into the learning_outcomes
 * textarea on submit IF it still has topics. Clean Up therefore also
 * clears those topic cards (via window.lsnDeleteTopic), otherwise the
 * cleaned HTML would be overwritten on save — so Clean Up confirms
 * first.
 *
 * Self-gating (no matching textarea → no-op), idempotent, re-inits
 * after instant-nav PJAX swaps.
 */
(function () {
    'use strict';

    var QUILL_FONTS = ['arial','helvetica','verdana','times-new-roman','courier-new','georgia','tahoma','trebuchet-ms'];
    var quillRegistered = false;

    function ensureQuillRegistered() {
        if (quillRegistered || typeof Quill === 'undefined') return;
        var Font = Quill.import('formats/font');
        Font.whitelist = QUILL_FONTS;
        Quill.register(Font, true);
        quillRegistered = true;
    }

    var ALLOWED = { P:1, BR:1, STRONG:1, B:1, EM:1, I:1, U:1, S:1, UL:1, OL:1,
                    LI:1, H1:1, H2:1, H3:1, H4:1, A:1, SPAN:1, BLOCKQUOTE:1,
                    PRE:1, CODE:1 };

    function cleanHtml(html) {
        html = String(html).replace(/<!--[\s\S]*?-->/g, '');
        var doc  = new DOMParser().parseFromString('<div id="__ct">' + html + '</div>', 'text/html');
        var root = doc.getElementById('__ct');
        if (!root) return '';
        var n = root.querySelectorAll('script,style,meta,link,iframe,object,embed');
        for (var i = 0; i < n.length; i++) n[i].parentNode.removeChild(n[i]);
        for (var pass = 0; pass < 80; pass++) {
            var bad = null, all = root.getElementsByTagName('*');
            for (var j = 0; j < all.length; j++) {
                if (!ALLOWED[all[j].tagName]) { bad = all[j]; break; }
            }
            if (!bad) break;
            while (bad.firstChild) bad.parentNode.insertBefore(bad.firstChild, bad);
            bad.parentNode.removeChild(bad);
        }
        var els = root.getElementsByTagName('*');
        for (var k = 0; k < els.length; k++) {
            var el = els[k];
            var keep = el.tagName === 'A' ? { href:1, target:1, rel:1 } : {};
            var attrs = Array.prototype.slice.call(el.attributes);
            for (var a = 0; a < attrs.length; a++) {
                if (!keep[attrs[a].name.toLowerCase()]) el.removeAttribute(attrs[a].name);
            }
        }
        return root.innerHTML.replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();
    }

    var ICONS = {
        editor: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>',
        html:   '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>',
        clean:  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-2 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>'
    };

    function applyBtnStyle(b, active) {
        b.style.cssText =
            'background:transparent !important;background-image:none !important;' +
            'border:1px solid ' + (active ? 'var(--lt-icon-active, #60a5fa)' : 'var(--lt-icon-line, #475569)') + ' !important;' +
            'border-radius:5px !important;' +
            'width:28px !important;min-width:28px !important;max-width:28px !important;' +
            'height:28px !important;min-height:28px !important;max-height:28px !important;' +
            'box-sizing:border-box !important;line-height:1 !important;' +
            'padding:0 !important;margin:0 !important;display:inline-flex !important;flex:0 0 28px !important;' +
            'align-items:center !important;justify-content:center !important;' +
            'color:' + (active ? 'var(--lt-icon-active, #60a5fa)' : 'var(--lt-icon, #cbd5e1)') + ' !important;' +
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

    /**
     * Convert Quill 2.x list output into semantic <ul>/<ol> HTML.
     *
     * Quill emits every list as <ol> with each <li data-list="bullet">
     * or data-list="ordered">; it draws the marker via CSS scoped to
     * .ql-editor. When that HTML is rendered anywhere else (storefront,
     * email, plain DOM), bullets disappear because there's no <ul> and
     * the data-list attribute is meaningless. So before writing to the
     * hidden textarea, walk every <ol>:
     *   - if all <li>s are data-list="bullet" → swap to <ul>, drop attrs
     *   - if all <li>s are data-list="ordered" → keep <ol>, drop attrs
     *   - if mixed → split into consecutive same-type runs, each its own list
     */
    // Strip every inline `background-color: ...` declaration. They almost
    // always arrive via paste from Google Docs / Word, where the source
    // app marks ranges with a light grey (rgb(221,221,221) / #dddddd /
    // #d3d3d3 / #f4f4f4 / white) that becomes a visible bar on the dark
    // course-edit and course-detail surfaces. Stripping the lot is more
    // robust than chasing individual shades, and the Quill toolbar's
    // "background" picker on this page isn't expected to be load-bearing
    // for editorial content -- if a user really wants a colour fill they
    // can apply it again. `color:` (foreground) is left alone.
    function stripInlineBackgrounds(root) {
        var els = root.querySelectorAll('[style*="background"]');
        for (var i = 0; i < els.length; i++) {
            var s = els[i].getAttribute('style') || '';
            var cleaned = s
                .replace(/background-color\s*:\s*[^;"]+;?/gi, '')
                .replace(/background\s*:\s*[^;"]+;?/gi, '')
                .trim()
                .replace(/;\s*;/g, ';')
                .replace(/^;|;$/g, '');
            if (cleaned) els[i].setAttribute('style', cleaned);
            else         els[i].removeAttribute('style');
        }
    }

    function normalizeQuillLists(html) {
        var hasLists = html && html.indexOf('data-list=') !== -1;
        var hasBg    = html && /background(-color)?\s*:/i.test(html);
        if (!hasLists && !hasBg) return html;
        var doc  = new DOMParser().parseFromString('<div id="__nlz">' + html + '</div>', 'text/html');
        var root = doc.getElementById('__nlz');
        if (!root) return html;

        if (hasBg) stripInlineBackgrounds(root);

        if (!hasLists) return root.innerHTML;
        var lists = root.querySelectorAll('ol');
        for (var i = 0; i < lists.length; i++) {
            var ol = lists[i];
            // Group consecutive <li>s by their data-list type
            var groups = [];
            var current = null;
            for (var j = 0; j < ol.children.length; j++) {
                var li   = ol.children[j];
                if (li.tagName !== 'LI') continue;
                var type = li.getAttribute('data-list') || 'ordered';
                if (!current || current.type !== type) {
                    current = { type: type, items: [] };
                    groups.push(current);
                }
                current.items.push(li);
            }
            if (!groups.length) continue;

            // Build replacement lists (one per group)
            var frag = doc.createDocumentFragment();
            groups.forEach(function (g) {
                var tag = (g.type === 'bullet') ? 'ul' : 'ol';
                var newList = doc.createElement(tag);
                g.items.forEach(function (li) {
                    li.removeAttribute('data-list');
                    // Quill nests a <span class="ql-ui"> placeholder inside
                    // each <li> for the rendered marker — strip it so the
                    // saved HTML stays clean.
                    var ui = li.querySelector(':scope > .ql-ui');
                    if (ui) ui.parentNode.removeChild(ui);
                    newList.appendChild(li);
                });
                frag.appendChild(newList);
            });
            ol.parentNode.replaceChild(frag, ol);
        }
        return root.innerHTML;
    }

    function buildQuill(host, placeholder) {
        ensureQuillRegistered();
        if (typeof Quill === 'undefined') return null;
        var toolbarCfg = [
            [{ header: [false, 1, 2, 3] }, { font: QUILL_FONTS }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ list: 'bullet' }, { list: 'ordered' }, 'blockquote', 'code-block'],
            [{ color: [] }, { background: [] }],
            [{ align: [] }],
            ['link', 'clean'],
        ];
        return new Quill(host, {
            theme: 'snow',
            placeholder: placeholder || '',
            modules: {
                toolbar: toolbarCfg,
                history: { delay: 800, maxStack: 200, userOnly: true },
            },
        });
    }

    function enhance(ta) {
        if (ta.getAttribute('data-ct-tools')) return;
        ta.setAttribute('data-ct-tools', '1');

        var bar = document.createElement('div');
        bar.style.cssText = 'display:flex;gap:8px;align-items:center;margin:0 0 8px;';
        var bEditor = btn('editor', 'Editor');
        var bHtml   = btn('html',   'HTML');
        var bClean  = btn('clean',  'Clean Up');
        bClean.style.marginLeft = 'auto';
        bar.appendChild(bEditor); bar.appendChild(bHtml); bar.appendChild(bClean);
        ta.parentNode.insertBefore(bar, ta);

        // Quill host wrapper — sits next to the textarea, swapped in/out
        // via display:none on each mode toggle.
        var wrap = document.createElement('div');
        wrap.className = 'qrt-wrap';
        wrap.style.display = 'none';
        var host = document.createElement('div');
        wrap.appendChild(host);
        ta.parentNode.insertBefore(wrap, ta.nextSibling);

        var quill = buildQuill(host, ta.getAttribute('placeholder'));
        if (!quill) {
            // Quill failed to load — fall back to a contenteditable surface
            // so the field is still usable (no toolbar but won't break).
            console.warn('[course-topics-tools] Quill unavailable, falling back to contenteditable.');
            wrap.removeChild(host);
            var ed = document.createElement('div');
            ed.contentEditable = 'true';
            ed.className = 'dcf-textarea dcf-textarea-rich ct-editor';
            ed.style.cssText = 'min-height:220px;overflow:auto;white-space:normal;padding:12px;border:1px solid #334155;border-radius:8px;background:#0f172a;color:#e2e8f0;';
            wrap.appendChild(ed);
            ed.innerHTML = ta.value.replace(/<!--[\s\S]*?-->/g, '');
            ed.addEventListener('input', function () {
                ta.value = ed.innerHTML;
                ta.setAttribute('data-ct-edited', '1');
            });
            quill = { __fallback: true, root: ed };
        } else {
            // Seed Quill from the textarea's existing HTML (stripping LSN_DATA
            // and other comments so the editor doesn't display them as text).
            var initial = (ta.value || '').replace(/<!--[\s\S]*?-->/g, '');
            if (initial.trim() !== '') {
                var delta = quill.clipboard.convert({ html: initial });
                quill.setContents(delta, 'silent');
            }
            quill.on('text-change', function (delta, oldDelta, source) {
                var html = quill.root.innerHTML;
                ta.value = (html === '<p><br></p>') ? '' : normalizeQuillLists(html);
                // Mark this textarea as Quill-owned so the lsn-topics
                // serializer (which otherwise re-serializes its topic
                // cards into learning_outcomes on submit) defers to the
                // user's Quill edits.
                if (source === 'user') ta.setAttribute('data-ct-edited', '1');
            });
        }

        function setMode(htmlMode) {
            applyBtnStyle(bHtml,   htmlMode);
            applyBtnStyle(bEditor, !htmlMode);
            if (htmlMode) {
                // Push the current editor HTML into the textarea before
                // showing the raw view so the user sees the latest content.
                if (!quill.__fallback) ta.value = (quill.root.innerHTML === '<p><br></p>') ? '' : normalizeQuillLists(quill.root.innerHTML);
                else                    ta.value = quill.root.innerHTML;
                ta.style.display = '';
                wrap.style.display = 'none';
            } else {
                // Re-seed the editor with whatever's now in the textarea
                // (admin may have hand-edited the HTML).
                var content = (ta.value || '').replace(/<!--[\s\S]*?-->/g, '');
                if (!quill.__fallback) {
                    var d = quill.clipboard.convert({ html: content });
                    quill.setContents(d, 'silent');
                } else {
                    quill.root.innerHTML = content;
                }
                ta.style.display = 'none';
                wrap.style.display = '';
            }
        }
        // Default to Editor (WYSIWYG) — this is what users want most of the time.
        setMode(false);

        bHtml.addEventListener('click',   function () { setMode(true);  });
        bEditor.addEventListener('click', function () { setMode(false); });

        bClean.addEventListener('click', function () {
            if (!window.confirm(
                'Clean Up converts this field to plain HTML — it removes ' +
                'any embedded LSN_DATA marker and structured Lesson cards. ' +
                'Continue?')) return;
            var cleaned = cleanHtml(ta.value);
            ta.value = cleaned;
            if (!quill.__fallback) {
                var d = quill.clipboard.convert({ html: cleaned });
                quill.setContents(d, 'silent');
            } else {
                quill.root.innerHTML = cleaned;
            }
            // The Lesson builder (js/lesson-builder.js) writes its topics into
            // this same learning_outcomes textarea on save; empty it so the
            // cleaned HTML is what gets saved.
            if (ta.name === 'learning_outcomes' && typeof window.lsbClearLesson === 'function') {
                window.lsbClearLesson();
            }
            setMode(false);
        });

        // Belt-and-suspenders sync at submit time (covers any edge case
        // where the text-change listener missed a transition).
        var form = ta.form || document.getElementById('dcf-form');
        if (form) form.addEventListener('submit', function () {
            if (wrap.style.display !== 'none') {
                if (!quill.__fallback) ta.value = (quill.root.innerHTML === '<p><br></p>') ? '' : normalizeQuillLists(quill.root.innerHTML);
                else                    ta.value = quill.root.innerHTML;
            }
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
        // Quill ships from CDN — it may arrive a beat after DOMContentLoaded.
        // Poll briefly so the editor still attaches once it lands.
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
