/**
 * Normalize / resolve share-page image URLs (ImgBB, Postimages)
 * into direct CDN URLs that mobile clients / the image proxy can load.
 */

const OG_IMAGE_RE =
  /(?:property|name)=["']og:image["'][^>]*content=["']([^"']+)["']|content=["']([^"']+)["'][^>]*(?:property|name)=["']og:image["']/i;

const RESOLVE_TIMEOUT_MS = 8000;

export function tidyImageUrl(raw) {
  let url = String(raw || '').trim();
  if (url.startsWith('//')) url = `https:${url}`;
  return url;
}

function tidy(raw) {
  return tidyImageUrl(raw);
}

function looksLikeBlockedPostimgPath(pathname) {
  const name = pathname.split('/').filter(Boolean).pop()?.toLowerCase() || '';
  return name.startsWith('file-00000000') || /^file-[0-9a-f]{20,}/.test(name);
}

/** Sync rewrite: prefer canonical postimg `image.ext` names. */
export function normalizeImageUrl(raw) {
  const url = tidy(raw);
  if (!url) return '';
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\./, '').toLowerCase();
    if (host === 'i.postimg.cc') {
      const parts = u.pathname.split('/').filter(Boolean);
      if (parts.length >= 2) {
        const file = parts[1].toLowerCase();
        if (!file.startsWith('image.')) {
          const ext = file.includes('.') ? file.split('.').pop() : 'jpg';
          const safeExt = ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(ext) ? ext : 'jpg';
          return `${u.protocol}//${u.host}/${parts[0]}/image.${safeExt === 'jpeg' ? 'jpg' : safeExt}`;
        }
      }
    }
  } catch {
    return url;
  }
  return url;
}

function needsResolution(url) {
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\./, '').toLowerCase();
    if (host === 'ibb.co' || host === 'postimg.cc' || host === 'postimages.org') return true;
    if (host === 'i.postimg.cc') {
      const parts = u.pathname.split('/').filter(Boolean);
      const file = (parts[1] || '').toLowerCase();
      // Non-canonical filenames often 403; resolve via share page.
      if (!file.startsWith('image.')) return true;
      if (looksLikeBlockedPostimgPath(u.pathname)) return true;
    }
    return false;
  } catch {
    return false;
  }
}

function sharePageCandidate(url) {
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\./, '').toLowerCase();
    if (host !== 'i.postimg.cc') return url;
    const code = u.pathname.split('/').filter(Boolean)[0];
    return code ? `https://postimg.cc/${code}` : url;
  } catch {
    return url;
  }
}

function looksLikeDirectImage(url) {
  try {
    const u = new URL(url);
    const host = u.hostname.toLowerCase();
    if (host === 'i.ibb.co' || host.includes('imgur.com')) return true;
    if (host === 'i.postimg.cc') {
      const name = u.pathname.split('/').filter(Boolean).pop()?.toLowerCase() || '';
      if (looksLikeBlockedPostimgPath(u.pathname)) return false;
      return name.startsWith('image.') || /\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$/i.test(u.pathname);
    }
    if (/\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$/i.test(u.pathname)) return true;
    return false;
  } catch {
    return false;
  }
}

function decodeHtmlEntities(value) {
  return String(value || '')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

/**
 * @param {string} raw
 * @returns {Promise<string>}
 */
export async function resolveImageUrl(raw) {
  const original = tidy(raw);
  if (!original) return '';

  const normalized = normalizeImageUrl(original);
  if (!needsResolution(original) && normalized === original) return original;

  const pageUrl = sharePageCandidate(original);
  try {
    const res = await fetch(pageUrl, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
        Accept: 'text/html,application/xhtml+xml',
      },
      signal: AbortSignal.timeout(RESOLVE_TIMEOUT_MS),
    });
    if (res.ok) {
      const html = await res.text();
      const og = html.match(OG_IMAGE_RE);
      const candidate = tidy(decodeHtmlEntities(og?.[1] || og?.[2] || ''));
      if (candidate && looksLikeDirectImage(candidate)) return candidate;

      const ibb = html.match(/https:\/\/i\.ibb\.co\/[^\s"'<>]+/);
      if (ibb?.[0]) return tidy(ibb[0]);
      const post = html.match(/https:\/\/i\.postimg\.cc\/[A-Za-z0-9]+\/image\.[a-zA-Z0-9]+/);
      if (post?.[0]) return tidy(post[0]);
    }
  } catch (err) {
    console.warn('resolveImageUrl failed:', pageUrl, err.message);
  }

  return normalized;
}

/**
 * Resolve every image URL inside a rich-content JSON string.
 * @param {string} content
 * @returns {Promise<string>}
 */
export async function resolveContentImageUrls(content) {
  const raw = String(content || '');
  if (!raw.trim()) return raw;
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return raw;
    const next = await Promise.all(
      parsed.map(async (block) => {
        if (!block || typeof block !== 'object') return block;
        if (block.type === 'image' && block.url) {
          return { ...block, url: await resolveImageUrl(block.url) };
        }
        return block;
      }),
    );
    return JSON.stringify(next);
  } catch {
    return raw;
  }
}

/**
 * Sync-normalize image URLs inside content JSON (no network).
 * @param {string} content
 * @returns {string}
 */
export function normalizeContentImageUrls(content) {
  const raw = String(content || '');
  if (!raw.trim()) return raw;
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return raw;
    const next = parsed.map((block) => {
      if (!block || typeof block !== 'object') return block;
      if (block.type === 'image' && block.url) {
        return { ...block, url: normalizeImageUrl(block.url) };
      }
      return block;
    });
    return JSON.stringify(next);
  } catch {
    return raw;
  }
}
