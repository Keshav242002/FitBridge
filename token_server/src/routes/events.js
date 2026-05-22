'use strict';

const express = require('express');
const router = express.Router();

// userId → Set<Response>
const clients = new Map();

function subscribe(userId, res) {
  if (!clients.has(userId)) clients.set(userId, new Set());
  clients.get(userId).add(res);
}

function unsubscribe(userId, res) {
  const set = clients.get(userId);
  if (set) { set.delete(res); if (set.size === 0) clients.delete(userId); }
}

function emit(userIds, eventName, data) {
  const payload = `event: ${eventName}\ndata: ${JSON.stringify(data)}\n\n`;
  for (const uid of userIds) {
    const set = clients.get(uid);
    if (!set) continue;
    for (const res of set) {
      try { res.write(payload); } catch (_) {}
    }
  }
}

// GET /events?userId=...
router.get('/', (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: 'userId required' });

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  res.write(`event: connected\ndata: {"userId":"${userId}"}\n\n`);

  subscribe(userId, res);

  const heartbeat = setInterval(() => {
    try { res.write(': heartbeat\n\n'); } catch (_) { clearInterval(heartbeat); }
  }, 25000);

  req.on('close', () => {
    clearInterval(heartbeat);
    unsubscribe(userId, res);
  });
});

module.exports = { router, emit };
