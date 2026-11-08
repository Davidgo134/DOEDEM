import re
import json

with open('scratch_2gis_route_174.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Look for initialState or scripts or links
scripts = re.findall(r'<script[^>]*>(.*?)</script>', html, re.DOTALL)
print(f"Total script tags: {len(scripts)}")
for i, s in enumerate(scripts):
    if len(s) > 100:
        print(f"Script #{i} length: {len(s)}")
        print("  Snippet:", s[:200])

# Look for window.__INITIAL_STATE__ or json
initial_state = re.search(r'window\.__INITIAL_STATE__\s*=\s*(\{.*?\});', html, re.DOTALL)
if initial_state:
    print("Found __INITIAL_STATE__!")
    try:
        data = json.loads(initial_state.group(1))
        print("Initial state keys:", list(data.keys()))
    except Exception as e:
        print("Error parsing state:", e)

# Look for canonical URL or meta tags
metas = re.findall(r'<meta[^>]+>', html)
for m in metas:
    if 'description' in m or 'title' in m or 'og:' in m:
        print("Meta:", m)
