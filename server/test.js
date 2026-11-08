const http = require('http');
const { WebSocket } = require('ws');

// Simple integration test for server
async function runTest() {
  console.log('--- Starting Doedem WebSocket Server Test ---');
  
  // 1. Test HTTP health endpoint
  const healthRes = await new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:8080/health', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });

  console.log('Health check response:', healthRes);
  if (healthRes.status !== 'ok') {
    throw new Error('Health status is not ok');
  }

  // 2. Test WebSocket connection & subscription
  const wsPassenger = new WebSocket('ws://127.0.0.1:8080/ws');
  const wsDriver = new WebSocket('ws://127.0.0.1:8080/ws');

  await Promise.all([
    new Promise(res => wsPassenger.on('open', res)),
    new Promise(res => wsDriver.on('open', res)),
  ]);

  console.log('Both passenger and driver WebSockets connected!');

  const receivedPointsPromise = new Promise((resolve) => {
    wsPassenger.on('message', (raw) => {
      const msg = JSON.parse(raw.toString());
      console.log('Passenger received msg:', msg.type, msg.routeId);
      if (msg.type === 'update' && msg.routeId === '174') {
        resolve(msg.points);
      }
    });
  });

  // Passenger subscribes to route 174
  wsPassenger.send(JSON.stringify({ type: 'subscribe', routeId: '174' }));

  // Driver sends a track point for route 174
  setTimeout(() => {
    wsDriver.send(JSON.stringify({
      type: 'track_point',
      point: {
        deviceId: 'driver-test-123',
        routeId: '174',
        lat: 48.7159,
        lng: 44.5165,
        speed: 15.0,
        accuracy: 4.5,
        source: 'driver',
        ts: new Date().toISOString()
      }
    }));
  }, 200);

  const points = await receivedPointsPromise;
  console.log('Passenger received updated points:', points);

  if (points.length !== 1 || points[0].deviceId !== 'driver-test-123') {
    throw new Error('Point verification failed: ' + JSON.stringify(points));
  }

  console.log('✓ Point verification passed successfully!');

  wsPassenger.close();
  wsDriver.close();

  console.log('All server integration tests PASSED!');
  process.exit(0);
}

runTest().catch((err) => {
  console.error('Test failed:', err);
  process.exit(1);
});
