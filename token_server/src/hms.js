'use strict';

const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

function mintAppToken({ userId, role, roomId }) {
  const accessKey = process.env.HMS_APP_ACCESS_KEY;
  const secret    = process.env.HMS_APP_SECRET;
  const hmsRoomId = roomId || process.env.HMS_ROOM_ID;

  if (accessKey && secret) {
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      access_key: accessKey,
      type: 'app',
      version: 2,
      room_id: hmsRoomId,
      user_id: userId,
      role,
      jti: uuidv4(),
      iat: now,
      exp: now + 86400, // 24h
      nbf: now,
    };
    const token = jwt.sign(payload, secret, { algorithm: 'HS256' });
    return { token, hmsRoomId, expiresAt: new Date((now + 86400) * 1000).toISOString(), mode: 'jwt' };
  }

  const fallback = process.env.HMS_FALLBACK_TOKEN;
  if (fallback) {
    return { token: fallback, hmsRoomId: hmsRoomId || '', expiresAt: null, mode: 'fallback' };
  }

  throw new Error('No HMS credentials configured. Set HMS_APP_ACCESS_KEY + HMS_APP_SECRET in .env, or set HMS_FALLBACK_TOKEN.');
}

module.exports = { mintAppToken };
