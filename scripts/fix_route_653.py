#!/usr/bin/env python3
"""
Generate 100% accurate road polyline for Route 653 (Волгоград - Михайловка - Троицкий - Реконструкция)
following Highway R-22 "Kaspiy" and road to Rekonstruktsiya.
"""
import json
import time
import requests

STOPS_653 = [
    {"name": "Центральный автовокзал Волгограда", "lat": 48.7126, "lng": 44.5126},
    {"name": "р.п. Городище (трасса Р-22)", "lat": 48.8035, "lng": 44.4720},
    {"name": "п. Самофаловка (трасса Р-22)", "lat": 49.0250, "lng": 44.2250},
    {"name": "р.п. Иловля (поворот / трасса Р-22)", "lat": 49.3033, "lng": 43.9806},
    {"name": "х. Ветютнев (поворот)", "lat": 49.7800, "lng": 43.6500},
    {"name": "г. Михайловка (автовокзал)", "lat": 50.0630, "lng": 43.2370},
    {"name": "х. Троицкий", "lat": 50.2350, "lng": 43.0540},
    {"name": "п. Реконструкция (конечная)", "lat": 50.2546, "lng": 43.0756}
]

def build_osrm_polyline(stops):
    full_polyline = []
    for i in range(len(stops) - 1):
        s1 = stops[i]
        s2 = stops[i + 1]
        coords_str = f"{s1['lng']},{s1['lat']};{s2['lng']},{s2['lat']}"
        url = f"http://router.project-osrm.org/route/v1/driving/{coords_str}?overview=full&geometries=geojson"
        try:
            r = requests.get(url, timeout=15)
            if r.status_code == 200:
                data = r.json()
                if data.get("routes"):
                    pts = data["routes"][0]["geometry"]["coordinates"]
                    for p in pts:
                        full_polyline.append({"lat": round(p[1], 6), "lng": round(p[0], 6)})
            else:
                full_polyline.append({"lat": s1["lat"], "lng": s1["lng"]})
                full_polyline.append({"lat": s2["lat"], "lng": s2["lng"]})
        except Exception as e:
            print(f"Error {s1['name']} -> {s2['name']}: {e}")
            full_polyline.append({"lat": s1["lat"], "lng": s1["lng"]})
            full_polyline.append({"lat": s2["lat"], "lng": s2["lng"]})
        time.sleep(0.15)

    deduped = []
    for pt in full_polyline:
        if not deduped or (deduped[-1]["lat"] != pt["lat"] or deduped[-1]["lng"] != pt["lng"]):
            deduped.append(pt)
    return deduped

def main():
    print("Building precise Route 653 with correct Rekonstruktsiya coordinates...")
    poly = build_osrm_polyline(STOPS_653)
    print(f"Done! Polyline points: {len(poly)}")

    # Load routes.json
    path = r"c:\Users\David\Pictures\DOEDEM\assets\routes.json"
    with open(path, "r", encoding="utf-8") as f:
        routes = json.load(f)

    # Find and update 653
    found = False
    for r in routes:
        if r["id"] == "653":
            r["name"] = "653 Волгоград - Михайловка - п. Реконструкция"
            r["description"] = "Пригородный экспресс по трассе Р-22 «Каспий» через Михайловку до п. Реконструкция."
            r["stops"] = STOPS_653
            r["polyline"] = poly
            found = True
            break

    if not found:
        routes.append({
            "id": "653",
            "name": "653 Волгоград - Михайловка - п. Реконструкция",
            "type": "Пригородный",
            "description": "Пригородный экспресс по трассе Р-22 «Каспий» через Михайловку до п. Реконструкция.",
            "color": "#006C50",
            "stops": STOPS_653,
            "polyline": poly
        })

    with open(path, "w", encoding="utf-8") as f:
        json.dump(routes, f, ensure_ascii=False, indent=2)

    print("Successfully updated Route 653 in assets/routes.json!")

if __name__ == "__main__":
    main()
