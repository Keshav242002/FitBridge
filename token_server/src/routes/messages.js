'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const store = require('../store');
const { emit } = require('./events');

const router = express.Router();

// In-memory typing state: { chatId: { userId: expiresAt } }
const typingState = {};

// POST /messages
router.post('/', (req, res) => {
  const { chatId, senderId, receiverId, text } = req.body || {};
  if (!chatId || !senderId || !receiverId || !text) {
    return res.status(400).json({ error: 'chatId, senderId, receiverId, text are required' });
  }
  if (typeof text !== 'string' || text.trim().length === 0) {
    return res.status(400).json({ error: 'text must be non-empty' });
  }
  if (!store.getUser(senderId) || !store.getUser(receiverId)) {
    return res.status(400).json({ error: 'Unknown user IDs' });
  }

  const msg = {
    id: uuidv4(),
    chatId,
    senderId,
    receiverId,
    text: text.trim(),
    createdAt: new Date().toISOString(),
    status: 'sent',
    isSystem: false,
  };
  store.addMessage(msg);
  emit([senderId, receiverId], 'message', msg);
  return res.status(201).json(msg);
});

// GET /messages?chatId=...&since=...
router.get('/', (req, res) => {
  const { chatId, since } = req.query;
  if (!chatId) return res.status(400).json({ error: 'chatId required' });
  return res.json(store.getMessages({ chatId, since }));
});

// POST /messages/typing — {chatId, userId}  (3-second TTL, no persistence)
router.post('/typing', (req, res) => {
  const { chatId, userId } = req.body || {};
  if (!chatId || !userId) return res.status(400).json({ error: 'chatId and userId required' });
  if (!typingState[chatId]) typingState[chatId] = {};
  typingState[chatId][userId] = Date.now() + 3000;
  return res.json({ ok: true });
});

// GET /messages/typing?chatId=... — returns [{userId}] for currently-typing users
router.get('/typing', (req, res) => {
  const { chatId } = req.query;
  if (!chatId) return res.status(400).json({ error: 'chatId required' });
  const now = Date.now();
  const active = Object.entries(typingState[chatId] || {})
    .filter(([, exp]) => exp > now)
    .map(([userId]) => ({ userId }));
  return res.json(active);
});

// POST /messages/read-batch — {ids: string[], readerId: string}
router.post('/read-batch', (req, res) => {
  const { ids, readerId } = req.body || {};
  if (!Array.isArray(ids) || !readerId) {
    return res.status(400).json({ error: 'ids (array) and readerId required' });
  }
  const updated = store.updateMessageStatus(ids, 'read');
  // notify original senders
  const senderIds = [...new Set(updated.map(m => m.senderId))];
  if (senderIds.length) emit(senderIds, 'messageRead', { ids, readerId });
  return res.json({ updated: updated.length });
});

module.exports = router;
