/**
 * Normalize / resolve share-page image URLs (ImgBB, Postimages)
 * into direct CDN URLs that mobile clients can load.
 */

const OG_IMAGE_RE =
  /(?:property|name)=["']og:image["'][^>]*content=["']([^"']+)["']|content=["']([^"']+)["'][^>]*(?:property|name)=["']og:image["']/i;

function tidy(raw) {
  let url = String(raw || '').trim();
  if (url.startsWith('//')) url = `https:${url}`;
  return url;
}

function looksLikeBlockedPostimgPath(pathname) {
  const name = pathname.split('/').filter(Boolean).pop()?.toLowerCase() || '';
  return name.startsWith('file-00000000') || /^file-[0-9a-f]{20,}/.test(name);
}

/** Sync rewrite: i.postimg.cc/CODE/file-....png -> .../CODE/image.png */
export function normalizeImageUrl(raw) {
  const url = tidy(raw);
  if (!url) return '';
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\./, '').toLowerCase();
    if (host === 'i.postimg.cc' && looksLikeBlockedPostimgPath(u.pathname)) {
      const parts = u.pathname.split('/').filter(Boolean);
      if (parts.length >= 2) {
        const ext = parts[parts.length - 1].includes('.')
          ? parts[parts.length - 1].split('.').pop()
          : 'png';
        return `${u.protocol}//${u.host}/${parts[0]}/image.${ext}`;
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
    if (host === 'i.postimg.cc' && looksLikeBlockedPostimgPath(u.pathname)) return true;
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
    return /\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$/i.test(u.pathname);
  } catch {
    return false;
  }
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
      signal: AbortSignal.timeout(12000),
    });
    if (res.ok) {
      const html = await res.text();
      const og = html.match(OG_IMAGE_RE);
      const candidate = tidy(og?.[1] || og?.[2] || '');
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
