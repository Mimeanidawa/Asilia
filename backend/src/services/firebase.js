import admin from 'firebase-admin';

let initialized = false;

export const FCM_TOPIC_ALL = 'asilia_all';
export const FCM_TOPIC_LESSONS = 'darasa_huru';
export const FCM_CHANNEL_ID = 'darasa_huru';

export function initFirebase() {
  if (initialized) return admin;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw || raw.trim() === '') {
    console.warn('FIREBASE_SERVICE_ACCOUNT not set — push notifications disabled');
    return null;
  }

  try {
    const serviceAccount = JSON.parse(raw);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
    console.log('Firebase Admin initialized');
    return admin;
  } catch (err) {
    console.error('Failed to initialize Firebase Admin:', err.message);
    return null;
  }
}

function androidConfig() {
  return {
    priority: 'high',
    notification: { channelId: FCM_CHANNEL_ID, sound: 'default' },
  };
}

function apnsConfig() {
  return {
    payload: { aps: { sound: 'default', badge: 1 } },
  };
}

async function sendToTopic(topic, { title, body, data }) {
  const fb = initFirebase();
  if (!fb) return { sent: false, reason: 'firebase_not_configured' };

  try {
    const messageId = await fb.messaging().send({
      topic,
      notification: { title, body },
      data,
      android: androidConfig(),
      apns: apnsConfig(),
    });
    return { sent: true, messageId };
  } catch (err) {
    console.error(`FCM topic send failed (${topic}):`, err.message);
    return { sent: false, error: err.message };
  }
}

async function sendToTokens(tokens, { title, body, data }) {
  const fb = initFirebase();
  if (!fb) return { sent: false, reason: 'firebase_not_configured' };
  if (!tokens?.length) return { sent: false, reason: 'no_tokens' };

  const unique = [...new Set(tokens.filter(Boolean))];
  let success = 0;
  const errors = [];

  for (const token of unique) {
    try {
      await fb.messaging().send({
        token,
        notification: { title, body },
        data,
        android: androidConfig(),
        apns: apnsConfig(),
      });
      success += 1;
    } catch (err) {
      errors.push(err.message);
      console.error('FCM token send failed:', err.message);
    }
  }

  return { sent: success > 0, successCount: success, errors };
}

export async function getUserDeviceTokens(userId) {
  const { getPool } = await import('../db.js');
  const db = getPool();
  const { rows } = await db.query(
    'SELECT token FROM device_tokens WHERE user_id = $1',
    [userId],
  );
  return rows.map((r) => r.token);
}

export async function sendLessonNotification(lesson) {
  const title = 'Darasa Huru — Somo Jipya!';
  const body = lesson.title;
  const data = {
    type: 'lesson',
    lessonId: lesson.id,
    title,
    body,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const topicResult = await sendToTopic(FCM_TOPIC_LESSONS, { title, body, data });
  return { sent: topicResult.sent, ...topicResult };
}

export async function sendContentNotification(post) {
  const title = 'Makala Mpya — Dawa Asili';
  const body = post.title;
  const data = {
    type: 'article',
    contentId: post.id,
    title,
    body,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const topicResult = await sendToTopic(FCM_TOPIC_ALL, { title, body, data });
  return { sent: topicResult.sent, ...topicResult };
}

export async function sendMwalimuReplyNotification({ userId, preview }) {
  const title = 'Jibu kutoka Mwalimu';
  const body = preview.length > 120 ? `${preview.slice(0, 117)}...` : preview;
  const data = {
    type: 'message',
    title,
    body,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const tokens = await getUserDeviceTokens(userId);
  return sendToTokens(tokens, { title, body, data });
}

export async function sendBroadcastNotification({ title, body, target = 'all' }) {
  const data = {
    type: 'general',
    title,
    body,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  if (target === 'all') {
    return sendToTopic(FCM_TOPIC_ALL, { title, body, data });
  }

  const { getPool } = await import('../db.js');
  const db = getPool();
  let query = 'SELECT token FROM device_tokens WHERE token IS NOT NULL';
  if (target === 'premium') {
    query = `SELECT dt.token FROM device_tokens dt
             INNER JOIN users u ON u.id = dt.user_id
             WHERE u.is_premium = TRUE`;
  } else if (target === 'free') {
    query = `SELECT dt.token FROM device_tokens dt
             INNER JOIN users u ON u.id = dt.user_id
             WHERE u.is_premium = FALSE`;
  }

  const { rows } = await db.query(query);
  const tokens = rows.map((r) => r.token);
  return sendToTokens(tokens, { title, body, data });
}
