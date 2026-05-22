'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const store = require('../store');
const { createHmsRoom } = require('../hms');
const { emit } = require('./events');

const router = express.Router();

function addSystemMessage(chatId, senderId, receiverId, text) {
  const msg = {
    id: uuidv4(),
    chatId,
    senderId,
    receiverId,
    text,
    createdAt: new Date().toISOString(),
    status: 'sent',
    isSystem: true,
  };
  store.addMessage(msg);
  emit([senderId, receiverId], 'message', msg);
  return msg;
}

// POST /call-requests
router.post('/', (req, res) => {
  const { memberId, trainerId, scheduledFor, note } = req.body || {};

  if (!memberId || !trainerId || !scheduledFor) {
    return res.status(400).json({ error: 'memberId, trainerId, scheduledFor are required' });
  }
  if (!store.getUser(memberId) || !store.getUser(trainerId)) {
    return res.status(400).json({ error: 'Unknown user IDs' });
  }
  if (note && note.length > 140) {
    return res.status(400).json({ error: 'note must be ≤ 140 characters' });
  }

  const scheduledDate = new Date(scheduledFor);
  if (isNaN(scheduledDate.getTime())) {
    return res.status(400).json({ error: 'scheduledFor must be a valid ISO date' });
  }
  if (scheduledDate <= new Date()) {
    return res.status(400).json({ error: 'Cannot schedule in the past' });
  }
  if (store.hasConflict(trainerId, scheduledFor)) {
    return res.status(409).json({ error: 'Slot already booked — trainer has an approved call within 30 minutes' });
  }

  const cr = {
    id: uuidv4(),
    memberId,
    trainerId,
    requestedAt: new Date().toISOString(),
    scheduledFor: scheduledDate.toISOString(),
    note: note || '',
    status: 'pending',
    declineReason: null,
  };
  store.addCallRequest(cr);

  const chatId = `c_${trainerId.replace('tr_', '')}_${memberId.replace('mb_', '')}`;
  emit([memberId, trainerId], 'callRequest', cr);

  return res.status(201).json(cr);
});

// PATCH /call-requests/:id
router.patch('/:id', async (req, res) => {
  const { status, declineReason } = req.body || {};
  const cr = store.getCallRequest(req.params.id);
  if (!cr) return res.status(404).json({ error: 'Call request not found' });

  const allowed = ['approved', 'declined', 'cancelled'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: `status must be one of: ${allowed.join(', ')}` });
  }

  const patch = { status };
  if (status === 'declined' && declineReason) patch.declineReason = declineReason;

  let roomMeta = null;
  if (status === 'approved') {
    let hmsRoomId;
    const templateId = process.env.HMS_TEMPLATE_ID;
    if (templateId) {
      try {
        hmsRoomId = await createHmsRoom({ name: `call-${cr.id}`, templateId });
        console.log(`[hms] created room ${hmsRoomId} for call ${cr.id}`);
      } catch (e) {
        console.warn('[hms] room create failed, falling back to HMS_ROOM_ID:', e.message);
        hmsRoomId = process.env.HMS_ROOM_ID || 'room_placeholder';
      }
    } else {
      hmsRoomId = process.env.HMS_ROOM_ID || 'room_placeholder';
    }
    roomMeta = {
      id: uuidv4(),
      callRequestId: cr.id,
      hmsRoomId,
      hmsRoleMember: 'guest',
      hmsRoleTrainer: 'host',
    };
    store.addRoomMeta(roomMeta);
    patch.roomMetaId = roomMeta.id;
  }

  const updated = store.updateCallRequest(cr.id, patch);
  const chatId = `c_${cr.trainerId.replace('tr_', '')}_${cr.memberId.replace('mb_', '')}`;

  const scheduledStr = new Date(cr.scheduledFor).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });

  if (status === 'approved') {
    addSystemMessage(chatId, cr.trainerId, cr.memberId, `Call approved for ${scheduledStr}.`);
    emit([cr.memberId, cr.trainerId], 'callRequestUpdated', { ...updated, roomMeta });
  } else if (status === 'declined') {
    const reason = declineReason ? ` Reason: ${declineReason}` : '';
    addSystemMessage(chatId, cr.trainerId, cr.memberId, `Call request declined.${reason}`);
    emit([cr.memberId, cr.trainerId], 'callRequestUpdated', updated);
  } else {
    emit([cr.memberId, cr.trainerId], 'callRequestUpdated', updated);
  }

  return res.json({ callRequest: updated, roomMeta });
});

// GET /call-requests?userId=...&since=...
router.get('/', (req, res) => {
  const { userId, since } = req.query;
  if (!userId) return res.status(400).json({ error: 'userId required' });
  return res.json(store.getCallRequests({ userId, since }));
});

module.exports = router;
