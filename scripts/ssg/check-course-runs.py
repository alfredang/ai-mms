#!/usr/bin/env python3
"""Weekly SSG course-run check for every funded (TGS-) course: WSQ, CASL and IBF.

Finds website class dates that have no course run on MySkillsFuture and sends them
to ai-lms-tms, which creates the course runs and their sessions on SSG.

  1. Candidates: ai-lms-tms /api/external/wsq-schedule-audit compares the website
     schedule (/courses/api_schedule) with the runs SSG holds, course by course.
  2. Confirmation: each candidate is checked against the public MySkillsFuture
     course record; a date MySkillsFuture already lists is dropped.
  3. Hand-over: the missing schedules (course title, course code, dates) go to
     ai-lms-tms /api/external/wsq-submit-runs. That endpoint re-checks eligibility
     and asks SSG again before it creates anything, so a duplicate cannot be made.
  4. Sample check: a few of the submitted dates are read back from SSG and
     MySkillsFuture.

Usage:
  check-course-runs.py                 report + preview only (nothing is created)
  check-course-runs.py --confirm       report, then have ai-lms-tms create the runs
  check-course-runs.py --verify        sample-check the last run (used by the hook)
Options: --sample N (default 5), --limit N (first N courses, for testing),
         --include-drift (also submit courses where SSG holds runs the website
         does not sell; held for a person by default).

Reads the TMS key from ~/.claude/lms_tms_api_key. Never writes to the website.
Reports: var/ssg-course-runs/ (gitignored, local only).
"""
import argparse
import datetime
import json
import os
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(REPO, 'var', 'ssg-course-runs')
LAST_RUN = os.path.join(OUT_DIR, 'last-run.json')
TMS = os.environ.get('LMS_TMS_URL', 'https://lms-tms.tertiaryinfotech.com').rstrip('/')
MSF = 'https://www.myskillsfuture.gov.sg/services/tex/individual/course-detail?action=get-course-by-ref-number&refNumber='
UA = ('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/130.0 Safari/537.36')
CHUNK = 250          # wsq-submit-runs accepts at most 250 items per call
JOB_WAIT_S = 45 * 60  # longest wait for one TMS submit job


def tms_key():
    with open(os.path.expanduser('~/.claude/lms_tms_api_key')) as f:
        return f.read().strip()


def http(url, data=None, headers=None, timeout=90):
    """Returns (status, parsed JSON or None). Never raises on an HTTP error status."""
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers or {})
    if body is not None:
        req.add_header('Content-Type', 'application/json')
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode('utf-8', 'replace'))
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode('utf-8', 'replace'))
        except ValueError:
            return e.code, None
    except (urllib.error.URLError, TimeoutError, ValueError) as e:
        return 0, {'error': str(e)}


def tms(path, data=None, timeout=90):
    return http(TMS + path, data, {'x-api-key': tms_key(), 'Accept': 'application/json'}, timeout)


def msf_run_starts(code):
    """Start dates of every run MySkillsFuture lists for a course; None when unreadable."""
    for attempt in range(3):
        status, d = http(MSF + urllib.parse.quote(code), headers={'User-Agent': UA, 'Accept': 'application/json'}, timeout=30)
        if status == 200 and isinstance(d, dict) and isinstance(d.get('data'), dict):
            return sorted({str(r.get('courseStartDate') or '')[:10] for r in d['data'].get('courseRuns') or []} - {''})
        time.sleep(2 * (attempt + 1))
    return None


def audit(limit=None):
    """Walk the TMS audit (website schedule vs SSG runs) for every funded course."""
    courses, offset = [], 0
    while offset is not None:
        page = 25 if not limit else min(25, limit - len(courses))
        status, d = tms(f'/api/external/wsq-schedule-audit?offset={offset}&limit={page}', timeout=120)
        if status != 200 or not d or not d.get('success'):
            raise SystemExit(f'TMS audit failed at offset {offset}: HTTP {status} {json.dumps(d)[:200]}')
        courses += d.get('courses') or []
        offset = d.get('next_offset')
        if limit and len(courses) >= limit:
            break
    return courses


def build_report(args):
    today = datetime.date.today().isoformat()
    report = {'generated_at': datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
              'source': 'ai-mms weekly SSG course-run check', 'courses_checked': 0,
              'courses': [], 'held_for_person': [], 'no_website_schedule': [], 'unchecked': []}
    rows = audit(args.limit)
    report['courses_checked'] = len(rows)
    for c in rows:
        code = c.get('course_code')
        ssg_code = c.get('resolved_course_code') or code
        title = c.get('title') or ''
        if c.get('error'):
            report['unchecked'].append({'course_title': title, 'course_code': code, 'reason': c['error']})
            continue
        if not c.get('storefront_dates') and not c.get('ssg_runs'):
            report['no_website_schedule'].append({'course_title': title, 'course_code': code})
            continue
        candidates = [s for s in c.get('storefront_only') or [] if (s.get('start_date') or '') > today]
        if not candidates:
            continue
        starts = msf_run_starts(ssg_code)
        time.sleep(0.3)
        missing = [{'start_date': s['start_date'], 'end_date': s['end_date'], 'schedule': s.get('raw') or ''}
                   for s in candidates if starts is None or s['start_date'] not in starts]
        if not missing:
            continue
        entry = {'course_title': title, 'course_code': code, 'ssg_course_code': ssg_code,
                 'runs_on_myskillsfuture': None if starts is None else len(starts),
                 'no_runs_at_all': starts == [] and not c.get('ssg_runs'),
                 'missing_schedules': missing}
        drift = c.get('ssg_only') or []
        if drift and not args.include_drift:
            entry['reason'] = (f'SSG holds {len(drift)} future run(s) on dates the website does not sell: '
                               + ', '.join(d['start_date'] for d in drift[:6]))
            report['held_for_person'].append(entry)
        else:
            report['courses'].append(entry)
    report['courses'].sort(key=lambda e: (not e['no_runs_at_all'], e['course_code']))
    return report


def wait_for_job(job_id, limit_s=JOB_WAIT_S):
    end = time.time() + limit_s
    job = None
    while time.time() < end:
        status, d = tms(f'/api/external/wsq-sync-status?job_id={job_id}')
        job = (d or {}).get('job') if status == 200 else None
        if job and job.get('status') != 'running':
            return job, (d or {}).get('failure_groups') or []
        time.sleep(20)
    return job, []


def send(report, confirm):
    """Hand the missing schedules to ai-lms-tms. Preview unless confirm."""
    items = [{'course_code': c['course_code'], 'start_date': m['start_date'], 'end_date': m['end_date'], 'raw': m['schedule']}
             for c in report['courses'] for m in c['missing_schedules']]
    result = {'confirmed': confirm, 'sent': len(items), 'accepted': [], 'rejected': [], 'jobs': [], 'errors': []}
    for i in range(0, len(items), CHUNK):
        chunk = items[i:i + CHUNK]
        for attempt in range(4):
            status, d = tms('/api/external/wsq-submit-runs', {'items': chunk, **({'confirm': True} if confirm else {})}, timeout=300)
            if status != 409:
                break
            time.sleep(120)   # another TMS sync job is running
        d = d or {}
        result['rejected'] += [{k: r.get(k) for k in ('course_code', 'start_date', 'end_date', 'reason')} for r in d.get('rejected') or []]
        if status == 200 and d.get('success'):
            ok = d.get('would_submit')
            if ok is None:   # confirmed call: accepted = chunk minus rejected
                bad = {(r.get('course_code'), r.get('start_date')) for r in d.get('rejected') or []}
                ok = [it for it in chunk if (it['course_code'], it['start_date']) not in bad]
            result['accepted'] += [{k: it.get(k) for k in ('course_code', 'start_date', 'end_date')} for it in ok]
            if confirm and d.get('job_id') is not None:
                job, failures = wait_for_job(d['job_id'])
                result['jobs'].append({'job_id': d['job_id'], 'job': job, 'failure_groups': failures})
        elif status != 400:   # 400 = nothing eligible in this chunk; reasons are in rejected
            result['errors'].append(f'HTTP {status}: {str(d.get("error") or d)[:200]}')
    return result


def verify(sample_n):
    """Read a sample of the last run's schedules back from SSG and MySkillsFuture."""
    if not os.path.exists(LAST_RUN):
        print('No previous run to check.')
        return 0
    last = json.load(open(LAST_RUN))
    tmsr = last.get('tms') or {}
    confirmed = bool(tmsr.get('confirmed'))
    pool = tmsr.get('accepted') or []
    if not pool:
        print('Sample check: nothing was accepted by ai-lms-tms in the last run, so there is nothing to read back.')
        return 0
    for j in tmsr.get('jobs') or []:
        if (j.get('job') or {}).get('status') in (None, 'running'):
            wait_for_job(j['job_id'], 240)
    new_codes = {c['course_code'] for c in last['report']['courses'] if c.get('no_runs_at_all')}
    resolved = {c['course_code']: c['ssg_course_code'] for c in last['report']['courses']}
    first = [p for p in pool if p['course_code'] in new_codes]
    rest = [p for p in pool if p['course_code'] not in new_codes]
    random.shuffle(first)
    random.shuffle(rest)
    picks, seen = [], set()
    for p in first + rest:               # one date per course, new courses first
        if p['course_code'] not in seen:
            picks.append(p)
            seen.add(p['course_code'])
        if len(picks) >= sample_n:
            break
    print(f"Sample check of {len(picks)} of {len(pool)} schedule(s) "
          f"({'submitted to SSG by ai-lms-tms' if confirmed else 'PREVIEW ONLY, not submitted'}; run of {last['report']['generated_at']})")
    failed = 0
    for p in picks:
        code = resolved.get(p['course_code'], p['course_code'])
        status, d = tms(f"/api/external/ssg-course-runs?course_code={urllib.parse.quote(code)}&from={p['start_date']}&to={p['start_date']}")
        runs = (d or {}).get('runs') or (d or {}).get('data') or []
        on_ssg = None if status != 200 else any((r.get('start_date') == p['start_date']) for r in runs)
        starts = msf_run_starts(code)
        on_msf = None if starts is None else p['start_date'] in starts
        word = lambda v: 'unreadable' if v is None else ('yes' if v else 'NO')
        new = ' (new course, had no runs)' if p['course_code'] in new_codes else ''
        print(f"  {p['course_code']} {p['start_date']}..{p['end_date']}{new}: on SSG = {word(on_ssg)}, on MySkillsFuture = {word(on_msf)}")
        if confirmed and on_ssg is False:
            failed += 1
    if not confirmed:
        print('  These dates were missing when checked and are expected to still be missing: nothing was submitted.')
    elif failed:
        print(f'  {failed} sampled run(s) were NOT created. See the job failures in {LAST_RUN}.')
    else:
        print('  Every sampled run exists on SSG. MySkillsFuture can take a while to show a new run.')
    return 1 if failed else 0


def write_outputs(report, tmsr):
    os.makedirs(OUT_DIR, exist_ok=True)
    stamp = datetime.date.today().isoformat()
    data = {'report': report, 'tms': tmsr}
    for path in (LAST_RUN, os.path.join(OUT_DIR, f'course-runs-{stamp}.json')):
        with open(path, 'w') as f:
            json.dump(data, f, indent=1)
    n_missing = sum(len(c['missing_schedules']) for c in report['courses'])
    lines = [f"# SSG course-run check, {stamp}", '',
             f"- Funded courses checked: {report['courses_checked']}",
             f"- Courses with missing course runs: {len(report['courses'])} ({n_missing} schedule(s)), "
             f"of which {sum(1 for c in report['courses'] if c['no_runs_at_all'])} have no run at all",
             f"- Sent to ai-lms-tms: {tmsr['sent']} ({'submitted' if tmsr['confirmed'] else 'preview only'}); "
             f"accepted {len(tmsr['accepted'])}, rejected {len(tmsr['rejected'])}",
             f"- Held for a person (SSG has runs the website does not sell): {len(report['held_for_person'])} course(s)",
             f"- No schedule on the website and no run on SSG: {len(report['no_website_schedule'])} course(s)",
             f"- Could not be checked: {len(report['unchecked'])} course(s)", '']
    for j in tmsr['jobs']:
        job = j.get('job') or {}
        lines.append(f"- TMS job {j['job_id']}: {job.get('status')}; {job.get('submitted')} submitted, "
                     f"{job.get('already_existed')} already existed, {job.get('ssg_errors')} rejected by SSG, {job.get('skipped')} skipped")
    lines += [f'- TMS error: {e}' for e in tmsr['errors']]
    def table(title, rows, extra=None):
        if not rows:
            return
        lines.extend(['', f'## {title}', '', '| Course title | Course code | Missing schedules |', '|---|---|---|'])
        for c in rows:
            dates = '; '.join(m['schedule'] or f"{m['start_date']}..{m['end_date']}" for m in c.get('missing_schedules', []))
            lines.append(f"| {c['course_title']} | {c['course_code']} | {dates or (extra(c) if extra else '')} |")
    table('Missing course runs sent to ai-lms-tms', report['courses'])
    table('Held for a person', report['held_for_person'])
    if tmsr['rejected']:
        lines += ['', '## Rejected by ai-lms-tms (not sent to SSG)', '', '| Course code | Dates | Reason |', '|---|---|---|']
        lines += [f"| {r['course_code']} | {r['start_date']}..{r['end_date']} | {r['reason']} |" for r in tmsr['rejected']]
    table('No schedule on the website and no run on SSG', report['no_website_schedule'], lambda c: 'add class dates on the website')
    table('Could not be checked', report['unchecked'], lambda c: c.get('reason', ''))
    md = os.path.join(OUT_DIR, f'course-runs-{stamp}.md')
    with open(md, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    return md, lines[:10 + len(tmsr['jobs']) + len(tmsr['errors'])]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--confirm', action='store_true')
    ap.add_argument('--verify', action='store_true')
    ap.add_argument('--include-drift', action='store_true')
    ap.add_argument('--sample', type=int, default=5)
    ap.add_argument('--limit', type=int)
    args = ap.parse_args()
    if args.verify:
        return verify(args.sample)
    report = build_report(args)
    tmsr = send(report, args.confirm) if report['courses'] else {
        'confirmed': args.confirm, 'sent': 0, 'accepted': [], 'rejected': [], 'jobs': [], 'errors': []}
    md, summary = write_outputs(report, tmsr)
    print('\n'.join(summary))
    print(f'\nReport: {md}')
    rc = verify(args.sample) if args.confirm else 0
    return 1 if (rc or tmsr['errors']) else 0


if __name__ == '__main__':
    sys.exit(main())
