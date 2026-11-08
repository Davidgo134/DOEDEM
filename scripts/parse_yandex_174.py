import json

with open('scratch_yandex_line_174.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("Top keys:", list(data.keys()))
if 'data' in data:
    d = data['data']
    print("Name:", d.get('name'))
    print("Title:", d.get('title'))
    print("Type:", d.get('type'))
    print("Line keys:", list(d.keys()))
    
    threads = d.get('threads', [])
    print(f"\nThreads count: {len(threads)}")
    for i, t in enumerate(threads):
        print(f"\n--- Thread {i+1}: {t.get('name')} (id: {t.get('id')}) ---")
        stops = t.get('stops', [])
        print(f"  Stops count: {len(stops)}")
        for s in stops[:3]:
            print(f"    Stop: {s.get('name')} (lat={s.get('lat') or s.get('coordinates')}, id={s.get('id')})")
            print("    Stop keys:", list(s.keys()))
        if len(stops) > 3:
            print(f"    ... and {len(stops)-3} more stops")
            last_stop = stops[-1]
            print(f"    Last Stop: {last_stop.get('name')} (lat={last_stop.get('lat') or last_stop.get('coordinates')})")
            
        polyline = t.get('polyline', {})
        print("  Polyline keys:", list(polyline.keys()) if isinstance(polyline, dict) else type(polyline))
        if isinstance(polyline, dict):
            pts = polyline.get('points', [])
            print(f"  Polyline points count: {len(pts)}")
            if pts:
                print(f"  First point: {pts[0]}")
                print(f"  Last point: {pts[-1]}")
