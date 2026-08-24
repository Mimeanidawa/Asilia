import { Router } from 'express';
import { getPool } from '../db.js';
import { publicApiBase } from '../utils/publicUrl.js';
import { toDisplayImageUrl } from '../utils/resolveImageUrl.js';

const router = Router();

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

router.get('/:id', async (req, res) => {
  const id = String(req.params.id || '').trim();
  if (!id) return res.status(400).send('Missing id');

  const apiBase = publicApiBase(req);
  const apiUrl = `${apiBase}/api/content/${encodeURIComponent(id)}`;

  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT id, title, excerpt, image_url
       FROM content_posts
       WHERE id = $1 AND is_published = TRUE`,
      [id],
    );

    if (!rows.length) {
      return res.status(404).send(`<!DOCTYPE html>
<html lang="sw"><head><meta charset="utf-8"><title>Makala haipatikani</title></head>
<body style="font-family:system-ui,sans-serif;padding:32px;text-align:center">
<h1>Makala haipatikani</h1>
<p>Kiungo hiki hakipo au bado hakijachapishwa.</p>
</body></html>`);
    }

    const row = rows[0];
    const title = row.title || 'Makala — Dawa Asili';
    const excerpt = row.excerpt || 'Soma makala kamili kwenye programu ya Dawa Asili.';
    let imageUrl = '';
    try {
      imageUrl = await toDisplayImageUrl(row.image_url, apiBase);
    } catch (_) {}

    const safeTitle = escapeHtml(title);
    const safeExcerpt = escapeHtml(excerpt);
    const safeImage = escapeHtml(imageUrl);

    res.setHeader('Cache-Control', 'public, max-age=120');
    res.send(`<!DOCTYPE html>
<html lang="sw">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${safeTitle}</title>
  <meta name="description" content="${safeExcerpt}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="${safeTitle}">
  <meta property="og:description" content="${safeExcerpt}">
  ${safeImage ? `<meta property="og:image" content="${safeImage}">` : ''}
  <meta property="og:url" content="${escapeHtml(`${apiBase}/makala/${id}`)}">
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; background: #f4faf6; color: #1a2e1f; }
    main { max-width: 520px; margin: 0 auto; padding: 32px 20px; }
    .card { background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 30px rgba(0,0,0,.08); }
    img { width: 100%; display: block; aspect-ratio: 16/9; object-fit: cover; background: #e8f5ec; }
    .body { padding: 20px; }
    h1 { font-size: 1.35rem; margin: 0 0 8px; line-height: 1.3; }
    p { margin: 0; color: #4b6354; line-height: 1.5; font-size: .95rem; }
    .cta { display: inline-block; margin-top: 18px; padding: 12px 18px; background: #166534; color: #fff; text-decoration: none; border-radius: 10px; font-weight: 700; }
    .hint { margin-top: 14px; font-size: .82rem; color: #6b7f72; }
  </style>
</head>
<body>
  <main>
    <div class="card">
      ${safeImage ? `<img src="${safeImage}" alt="${safeTitle}">` : ''}
      <div class="body">
        <h1>${safeTitle}</h1>
        <p>${safeExcerpt}</p>
        <a class="cta" href="${escapeHtml(apiUrl)}">Fungua makala</a>
        <p class="hint">Fungua programu ya Dawa Asili ili kusoma makala kamili.</p>
      </div>
    </div>
  </main>
</body>
</html>`);
  } catch (err) {
    console.error('GET /makala/:id:', err);
    res.status(500).send('Imeshindwa kupakia makala');
  }
});

export default router;
