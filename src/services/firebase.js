import admin from 'firebase-admin';

let initialized = false;

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

export async function sendLessonNotification(lesson) {
  const fb = initFirebase();
  if (!fb) {
    return { sent: false, reason: 'firebase_not_configured' };
  }

  const title = 'Darasa Huru — Somo Jipya!';
  const body = lesson.title;
  const data = {
    type: 'lesson',
    lessonId: lesson.id,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const results = { topic: null, tokens: null };

  try {
    results.topic = await fb.messaging().send({
      topic: 'darasa_huru',
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: { channelId: 'darasa_huru', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
  } catch (err) {
    console.error('FCM topic send failed:', err.message);
    results.topicError = err.message;
  }

  return { sent: !!results.topic, ...results };
}

export async function sendContentNotification(post) {
  const fb = initFirebase();
  if (!fb) {
    return { sent: false, reason: 'firebase_not_configured' };
  }

  const title = 'Makala Mpya — Dawa Asili';
  const body = post.title;
  const data = {
    type: 'article',
    contentId: post.id,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };

  const results = { topic: null };

  try {
    results.topic = await fb.messaging().send({
      topic: 'darasa_huru',
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: { channelId: 'darasa_huru', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
  } catch (err) {
    console.error('FCM content send failed:', err.message);
    results.topicError = err.message;
  }

  return { sent: !!results.topic, ...results };
}
