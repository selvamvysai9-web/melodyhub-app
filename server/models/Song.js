const mongoose = require('mongoose');

const songSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  artist: {
    type: String,
    default: 'Unknown Artist'
  },
  youtubeId: {
    type: String,
    required: true,
    unique: true
  },
  thumbnail: {
    type: String,
    default: ''
  },
  duration: {
    type: String,
    default: '0:00'
  },
  lyrics: {
    type: String,
    default: ''
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  playCount: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt timestamp before saving
songSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Song', songSchema);
