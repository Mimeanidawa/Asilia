import { Router } from 'express';
import { getPool } from '../db.js';

const router = Router();

// GET /api/products - list all published products
router.get('/', async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM products WHERE is_published = TRUE ORDER BY created_at ASC`
    );
    const products = rows.map((r) => ({
      id: r.id,
      title: r.title,
      subtitle: r.subtitle,
      description: r.description,
      price: r.price,
      original_price: r.original_price,
      discount_percent: r.discount_percent,
      image_url: r.image_url,
      badge_text: r.badge_text,
      stock_quantity: r.stock_quantity,
      category: r.category,
      targetKeywords: r.target_keywords || '',
      target_keywords: r.target_keywords || '',
      benefits: Array.isArray(r.benefits) ? r.benefits : JSON.parse(r.benefits || '[]'),
      how_to_use: r.how_to_use,
      is_published: r.is_published,
      created_at: r.created_at,
    }));
    res.json({ products });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// GET /api/products/:id - single product
router.get('/:id', async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM products WHERE id = $1`,
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    const r = rows[0];
    const product = {
      id: r.id,
      title: r.title,
      subtitle: r.subtitle,
      description: r.description,
      price: r.price,
      original_price: r.original_price,
      discount_percent: r.discount_percent,
      image_url: r.image_url,
      badge_text: r.badge_text,
      stock_quantity: r.stock_quantity,
      category: r.category,
      targetKeywords: r.target_keywords || '',
      target_keywords: r.target_keywords || '',
      benefits: Array.isArray(r.benefits) ? r.benefits : JSON.parse(r.benefits || '[]'),
      how_to_use: r.how_to_use,
      is_published: r.is_published,
      created_at: r.created_at,
    };
    res.json({ product });
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

export default router;
