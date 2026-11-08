import json

with open(r'c:\Users\David\Pictures\DOEDEM\assets\routes.json', 'r', encoding='utf-8') as f:
    routes = json.load(f)

for r in routes:
    print(f"=== Route {r['id']}: {r['name']} ===")
    print(f"  Type: {r['type']}, Stops: {len(r['stops'])}, Polyline points: {len(r['polyline'])}")
    if r['stops']:
        print(f"  Start: {r['stops'][0]['name']} ({r['stops'][0]['lat']}, {r['stops'][0]['lng']})")
        print(f"  End:   {r['stops'][-1]['name']} ({r['stops'][-1]['lat']}, {r['stops'][-1]['lng']})")
    print()
