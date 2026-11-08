const puppeteer = require('puppeteer-core');
const fs = require('fs');

const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

async function testRoute174() {
  console.log('Launching Chrome...');
  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: false, // run visible so we can see what Yandex displays
    defaultViewport: { width: 1280, height: 800 },
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--lang=ru-RU,ru']
  });

  const page = await browser.newPage();
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7'
  });

  // Intercept all JSON responses
  const capturedResponses = [];
  page.on('response', async (response) => {
    const url = response.url();
    const status = response.status();
    const contentType = response.headers()['content-type'] || '';

    if (contentType.includes('json') || url.includes('masstransit') || url.includes('line') || url.includes('search')) {
      try {
        const text = await response.text();
        if (text.includes('174') || text.includes('thread') || text.includes('stops') || text.includes('polyline')) {
          console.log(`[Captured] ${status} ${url.substring(0, 80)} (Length: ${text.length})`);
          capturedResponses.push({ url, text });
          
          if (text.includes('stops') && text.includes('polyline')) {
            console.log('>>> FOUND ROUTE WITH STOPS AND POLYLINE! <<<');
            fs.writeFileSync('scratch_captured_yandex_route.json', text);
          }
        }
      } catch (_) {}
    }
  });

  console.log('Navigating to Yandex Maps search for маршрутка 174 Волгоград...');
  const targetUrl = 'https://yandex.ru/maps/38/volgograd/?text=' + encodeURIComponent('маршрутка 174');
  await page.goto(targetUrl, { waitUntil: 'networkidle2', timeout: 30000 });

  console.log('Page loaded! Waiting 10 seconds for user/transport interaction...');
  await new Promise(r => setTimeout(r, 10000));

  // Take screenshot
  await page.screenshot({ path: 'scratch_yandex_page.png' });
  console.log('Screenshot saved to scratch_yandex_page.png');

  console.log(`Total captured relevant responses: ${capturedResponses.length}`);
  fs.writeFileSync('scratch_all_captured.json', JSON.stringify(capturedResponses.map(c => ({ url: c.url, len: c.text.length })), null, 2));

  await browser.close();
  console.log('Browser closed.');
}

testRoute174().catch(console.error);
