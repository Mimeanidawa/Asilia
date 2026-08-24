import admin from 'firebase-admin';
import { publicApiBase } from '../utils/publicUrl.js';

let initialized = false;

export const FCM_TOPIC_ALL = 'asilia_all';
export const FCM_TOPIC_LESSONS = 'darasa_huru';
export const FCM_TOPIC_ADMIN = 'asilia_admin';
export const FCM_CHANNEL_ID = 'darasa_huru';
export const FCM_ADMIN_CHANNEL_ID = 'asilia_admin';

function apiOrigin() {
  return publicApiBase(null);
}

/** FCM data values must be strings. Skip empty entries. */
function stringifyData(obj = {}) {
  const data = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value == null) continue;
    const text = String(value).trim();
    if (!text) continue;
    data[key] = text;
  }
  return data;
}

/** Public URL FCM servers can fetch for BigPicture / iOS rich notifications. */
function fcmImageUrl(raw) {
  const url = String(raw || '').trim();
  if (!url) return undefined;
  if (/^https:\/\//i.test(url) && (url.includes('/api/media/') || url.includes('/api/images/'))) {
    return url;
  }
  if (/^https:\/\//i.test(url) && url.includes('/api/media/')) return url;
  const base = apiOrigin();
  if (url.startsWith('/api/')) return `${base}${url}`;
  return `${base}/api/images/proxy?url=${encodeURIComponent(url)}`;
}

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

function androidConfig(channelId, { imageUrl } = {}) {
  const notification = {
    channelId,
    sound: 'default',
    defaultSound: true,
    defaultVibrateTimings: true,
    priority: 'high',
    visibility: 'public',
    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
  };
  if (imageUrl) notification.imageUrl = imageUrl;
  return {
    priority: 'high',
    ttl: 86400000,
    notification,
  };
}

function apnsConfig({ imageUrl } = {}) {
  const config = {
    headers: { 'apns-priority': '10' },
    payload: {
      aps: {
        sound: 'default',
        badge: 1,
        'content-available': 1,
        'mutable-content': 1,
      },
    },
  };
  if (imageUrl) config.fcmOptions = { imageUrl };
  return config;
}

async function sendToTopic(topic, { title, body, data, channelId, imageUrl }) {
  const fb = initFirebase();
  if (!fb) return { sent: false, reason: 'firebase_not_configured' };

  const image = fcmImageUrl(imageUrl);
  const notification = { title, body };
  if (image) notification.imageUrl = image;

  try {
    const messageId = await fb.messaging().send({
      topic,
      notification,
      data: stringifyData(data),
      android: androidConfig(channelId || FCM_CHANNEL_ID, { imageUrl: image }),
      apns: apnsConfig({ imageUrl: image }),
    });
    return { sent: true, messageId };
  } catch (err) {
    console.error(`FCM topic send failed (${topic}):`, err.message);
    return { sent: false, error: err.message };
  }
}

async function sendToTokens(tokens, { title, body, data, channelId, imageUrl }) {
  const fb = initFirebase();
  if (!fb) return { sent: false, reason: 'firebase_not_configured' };
  if (!tokens?.length) return { sent: false, reason: 'no_tokens' };

  const unique = [...new Set(tokens.filter(Boolean))];
  const image = fcmImageUrl(imageUrl);
  const notification = { title, body };
  if (image) notification.imageUrl = image;

  let success = 0;
  const errors = [];

  for (const token of unique) {
    try {
      await fb.messaging().send({
        token,
        notification,
        data: stringifyData(data),
        android: androidConfig(channelId || FCM_CHANNEL_ID, { imageUrl: image }),
        apns: apnsConfig({ imageUrl: image }),
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
    imageUrl: lesson.imageUrl || '',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const topicResult = await sendToTopic(FCM_TOPIC_LESSONS, {
    title,
    body,
    data,
    channelId: FCM_CHANNEL_ID,
    imageUrl: lesson.imageUrl,
  });
  return { sent: topicResult.sent, ...topicResult };
}

export async function sendContentNotification(post, { title, body } = {}) {
  const notifTitle = title?.trim() || 'Makala Mpya — Dawa Asili';
  const notifBody = body?.trim() || post.title;
  const data = {
    type: 'article',
    contentId: String(post.id || ''),
    section: post.section ?? '',
    title: notifTitle,
    body: notifBody,
    imageUrl: post.imageUrl || '',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const topicResult = await sendToTopic(FCM_TOPIC_ALL, {
    title: notifTitle,
    body: notifBody,
    data,
    channelId: FCM_CHANNEL_ID,
    imageUrl: post.imageUrl,
  });
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
  return sendToTokens(tokens, {
    title,
    body,
    data,
    channelId: FCM_CHANNEL_ID,
  });
}

/** Status-bar alert for admins — never include the user's message text. */
export async function sendAdminNewUserMessageNotification({ userName } = {}) {
  const title = 'Ujumbe mpya';
  const who = userName?.trim() ? userName.trim() : 'mtumiaji';
  const body = `New message from ${who}`;
  const data = {
    type: 'admin_message',
    title,
    body,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const payload = {
    title,
    body,
    data,
    channelId: FCM_ADMIN_CHANNEL_ID,
  };

  let tokenResult = { sent: false, reason: 'no_tokens' };
  let topicResult = { sent: false, reason: 'not_attempted' };

  try {
    const { getPool } = await import('../db.js');
    const db = getPool();
    const { rows } = await db.query(
      'SELECT token FROM admin_device_tokens WHERE token IS NOT NULL',
    );
    const tokens = rows.map((r) => r.token).filter(Boolean);
    if (tokens.length) {
      tokenResult = await sendToTokens(tokens, payload);
    }
  } catch (err) {
    console.error('Admin device token notify failed:', err.message);
    tokenResult = { sent: false, error: err.message };
  }

  // Topic delivery works even when token registration failed (e.g. app never logged in
  // after install but topic was subscribed at bootstrap). Skip topic only when every
  // token send succeeded to avoid double notifications on the same device.
  const allTokensSucceeded =
    tokenResult.sent &&
    (!tokenResult.errors || tokenResult.errors.length === 0) &&
    (tokenResult.successCount ?? 0) > 0;

  if (!allTokensSucceeded) {
    topicResult = await sendToTopic(FCM_TOPIC_ADMIN, payload);
  }

  const sent = tokenResult.sent || topicResult.sent;
  if (!sent) {
    console.warn('Admin new-message push not delivered', { tokenResult, topicResult });
  }

  return { sent, tokens: tokenResult, topic: topicResult };
}

export async function sendBroadcastNotification({
  title,
  body,
  target = 'all',
  contentId,
  imageUrl,
} = {}) {
  const data = {
    type: contentId ? 'article' : 'general',
    title,
    body,
    contentId: contentId || '',
    imageUrl: imageUrl || '',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  if (target === 'all') {
    return sendToTopic(FCM_TOPIC_ALL, {
      title,
      body,
      data,
      channelId: FCM_CHANNEL_ID,
      imageUrl,
    });
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
  return sendToTokens(tokens, {
    title,
    body,
    data,
    channelId: FCM_CHANNEL_ID,
    imageUrl,
  });
}
