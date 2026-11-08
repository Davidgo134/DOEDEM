import json
import re

with open('scratch_wikiroutes_174.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Look for route ids, polyline, coordinates, stops, or json objects
print("Searching for routes and geo in wikiroutes HTML...")

# Look for json data in script tags
scripts = re.findall(r'<script[^>]*>(.*?)</script>', html, re.DOTALL)
print(f"Total script tags: {len(scripts)}")

for i, s in enumerate(scripts):
    if '174' in s or 'points' in s or 'polyline' in s or 'stops' in s or 'lat' in s:
        print(f"Script #{i} matches! Length: {len(s)}")
        # Print snippet
        lines = [line.strip() for line in s.split('\n') if line.strip()]
        for line in lines[:10]:
            print("  ", line[:120])

# Look for links to actual route pages
links = re.findall(r'href=[\'"](/volgograd/[^\'"]+)[\'"]', html)
print(f"Route links found: {len(links)}")
for l in links[:10]:
    print("  Link:", l)
