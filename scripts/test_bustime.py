import requests
import re

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
r = requests.get('https://www.busti.me/volgograd/', headers=headers, timeout=10)
print('Status:', r.status_code)
matches = re.findall(r'href=[\'"](/volgograd/[^\'"]+)[\'"]', r.text)
found_174 = [m for m in matches if '174' in m]
print('Found 174 links:', found_174)
print('First 15 links:', matches[:15])
