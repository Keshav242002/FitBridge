'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const store = require('../store');

const router = express.Router();

// POST /session-logs
router.post('/', (req, res) => {
  const { memberId, trainerId, callRequestId, startedAt, endedAt, trainerNotes, memberNotes } = req.body || {};

  if (!memberId || !trainerId || !callRequestId || !startedAt || !endedAt) {
    return res.status(400).json({ error: 'memberId, trainerId, callRequestId, startedAt, endedAt are required' });
  }
  if (!store.getUser(memberId) || !store.getUser(trainerId)) {
    return res.status(400).json({ error: 'Unknown user IDs' });
  }

  const start = new Date(startedAt);
  const end   = new Date(endedAt);
  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    return res.status(400).json({ error: 'startedAt and endedAt must be valid ISO dates' });
  }

  const durationSec = Math.max(0, Math.round((end - start) / 1000));

  const sl = {
    id: uuidv4(),
    memberId,
    trainerId,
    callRequestId,
    startedAt: start.toISOString(),
    endedAt: end.toISOString(),
    durationSec,
    rating: null,
    trainerNotes: trainerNotes || null,
    memberNotes: memberNotes || null,
  };
  store.addSessionLog(sl);
  return res.status(201).json(sl);
});

// PATCH /session-logs/:id
router.patch('/:id', (req, res) => {
  const sl = store.getSessionLog(req.params.id);
  if (!sl) return res.status(404).json({ error: 'Session log not found' });

  const { rating, trainerNotes, memberNotes } = req.body || {};
  const patch = {};
  if (rating !== undefined) {
    const r = Number(rating);
    if (!Number.isInteger(r) || r < 1 || r > 5) {
      return res.status(400).json({ error: 'rating must be 1–5' });
    }
    patch.rating = r;
  }
  if (trainerNotes !== undefined) patch.trainerNotes = trainerNotes;
  if (memberNotes  !== undefined) patch.memberNotes  = memberNotes;

  const updated = store.updateSessionLog(sl.id, patch);
  return res.json(updated);
});

// GET /session-logs?userId=...&from=...&to=...
router.get('/', (req, res) => {
  const { userId, from, to } = req.query;
  if (!userId) return res.status(400).json({ error: 'userId required' });
  return res.json(store.getSessionLogs({ userId, from, to }));
});

module.exports = router;
