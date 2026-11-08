const fs = require('fs');

const captured = JSON.parse(fs.readFileSync('scratch_all_captured.json', 'utf8'));
console.log('Captured responses count:', captured.length);
for (const c of captured) {
  console.log(`- ${c.url} (size: ${c.len})`);
}
