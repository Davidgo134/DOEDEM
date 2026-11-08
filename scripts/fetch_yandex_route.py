import requests
import json
import re

session = requests.Session()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept-Language': 'ru-RU,ru;q=0.9',
}

def main():
    print("1. Fetching Yandex Maps main page...")
    r = session.get('https://yandex.ru/maps/38/volgograd/', headers=headers, timeout=12)
    print(f"Status: {r.status_code}, Length: {len(r.text)}")
    
    token_match = re.search(r'"csrfToken":\s*"([^"]+)"', r.text)
    if token_match:
        token = token_match.group(1)
        print(f"Found CSRF Token: {token[:30]}...")
    else:
        # Try getting token from ajax request
        r_token = session.get('https://yandex.ru/maps/api/masstransit/getLine?ajax=1', headers=headers, timeout=10)
        token = r_token.json().get('csrfToken', '')
        print(f"Got CSRF Token from API: {token[:30]}...")

    print("\n2. Searching for transport lines...")
    # Search for masstransit line 174
    search_url = f'https://yandex.ru/maps/api/search?ajax=1&csrfToken={token}&lang=ru_RU&ll=44.5126%2C48.7126&spn=0.5%2C0.5&text=%D0%BC%D0%B0%D1%80%D1%88%D1%80%D1%83%D1%82%D0%BA%D0%B0%20174'
    r2 = session.get(search_url, headers=headers, timeout=12)
    print(f"Search status: {r2.status_code}, Length: {len(r2.text)}")
    
    try:
        data = r2.json()
        with open('scratch_yandex_search_174.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("Keys:", list(data.keys()))
        
        # Check for results
        results = data.get('data', {}).get('results', {})
        items = results.get('items', [])
        print(f"Items found: {len(items)}")
        for it in items[:5]:
            print(f"  Item: {it.get('title')} | Type: {it.get('type')} | Metadata: {it.get('metadata')}")
            # If it's a masstransit line:
            if 'masstransit' in str(it):
                print("    MASSTRANSIT FOUND!")
    except Exception as e:
        print("Error parsing search json:", e, r2.text[:300])

if __name__ == '__main__':
    main()
