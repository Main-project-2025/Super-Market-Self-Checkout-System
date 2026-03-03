const express = require('express');
const fs = require('fs');
const path = require('path');
const { getDatabase } = require('../database/init');
const { authenticateToken, requireAdmin } = require('./auth');

const router = express.Router();
const db = getDatabase();

// Get all products
router.get('/', async (req, res) => {
  try {
    const products = await new Promise((resolve, reject) => {
      db.all(
        'SELECT id, name, price, barcode, description, category, stock_quantity, image_url FROM products WHERE is_active = 1 ORDER BY name',
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: products,
      count: products.length
    });

  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get product by barcode
router.get('/barcode/:barcode', async (req, res) => {
  try {
    const { barcode } = req.params;

    const product = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id, name, price, barcode, description, category, stock_quantity, image_url FROM products WHERE barcode = ? AND is_active = 1',
        [barcode],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found',
        barcode: barcode
      });
    }

    res.json({
      success: true,
      data: product
    });

  } catch (error) {
    console.error('Get product by barcode error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get product by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const product = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id, name, price, barcode, description, category, stock_quantity, image_url FROM products WHERE id = ? AND is_active = 1',
        [id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    res.json({
      success: true,
      data: product
    });

  } catch (error) {
    console.error('Get product by ID error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create new product (Admin only)
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { name, price, barcode, description, category, stock_quantity, image_url } = req.body;

    // Validation
    if (!name || !price || !barcode) {
      return res.status(400).json({ error: 'Name, price, and barcode are required' });
    }

    if (price <= 0) {
      return res.status(400).json({ error: 'Price must be greater than 0' });
    }

    // Check if barcode already exists
    const existingProduct = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM products WHERE barcode = ?', [barcode], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (existingProduct) {
      return res.status(400).json({ error: 'Product with this barcode already exists' });
    }

    // Generate unique ID
    const { v4: uuidv4 } = require('uuid');
    const productId = uuidv4();

    // Insert product
    await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO products (id, name, price, barcode, description, category, stock_quantity, image_url) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [productId, name, price, barcode, description || null, category || null, stock_quantity || 0, image_url || null],
        function (err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: {
        id: productId,
        name,
        price,
        barcode,
        description,
        category,
        stock_quantity: stock_quantity || 0,
        image_url
      }
    });

  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update product (Admin only)
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, price, barcode, description, category, stock_quantity, image_url } = req.body;

    // Check if product exists
    const existingProduct = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM products WHERE id = ?', [id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!existingProduct) {
      return res.status(404).json({ error: 'Product not found' });
    }

    // Update product
    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE products SET 
         name = COALESCE(?, name),
         price = COALESCE(?, price),
         barcode = COALESCE(?, barcode),
         description = COALESCE(?, description),
         category = COALESCE(?, category),
         stock_quantity = COALESCE(?, stock_quantity),
         image_url = COALESCE(?, image_url),
         updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [name, price, barcode, description, category, stock_quantity, image_url, id],
        function (err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    res.json({
      success: true,
      message: 'Product updated successfully'
    });

  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete product (Admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Soft delete - set is_active to 0
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE products SET is_active = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        [id],
        function (err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });

  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get products by category
router.get('/category/:category', async (req, res) => {
  try {
    const { category } = req.params;

    const products = await new Promise((resolve, reject) => {
      db.all(
        'SELECT id, name, price, barcode, description, category, stock_quantity, image_url FROM products WHERE category = ? AND is_active = 1 ORDER BY name',
        [category],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: products,
      count: products.length,
      category: category
    });

  } catch (error) {
    console.error('Get products by category error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get pricing suggestion for a product (Admin only)
// Helper to get pricing suggestion
const { exec } = require('child_process');
const PYTHON_BIN = 'python3';

// Category-level fallback multipliers (used if ML script cannot run)
const DEFAULT_MULTIPLIERS = {
  'Dairy': 0.98,
  'Dairy Alternatives': 0.97,
  'Produce': 1.05,
  'Meat': 1.10,
  'Bakery': 1.02,
  'Snacks': 1.03,
  'Beverages': 1.01,
};

// Run the ML script and wait for it to produce results
function runDynamicPricingScript(dbPath, analyticsDir) {
  return new Promise((resolve) => {
    const scriptPath = path.join(analyticsDir, 'dynamic_pricing.py');
    const cmd = `${PYTHON_BIN} "${scriptPath}" --use-db --db-path "${dbPath}"`;
    exec(cmd, { timeout: 60000 }, (err) => {
      // Resolve regardless — we check file existence after
      resolve(!err);
    });
  });
}

async function getPricingSuggestion(id) {
  const analyticsDir = path.join(__dirname, '..', 'analytics');
  const dbPath = process.env.DATABASE_PATH || path.join(__dirname, '..', 'database', 'checkout.db');
  const resultsPath = path.join(analyticsDir, 'dynamic_pricing_results.csv');
  const metricsPath = path.join(analyticsDir, 'model_metrics.json');

  // Auto-generate results if not available yet
  if (!fs.existsSync(resultsPath) || !fs.existsSync(metricsPath)) {
    console.log('[products] Pricing results not found — running dynamic_pricing.py...');
    await runDynamicPricingScript(dbPath, analyticsDir);
  }

  // Get product from DB
  const dbProduct = await new Promise((resolve) => {
    db.get('SELECT * FROM products WHERE id = ?', [id], (err, row) => resolve(row));
  });

  if (!dbProduct) return null;

  // Read metrics (if available)
  let confidence = 0;
  let metricsData = {};
  if (fs.existsSync(metricsPath)) {
    try {
      metricsData = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
      confidence = metricsData.r2_score || 0;
    } catch (err) {
      console.warn('Failed to read model metrics:', err);
    }
  }

  // Try to find product in CSV
  let suggestion = null;
  if (fs.existsSync(resultsPath)) {
    const csvContent = fs.readFileSync(resultsPath, 'utf8');
    const lines = csvContent.split('\n').filter(line => line.trim());

    if (lines.length >= 2) {
      const headers = lines[0].split(',').map(h => h.trim().replace(/^"|"$/g, ''));
      const productIdIdx = headers.indexOf('Product_ID');
      const predictedIdx = headers.indexOf('Predicted_Price');

      if (productIdIdx !== -1 && predictedIdx !== -1) {
        for (let i = 1; i < lines.length; i++) {
          const row = [];
          let current = '', inQuotes = false;
          for (const char of lines[i]) {
            if (char === '"') inQuotes = !inQuotes;
            else if (char === ',' && !inQuotes) { row.push(current.trim()); current = ''; }
            else current += char;
          }
          row.push(current.trim());

          if (row[productIdIdx]?.replace(/^"|"$/g, '') === id) {
            const predictedPrice = parseFloat(row[predictedIdx]?.replace(/^"|"$/g, ''));
            if (!isNaN(predictedPrice)) {
              suggestion = {
                current_price: dbProduct.price,
                suggested_price: predictedPrice,
                confidence: confidence,
              };
            }
            break;
          }
        }
      }
    }
  }

  // Fallback: use category multipliers
  if (!suggestion) {
    const categoryMult = (metricsData.category_multipliers && metricsData.category_multipliers[dbProduct.category])
      || DEFAULT_MULTIPLIERS[dbProduct.category]
      || 1.0;

    suggestion = {
      current_price: dbProduct.price,
      suggested_price: parseFloat((dbProduct.price * categoryMult).toFixed(2)),
      confidence: (confidence || 0) * 0.5,
      is_fallback: true,
      details: `Category-based estimate for: ${dbProduct.category || 'Unknown'}`,
    };
  }

  suggestion.current_price = dbProduct.price;
  return suggestion;
}


// Get pricing suggestion endpoint
router.get('/:id/pricing-suggestion', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const suggestion = await getPricingSuggestion(req.params.id);

    if (!suggestion) {
      return res.status(404).json({ error: 'Product not found or suggestion unavailable' });
    }

    res.json({ success: true, data: suggestion });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Apply pricing suggestion endpoint
router.post('/:id/apply-pricing', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const suggestion = await getPricingSuggestion(req.params.id);

    if (!suggestion) {
      return res.status(404).json({ error: 'Pricing suggestion unavailable' });
    }

    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE products SET price = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        [suggestion.suggested_price, req.params.id],
        function (err) {
          if (err) reject(err);
          else resolve(this.changes);
        }
      );
    });

    res.json({
      success: true,
      message: 'Price updated successfully',
      new_price: suggestion.suggested_price
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
