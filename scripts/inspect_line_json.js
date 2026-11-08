const fs = require('fs');

if (fs.existsSync('scratch_captured_yandex_route.json')) {
  const data = JSON.parse(fs.readFileSync('scratch_captured_yandex_route.json', 'utf8'));
  console.log('Top keys:', Object.keys(data));
  if (data.data) {
    const line = data.data;
    console.log('Line Name:', line.name);
    console.log('Line Title:', line.title);
    console.log('Line Type:', line.type);
    console.log('Threads count:', line.threads ? line.threads.length : 0);
    if (line.threads) {
      for (let i = 0; i < line.threads.length; i++) {
        const t = line.threads[i];
        console.log(`\nThread #${i + 1}: ${t.name}`);
        console.log(`  Stops count: ${t.stops ? t.stops.length : 0}`);
        if (t.stops && t.stops.length > 0) {
          console.log(`  First stop: ${t.stops[0].name} (${t.stops[0].coordinates})`);
          console.log(`  Last stop: ${t.stops[t.stops.length - 1].name} (${t.stops[t.stops.length - 1].coordinates})`);
        }
        if (t.polyline) {
          console.log(`  Polyline points count: ${t.polyline.points ? t.polyline.points.length : 0}`);
        }
      }
    }
  }
} else {
  console.log('scratch_captured_yandex_route.json not found!');
}
