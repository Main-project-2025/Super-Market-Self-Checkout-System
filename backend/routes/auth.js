const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDatabase } = require('../database/init');

const router = express.Router();
const db = getDatabase();

// Register endpoint
router.post('/register', async (req, res) => {
  try {
    const { email, password, name, first_name, last_name } = req.body;

    // Validation
    if (!email || !password || (!name && !first_name)) {
      return res.status(400).json({ error: 'Email, password, and name are required' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Check if user already exists
    const existingUser = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM users WHERE email = ?', [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (existingUser) {
      return res.status(400).json({ error: 'User already exists with this email' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user (default role is 'customer')
    const displayName = name || `${first_name} ${last_name}`.trim();
    const userId = await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO users (email, password, name, first_name, last_name, role) VALUES (?, ?, ?, ?, ?, ?)',
        [email, hashedPassword, displayName, first_name || '', last_name || '', 'customer'],
        function (err) {
          if (err) {
            console.error('Database insert error:', err);
            reject(err);
          } else {
            console.log(`✅ User created successfully with ID: ${this.lastID}`);
            resolve(this.lastID);
          }
        }
      );
    });

    // Generate JWT token (new users are always 'customer' role)
    const token = jwt.sign(
      { userId, email, role: 'customer' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    console.log(`✅ Registration successful for user: ${email} (ID: ${userId})`);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: userId,
        email,
        name: displayName,
        first_name: first_name || '',
        last_name: last_name || '',
        role: 'customer'
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const user = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id, email, password, name, first_name, last_name, role FROM users WHERE email = ?',
        [email],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role || 'customer' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name || `${user.first_name} ${user.last_name}`.trim(),
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role || 'customer'
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Staff Management Endpoints (Admin only)
router.get('/staff', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const staff = await new Promise((resolve, reject) => {
      db.all(
        'SELECT id, email, name, first_name, last_name, role FROM users WHERE role = "staff"',
        [],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });
    res.json({ success: true, data: staff });
  } catch (error) {
    console.error('Fetch staff error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/staff', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { email, password, first_name, last_name } = req.body;

    if (!email || !password || !first_name || !last_name) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const displayName = `${first_name} ${last_name}`.trim();

    const result = await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO users (email, password, name, first_name, last_name, role) VALUES (?, ?, ?, ?, ?, ?)',
        [email, hashedPassword, displayName, first_name, last_name, 'staff'],
        function (err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    res.status(201).json({
      success: true,
      data: {
        id: result,
        email,
        name: displayName,
        first_name,
        last_name,
        role: 'staff'
      }
    });
  } catch (error) {
    if (error.message.includes('UNIQUE constraint failed')) {
      return res.status(400).json({ error: 'Staff with this email already exists' });
    }
    console.error('Create staff error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/staff/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    await new Promise((resolve, reject) => {
      db.run('DELETE FROM users WHERE id = ? AND role = "staff"', [id], function (err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
    res.json({ success: true, message: 'Staff deleted successfully' });
  } catch (error) {
    console.error('Delete staff error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Verify token endpoint
router.get('/verify', authenticateToken, async (req, res) => {
  try {
    // Get user role from database
    const user = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id, email, name, first_name, last_name, role FROM users WHERE id = ?',
        [req.user.userId],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      valid: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name || `${user.first_name} ${user.last_name}`.trim(),
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role || 'customer'
      }
    });
  } catch (error) {
    console.error('Verify token error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Middleware to authenticate JWT token
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

// Middleware to check if user is admin
function requireAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }

  next();
}

// Export middleware for use in other routes
module.exports = router;
module.exports.authenticateToken = authenticateToken;
module.exports.requireAdmin = requireAdmin;

