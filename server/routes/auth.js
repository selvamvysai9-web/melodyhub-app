const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Song = require('../models/Song');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');
const axios = require('axios');

// Register new user
router.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Username, email and password are required' });
    }

    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const user = new User({ username, email, password });
    await user.save();

    const token = require('jsonwebtoken').sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'your-secret-key-change-in-production',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        role: user.role,
        isPremium: user.isPremium
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error during registration' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isMatch = await require('bcryptjs').compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update premium status if needed
    if (user.isPremium) {
      await user.updatePremiumStatus();
    }

    const token = require('jsonwebtoken').sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'your-secret-key-change-in-production',
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        role: user.role,
        isPremium: user.isPremium,
        premiumExpiry: user.premiumExpiry
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error during login' });
  }
});

// Get current user profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    res.json({
      user: {
        id: req.user._id,
        username: req.user.username,
        email: req.user.email,
        role: req.user.role,
        isPremium: req.user.isPremiumActive(),
        premiumExpiry: req.user.premiumExpiry,
        createdAt: req.user.createdAt
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Upgrade to premium (simulate payment)
router.post('/upgrade-premium', authMiddleware, async (req, res) => {
  try {
    const { durationMonths } = req.body;
    const months = durationMonths || 1;
    
    const now = new Date();
    const expiryDate = req.user.premiumExpiry && req.user.premiumExpiry > now
      ? new Date(req.user.premiumExpiry.setMonth(req.user.premiumExpiry.getMonth() + months))
      : new Date(now.setMonth(now.getMonth() + months));

    req.user.isPremium = true;
    req.user.premiumExpiry = expiryDate;
    req.user.role = 'premium';
    
    await req.user.save();

    res.json({
      message: 'Successfully upgraded to Premium',
      premiumExpiry: req.user.premiumExpiry,
      isPremium: true
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to upgrade premium' });
  }
});

// Admin: Get all users
router.get('/admin/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    res.json({ users });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Admin: Update user role
router.put('/admin/users/:userId/role', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { role } = req.body;
    const user = await User.findById(req.params.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (!['user', 'admin', 'premium'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    user.role = role;
    if (role === 'premium') {
      user.isPremium = true;
      user.premiumExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
    }
    
    await user.save();

    res.json({ message: 'User role updated', user: { id: user._id, username: user.username, role: user.role } });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update user role' });
  }
});

// Admin: Create initial admin user (only if no admin exists)
router.post('/admin/init', async (req, res) => {
  try {
    const adminCount = await User.countDocuments({ role: 'admin' });
    
    if (adminCount > 0) {
      return res.status(400).json({ error: 'Admin user already exists' });
    }

    const { username, email, password } = req.body;
    
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Username, email and password are required' });
    }

    const admin = new User({ username, email, password, role: 'admin' });
    await admin.save();

    res.status(201).json({ message: 'Admin user created successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create admin user' });
  }
});

module.exports = router;
