'use strict';

const fs = require('fs');
const path = require('path');

const DATA_FILE = process.env.DATA_FILE || './data.json';
const WRITE_DEBOUNCE_MS = 200;

const SEEDED_USERS = {
  tr_aarav: { id: 'tr_aarav', role: 'trainer', name: 'Aarav', email: 'aarav@wtf.local', avatarUrl: null, assignedTrainerId: null },
  mb_dk:    { id: 'mb_dk',    role: 'member',  name: 'DK',    email: 'dk@wtf.local',    avatarUrl: null, assignedTrainerId: 'tr_aarav' },
};

let state = {
  users: { ...SEEDED_USERS },
  messages: [],
  callRequests: [],
  roomMetas: [],
  sessionLogs: [],
};

function _load() {
  try {
    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    const saved = JSON.parse(raw);
    state = {
      users: { ...SEEDED_USERS, ...(saved.users || {}) },
      messages: saved.messages || [],
      callRequests: saved.callRequests || [],
      roomMetas: saved.roomMetas || [],
      sessionLogs: saved.sessionLogs || [],
    };
  } catch (_) {
    // no file yet — start fresh
  }
}

let _writeTimer = null;
function _scheduleWrite() {
  if (_writeTimer) clearTimeout(_writeTimer);
  _writeTimer = setTimeout(() => {
    try {
      fs.writeFileSync(DATA_FILE, JSON.stringify(state, null, 2));
    } catch (e) {
      console.error('[store] write error', e.message);
    }
  }, WRITE_DEBOUNCE_MS);
}

_load();

const store = {
  getUser: (id) => state.users[id] || null,
  getAllUsers: () => Object.values(state.users),

  addMessage: (msg) => { state.messages.push(msg); _scheduleWrite(); },
  getMessages: ({ chatId, since }) => {
    let msgs = state.messages.filter(m => m.chatId === chatId);
    if (since) {
      const sinceDate = new Date(since);
      msgs = msgs.filter(m => new Date(m.createdAt) > sinceDate);
    }
    return msgs.slice(-100).sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
  },
  updateMessageStatus: (ids, status) => {
    let changed = [];
    state.messages = state.messages.map(m => {
      if (ids.includes(m.id)) { const updated = { ...m, status }; changed.push(updated); return updated; }
      return m;
    });
    if (changed.length) _scheduleWrite();
    return changed;
  },

  addCallRequest: (cr) => { state.callRequests.push(cr); _scheduleWrite(); },
  getCallRequest: (id) => state.callRequests.find(cr => cr.id === id) || null,
  getCallRequests: ({ userId, since }) => {
    let list = state.callRequests.filter(cr => cr.memberId === userId || cr.trainerId === userId);
    if (since) { const d = new Date(since); list = list.filter(cr => new Date(cr.requestedAt) > d); }
    return list.sort((a, b) => new Date(a.scheduledFor) - new Date(b.scheduledFor));
  },
  updateCallRequest: (id, patch) => {
    let updated = null;
    state.callRequests = state.callRequests.map(cr => {
      if (cr.id !== id) return cr;
      updated = { ...cr, ...patch };
      return updated;
    });
    if (updated) _scheduleWrite();
    return updated;
  },
  hasConflict: (trainerId, scheduledFor) => {
    const t = new Date(scheduledFor).getTime();
    return state.callRequests.some(cr =>
      cr.trainerId === trainerId &&
      cr.status === 'approved' &&
      Math.abs(new Date(cr.scheduledFor).getTime() - t) < 30 * 60 * 1000
    );
  },

  addRoomMeta: (rm) => { state.roomMetas.push(rm); _scheduleWrite(); },
  getRoomMeta: (callRequestId) => state.roomMetas.find(r => r.callRequestId === callRequestId) || null,

  addSessionLog: (sl) => { state.sessionLogs.push(sl); _scheduleWrite(); },
  getSessionLog: (id) => state.sessionLogs.find(s => s.id === id) || null,
  updateSessionLog: (id, patch) => {
    let updated = null;
    state.sessionLogs = state.sessionLogs.map(s => {
      if (s.id !== id) return s;
      updated = { ...s, ...patch };
      return updated;
    });
    if (updated) _scheduleWrite();
    return updated;
  },
  getSessionLogs: ({ userId, from, to }) => {
    let list = state.sessionLogs.filter(s => s.memberId === userId || s.trainerId === userId);
    if (from) { const d = new Date(from); list = list.filter(s => new Date(s.startedAt) >= d); }
    if (to)   { const d = new Date(to);   list = list.filter(s => new Date(s.startedAt) <= d); }
    return list.sort((a, b) => new Date(b.startedAt) - new Date(a.startedAt));
  },
};

module.exports = store;
