import requests
import json
import re

session = requests.Session()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept-Language': 'ru-RU,ru;q=0.9',
}

# Fetch the Volgograd transport page specifically:
print("Fetching yandex.ru/maps/38/volgograd/transport/ ...")
r = session.get('https://yandex.ru/maps/38/volgograd/transport/', headers=headers, timeout=20)
print(f"Status: {r.status_code}, Length: {len(r.text)}")

# Save to inspect
with open('scratch_yandex_transport.html', 'w', encoding='utf-8') as f:
    f.write(r.text)

print("Checking for routes/174/masstransit in page...")
matches_174 = [m.start() for m in re.finditer(r'174', r.text)]
print(f"Occurrences of '174': {len(matches_174)}")

for idx in matches_174[:5]:
    start = max(0, idx - 100)
    end = min(len(r.text), idx + 200)
    print("--- SNIPPET ---")
    print(r.text[start:end])
