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


def main():
    index = get(f'{BASE}/lgs')
    slugs = sorted(set(re.findall(r'href="/lgs/([a-z-]+)"', index)))
    print(len(slugs), 'province slugs')
    rows, seen, skipped = [], set(), collections.Counter()
    for slug in slugs:
        html = get(f'{BASE}/lgs/{slug}')
        ex = [p for p in programs(html) if p.get('admission_mode') == 'exam']
        per_inst = collections.Counter(p['institution_id'] for p in ex)
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
            if per_inst[p['institution_id']] > 1:
                name = f"{name} ({p['department_name'].strip()})"
            rows.append({
                'il': CITY_ALIAS.get(p['city'], p['city']),
                'ilce': p.get('district') or '',
                'okul': name,
                'tur': t,
                'taban_puan': score or '',
                'yuzdelik': pct25 or '',
                'yuzdelik_2026': pct26 or '',
            })
            n += 1
        print(f'{slug}: {n}')
        time.sleep(1.5)
    out = pathlib.Path('data'); out.mkdir(exist_ok=True)
    with open(out / 'schools.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(len(rows), 'rows; skipped', dict(skipped))


if __name__ == '__main__':
    main()
