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

function signManagementToken() {
  const accessKey = process.env.HMS_APP_ACCESS_KEY;
  const secret    = process.env.HMS_APP_SECRET;
  if (!accessKey || !secret) return null;

  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      access_key: accessKey,
      type: 'management',
      version: 2,
      iat: now,
      nbf: now,
      exp: now + 86400,
      jti: uuidv4(),
    },
    secret,
    { algorithm: 'HS256' }
  );
}

async function createHmsRoom({ name, templateId }) {
  const mgmtToken = signManagementToken();
  if (!mgmtToken) {
    throw new Error('No HMS credentials for management token');
  }

  const res = await fetch('https://api.100ms.live/v2/rooms', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${mgmtToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name,
      template_id: templateId,
      description: `WTF call ${name}`,
    }),
  });

  if (!res.ok) {
    throw new Error(`HMS room create failed: ${res.status} ${await res.text()}`);
  }

  const data = await res.json();
  return data.id;
}

module.exports = { mintAppToken, signManagementToken, createHmsRoom };
