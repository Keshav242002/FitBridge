'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const store = require('../store');
const { emit } = require('./events');

const router = express.Router();

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
