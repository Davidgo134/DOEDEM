import json

with open(r'c:\Users\David\Pictures\DOEDEM\assets\routes.json', 'r', encoding='utf-8') as f:
    routes = json.load(f)

for r in routes:
    print(f"=== {r['id']}: {r['name']} ===")
    print(f"  Stops: {len(r['stops'])}, Polyline points: {len(r['polyline'])}")
    if r['id'] == '653':
        for i, s in enumerate(r['stops']):
            print(f"    {i+1}. {s['name']} ({s['lat']}, {s['lng']})")
