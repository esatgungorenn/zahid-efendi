"""Phase 1: save raw HTML samples for parser development."""
import pathlib, time, requests

OUT = pathlib.Path('data/raw'); OUT.mkdir(parents=True, exist_ok=True)
H = {'User-Agent': 'zahit-efendi-family-app/1.0 (one-time fetch)'}
for slug in ['', 'konya', 'afyon', 'afyonkarahisar']:
    url = f'https://tabanpuanlari.net/lgs/{slug}'.rstrip('/')
    r = requests.get(url, headers=H, timeout=60)
    (OUT / f'{slug or "index"}.html').write_text(r.text, encoding='utf-8')
    print(url, r.status_code, len(r.text))
    time.sleep(1)
