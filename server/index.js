const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');

const PORT = parseInt(process.env.PORT || '8080', 10);
const HOST = '0.0.0.0';
// Stale threshold: vehicles inactive for more than 120 seconds are purged
const STALE_TTL_MS = 120 * 1000;

// In-memory state:
// routeId -> Map<deviceId, TrackPoint>
const routePoints = new Map();

// WebSocket -> Set<routeId>
const clientSubscriptions = new Map();

// Helper to get active points for a route as an array
function getActivePointsForRoute(routeId) {
  const map = routePoints.get(routeId);
  if (!map) return [];
  return Array.from(map.values());
}

// Broadcast an update for a route to all subscribed clients
function broadcastRouteUpdate(routeId) {
  const points = getActivePointsForRoute(routeId);
  const payload = JSON.stringify({
    type: 'update',
    routeId,
    points,
    serverTime: new Date().toISOString()
  });

  for (const [ws, routes] of clientSubscriptions.entries()) {
    if (routes.has(routeId) && ws.readyState === WebSocket.OPEN) {
      try {
        ws.send(payload);
      } catch (err) {
        console.error('Failed to send to client:', err.message);
      }
    }
  }
}

// Ingest a track point from a driver or passenger
function ingestTrackPoint(point) {
  if (!point || !point.routeId || !point.deviceId || point.lat === undefined || point.lng === undefined) {
    return false;
  }

  const routeId = String(point.routeId);
  const deviceId = String(point.deviceId);

  if (!routePoints.has(routeId)) {
    routePoints.set(routeId, new Map());
  }

  const map = routePoints.get(routeId);
  
  // Format normalized point
  const normalizedPoint = {
    deviceId,
    routeId,
    lat: Number(point.lat),
    lng: Number(point.lng),
    speed: Number(point.speed || 0),
    accuracy: Number(point.accuracy || 0),
    source: point.source === 'driver' ? 'driver' : 'passenger',
    ts: point.ts ? new Date(point.ts).toISOString() : new Date().toISOString(),
    receivedAt: Date.now()
  };

  map.set(deviceId, normalizedPoint);
  broadcastRouteUpdate(routeId);
  return true;
}

// Periodic cleanup of stale points (> 120s without update)
setInterval(() => {
  const now = Date.now();
  for (const [routeId, map] of routePoints.entries()) {
    let changed = false;
    for (const [deviceId, pt] of map.entries()) {
      const pointTime = new Date(pt.ts).getTime();
      const age = now - (isNaN(pointTime) ? pt.receivedAt : pointTime);
      if (age > STALE_TTL_MS) {
        map.delete(deviceId);
        changed = true;
        console.log(`[STALE] Evicted device ${deviceId} from route ${routeId} (age: ${Math.round(age / 1000)}s)`);
      }
    }
    if (changed) {
      broadcastRouteUpdate(routeId);
    }
  }
}, 10000);

// Create HTTP Server
const server = http.createServer((req, res) => {
  // Add CORS headers for web testing/diagnostics
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  // Health check endpoint for Render.com zero-downtime monitoring
  if (url.pathname === '/health' || url.pathname === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'doedem-ws-server',
      uptime: process.uptime(),
      connections: clientSubscriptions.size,
      activeRoutes: routePoints.size,
      timestamp: new Date().toISOString()
    }));
    return;
  }

  // Debug REST API to inspect points of a route: /api/routes/:id/points
  if (url.pathname.startsWith('/api/routes/') && url.pathname.endsWith('/points')) {
    const parts = url.pathname.split('/');
    const routeId = parts[3];
    const points = getActivePointsForRoute(routeId);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ routeId, pointsCount: points.length, points }));
    return;
  }

  // Root landing info
  if (url.pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      name: 'DOEDEM Real-Time Transit WebSocket Server',
      description: 'Volgograd Public Transport Live GPS Tracking',
      wsEndpoint: '/ws',
      healthCheck: '/health',
      activeConnections: clientSubscriptions.size,
      version: '1.0.0'
    }, null, 2));
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

// Create WebSocket Server attached to HTTP server
const wss = new WebSocketServer({ server });

wss.on('connection', (ws, req) => {
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  console.log(`[WS] Client connected from ${clientIp}`);

  clientSubscriptions.set(ws, new Set());

  // Send welcome ping
  ws.send(JSON.stringify({
    type: 'connected',
    message: 'Connected to DOEDEM Real-Time Tracking Server',
    serverTime: new Date().toISOString()
  }));

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());
      handleClientMessage(ws, message);
    } catch (err) {
      console.error('[WS] Invalid JSON message received:', err.message);
      try {
        ws.send(JSON.stringify({ type: 'error', error: 'Invalid JSON payload' }));
      } catch (_) {}
    }
  });

  ws.on('close', (code, reason) => {
    clientSubscriptions.delete(ws);
    console.log(`[WS] Client disconnected (code: ${code})`);
  });

  ws.on('error', (err) => {
    console.error('[WS] Socket error:', err.message);
    clientSubscriptions.delete(ws);
  });
});

function handleClientMessage(ws, msg) {
  if (!msg || !msg.type) return;

  const routes = clientSubscriptions.get(ws);
  if (!routes) return;

  switch (msg.type) {
    case 'subscribe': {
      const routeId = String(msg.routeId || '');
      if (routeId) {
        routes.add(routeId);
        console.log(`[WS] Client subscribed to route ${routeId}`);
        // Immediately send current active points for this route
        const points = getActivePointsForRoute(routeId);
        ws.send(JSON.stringify({
          type: 'init',
          routeId,
          points,
          serverTime: new Date().toISOString()
        }));
      }
      break;
    }

    case 'unsubscribe': {
      const routeId = String(msg.routeId || '');
      if (routeId) {
        routes.delete(routeId);
        console.log(`[WS] Client unsubscribed from route ${routeId}`);
      }
      break;
    }

    case 'track_point': {
      const point = msg.point;
      if (point) {
        ingestTrackPoint(point);
      }
      break;
    }

    case 'track_batch': {
      const points = msg.points;
      if (Array.isArray(points)) {
        for (const pt of points) {
          ingestTrackPoint(pt);
        }
      }
      break;
    }

    case 'ping': {
      ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
      break;
    }

    default:
      console.warn(`[WS] Unknown message type: ${msg.type}`);
  }
}

// Start server
server.listen(PORT, HOST, () => {
  console.log(`====================================================`);
  console.log(` DOEDEM Real-Time Transit WebSocket Server`);
  console.log(` Listening on http://${HOST}:${PORT}`);
  console.log(` Health check: http://${HOST}:${PORT}/health`);
  console.log(` WebSocket: ws://${HOST}:${PORT}/ws`);
  console.log(`====================================================`);
});

// Graceful shutdown
function shutdown() {
  console.log('Shutting down server...');
  wss.close(() => {
    server.close(() => {
      console.log('Server shut down cleanly.');
      process.exit(0);
    });
  });
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
