'use strict';

require('dotenv').config();

const express = require('express');
const cors    = require('cors');

const { router: eventsRouter } = require('./routes/events');
const messagesRouter           = require('./routes/messages');
const callRequestsRouter       = require('./routes/call_requests');
const sessionLogsRouter        = require('./routes/session_logs');
const tokenRouter              = require('./routes/token');
const store                    = require('./store');

const app  = express();
const PORT = parseInt(process.env.PORT || '8787', 10);

app.use(cors());
app.use(express.json());

// Health
app.get('/health', (_req, res) => {
  const hasHms = !!(process.env.HMS_APP_ACCESS_KEY && process.env.HMS_APP_SECRET);
  const hasFallback = !!process.env.HMS_FALLBACK_TOKEN;
  res.json({
    ok: true,
    uptime: Math.floor(process.uptime()),
    hmsMode: hasHms ? 'jwt' : hasFallback ? 'fallback' : 'unconfigured',
  });
});

// Users (read-only seeded list)
app.get('/users', (_req, res) => res.json(store.getAllUsers()));

// Routes
app.use('/events',        eventsRouter);
app.use('/messages',      messagesRouter);
app.use('/call-requests', callRequestsRouter);
app.use('/session-logs',  sessionLogsRouter);
app.use('/token',         tokenRouter);

// 404
app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

app.listen(PORT, () => {
  console.log(`[wtf-server] listening on http://localhost:${PORT}`);
  console.log(`[wtf-server] HMS mode: ${process.env.HMS_APP_ACCESS_KEY ? 'jwt' : process.env.HMS_FALLBACK_TOKEN ? 'fallback' : 'unconfigured'}`);
});
