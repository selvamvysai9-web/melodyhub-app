const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'premium'],
    default: 'user'
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  premiumExpiry: {
    type: Date,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Method to check if premium is active
userSchema.methods.isPremiumActive = function() {
  if (!this.isPremium || !this.premiumExpiry) return false;
  return new Date() < this.premiumExpiry;
};

// Method to update premium status
userSchema.methods.updatePremiumStatus = async function() {
  const isActive = this.isPremiumActive();
  if (!isActive) {
    this.isPremium = false;
    this.role = this.role === 'admin' ? 'admin' : 'user';
  }
  return this.save();
};

module.exports = mongoose.model('User', userSchema);
