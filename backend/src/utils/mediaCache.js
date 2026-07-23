import { randomUUID } from 'crypto';
import { getPool } from '../db.js';
import { resolveImageUrl, tidyImageUrl, normalizeImageUrl } from './resolveImageUrl.js';

const FETCH_TIMEOUT_MS = 45000;
const MAX_BYTES = 12 * 1024 * 1024;
const MIN_REAL_IMAGE_BYTES = 8000; // Postimages hotlink block is ~2.8KB

function postimgCandidates(raw) {
  const url = tidyImageUrl(raw);
  const out = [];
  const push = (u) => {
    if (u && !out.includes(u)) out.push(u);
  };
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\./, '').toLowerCase();
    if (host === 'i.postimg.cc') {
      const parts = u.pathname.split('/').filter(Boolean);
      if (parts.length >= 1) {
        const code = parts[0];
        const name = parts[1] || 'image.jpg';
        const ext = name.includes('.') ? name.split('.').pop().toLowerCase() : 'jpg';
        push(`https://i.postimg.cc/${code}/image.jpg`);
        push(`https://i.postimg.cc/${code}/image.png`);
        push(`https://i.postimg.cc/${code}/image.webp`);
        if (ext && !['jpg', 'jpeg', 'png', 'webp'].includes(ext)) {
          push(`https://i.postimg.cc/${code}/image.${ext}`);
        }
        push(`https://i.postimg.cc/${code}/image.${ext}`);
      }
    }
  } catch {
    // ignore
  }
  push(normalizeImageUrl(url));
  push(url);
  return out;
}

function refererFor(url) {
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\./, '').toLowerCase();
    if (host === 'i.postimg.cc') {
      const code = u.pathname.split('/').filter(Boolean)[0];
      return code ? `https://postimg.cc/${code}` : 'https://postimg.cc/';
    }
    if (host === 'i.ibb.co') return 'https://ibb.co/';
    return `${u.origin}/`;
  } catch {
    return 'https://www.google.com/';
  }
}

async function fetchBinary(url) {
  const res = await fetch(url, {
    redirect: 'follow',
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      Accept: 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      Referer: refererFor(url),
      'Cache-Control': 'no-cache',
    },
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = new Error(`upstream_${res.status}`);
    err.status = res.status;
    throw err;
  }
  const contentType = (res.headers.get('content-type') || '').toLowerCase();
  if (contentType.includes('text/html') || contentType.includes('application/json')) {
    throw new Error('not_image');
  }
  const buffer = Buffer.from(await res.arrayBuffer());
  if (buffer.length < MIN_REAL_IMAGE_BYTES) {
    throw new Error('placeholder_or_blocked');
  }
  if (buffer.length > MAX_BYTES) {
    throw new Error('too_large');
  }
  const type = contentType.startsWith('image/')
    ? contentType.split(';')[0]
    : 'image/jpeg';
  return { buffer, contentType: type };
}

export async function findCachedMedia(sourceUrl) {
  const url = tidyImageUrl(sourceUrl);
  if (!url) return null;
  const db = getPool();
  const { rows } = await db.query(
    `SELECT id, content_type, byte_size, source_url
     FROM media_assets
     WHERE source_url = $1
     LIMIT 1`,
    [url],
  );
  return rows[0] || null;
}

export async function getCachedMediaById(id) {
  const db = getPool();
  const { rows } = await db.query(
    `SELECT id, content_type, bytes, byte_size, source_url
     FROM media_assets WHERE id = $1 LIMIT 1`,
    [id],
  );
  return rows[0] || null;
}

async function storeMedia(sourceUrl, buffer, contentType) {
  const db = getPool();
  const id = randomUUID();
  const { rows } = await db.query(
    `INSERT INTO media_assets (id, source_url, content_type, bytes, byte_size)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (source_url) DO UPDATE SET
       content_type = EXCLUDED.content_type,
       bytes = EXCLUDED.bytes,
       byte_size = EXCLUDED.byte_size,
       updated_at = NOW()
     RETURNING id, content_type, byte_size, source_url`,
    [id, sourceUrl, contentType, buffer, buffer.length],
  );
  return rows[0];
}

/**
 * Download an image (trying Postimages candidates) and cache it.
 * @returns {Promise<{id, contentType, byteSize, sourceUrl, buffer?} | null>}
 */
export async function ingestImageUrl(raw, { includeBuffer = false } = {}) {
  const original = tidyImageUrl(raw);
  if (!original) return null;

  const existing = await findCachedMedia(original);
  if (existing && !includeBuffer) {
    return {
      id: existing.id,
      contentType: existing.content_type,
      byteSize: existing.byte_size,
      sourceUrl: existing.source_url,
    };
  }
  if (existing && includeBuffer) {
    const full = await getCachedMediaById(existing.id);
    return {
      id: full.id,
      contentType: full.content_type,
      byteSize: full.byte_size,
      sourceUrl: full.source_url,
      buffer: full.bytes,
    };
  }

  const resolved = await resolveImageUrl(original);
  const candidates = [
    ...postimgCandidates(resolved),
    ...postimgCandidates(original),
  ].filter((v, i, arr) => arr.indexOf(v) === i);

  let lastError = null;
  for (const candidate of candidates) {
    try {
      const { buffer, contentType } = await fetchBinary(candidate);
      // Store under both original and candidate keys for lookup.
      const saved = await storeMedia(original, buffer, contentType);
      if (candidate !== original) {
        try {
          await storeMedia(candidate, buffer, contentType);
        } catch {
          // ignore duplicate store race
        }
      }
      return {
        id: saved.id,
        contentType: saved.content_type,
        byteSize: saved.byte_size,
        sourceUrl: saved.source_url,
        ...(includeBuffer ? { buffer } : {}),
      };
    } catch (err) {
      lastError = err;
    }
  }

  if (lastError) throw lastError;
  return null;
}

/**
 * Prefer a stable API media URL when cached; otherwise return a proxy URL.
 */
export function mediaPublicPath(mediaId) {
  return `/api/media/${mediaId}`;
}

export async function toDisplayImageUrl(raw, apiBase = '') {
  const url = tidyImageUrl(raw);
  if (!url) return '';
  try {
    const cached = await findCachedMedia(url);
    if (cached) {
      const base = String(apiBase || '').replace(/\/$/, '');
      return base ? `${base}${mediaPublicPath(cached.id)}` : mediaPublicPath(cached.id);
    }
  } catch {
    // fall through
  }
  const base = String(apiBase || '').replace(/\/$/, '');
  const proxyPath = `/api/images/proxy?url=${encodeURIComponent(url)}`;
  return base ? `${base}${proxyPath}` : proxyPath;
}
