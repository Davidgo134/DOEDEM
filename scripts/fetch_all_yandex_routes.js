const puppeteer = require('puppeteer-core');
const fs = require('fs');

const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const ROUTES_TO_FETCH = ['174', '123', '160', '260', '3с'];

async function fetchYandexRoute(routeNum) {
  console.log(`\n========================================`);
  console.log(`FETCHING YANDEX ROUTE: ${routeNum}`);
  console.log(`========================================`);

  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: false,
    defaultViewport: { width: 1280, height: 800 },
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--lang=ru-RU,ru']
  });

  const page = await browser.newPage();
  let capturedLineData = null;

  page.on('response', async (response) => {
    const url = response.url();
    if (url.includes('/masstransit/getLine')) {
      try {
        const text = await response.text();
        console.log(`[getLine Captured!] Size: ${text.length}`);
        const json = JSON.parse(text);
        capturedLineData = json;
        fs.writeFileSync(`scratch_yandex_line_${routeNum}.json`, JSON.stringify(json, null, 2));
      } catch (e) {
        console.log('Error parsing getLine:', e);
      }
    }
  });

  const query = `маршрутка ${routeNum}`;
  const targetUrl = 'https://yandex.ru/maps/38/volgograd/?text=' + encodeURIComponent(query);
  console.log(`Opening: ${targetUrl}`);

  try {
    await page.goto(targetUrl, { waitUntil: 'networkidle2', timeout: 35000 });
  } catch (e) {
    console.log('Navigation timeout or error:', e.message);
  }

  // If getLine hasn't triggered yet, click on the first search result card
  if (!capturedLineData) {
    console.log('Waiting for search results and clicking transport item...');
    await new Promise(r => setTimeout(r, 3000));
    try {
      // Look for search result item or transport snippet
      const items = await page.$$('.search-snippet-view, .masstransit-line-view, .search-list-view__list-item');
      if (items.length > 0) {
        console.log(`Found ${items.length} snippets, clicking first...`);
        await items[0].click();
      }
    } catch (e) {
      console.log('Click error:', e.message);
    }
    await new Promise(r => setTimeout(r, 4000));
  }

  await browser.close();
  return capturedLineData;
}

async function main() {
  for (const r of ROUTES_TO_FETCH) {
    await fetchYandexRoute(r);
    await new Promise(res => setTimeout(res, 2000));
  }
}

main().catch(console.error);
