# DOEDEM Real-Time Transit WebSocket Server

Быстрый и легковесный сервер реального времени для синхронизации геопозиций водителей и пассажиров приложения «ДОЕДЕМ».

## Как развернуть на Render.com за 2 минуты (бесплатно)

### Вариант 1: Через веб-интерфейс Render.com
1. Зарегистрируйтесь / войдите на [render.com](https://render.com).
2. Нажмите **New +** -> **Web Service**.
3. Подключите ваш репозиторий GitHub с проектом DOEDEM (или отдельный репозиторий с папкой `server`).
4. Настройте сервис:
   - **Name**: `doedem-server` (или любое другое)
   - **Root Directory**: `server` (если репозиторий общий)
   - **Runtime**: `Node`
   - **Build Command**: `npm install --production`
   - **Start Command**: `node index.js`
   - **Instance Type**: `Free`
5. Нажмите **Deploy Web Service**.
6. Через 1-2 минуты сервис запустится и выдаст URL вида:
   `https://doedem-server.onrender.com`
7. В приложении «ДОЕДЕМ» в Настройках укажите адрес:
   `wss://doedem-server.onrender.com/ws`

### Вариант 2: Через Docker
Если разворачиваете контейнером:
- Render автоматически обнаружит `server/Dockerfile`.

---

## Протокол обмена сообщениями (WebSocket)

- **Подключение**: `ws://HOST:PORT/ws` или `wss://HOST:PORT/ws`
- **Подписка на маршрут**:
  ```json
  {"type": "subscribe", "routeId": "174"}
  ```
  Сервер сразу возвращает текущие активные машины маршрута:
  ```json
  {"type": "init", "routeId": "174", "points": [...]}
  ```
- **Отправка точки (водитель или пассажир)**:
  ```json
  {
    "type": "track_point",
    "point": {
      "deviceId": "device_uuid_123",
      "routeId": "174",
      "lat": 48.715913,
      "lng": 44.516528,
      "speed": 14.5,
      "accuracy": 5.0,
      "source": "driver",
      "ts": "2026-11-08T22:00:00.000Z"
    }
  }
  ```
- **Широковещательное обновление подписчикам**:
  ```json
  {"type": "update", "routeId": "174", "points": [...]}
  ```
- **Keep-alive / Ping**:
  ```json
  {"type": "ping"}
  ```
  Ответ:
  ```json
  {"type": "pong", "timestamp": 1794175748000}
  ```

---

## Диагностические эндпоинты
- `GET /health` — проверка работоспособности (200 OK)
- `GET /api/routes/:routeId/points` — просмотр активных точек на маршруте через браузер
