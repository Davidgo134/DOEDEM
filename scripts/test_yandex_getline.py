import requests
import json
import re

session = requests.Session()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept-Language': 'ru-RU,ru;q=0.9',
}

# 1. Fetch transport page to get cookies and session
r = session.get('https://yandex.ru/maps/38/volgograd/transport/', headers=headers, timeout=15)

# Extract csrfToken
token_match = re.search(r'"csrfToken":\s*"([^"]+)"', r.text)
csrf = token_match.group(1) if token_match else ''
print("CSRF Token:", csrf[:25])

# 2. Call getLine for line 2209963758 (minibus 149) or 2209963647 (bus 25)
for line_id in ['2209963758', '2209963647']:
    url = f'https://yandex.ru/maps/api/masstransit/getLine?ajax=1&csrfToken={csrf}&lang=ru_RU&lineId={line_id}'
    r_line = session.get(url, headers=headers, timeout=10)
    print(f"\nLine {line_id} status: {r_line.status_code}, Length: {len(r_line.text)}")
    if r_line.status_code == 200:
        try:
            data = r_line.json()
            with open(f'scratch_yandex_line_{line_id}.json', 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print("Keys:", list(data.keys()))
            if 'data' in data:
                line_data = data['data']
                print("Line title:", line_data.get('title') or line_data.get('name'))
                threads = line_data.get('threads', [])
                print(f"Threads: {len(threads)}")
                for t in threads:
                    print(f"  Thread: {t.get('name')}, Stops: {len(t.get('stops', []))}, Polyline: {len(t.get('polyline', {}).get('points', []))}")
        except Exception as e:
            print("Error parsing:", e, r_line.text[:200])
