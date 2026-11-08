import re
import json

with open('scratch_yandex_transport.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Look for transit lines
lines = re.findall(r'"lineId":"(\d+)","name":"([^"]+)","Types":\["([^"]+)"\]', html)
print(f"Total lines found in initial transport state: {len(lines)}")
seen = set()
for lid, name, ltype in lines:
    key = (lid, name, ltype)
    if key not in seen:
        seen.add(key)
        print(f"  Line ID: {lid} | Name: {name} | Type: {ltype}")

# Also look for any search API or endpoint in JS
api_urls = set(re.findall(r'https?://[^\s"\'<>]+(?:masstransit|transit|transport)[^\s"\'<>]*', html))
print(f"\nAPI URLs related to transport in JS: {len(api_urls)}")
for u in list(api_urls)[:10]:
    print(" ", u)
