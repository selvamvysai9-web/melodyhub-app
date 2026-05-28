const express = require('express');
const router = express.Router();
const Song = require('../models/Song');
const User = require('../models/User');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');
const axios = require('axios');

// Get all songs (public)
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const query = search ? { 
      $or: [
        { title: { $regex: search, $options: 'i' } },
        { artist: { $regex: search, $options: 'i' } }
      ]
    } : {};
    
    const songs = await Song.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    const count = await Song.countDocuments(query);
    
    res.json({
      songs,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      total: count
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch songs' });
  }
});

// Get single song by ID
router.get('/:id', async (req, res) => {
  try {
    const song = await Song.findById(req.params.id);
    if (!song) {
      return res.status(404).json({ error: 'Song not found' });
    }
    
    // Increment play count
    song.playCount += 1;
    await song.save();
    
    res.json({ song });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch song' });
  }
});

// Admin: Upload new song
router.post('/', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { title, artist, youtubeId, thumbnail, duration, lyrics, isPremium } = req.body;
    
    if (!title || !youtubeId) {
      return res.status(400).json({ error: 'Title and YouTube ID are required' });
    }

    // Check if song already exists
    const existingSong = await Song.findOne({ youtubeId });
    if (existingSong) {
      return res.status(400).json({ error: 'Song with this YouTube ID already exists' });
    }

    // Fetch additional info from YouTube if not provided
    let finalThumbnail = thumbnail || '';
    let finalDuration = duration || '0:00';
    
    if (!finalThumbnail || !finalDuration) {
      try {
        const response = await axios.get(
          `https://www.googleapis.com/youtube/v3/videos`,
          {
            params: {
              part: 'snippet,contentDetails',
              id: youtubeId,
              key: process.env.YOUTUBE_API_KEY
            }
          }
        );
        
        if (response.data.items && response.data.items.length > 0) {
          const item = response.data.items[0];
          if (!finalThumbnail) {
            finalThumbnail = item.snippet.thumbnails?.high?.url || item.snippet.thumbnails?.default?.url || '';
          }
          if (!finalDuration) {
            finalDuration = item.contentDetails?.duration || '0:00';
          }
          if (!artist) {
            artist = item.snippet.channelTitle || 'Unknown Artist';
          }
        }
      } catch (err) {
        console.log('Could not fetch YouTube details, using provided values');
      }
    }

    const song = new Song({
      title,
      artist,
      youtubeId,
      thumbnail: finalThumbnail,
      duration: finalDuration,
      lyrics: lyrics || '',
      uploadedBy: req.user._id,
      isPremium: isPremium || false
    });
    
    await song.save();
    
    res.status(201).json({ message: 'Song uploaded successfully', song });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Failed to upload song' });
  }
});

// Admin: Update song (title, lyrics, etc.)
router.put('/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { title, artist, lyrics, isPremium } = req.body;
    const song = await Song.findById(req.params.id);
    
    if (!song) {
      return res.status(404).json({ error: 'Song not found' });
    }

    if (title) song.title = title;
    if (artist) song.artist = artist;
    if (lyrics !== undefined) song.lyrics = lyrics;
    if (isPremium !== undefined) song.isPremium = isPremium;
    
    await song.save();
    
    res.json({ message: 'Song updated successfully', song });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update song' });
  }
});

// Admin: Delete song
router.delete('/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const song = await Song.findByIdAndDelete(req.params.id);
    
    if (!song) {
      return res.status(404).json({ error: 'Song not found' });
    }
    
    res.json({ message: 'Song deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete song' });
  }
});

// Admin: Get all songs with details
router.get('/admin/all', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const songs = await Song.find()
      .populate('uploadedBy', 'username email')
      .sort({ createdAt: -1 });
    
    res.json({ songs });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch songs' });
  }
});

module.exports = router;
