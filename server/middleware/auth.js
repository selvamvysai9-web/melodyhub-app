const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key-change-in-production');
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    // Check if premium has expired and update status
    if (user.isPremium) {
      await user.updatePremiumStatus();
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

const adminMiddleware = async (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

const premiumMiddleware = async (req, res, next) => {
  if (!req.user.isPremiumActive() && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Premium subscription required' });
  }
  next();
};

module.exports = { authMiddleware, adminMiddleware, premiumMiddleware };
