#!/usr/bin/env python3
"""Builds assets/schools.json from a CSV and validates it.

CSV columns (UTF-8, header row required):
    il, ilce, okul, tur, taban_puan, yuzdelik

- tur: one of fen | sosyal | anadolu | imamHatip | mesleki
  (Turkish labels such as "Fen Lisesi", "Anadolu İmam Hatip Lisesi" are mapped too)
- taban_puan / yuzdelik may be empty; decimal comma or point accepted

Usage:
    tool/build_schools.py data/schools.csv --score-year 2026 --percentile-year 2025
"""
import argparse
import csv
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROVINCES = re.findall(r"'([^']+)'", (ROOT / 'lib/provinces.dart').read_text(encoding='utf-8').split('foldTr')[0])
assert len(PROVINCES) == 81, len(PROVINCES)

TYPES = {'fen', 'sosyal', 'anadolu', 'imamHatip', 'mesleki'}


def map_type(raw: str) -> str:
    t = raw.strip()
    if t in TYPES:
        return t
    low = t.lower().replace('i̇', 'i')
    if 'imam' in low:
        return 'imamHatip'
    if 'sosyal' in low:
        return 'sosyal'
    if 'fen' in low:
        return 'fen'
    if 'mesleki' in low or 'teknik' in low or 'mtal' in low:
        return 'mesleki'
    if 'anadolu' in low:
        return 'anadolu'
    raise ValueError(f'bilinmeyen okul türü: {raw!r}')


def num(raw: str, lo: float, hi: float, what: str):
    raw = (raw or '').strip().replace('%', '')
    if not raw:
        return None
    v = float(raw.replace(',', '.'))
    if not lo <= v <= hi:
        raise ValueError(f'{what} aralık dışı: {v}')
    return round(v, 4)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('csv')
    ap.add_argument('--score-year', type=int, required=True)
    ap.add_argument('--percentile-year', type=int, required=True)
    ap.add_argument('--out', default=str(ROOT / 'assets/schools.json'))
    a = ap.parse_args()

    schools, errors, seen = [], [], set()
    with open(a.csv, encoding='utf-8-sig', newline='') as f:
        for n, row in enumerate(csv.DictReader(f), start=2):
            try:
                il = row['il'].strip()
                if il not in PROVINCES:
                    raise ValueError(f'il listede yok: {il!r}')
                name = re.sub(r'\s+', ' ', row['okul']).strip()
                district = row['ilce'].strip()
                key = (il, district, name)
                if key in seen:
                    raise ValueError(f'tekrar eden satır: {name}')
                seen.add(key)
                s = {
                    'name': name,
                    'province': il,
                    'district': district,
                    'type': map_type(row['tur']),
                    'score': num(row['taban_puan'], 100, 500, 'taban puan'),
                    'percentile': num(row['yuzdelik'], 0, 100, 'yüzdelik'),
                }
                if s['score'] is None and s['percentile'] is None:
                    raise ValueError('puan ve yüzdelik ikisi de boş')
                schools.append(s)
            except (ValueError, KeyError) as e:
                errors.append(f'satır {n}: {e}')

    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1

    schools.sort(key=lambda s: (s['province'], s['district'], s['name']))
    out = {'scoreYear': a.score_year, 'percentileYear': a.percentile_year, 'schools': schools}
    pathlib.Path(a.out).write_text(json.dumps(out, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')

    per = {}
    for s in schools:
        per[s['province']] = per.get(s['province'], 0) + 1
    missing = [p for p in PROVINCES if p not in per]
    print(f'{len(schools)} okul, {len(per)} il yazıldı → {a.out}')
    if missing:
        print(f'UYARI: verisi olmayan iller ({len(missing)}): {", ".join(missing)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
