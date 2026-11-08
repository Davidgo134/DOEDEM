import json

with open('scratch_yandex_line_174.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

d = data['data']
print("Color:", d.get('color'))
print("Active thread:", d.get('activeThread'))
features = d.get('features', [])
print(f"Features count: {len(features)}")

for i, f in enumerate(features[:10]):
    ftype = f.get('type')
    geom = f.get('geometry', {})
    props = f.get('properties', {})
    print(f"Feature #{i}: geom_type={geom.get('type')}, properties_keys={list(props.keys())}")
    if 'name' in props:
        print(f"  Name: {props.get('name')}")
    if 'StopMetaData' in props:
        smd = props['StopMetaData']
        print(f"  Stop: {smd.get('name')}, coords={geom.get('coordinates')}")
    if 'ThreadMetaData' in props:
        tmd = props['ThreadMetaData']
        print(f"  ThreadMetaData: name={tmd.get('name')}, id={tmd.get('id')}, type={tmd.get('type')}")
    if 'LineMetaData' in props:
        lmd = props['LineMetaData']
        print(f"  LineMetaData: name={lmd.get('name')}, id={lmd.get('id')}")
    if geom.get('type') == 'LineString':
        coords = geom.get('coordinates', [])
        print(f"  LineString points: {len(coords)}")
        if coords:
            print(f"    first: {coords[0]}, last: {coords[-1]}")
