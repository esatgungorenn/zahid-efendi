"""Extracts LGS program records from a tabanpuanlari.net province page (Next.js RSC payload)."""
import json
import re

_PUSH = re.compile(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)', re.S)
_DEC = json.JSONDecoder()


def _payload(html: str) -> str:
    raw = ''.join(_PUSH.findall(html))
    # The chunks are JS string literals; decode them as JSON strings.
    return json.loads('"' + raw + '"')


def programs(html: str):
    s = _payload(html)
    seen = set()
    for m in re.finditer(r'\{"id":(\d+),"exam_type_id"', s):
        if m.group(1) in seen:
            continue
        try:
            obj, _ = _DEC.raw_decode(s, m.start())
        except json.JSONDecodeError:
            continue
        if obj.get('exam_type_code') != 'LGS':
            continue
        seen.add(m.group(1))
        yield obj


def stat(obj, year):
    for st in obj.get('yearly_stats') or []:
        if st.get('year') == year and st.get('term') == 1:
            return st
    return None
