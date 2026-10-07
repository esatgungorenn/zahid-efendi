"""One-time fetch of LGS exam-admission programs for all provinces from tabanpuanlari.net.

Writes data/schools.csv in the format tool/build_schools.py expects
(plus a percentile_2026 column kept for reference).
"""
import collections
import csv
import pathlib
import re
import sys
import time

import requests

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from parse_rsc import programs, stat  # noqa: E402

BASE = 'https://tabanpuanlari.net'
H = {'User-Agent': 'zahit-efendi-family-app/1.0 (one-time fetch)'}
TYPES = {
    'fen_lisesi': 'fen',
    'sosyal_bilimler_lisesi': 'sosyal',
    'anadolu_lisesi': 'anadolu',
    'anadolu_imam_hatip_lisesi': 'imamHatip',
    'mesleki_teknik_anadolu_lisesi': 'mesleki',
}
CITY_ALIAS = {'Afyon': 'Afyonkarahisar'}

# The source title-cases with ASCII rules, turning İ into I ("Imam", "Istanbul").
# Words that genuinely start with dotless I are kept.
DOTLESS_I = {'Ilgın', 'Ilıcak', 'Ilıca', 'Iğdır', 'Isparta', 'Ilgaz', 'Işıkkent',
             'Işıl', 'Irmak', 'Işık'}


def fix_i(text: str) -> str:
    return re.sub(r"\bI(\w*)", lambda m: m.group(0) if m.group(0) in DOTLESS_I
                  else 'İ' + m.group(1), text)


def variant(p) -> list:
    out = [p.get('language') or '', p.get('score_type') or '',
           f"{p['duration']} yıl" if p.get('duration') else '',
           'Pansiyonlu' if p.get('boarding') == 'Var' else '']
    return out


def get(url):
    for attempt in range(4):
        try:
            r = requests.get(url, headers=H, timeout=90)
            if r.status_code == 200:
                return r.text
            print('HTTP', r.status_code, url)
        except requests.RequestException as e:
            print('ERR', e, url)
        time.sleep(5 * (attempt + 1))
    raise SystemExit(f'failed: {url}')


def number_duplicates(rows):
    """Programs the source lists with identical visible attributes get "(2)", "(3)"…"""
    count = collections.Counter()
    for r in rows:
        key = (r['il'], r['ilce'], r['okul'])
        count[key] += 1
        if count[key] > 1:
            r['okul'] = f"{r['okul']} ({count[key]})"


def main():
    index = get(f'{BASE}/lgs')
    slugs = sorted(set(re.findall(r'href="/lgs/([a-z-]+)"', index)))
    print(len(slugs), 'province slugs')
    rows, seen, skipped = [], set(), collections.Counter()
    for slug in slugs:
        html = get(f'{BASE}/lgs/{slug}')
        ex = [p for p in programs(html) if p.get('admission_mode') == 'exam']
        per_inst = collections.Counter(p['institution_id'] for p in ex)
        groups = collections.defaultdict(list)
        for p in ex:
            groups[(p['institution_id'], p.get('department_name'))].append(p)
        n = 0
        for p in ex:
            if p['id'] in seen:
                continue
            seen.add(p['id'])
            t = TYPES.get(p.get('institution_subtype'))
            if t is None:
                skipped[p.get('institution_subtype')] += 1
                continue
            s26, s25 = stat(p, 2026), stat(p, 2025)
            score = s26 and s26.get('min_score') or None
            pct25 = s25 and s25.get('min_percentile') or None
            pct26 = s26 and s26.get('min_percentile') or None
            if not score and not pct25:
                skipped['no-data'] += 1
                continue
            name = p['institution_name'].strip()
            extra = []
            dept = (p.get('department_name') or '').strip()
            if per_inst[p['institution_id']] > 1 and dept:
                extra.append(dept)
            same = groups[(p['institution_id'], p.get('department_name'))]
            if len(same) > 1:
                vs = [variant(x) for x in same]
                mine = variant(p)
                extra += [v for i, v in enumerate(mine)
                          if v and len({x[i] for x in vs}) > 1]
            if extra:
                name = f"{name} ({', '.join(extra)})"
            name = fix_i(name)
            rows.append({
                'il': CITY_ALIAS.get(p['city'], p['city']),
                'ilce': fix_i(p.get('district') or ''),
                'okul': name,
                'tur': t,
                'taban_puan': score or '',
                'yuzdelik': pct25 or '',
                'yuzdelik_2026': pct26 or '',
            })
            n += 1
        print(f'{slug}: {n}')
        time.sleep(1.5)
    number_duplicates(rows)
    out = pathlib.Path('data'); out.mkdir(exist_ok=True)
    with open(out / 'schools.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(len(rows), 'rows; skipped', dict(skipped))


if __name__ == '__main__':
    main()
