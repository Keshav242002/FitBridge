'use strict';

const express = require('express');
const store   = require('../store');
const { mintAppToken } = require('../hms');

const router = express.Router();

// POST /token — {userId, role, callRequestId?}
router.post('/', (req, res) => {
  const { userId, role, callRequestId } = req.body || {};

  if (!userId || !role) {
    return res.status(400).json({ error: 'userId and role are required' });
  }
  if (!['host', 'guest'].includes(role)) {
    return res.status(400).json({ error: 'role must be "host" or "guest"' });
  }
  if (!store.getUser(userId)) {
    return res.status(400).json({ error: 'Unknown userId' });
  }

  let roomId = process.env.HMS_ROOM_ID;
  if (callRequestId) {
    const rm = store.getRoomMeta(callRequestId);
    if (rm) roomId = rm.hmsRoomId;
  }

  try {
    const result = mintAppToken({ userId, role, roomId });
    return res.json(result);
  } catch (err) {
    return res.status(503).json({ error: err.message });
  }
});

module.exports = router;
