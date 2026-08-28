import { Router } from 'express';
import { getPool } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';

const router = Router();

const PLAY_STORE_DEFAULT =
  'https://play.google.com/store/apps/details?id=com.asilia';

function truthy(value) {
  if (value == null) return false;
  const v = String(value).trim().toLowerCase();
  return v === '1' || v === 'true' || v === 'yes' || v === 'on';
}

function readSettingsMap(rows) {
  const settings = {};
  for (const r of rows) settings[r.key] = r.value;
  return settings;
}

function buildConfig(settings) {
  const messageEnabled = truthy(settings.screen_message_enabled);
  const messageBody = (settings.screen_message_body || '').trim();
  const forceUpdate = truthy(settings.force_update_enabled);

  return {
    screenMessage: {
      enabled: messageEnabled && messageBody.length > 0,
      id: settings.screen_message_id || '',
      title: settings.screen_message_title || '',
      body: messageBody,
      style: ['info', 'warning', 'success'].includes(settings.screen_message_style)
        ? settings.screen_message_style
        : 'info',
      dismissible: settings.screen_message_dismissible == null
        ? true
        : truthy(settings.screen_message_dismissible),
    },
    update: {
      forceUpdate,
      minVersion: settings.min_app_version || '',
      minBuild: parseInt(settings.min_app_build || '0', 10) || 0,
      title: settings.update_title || 'Update Required',
      message: settings.update_message ||
        'A new version of Dawa Asili is available. Update now to continue.',
      storeUrl: settings.store_url || PLAY_STORE_DEFAULT,
    },
  };
}

async function upsertSetting(db, key, value) {
  if (value == null) return;
  await db.query(
    `INSERT INTO app_settings (key, value, updated_at) VALUES ($1, $2, NOW())
     ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = NOW()`,
    [key, String(value)],
  );
}

/** Public: user app polls this on launch / refresh. */
router.get('/config', async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query('SELECT key, value FROM app_settings');
    res.json({ config: buildConfig(readSettingsMap(rows)) });
  } catch (err) {
    console.error('GET /api/app/config', err);
    res.status(500).json({ error: 'Imeshindwa kupata mipangilio ya app' });
  }
});

/** Admin: update screen message + force-update rules. */
router.put('/config', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const body = req.body || {};
    const screen = body.screenMessage || {};
    const update = body.update || {};

    const enabled = screen.enabled === true || screen.enabled === 'true';
    const dismissible = screen.dismissible == null
      ? true
      : screen.dismissible === true || screen.dismissible === 'true';
    const forceUpdate = update.forceUpdate === true || update.forceUpdate === 'true';
    const style = ['info', 'warning', 'success'].includes(screen.style)
      ? screen.style
      : 'info';

    // Bump message id whenever content changes so dismissed banners reappear.
    let messageId = (screen.id || '').trim();
    if (enabled) {
      const stamp = Date.now().toString(36);
      if (!messageId) {
        messageId = `msg_${stamp}`;
      } else if (body.bumpMessageId === true) {
        messageId = `msg_${stamp}`;
      }
    }

    await upsertSetting(db, 'screen_message_enabled', enabled ? 'true' : 'false');
    await upsertSetting(db, 'screen_message_id', messageId);
    await upsertSetting(db, 'screen_message_title', (screen.title || '').trim());
    await upsertSetting(db, 'screen_message_body', (screen.body || '').trim());
    await upsertSetting(db, 'screen_message_style', style);
    await upsertSetting(db, 'screen_message_dismissible', dismissible ? 'true' : 'false');

    await upsertSetting(db, 'force_update_enabled', forceUpdate ? 'true' : 'false');
    await upsertSetting(db, 'min_app_version', (update.minVersion || '').trim());
    await upsertSetting(
      db,
      'min_app_build',
      String(Math.max(0, parseInt(String(update.minBuild ?? '0'), 10) || 0)),
    );
    await upsertSetting(db, 'update_title', (update.title || '').trim() || 'Update Required');
    await upsertSetting(db, 'update_message', (update.message || '').trim());
    await upsertSetting(
      db,
      'store_url',
      (update.storeUrl || '').trim() || PLAY_STORE_DEFAULT,
    );

    const { rows } = await db.query('SELECT key, value FROM app_settings');
    res.json({ ok: true, config: buildConfig(readSettingsMap(rows)) });
  } catch (err) {
    console.error('PUT /api/app/config', err);
    res.status(500).json({ error: 'Imeshindwa kuhifadhi mipangilio ya app' });
  }
});

export default router;
