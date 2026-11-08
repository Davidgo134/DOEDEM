#!/usr/bin/env python3
"""Test and generate full real route 174 with all stops from Peschanka to Krasnoslobodsk VIR."""
import json
import time
import requests

ROUTE_174_STOPS = [
    {"name": "пос. Песчанка (Школа № 3)", "lat": 48.6482, "lng": 44.3315},
    {"name": "ТРЦ «Акварель»", "lat": 48.6367, "lng": 44.4361},
    {"name": "ВолГУ", "lat": 48.6420, "lng": 44.4320},
    {"name": "Кардиоцентр", "lat": 48.6465, "lng": 44.4285},
    {"name": "ЖК «Янтарный город»", "lat": 48.6520, "lng": 44.4380},
    {"name": "ул. Полухина", "lat": 48.6620, "lng": 44.4520},
    {"name": "Обувная фабрика", "lat": 48.6720, "lng": 44.4600},
    {"name": "Зелёное кольцо", "lat": 48.6790, "lng": 44.4650},
    {"name": "Колледж нефти и газа", "lat": 48.6850, "lng": 44.4690},
    {"name": "Стадион «Нефтяник»", "lat": 48.6890, "lng": 44.4740},
    {"name": "ВолГАУ (СХИ)", "lat": 48.6940, "lng": 44.4790},
    {"name": "Сельхозтехника", "lat": 48.6980, "lng": 44.4840},
    {"name": "ул. Ардатовская", "lat": 48.7010, "lng": 44.4875},
    {"name": "ул. Елисеева", "lat": 48.7020, "lng": 44.4890},
    {"name": "ул. Кузнецкая (Елецкая)", "lat": 48.7045, "lng": 44.4940},
    {"name": "Казачий театр", "lat": 48.7005, "lng": 44.5020},
    {"name": "Площадь Чекистов", "lat": 48.7040, "lng": 44.5120},
    {"name": "ул. Краснознаменская", "lat": 48.7065, "lng": 44.5165},
    {"name": "ул. Комсомольская", "lat": 48.7095, "lng": 44.5220},
    {"name": "ул. Порт-Саида", "lat": 48.7140, "lng": 44.5265},
    {"name": "Площадь Ленина", "lat": 48.7209, "lng": 44.5329},
    {"name": "7-я Гвардейская", "lat": 48.7265, "lng": 44.5385},
    {"name": "ул. Хиросимы", "lat": 48.7300, "lng": 44.5420},
    {"name": "Мост через Волгу", "lat": 48.7325, "lng": 44.5650},
    {"name": "Бобры (Заволжье)", "lat": 48.7300, "lng": 44.5950},
    {"name": "г. Краснослободск (ПМК-41)", "lat": 48.7150, "lng": 44.6200},
    {"name": "г. Краснослободск (Школа № 4)", "lat": 48.7100, "lng": 44.6280},
    {"name": "г. Краснослободск (Мебельная фабрика)", "lat": 48.7060, "lng": 44.6320},
    {"name": "г. Краснослободск (Рынок / Центр)", "lat": 48.7020, "lng": 44.6390},
    {"name": "г. Краснослободск (Поликлиника)", "lat": 48.6980, "lng": 44.6440},
    {"name": "мкр. ВИР (конечная)", "lat": 48.6920, "lng": 44.6520}
]

def build_osrm_polyline(stops):
    full_polyline = []
    for i in range(len(stops) - 1):
        s1 = stops[i]
        s2 = stops[i + 1]
        coords_str = f"{s1['lng']},{s1['lat']};{s2['lng']},{s2['lat']}"
        url = f"http://router.project-osrm.org/route/v1/driving/{coords_str}?overview=full&geometries=geojson"
        try:
            r = requests.get(url, timeout=12)
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
        time.sleep(0.1)

    deduped = []
    for pt in full_polyline:
        if not deduped or (deduped[-1]["lat"] != pt["lat"] or deduped[-1]["lng"] != pt["lng"]):
            deduped.append(pt)
    return deduped

def main():
    print("Building full 174 route with OSRM...")
    poly = build_osrm_polyline(ROUTE_174_STOPS)
    print(f"Done! Points: {len(poly)}")
    
    # Read existing routes.json
    with open(r"c:\Users\David\Pictures\DOEDEM\assets\routes.json", "r", encoding="utf-8") as f:
        routes = json.load(f)
        
    # Replace 174
    for r in routes:
        if r["id"] == "174":
            r["name"] = "174 пос. Песчанка - ТРЦ Акварель - ВИР (Краснослободск)"
            r["description"] = "Интервал 8-12 мин. Самый длинный маршрут: Песчанка -> ТРЦ Акварель -> Центр -> Мост через Волгу -> Краснослободск (ВИР)"
            r["stops"] = ROUTE_174_STOPS
            r["polyline"] = poly
            break
            
    with open(r"c:\Users\David\Pictures\DOEDEM\assets\routes.json", "w", encoding="utf-8") as f:
        json.dump(routes, f, ensure_ascii=False, indent=2)
    print("Updated 174 in assets/routes.json successfully!")

if __name__ == "__main__":
    main()
