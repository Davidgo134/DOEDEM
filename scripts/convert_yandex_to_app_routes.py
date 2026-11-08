#!/usr/bin/env python3
"""
Convert official Yandex Maps Masstransit lines to DOEDEM routes.json.
Now includes ALL 6 ROUTES (174, 123, 160, 260, 3с, 653) directly from official Yandex Maps!
"""
import json
import os

ROUTE_DEFS = [
    {
        "file_id": "174",
        "id": "174",
        "color": "#00897B",
        "type": "Городской"
    },
    {
        "file_id": "123",
        "id": "123",
        "color": "#1565C0",
        "type": "Пригородный"
    },
    {
        "file_id": "160",
        "id": "160",
        "color": "#E65100",
        "type": "Пригородный"
    },
    {
        "file_id": "260",
        "id": "260",
        "color": "#6A1B9A",
        "type": "Пригородный"
    },
    {
        "file_id": "3с",
        "id": "3с",
        "color": "#D84315",
        "type": "Городской"
    },
    {
        "file_id": "653",
        "id": "653",
        "color": "#006C50",
        "type": "Пригородный"
    }
]

def parse_yandex_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    line_data = data.get('data', {})
    active_thread = line_data.get('activeThread', {})
    features = active_thread.get('features', [])
    
    stops = []
    polyline = []
    
    for item in features:
        if 'coordinates' in item and 'name' in item:
            name = item.get('name', '')
            coords = item.get('coordinates', [])
            if len(coords) >= 2:
                stops.append({
                    "name": name,
                    "lat": round(coords[1], 6),
                    "lng": round(coords[0], 6)
                })
        elif 'points' in item:
            pts = item.get('points', [])
            for p in pts:
                if len(p) >= 2:
                    polyline.append({
                        "lat": round(p[1], 6),
                        "lng": round(p[0], 6)
                    })
                    
    deduped_poly = []
    for p in polyline:
        if not deduped_poly or deduped_poly[-1]['lat'] != p['lat'] or deduped_poly[-1]['lng'] != p['lng']:
            deduped_poly.append(p)
            
    if not deduped_poly and stops:
        deduped_poly = [{"lat": s["lat"], "lng": s["lng"]} for s in stops]
        
    thread_meta = active_thread.get('properties', {}).get('ThreadMetaData', {})
    essential_stops = thread_meta.get('EssentialStops', [])
    from_name = stops[0]['name'] if stops else ''
    to_name = stops[-1]['name'] if stops else ''
    if len(essential_stops) >= 2:
        from_name = essential_stops[0].get('name', from_name)
        to_name = essential_stops[1].get('name', to_name)
        
    return {
        "stops": stops,
        "polyline": deduped_poly,
        "from": from_name,
        "to": to_name
    }

def main():
    final_routes = []
    
    for rdef in ROUTE_DEFS:
        fname = f"scratch_yandex_line_{rdef['file_id']}.json"
        if not os.path.exists(fname):
            print(f"WARNING: File {fname} not found!")
            continue
            
        print(f"Parsing Yandex file: {fname}...")
        parsed = parse_yandex_file(fname)
        
        route_id = rdef["id"]
        from_to = f"{parsed['from']} - {parsed['to']}" if parsed['from'] and parsed['to'] else ""
        route_name = f"{route_id} {from_to}".strip()
        
        print(f"  Route: {route_name}")
        print(f"  Stops: {len(parsed['stops'])}")
        print(f"  Polyline points: {len(parsed['polyline'])}")
        if parsed['stops']:
            print(f"    1st stop: {parsed['stops'][0]['name']}")
            print(f"    Last stop: {parsed['stops'][-1]['name']}")
            
        route_obj = {
            "id": route_id,
            "name": route_name,
            "type": rdef["type"],
            "description": f"Официальный маршрут Яндекс Карт. {len(parsed['stops'])} остановок.",
            "color": rdef["color"],
            "stops": parsed["stops"],
            "polyline": parsed["polyline"]
        }
        final_routes.append(route_obj)
        
    out_path = r"c:\Users\David\Pictures\DOEDEM\assets\routes.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(final_routes, f, ensure_ascii=False, indent=2)
        
    print(f"\nSUCCESS! Wrote {len(final_routes)} authentic Yandex routes to {out_path}")

if __name__ == '__main__':
    main()
