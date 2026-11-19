const { createHash } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');

const {
  PAGASA_URL,
  PHIVOLCS_URL,
  parseEarthquakes,
  parseTyphoon,
} = require('./alert_sources');

initializeApp();

const db = getFirestore();

async function fetchOfficialPage(url) {
  const response = await fetch(url, {
    headers: { Accept: 'text/html' },
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) {
    throw new Error(`Official source returned HTTP ${response.status}: ${url}`);
  }
  return response.text();
}

async function sendEarthquakeAlerts() {
  const events = parseEarthquakes(await fetchOfficialPage(PHIVOLCS_URL));
  const stateRef = db.doc('disasterAlertState/earthquakes');
  const state = await stateRef.get();
  const latestId = events[0].id;

  if (!state.exists) {
    await stateRef.set({ latestId, updatedAt: new Date() });
    return;
  }

  const priorId = state.data().latestId;
  const newEvents = [];
  for (const event of events) {
    if (event.id === priorId) break;
    newEvents.push(event);
  }

  if (newEvents.length === 0) return;
  for (const event of newEvents.reverse()) {
    if (Number(event.magnitude) >= 4) {
      await getMessaging().send({
        topic: 'earthquake-alerts',
        notification: {
          title: `PHIVOLCS earthquake: magnitude ${event.magnitude}`,
          body: `${event.location} • ${event.time}`,
        },
        data: { kind: 'earthquake', url: event.id },
        android: { priority: 'high' },
      });
    }
    await stateRef.set({ latestId: event.id, updatedAt: new Date() });
  }
}

async function sendTyphoonAlerts() {
  const bulletin = parseTyphoon(await fetchOfficialPage(PAGASA_URL));
  const fingerprint = bulletin
    ? createHash('sha256').update(bulletin.id).digest('hex')
    : 'no-active-cyclone';
  const stateRef = db.doc('disasterAlertState/typhoon');
  const state = await stateRef.get();

  if (!state.exists) {
    await stateRef.set({ fingerprint, updatedAt: new Date() });
    return;
  }
  if (state.data().fingerprint === fingerprint) return;

  if (!bulletin) {
    await stateRef.set({ fingerprint, updatedAt: new Date() });
    return;
  }

  await getMessaging().send({
    topic: 'typhoon-alerts',
    notification: {
      title: 'PAGASA tropical cyclone bulletin',
      body: `${bulletin.title}: ${bulletin.details}`.slice(0, 240),
    },
    data: { kind: 'typhoon', url: bulletin.sourceUrl },
    android: { priority: 'high' },
  });
  await stateRef.set({ fingerprint, updatedAt: new Date() });
}

exports.publishDisasterAlerts = onSchedule(
  {
    schedule: 'every 5 minutes',
    timeZone: 'Asia/Manila',
    timeoutSeconds: 120,
  },
  async () => {
    const results = await Promise.allSettled([
      sendEarthquakeAlerts(),
      sendTyphoonAlerts(),
    ]);
    results.forEach((result, index) => {
      if (result.status === 'rejected') {
        logger.error(
          index === 0
            ? 'Failed to check PHIVOLCS earthquake alerts.'
            : 'Failed to check PAGASA typhoon bulletins.',
          result.reason,
        );
      }
    });
    if (results.every((result) => result.status === 'rejected')) {
      throw new Error('Could not check either official alert source.');
    }
  },
);
