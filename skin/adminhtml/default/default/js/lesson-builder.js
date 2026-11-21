/**
 * Course Lesson: the read view on the course / class page (.lsv) and the
 * Lesson builder in the course editor (#lsb). MMD_LessonQuiz.
 *
 * Lesson data = [{title, subsecs: [{title, links: [{type, title, url, qid}]}]}]
 * (asset types: web | doc | act = URL link, yt = embedded video, qz = quiz),
 * saved as the LSN_DATA marker at the top of the course description. A quiz's
 * questions are saved separately, straight away, by the Edit Quiz dialog.
 */
(function () {
    'use strict';

    // The script tag can be on a page more than once; run once.
    if (window.__mmdLessonBuilder) return;
    window.__mmdLessonBuilder = true;

    var ICON = {
        grip: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="20" y2="17"/></svg>',
        caret: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="6 9 12 15 18 9"/></svg>',
        trash: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>',
        doc: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg>',
        link: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>',
        video: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="5" width="20" height="14" rx="3"/><polygon points="10 9 15 12 10 15 10 9"/></svg>',
        quiz: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3h6v1"/><polyline points="9 13 11 15 15 11"/></svg>',
        plus: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>',
        close: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><line x1="6" y1="6" x2="18" y2="18"/><line x1="18" y1="6" x2="6" y2="18"/></svg>'
    };

    /* ----------------------------------------------------------- helpers */

    /** el('div', {class: 'x', html: '<svg>', text: 'abc', 'data-a': 'b'}, [children]) */
    function el(tag, attrs, kids) {
        var n = document.createElement(tag), k;
        for (k in attrs || {}) {
            if (!Object.prototype.hasOwnProperty.call(attrs, k) || attrs[k] == null) continue;
            if (k === 'text') n.textContent = attrs[k];
            else if (k === 'html') n.innerHTML = attrs[k];
            else if (k === 'value') n.value = attrs[k];
            else n.setAttribute(k, attrs[k]);
        }
        for (var i = 0; kids && i < kids.length; i++) {
            if (kids[i]) n.appendChild(kids[i]);
        }
        return n;
    }

    function closest(node, sel) {
        while (node && node.nodeType === 1) {
            if (node.matches(sel)) return node;
            node = node.parentNode;
        }
        return null;
    }

    function getJson(url) {
        return fetch(url, { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } })
            .then(function (r) { return r.json(); });
    }

    function postForm(url, data) {
        var body = new URLSearchParams();
        body.set('form_key', window.FORM_KEY || '');
        for (var k in data) {
            if (Object.prototype.hasOwnProperty.call(data, k)) body.set(k, data[k]);
        }
        return fetch(url, {
            method: 'POST', credentials: 'same-origin', body: body,
            headers: { 'X-Requested-With': 'XMLHttpRequest' }
        }).then(function (r) { return r.json(); });
    }

    function withParam(url, key, value) {
        return url + (url.indexOf('?') < 0 ? '?' : '&') + key + '=' + encodeURIComponent(value);
    }

    /**
     * Full-screen layer (video, QR code) or dialog (results, Edit Quiz).
     * Esc and the close button close it; focus returns to the opener.
     */
    function openLayer(cls, label, build) {
        var opener = document.activeElement;
        // The shared admin button and table rules are scoped to .admin-main, and the layer has to
        // sit on <body> to cover the top bar and the sidebar, so it carries the class itself.
        var layer = el('div', { 'class': 'admin-main lsx-layer ' + cls, role: 'dialog', 'aria-modal': 'true', 'aria-label': label });
        var overflow = document.body.style.overflow;
        function close() {
            document.removeEventListener('keydown', onKey);
            document.body.style.overflow = overflow;
            if (layer.parentNode) layer.parentNode.removeChild(layer);
            if (layer.onclose) layer.onclose();
            if (opener && opener.focus) opener.focus();
        }
        function onKey(e) { if (e.key === 'Escape') close(); }
        var x = el('button', { type: 'button', 'class': 'lsx-close', 'aria-label': 'Close', html: ICON.close });
        x.addEventListener('click', close);
        build(layer, close);
        // In a dialog the close button belongs to the card; on a full-screen layer, to the corner.
        (layer.querySelector('.lsx-modal') || layer).insertBefore(x, (layer.querySelector('.lsx-modal') || layer).firstChild);
        layer.addEventListener('mousedown', function (e) { if (e.target === layer) close(); });
        document.addEventListener('keydown', onKey);
        document.body.style.overflow = 'hidden';
        document.body.appendChild(layer);
        x.focus();
        return layer;
    }

    /* --------------------------------------------------------- read view */

    function setTopicOpen(topic, open) {
        topic.classList.toggle('open', open);
        var head = topic.querySelector('[data-lsv-topic]');
        if (head) head.setAttribute('aria-expanded', open ? 'true' : 'false');
    }

    function syncToggleAll(view) {
        var btn = view.querySelector('[data-lsv-toggle-all]');
        if (!btn) return;
        var anyOpen = !!view.querySelector('.lsv-topic.open');
        btn.textContent = anyOpen ? 'Collapse all topics' : 'Expand all topics';
        btn.setAttribute('aria-expanded', anyOpen ? 'true' : 'false');
    }

    function videoFrame(embed, title) {
        return el('iframe', {
            src: embed, title: title, allowfullscreen: 'allowfullscreen',
            allow: 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        });
    }

    function playVideo(video) {
        var frame = video.querySelector('.lsv-video-frame');
        video._poster = video._poster || frame.firstElementChild;
        frame.textContent = '';
        frame.appendChild(videoFrame(video.getAttribute('data-embed'), video.getAttribute('data-title')));
    }

    function zoomVideo(video) {
        // Stop the inline player so the video does not play twice.
        var frame = video.querySelector('.lsv-video-frame');
        if (video._poster && frame.firstElementChild !== video._poster) {
            frame.textContent = '';
            frame.appendChild(video._poster);
        }
        var title = video.getAttribute('data-title');
        openLayer('lsx-dark', title + ' full screen', function (layer) {
            layer.appendChild(el('div', { 'class': 'lsx-video' }, [videoFrame(video.getAttribute('data-embed'), title)]));
        });
    }

    function showQr(view, btn) {
        var quizId = btn.getAttribute('data-lsv-qr');
        var count = parseInt(btn.getAttribute('data-count'), 10) || 0;
        var title = btn.getAttribute('data-title');
        var timer = null;
        var layer = openLayer('lsx-dark', 'Quiz QR code full screen', function (layer) {
            var tally = el('p', { 'class': 'lsx-qr-tally', role: 'status' });
            layer.appendChild(el('div', { 'class': 'lsx-qr' }, [
                el('h2', { 'class': 'lsx-qr-name', text: title }),
                el('p', { 'class': 'lsx-qr-sub', text: 'Scan to take the quiz · ' + count + ' question' + (count === 1 ? '' : 's') }),
                el('div', { 'class': 'lsx-qr-img' }, [
                    el('img', { src: withParam(view.getAttribute('data-qr-url'), 'quiz_id', quizId), alt: 'QR code for ' + title })
                ]),
                tally,
                el('p', { 'class': 'lsx-qr-link', text: btn.getAttribute('data-link') })
            ]));
            function load() {
                getJson(withParam(view.getAttribute('data-results-url'), 'quiz_id', quizId)).then(function (j) {
                    if (!j || !j.success) return;
                    var n = j.tally.learners;
                    tally.textContent = n + ' learner' + (n === 1 ? '' : 's') + ' completed'
                        + (j.tally.average !== null ? ' · average ' + j.tally.average + '%' : '');
                }).catch(function () { /* the counter is optional */ });
            }
            load();
            timer = setInterval(load, 10000);
        });
        layer.onclose = function () { clearInterval(timer); };
    }

    function showResults(view, btn) {
        var quizId = btn.getAttribute('data-lsv-results');
        openLayer('lsx-dim', 'Quiz results', function (layer) {
            var body = el('div', { 'class': 'lsx-modal-body' }, [el('p', { 'class': 'lsx-note', text: 'Loading...' })]);
            layer.appendChild(el('div', { 'class': 'lsx-modal' }, [
                el('div', { 'class': 'lsx-modal-head' }, [
                    el('h2', { 'class': 'lsx-modal-name', text: btn.getAttribute('data-title') + ': results' })
                ]),
                body
            ]));
            getJson(withParam(view.getAttribute('data-results-url'), 'quiz_id', quizId)).then(function (j) {
                body.textContent = '';
                if (!j || !j.success) {
                    body.appendChild(el('p', { 'class': 'lsx-error', role: 'alert', text: (j && j.error) || 'Could not load the results.' }));
                    return;
                }
                var n = j.tally.learners;
                body.appendChild(el('p', { 'class': 'lsx-note', text: n + ' learner' + (n === 1 ? '' : 's') + ' completed'
                    + (j.tally.average !== null ? ' · average ' + j.tally.average + '%' : '') + '. Each learner’s latest attempt is shown.' }));
                if (!n) return;
                var tbody = el('tbody');
                for (var i = 0; i < j.results.length; i++) {
                    var r = j.results[i];
                    tbody.appendChild(el('tr', null, [
                        el('td', { 'class': 'strong', text: r.name || '—' }),
                        el('td', { 'class': 'muted', text: r.email }),
                        el('td', { 'class': 'num', text: r.score + ' / ' + r.total }),
                        el('td', { 'class': 'muted', text: new Date(r.completed_at.replace(' ', 'T')).toLocaleString() })
                    ]));
                }
                body.appendChild(el('table', { 'class': 'mm-table lsx-results-table' }, [
                    el('thead', null, [el('tr', null, [
                        el('th', { scope: 'col', text: 'Learner' }), el('th', { scope: 'col', text: 'Email' }),
                        el('th', { scope: 'col', 'class': 'num', text: 'Score' }), el('th', { scope: 'col', text: 'Completed' })
                    ])]),
                    tbody
                ]));
            }).catch(function () {
                body.textContent = '';
                body.appendChild(el('p', { 'class': 'lsx-error', role: 'alert', text: 'Could not load the results.' }));
            });
        });
    }

    function onViewAction(e) {
        var t = e.target;
        if (!t || t.nodeType !== 1) return;
        var isKey = e.type === 'keydown';
        if (isKey && e.key !== 'Enter' && e.key !== ' ') return;
        var view = closest(t, '[data-lsv]');
        if (!view) return;
        var node;
        // Keys only act on the role="button" elements; real buttons click themselves.
        if ((node = closest(t, '[data-lsv-play]'))) {
            if (isKey) e.preventDefault();
            playVideo(closest(node, '[data-lsv-video]'));
        } else if ((node = closest(t, '[data-lsv-topic]'))) {
            if (isKey) e.preventDefault();
            setTopicOpen(node.parentNode, !node.parentNode.classList.contains('open'));
            syncToggleAll(view);
        } else if (isKey) {
            return;
        } else if ((node = closest(t, '[data-lsv-zoom]'))) {
            zoomVideo(closest(node, '[data-lsv-video]'));
        } else if ((node = closest(t, '[data-lsv-qr]'))) {
            showQr(view, node);
        } else if ((node = closest(t, '[data-lsv-results]'))) {
            showResults(view, node);
        } else if ((node = closest(t, '[data-lsv-toggle-all]'))) {
            var open = !view.querySelector('.lsv-topic.open');
            var topics = view.querySelectorAll('.lsv-topic');
            for (var i = 0; i < topics.length; i++) setTopicOpen(topics[i], open);
            syncToggleAll(view);
        }
    }
    document.addEventListener('click', onViewAction);
    document.addEventListener('keydown', onViewAction);

    /* ------------------------------------------------------------ builder */

    var TAGS = { qz: 'Quiz', yt: 'Video', web: 'Link', doc: 'Document', act: 'Activity' };
    var MAX_Q = 10, MIN_OPT = 2, MAX_OPT = 4;

    function initBuilder(root) {
        var cfg = JSON.parse(document.getElementById('lsb-seed').textContent || '{}');
        var topics = cfg.topics || [];
        var counts = cfg.counts || {};       // {quiz id: number of questions}
        var list = root.querySelector('[data-lsb-list]');
        var toggleAll = root.querySelector('[data-lsb-toggle-all]');
        var dirty = false;                   // the Lesson was changed in this editor

        function touch() { dirty = true; }

        function iconBtn(action, label, icon, extra, idx) {
            var b = el('button', { type: 'button', 'class': 'mmd-iconbtn mmd-tip ' + (extra || ''), 'data-a': action, 'data-tip': label, 'aria-label': label, html: icon });
            for (var k in idx) b.setAttribute('data-' + k, idx[k]);
            return b;
        }

        function grip(label) {
            return el('span', { 'class': 'lsb-grip', title: 'Drag to reorder', 'aria-label': label, html: ICON.grip });
        }

        function assetRow(l, ti, si, li) {
            var kind = l.type === 'qz' ? 'quiz' : (l.type === 'yt' ? 'video' : 'link');
            var idx = { t: ti, s: si, l: li };
            var row = el('div', { 'class': 'lsb-asset lsb-asset-' + kind, 'data-level': 'asset', 'data-t': ti, 'data-s': si, 'data-l': li }, [
                grip('Reorder asset'),
                el('span', { 'class': 'lsv-tag lsv-tag-' + kind, text: TAGS[l.type] || 'Link' }),
                el('input', { type: 'text', 'class': 'lsb-input lsb-asset-title', placeholder: 'Title', 'aria-label': (TAGS[l.type] || 'Link') + ' title',
                    value: l.title || '', 'data-f': 'title', 'data-t': ti, 'data-s': si, 'data-l': li })
            ]);
            if (l.type === 'qz') {
                var n = l.qid ? (counts[l.qid] || 0) : 0;
                var edit = el('button', { type: 'button', 'class': 'lsb-quiz-edit', 'data-a': 'quiz', 'data-t': ti, 'data-s': si, 'data-l': li }, [
                    el('span', { text: n ? n + ' question' + (n === 1 ? '' : 's') : 'Click to add questions' }),
                    el('span', { 'class': 'lsb-quiz-edit-go', text: 'Edit Quiz →' })
                ]);
                row.appendChild(edit);
            } else {
                row.appendChild(el('input', { type: 'url', 'class': 'lsb-input lsb-asset-url', 'aria-label': l.type === 'yt' ? 'YouTube link' : 'URL',
                    placeholder: l.type === 'yt' ? 'YouTube link (https://www.youtube.com/watch?v=...)' : 'URL',
                    value: l.url || '', 'data-f': 'url', 'data-t': ti, 'data-s': si, 'data-l': li }));
            }
            row.appendChild(iconBtn('del-asset', 'Delete ' + (TAGS[l.type] || 'link').toLowerCase(), ICON.trash, 'lsb-del', idx));
            return row;
        }

        function addBtn(type, label, icon, ti, si) {
            return el('button', { type: 'button', 'class': 'mm-btn mm-btn-sm lsb-add lsb-add-' + type, 'data-a': 'add-asset', 'data-type': type, 'data-t': ti, 'data-s': si }, [
                el('span', { 'class': 'lsb-add-icon', html: icon }), el('span', { text: label })
            ]);
        }

        function subBlock(s, ti, si) {
            var kids = [el('div', { 'class': 'lsb-sub-head' }, [
                grip('Reorder sub topic'),
                el('span', { 'class': 'lsb-sub-icon', html: ICON.doc }),
                el('input', { type: 'text', 'class': 'lsb-input lsb-sub-title', placeholder: 'Sub topic title', 'aria-label': 'Sub topic title',
                    value: s.title || '', 'data-f': 'sub', 'data-t': ti, 'data-s': si }),
                iconBtn('del-sub', 'Delete sub topic', ICON.trash, 'lsb-del', { t: ti, s: si })
            ])];
            for (var li = 0; li < s.links.length; li++) kids.push(assetRow(s.links[li], ti, si, li));
            kids.push(el('div', { 'class': 'lsb-add-row' }, [
                addBtn('web', 'URL Link', ICON.link, ti, si),
                addBtn('yt', 'Embed Video', ICON.video, ti, si),
                addBtn('qz', 'Quiz', ICON.quiz, ti, si)
            ]));
            return el('div', { 'class': 'lsb-sub', 'data-level': 'sub', 'data-t': ti, 'data-s': si }, kids);
        }

        function topicCard(t, ti) {
            var bodyId = 'lsb-topic-body-' + ti;
            var body = el('div', { 'class': 'lsb-topic-body', id: bodyId });
            for (var si = 0; si < t.subsecs.length; si++) body.appendChild(subBlock(t.subsecs[si], ti, si));
            body.appendChild(el('button', { type: 'button', 'class': 'mm-btn mm-btn-sm lsb-add-sub', 'data-a': 'add-sub', 'data-t': ti }, [
                el('span', { 'class': 'lsb-add-icon', html: ICON.plus }), el('span', { text: 'Add Sub Topic' })
            ]));
            var caret = iconBtn('toggle', t._open ? 'Collapse topic' : 'Expand topic', ICON.caret, 'lsb-caret', { t: ti });
            caret.setAttribute('aria-expanded', t._open ? 'true' : 'false');
            caret.setAttribute('aria-controls', bodyId);
            return el('div', { 'class': 'lsb-topic' + (t._open ? ' open' : ''), 'data-level': 'topic', 'data-t': ti }, [
                el('div', { 'class': 'lsb-topic-head' }, [
                    grip('Reorder topic'),
                    el('input', { type: 'text', 'class': 'lsb-input lsb-topic-title', placeholder: 'Topic title', 'aria-label': 'Topic title',
                        value: t.title || '', 'data-f': 'topic', 'data-t': ti }),
                    caret,
                    iconBtn('del-topic', 'Delete topic', ICON.trash, 'lsb-del', { t: ti })
                ]),
                body
            ]);
        }

        function render() {
            list.textContent = '';
            var anyOpen = false;
            for (var ti = 0; ti < topics.length; ti++) {
                list.appendChild(topicCard(topics[ti], ti));
                if (topics[ti]._open) anyOpen = true;
            }
            toggleAll.textContent = anyOpen ? 'Collapse All Topics' : 'Expand All Topics';
            toggleAll.setAttribute('aria-expanded', anyOpen ? 'true' : 'false');
            toggleAll.hidden = !topics.length;
        }

        /** Focus the control that a structural change just created or left behind. */
        function focusSel(sel) {
            var n = list.querySelector(sel);
            if (n) n.focus();
        }

        root.addEventListener('click', function (e) {
            var b = closest(e.target, '[data-a]');
            if (!b || !root.contains(b)) return;
            var a = b.getAttribute('data-a');
            var ti = parseInt(b.getAttribute('data-t'), 10), si = parseInt(b.getAttribute('data-s'), 10), li = parseInt(b.getAttribute('data-l'), 10);
            if (a === 'toggle-all') {
                var open = true;
                for (var i = 0; i < topics.length; i++) if (topics[i]._open) open = false;
                for (i = 0; i < topics.length; i++) topics[i]._open = open;
                render();
                return;
            }
            if (a === 'toggle') {
                topics[ti]._open = !topics[ti]._open;
                render();
                focusSel('.lsb-caret[data-t="' + ti + '"]');
                return;
            }
            if (a === 'quiz') {
                openQuiz(topics[ti].subsecs[si].links[li], b);
                return;
            }
            touch();
            if (a === 'add-topic') {
                topics.push({ title: 'Topic ' + (topics.length + 1) + ': New Topic', subsecs: [{ title: '', links: [] }], _open: true });
                render();
                focusSel('.lsb-topic-title[data-t="' + (topics.length - 1) + '"]');
            } else if (a === 'del-topic') {
                if (!window.confirm('Delete this topic and everything in it?')) return;
                topics.splice(ti, 1);
                render();
            } else if (a === 'add-sub') {
                topics[ti].subsecs.push({ title: '', links: [] });
                render();
                focusSel('.lsb-sub-title[data-t="' + ti + '"][data-s="' + (topics[ti].subsecs.length - 1) + '"]');
            } else if (a === 'del-sub') {
                var sub = topics[ti].subsecs[si];
                if ((sub.title || sub.links.length) && !window.confirm('Delete this sub topic and its links, videos and quizzes?')) return;
                topics[ti].subsecs.splice(si, 1);
                render();
            } else if (a === 'add-asset') {
                var links = topics[ti].subsecs[si].links;
                links.push({ type: b.getAttribute('data-type'), title: '', url: '', qid: 0 });
                render();
                focusSel('.lsb-asset-title[data-t="' + ti + '"][data-s="' + si + '"][data-l="' + (links.length - 1) + '"]');
            } else if (a === 'del-asset') {
                topics[ti].subsecs[si].links.splice(li, 1);
                render();
            }
        });

        root.addEventListener('input', function (e) {
            var f = e.target.getAttribute && e.target.getAttribute('data-f');
            if (!f) return;
            var ti = parseInt(e.target.getAttribute('data-t'), 10), si = parseInt(e.target.getAttribute('data-s'), 10), li = parseInt(e.target.getAttribute('data-l'), 10);
            if (f === 'topic') topics[ti].title = e.target.value;
            else if (f === 'sub') topics[ti].subsecs[si].title = e.target.value;
            else topics[ti].subsecs[si].links[li][f] = e.target.value;
            touch();
        });

        // Enter in a Lesson field must not submit the whole course form.
        root.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && e.target.tagName === 'INPUT') e.preventDefault();
        });

        /* Drag to reorder: topics, sub topics inside a topic, assets inside a
           sub topic. Only the grip starts a drag, so text fields stay selectable. */
        var drag = null;
        function sameParent(a, b) {
            if (a.level !== b.level) return false;
            if (a.level === 'topic') return true;
            if (a.level === 'sub') return a.t === b.t;
            return a.t === b.t && a.s === b.s;
        }
        function pos(node) {
            return {
                level: node.getAttribute('data-level'),
                t: parseInt(node.getAttribute('data-t'), 10),
                s: parseInt(node.getAttribute('data-s'), 10),
                l: parseInt(node.getAttribute('data-l'), 10)
            };
        }
        function dropTarget(e) {
            var n = drag ? closest(e.target, '[data-level="' + drag.level + '"]') : null;
            return n && sameParent(drag, pos(n)) ? n : null;
        }
        function clearDrag() {
            var marked = list.querySelectorAll('.lsb-drop, .lsb-dragging, [draggable="true"]');
            for (var i = 0; i < marked.length; i++) {
                marked[i].classList.remove('lsb-drop', 'lsb-dragging');
                marked[i].removeAttribute('draggable');
            }
        }
        list.addEventListener('mousedown', function (e) {
            var g = closest(e.target, '.lsb-grip');
            if (g) closest(g, '[data-level]').setAttribute('draggable', 'true');
        });
        list.addEventListener('mouseup', function () { if (!drag) clearDrag(); });
        list.addEventListener('dragstart', function (e) {
            var n = closest(e.target, '[draggable="true"]');
            if (!n) return;
            drag = pos(n);
            n.classList.add('lsb-dragging');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', drag.level);
        });
        list.addEventListener('dragover', function (e) {
            var n = dropTarget(e);
            if (!n) return;
            e.preventDefault();
            var old = list.querySelectorAll('.lsb-drop');
            for (var i = 0; i < old.length; i++) if (old[i] !== n) old[i].classList.remove('lsb-drop');
            n.classList.add('lsb-drop');
        });
        list.addEventListener('drop', function (e) {
            var n = dropTarget(e);
            if (!n) return;
            e.preventDefault();
            var to = pos(n);
            var arr = drag.level === 'topic' ? topics : (drag.level === 'sub' ? topics[drag.t].subsecs : topics[drag.t].subsecs[drag.s].links);
            var key = drag.level === 'topic' ? 't' : (drag.level === 'sub' ? 's' : 'l');
            if (drag[key] !== to[key]) {
                arr.splice(to[key], 0, arr.splice(drag[key], 1)[0]);
                touch();
            }
            drag = null;
            render();
        });
        list.addEventListener('dragend', function () { drag = null; clearDrag(); });

        /* ------------------------------------------------------- Edit Quiz */

        function openQuiz(link, opener) {
            if (!cfg.productId) {
                window.alert('Save the course first, then add the quiz.');
                return;
            }
            var quiz = { title: link.title || '', questions: [] };
            var ai = { open: false, topic: '', count: 5, instruction: '', mode: 'replace', busy: false };
            var loading = !!link.qid, saving = false, error = '';
            var body, footNote, saveBtn, closeLayer;

            function blank() {
                return { id: 'q' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6), question: '', options: ['', ''], correct: 0 };
            }

            function field(label, input) {
                return el('label', { 'class': 'lsq-field' }, [el('span', { 'class': 'lsq-label', text: label }), input]);
            }

            function aiPanel() {
                var toggle = el('button', { type: 'button', 'class': 'lsq-ai-toggle', 'data-q': 'ai-toggle', 'aria-expanded': ai.open ? 'true' : 'false' }, [
                    el('span', { text: 'Generate with AI' }), el('span', { 'class': 'lsq-ai-show', text: ai.open ? 'Hide' : 'Show' })
                ]);
                var panel = el('div', { 'class': 'lsq-ai' }, [toggle]);
                if (!ai.open) return panel;
                var mode = el('select', { 'class': 'mm-select-sm', 'data-qf': 'ai-mode', 'aria-label': 'What to do with the current questions' }, [
                    el('option', { value: 'replace', text: 'Replace the current questions' }),
                    el('option', { value: 'append', text: 'Add to the current questions' })
                ]);
                mode.value = ai.mode;
                var count = el('input', { type: 'number', min: '1', max: String(MAX_Q), 'class': 'lsb-input lsq-ai-count', value: ai.count, 'data-qf': 'ai-count' });
                var go = el('button', { type: 'button', 'class': 'mm-btn-primary mm-btn-sm', 'data-q': 'ai-go', text: ai.busy ? 'Generating...' : 'Generate questions' });
                if (ai.busy) go.disabled = true;
                panel.appendChild(el('div', { 'class': 'lsq-ai-body' }, [
                    field('Topic', el('input', { type: 'text', 'class': 'lsb-input', placeholder: 'e.g. Prompt injection and jailbreak attacks', value: ai.topic, 'data-qf': 'ai-topic' })),
                    field('Extra instructions (optional)', el('input', { type: 'text', 'class': 'lsb-input', placeholder: 'e.g. scenario-based, beginner level', value: ai.instruction, 'data-qf': 'ai-instruction' })),
                    el('div', { 'class': 'lsq-ai-row' }, [field('Questions', count), mode, go])
                ]));
                return panel;
            }

            function questionCard(q, qi) {
                var kids = [el('div', { 'class': 'lsq-q-head' }, [
                    el('span', { 'class': 'lsq-q-num', text: String(qi + 1), 'aria-hidden': 'true' }),
                    el('input', { type: 'text', 'class': 'lsb-input lsq-q-text', placeholder: 'Enter the question', 'aria-label': 'Question ' + (qi + 1),
                        value: q.question, 'data-qf': 'question', 'data-qi': qi }),
                    quiz.questions.length > 1 ? (function () {
                        var b = el('button', { type: 'button', 'class': 'mmd-iconbtn mmd-tip mmd-tip-left lsb-del', 'data-q': 'del-q', 'data-qi': qi, 'data-tip': 'Delete question', 'aria-label': 'Delete question ' + (qi + 1), html: ICON.trash });
                        return b;
                    })() : null
                ])];
                for (var oi = 0; oi < q.options.length; oi++) {
                    var radio = el('input', { type: 'radio', name: 'lsq-correct-' + q.id, 'data-qf': 'correct', 'data-qi': qi, 'data-oi': oi,
                        'aria-label': 'Option ' + (oi + 1) + ' is the correct answer' });
                    radio.checked = q.correct === oi;
                    kids.push(el('div', { 'class': 'lsq-opt' + (q.correct === oi ? ' is-correct' : '') }, [
                        radio,
                        el('input', { type: 'text', 'class': 'lsb-input lsq-opt-text', placeholder: 'Option ' + (oi + 1), 'aria-label': 'Question ' + (qi + 1) + ' option ' + (oi + 1),
                            value: q.options[oi], 'data-qf': 'option', 'data-qi': qi, 'data-oi': oi }),
                        q.options.length > MIN_OPT
                            ? el('button', { type: 'button', 'class': 'mmd-iconbtn mmd-tip mmd-tip-left', 'data-q': 'del-opt', 'data-qi': qi, 'data-oi': oi, 'data-tip': 'Remove option', 'aria-label': 'Remove option ' + (oi + 1), html: ICON.close })
                            : null
                    ]));
                }
                if (q.options.length < MAX_OPT) {
                    kids.push(el('button', { type: 'button', 'class': 'lsq-link', 'data-q': 'add-opt', 'data-qi': qi, text: '+ Add option' }));
                }
                return el('div', { 'class': 'lsq-q', role: 'group', 'aria-label': 'Question ' + (qi + 1) }, kids);
            }

            function renderQuiz() {
                body.textContent = '';
                if (loading) {
                    body.appendChild(el('p', { 'class': 'lsx-note', text: 'Loading...' }));
                    return;
                }
                body.appendChild(field('Quiz Title', el('input', { type: 'text', 'class': 'lsb-input lsq-title', placeholder: 'e.g. Python Basics Quiz', value: quiz.title, 'data-qf': 'title', maxlength: '255' })));
                body.appendChild(aiPanel());
                for (var qi = 0; qi < quiz.questions.length; qi++) body.appendChild(questionCard(quiz.questions[qi], qi));
                var add = el('button', { type: 'button', 'class': 'mm-btn mm-btn-sm', 'data-q': 'add-q', text: '+ Add Question (' + quiz.questions.length + '/' + MAX_Q + ')' });
                if (quiz.questions.length >= MAX_Q) add.disabled = true;
                body.appendChild(add);
                footNote.textContent = error;
                footNote.hidden = !error;
                saveBtn.disabled = saving;
                saveBtn.textContent = saving ? 'Saving...' : 'Save Quiz';
            }

            function fail(message) {
                error = message;
                saving = false;
                ai.busy = false;
                renderQuiz();
            }

            function save() {
                saving = true;
                error = '';
                renderQuiz();
                postForm(cfg.saveUrl, {
                    product_id: cfg.productId, quiz_id: link.qid || 0, title: quiz.title,
                    questions: JSON.stringify(quiz.questions)
                }).then(function (j) {
                    if (!j || !j.success) { fail((j && j.error) || 'Could not save the quiz.'); return; }
                    var isNew = link.qid !== j.quiz_id;
                    link.qid = j.quiz_id;
                    link.title = j.title;
                    counts[j.quiz_id] = j.count;
                    if (isNew) touch();
                    render();
                    closeLayer();
                    root.querySelector('[data-lsb-note]').hidden = !isNew;
                }).catch(function () { fail('Could not save the quiz. Check your connection and try again.'); });
            }

            function generate() {
                if (!ai.topic.trim()) { fail('Enter a topic to generate questions about.'); return; }
                ai.busy = true;
                error = '';
                renderQuiz();
                postForm(cfg.generateUrl, { topic: ai.topic, count: ai.count, instruction: ai.instruction }).then(function (j) {
                    if (!j || !j.success) { fail((j && j.error) || 'Could not generate questions.'); return; }
                    var made = [];
                    for (var i = 0; i < j.questions.length; i++) {
                        var q = blank();
                        q.question = j.questions[i].question;
                        q.options = j.questions[i].options;
                        q.correct = j.questions[i].correct;
                        made.push(q);
                    }
                    var kept = [];
                    if (ai.mode === 'append') {
                        for (i = 0; i < quiz.questions.length; i++) if (quiz.questions[i].question.trim()) kept.push(quiz.questions[i]);
                    }
                    quiz.questions = kept.concat(made).slice(0, MAX_Q);
                    if (!quiz.title.trim()) quiz.title = ai.topic.trim() + ' Quiz';
                    ai.busy = false;
                    renderQuiz();
                }).catch(function () { fail('Could not generate questions. Please try again.'); });
            }

            openLayer('lsx-dim', 'Edit Quiz', function (layer, close) {
                closeLayer = close;
                body = el('div', { 'class': 'lsx-modal-body' });
                footNote = el('p', { 'class': 'lsx-error', role: 'alert', hidden: 'hidden' });
                saveBtn = el('button', { type: 'button', 'class': 'mm-btn-primary', text: 'Save Quiz' });
                var cancel = el('button', { type: 'button', 'class': 'mm-btn mm-btn-ghost', text: 'Cancel' });
                cancel.addEventListener('click', close);
                saveBtn.addEventListener('click', save);
                var modal = el('div', { 'class': 'lsx-modal lsq-modal' }, [
                    el('div', { 'class': 'lsx-modal-head' }, [
                        el('h2', { 'class': 'lsx-modal-name', text: 'Edit Quiz' }),
                        el('p', { 'class': 'lsx-note', text: 'Up to ' + MAX_Q + ' questions. Each question can have ' + MIN_OPT + '–' + MAX_OPT + ' options; select the correct answer with the radio button.' })
                    ]),
                    body,
                    el('div', { 'class': 'lsx-modal-foot' }, [footNote, cancel, saveBtn])
                ]);
                layer.appendChild(modal);

                modal.addEventListener('click', function (e) {
                    var b = closest(e.target, '[data-q]');
                    if (!b) return;
                    var a = b.getAttribute('data-q'), qi = parseInt(b.getAttribute('data-qi'), 10), oi = parseInt(b.getAttribute('data-oi'), 10);
                    if (a === 'ai-toggle') ai.open = !ai.open;
                    else if (a === 'ai-go') { generate(); return; }
                    else if (a === 'add-q') quiz.questions.push(blank());
                    else if (a === 'del-q') quiz.questions.splice(qi, 1);
                    else if (a === 'add-opt') quiz.questions[qi].options.push('');
                    else if (a === 'del-opt') {
                        var q = quiz.questions[qi];
                        q.options.splice(oi, 1);
                        if (q.correct === oi) q.correct = 0;
                        else if (q.correct > oi) q.correct--;
                    }
                    renderQuiz();
                    if (a === 'add-q') { var t = body.querySelectorAll('.lsq-q-text'); t[t.length - 1].focus(); }
                    else if (a === 'add-opt') { var o = body.querySelectorAll('.lsq-opt-text[data-qi="' + qi + '"]'); o[o.length - 1].focus(); }
                    else if (a === 'ai-toggle') body.querySelector('.lsq-ai-toggle').focus();
                });
                function onField(e) {
                    var f = e.target.getAttribute && e.target.getAttribute('data-qf');
                    if (!f) return;
                    var qi = parseInt(e.target.getAttribute('data-qi'), 10), oi = parseInt(e.target.getAttribute('data-oi'), 10);
                    if (f === 'title') quiz.title = e.target.value;
                    else if (f === 'question') quiz.questions[qi].question = e.target.value;
                    else if (f === 'option') quiz.questions[qi].options[oi] = e.target.value;
                    else if (f === 'ai-topic') ai.topic = e.target.value;
                    else if (f === 'ai-instruction') ai.instruction = e.target.value;
                    else if (f === 'ai-count') ai.count = Math.max(1, Math.min(MAX_Q, parseInt(e.target.value, 10) || 1));
                    else if (f === 'ai-mode') ai.mode = e.target.value;
                    else if (f === 'correct' && e.type === 'change') {
                        quiz.questions[qi].correct = oi;
                        renderQuiz();
                        body.querySelector('input[data-qf="correct"][data-qi="' + qi + '"][data-oi="' + oi + '"]').focus();
                    }
                }
                modal.addEventListener('input', onField);
                modal.addEventListener('change', onField);

                if (!loading) {
                    quiz.questions.push(blank());
                    renderQuiz();
                    return;
                }
                renderQuiz();
                getJson(withParam(cfg.loadUrl, 'quiz_id', link.qid)).then(function (j) {
                    loading = false;
                    if (j && j.success) {
                        quiz.title = j.quiz.title;
                        quiz.questions = j.quiz.questions;
                    }
                    if (!quiz.questions.length) quiz.questions.push(blank());
                    renderQuiz();
                }).catch(function () { loading = false; quiz.questions.push(blank()); fail('Could not load the quiz.'); });
            });
        }

        /* ---------------------------------------------------------- saving */

        function esc(s) {
            return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        }

        /**
         * The course description: the LSN_DATA marker, then the outline the public course
         * page shows (topics and sub topics only; links, videos and quizzes are for the class).
         */
        function serialize() {
            var clean = [];
            for (var ti = 0; ti < topics.length; ti++) {
                var subs = [];
                for (var si = 0; si < topics[ti].subsecs.length; si++) {
                    var s = topics[ti].subsecs[si], links = [];
                    for (var li = 0; li < s.links.length; li++) {
                        var l = s.links[li], row = { type: l.type || 'web', title: l.title || '', url: l.url || '' };
                        if (row.type === 'qz') row.qid = l.qid || 0;
                        if (row.title || row.url || row.qid) links.push(row);
                    }
                    if (s.title || links.length) subs.push({ title: s.title || '', links: links });
                }
                clean.push({ title: topics[ti].title || '', subsecs: subs });
            }
            var html = '<!-- LSN_DATA: ' + JSON.stringify(clean).replace(/-->/g, '--&gt;') + ' -->\n';
            for (ti = 0; ti < clean.length; ti++) {
                html += '<p><strong>' + esc(clean[ti].title || 'Topic') + '</strong></p>\n';
                for (si = 0; si < clean[ti].subsecs.length; si++) {
                    if (clean[ti].subsecs[si].title) html += '<p><em>' + esc(clean[ti].subsecs[si].title) + '</em></p>\n';
                }
            }
            return html;
        }

        var form = document.getElementById('dcf-form');
        if (form) {
            // Write the Lesson into the description before the form is sent.
            // An untouched Lesson, or one whose Course Topics text the user
            // edited by hand (data-ct-edited), leaves the description alone.
            var flush = function () {
                if (!dirty || !topics.length) return;
                var ta = form.querySelector('textarea[name="learning_outcomes"]');
                if (!ta || ta.getAttribute('data-ct-edited') === '1') return;
                ta.value = serialize();
            };
            // Save Changes dispatches a submit event; form.submit() does not.
            form.addEventListener('submit', flush, false);
            try {
                var nativeSubmit = HTMLFormElement.prototype.submit.bind(form);
                form.submit = function () { flush(); return nativeSubmit(); };
            } catch (err) { /* keep the native submit */ }
        }

        // Course Topics "Clean Up" (course-topics-tools.js) turns the description into plain
        // HTML: drop the Lesson so it is not written back over it on save.
        window.lsbClearLesson = function () {
            topics.length = 0;
            dirty = false;
            render();
        };

        render();
    }

    function boot() {
        var root = document.getElementById('lsb');
        if (root && !root._lsb) {
            root._lsb = true;
            initBuilder(root);
        }
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
    else boot();
})();
