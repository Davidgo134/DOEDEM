import requests
import json

# Query only relation metadata first (small and fast)
query = """[out:json][timeout:25];
area["name"="Волгоград"]["boundary"="administrative"]->.a;
(
  relation["route"~"bus|share_taxi"]["ref"="174"](area.a);
  relation["route"~"bus|share_taxi"]["ref"="123"](area.a);
  relation["route"~"bus|share_taxi"]["ref"="160"](area.a);
  relation["route"~"bus|share_taxi"]["ref"="260"](area.a);
  relation["route"~"bus|share_taxi"]["ref"="3с"](area.a);
);
out tags;
"""

print("Querying OSM relations tags...")
try:
    r = requests.post(
        'https://overpass-api.de/api/interpreter',
        data={'data': query},
        headers={'User-Agent': 'VolTransport/1.0'},
        timeout=20
    )
    print("Status:", r.status_code)
    if r.status_code == 200:
        data = r.json()
        print(f"Relations found: {len(data.get('elements', []))}")
        for el in data.get('elements', []):
            tags = el.get('tags', {})
            print(f"ID: {el['id']} | ref: {tags.get('ref')} | from: {tags.get('from')} -> to: {tags.get('to')} | name: {tags.get('name')}")
except Exception as e:
    print("Error:", e)
