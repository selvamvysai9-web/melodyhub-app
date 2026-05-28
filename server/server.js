const express = require('express');
const cors = require('cors');
const axios = require('axios');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY;
const MONGODB_URI = process.env.MONGODB_URI;

// Connect to MongoDB only if URI is provided
let mongoConnected = false;
if (MONGODB_URI && MONGODB_URI !== 'mongodb://localhost:27017/melody-hub') {
  mongoose.connect(MONGODB_URI)
    .then(() => {
      console.log('✅ MongoDB connected');
      mongoConnected = true;
    })
    .catch(err => console.error('❌ MongoDB connection error:', err));
} else {
  console.warn('⚠️  MONGODB_URI not configured. Database features disabled.');
}

if (!YOUTUBE_API_KEY) {
  console.warn('⚠️  YOUTUBE_API_KEY not found. YouTube Data API v3 search will not work.');
}

// Import routes
const authRoutes = require('./routes/auth');
const songRoutes = require('./routes/songs');

// CORS configuration
const corsOrigins = process.env.CORS_ORIGINS 
  ? process.env.CORS_ORIGINS.split(',') 
  : ['http://localhost:3000', 'http://localhost:8080'];

app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    if (corsOrigins.indexOf(origin) !== -1 || origin.includes('onrender.com') || origin.includes('flutter.dev')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));

app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    database: mongoConnected ? 'connected' : 'not-configured',
    youtubeApi: YOUTUBE_API_KEY ? 'configured' : 'not-configured'
  });
});

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/songs', songRoutes);

// YouTube search endpoint using YouTube Data API v3
app.get('/api/youtube/search', async (req, res) => {
  try {
    const query = req.query.q;
    
    if (!query) {
      return res.status(400).json({ error: 'Search query is required' });
    }

    // If no API key, fallback to scraping method
    if (!YOUTUBE_API_KEY) {
      console.log('No API key, using fallback search method');
      return await fallbackSearch(req, res, query);
    }

    // Use YouTube Data API v3
    const searchUrl = 'https://www.googleapis.com/youtube/v3/search';
    const params = new URLSearchParams({
      part: 'snippet',
      q: query,
      type: 'video',
      maxResults: '15',
      key: YOUTUBE_API_KEY
    });

    const response = await axios.get(`${searchUrl}?${params.toString()}`);
    
    const results = response.data.items.map(item => ({
      videoId: item.id.videoId,
      title: item.snippet.title,
      channelTitle: item.snippet.channelTitle,
      thumbnail: item.snippet.thumbnails?.high?.url || item.snippet.thumbnails?.default?.url,
      description: item.snippet.description,
      publishedAt: item.snippet.publishedAt
    }));

    res.json({ results });
  } catch (error) {
    console.error('Search error:', error.message);
    
    // Fallback to scraping if API fails
    if (error.response?.status === 403 || error.response?.status === 400) {
      console.log('API error, trying fallback method');
      return await fallbackSearch(req, res, req.query.q);
    }
    
    res.status(500).json({ 
      error: 'Failed to search YouTube',
      message: error.message 
    });
  }
});

// Fallback search method using scraping
async function fallbackSearch(req, res, query) {
  try {
    const searchUrl = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}`;
    
    const response = await axios.get(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });

    const results = [];
    const regex = /"videoId":"([^"]+)".*?"title":"([^"]+)".*?"channelTitle":"([^"]+)"/g;
    let match;
    let count = 0;
    
    while ((match = regex.exec(response.data)) && count < 15) {
      const [_, videoId, title, channelTitle] = match;
      
      const decodedTitle = title.replace(/&quot;/g, '"').replace(/&amp;/g, '&').replace(/&#39;/g, "'").replace(/\\u0026/g, '&');
      
      results.push({
        videoId,
        title: decodedTitle,
        channelTitle: channelTitle || 'Unknown',
        thumbnail: `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`
      });
      count++;
    }

    if (results.length === 0) {
      return res.json({
        results: [
          {
            videoId: 'dQw4w9WgXcQ',
            title: 'Rick Astley - Never Gonna Give You Up',
            channelTitle: 'Rick Astley',
            thumbnail: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg'
          }
        ]
      });
    }

    res.json({ results });
  } catch (error) {
    console.error('Fallback search error:', error.message);
    res.status(500).json({ 
      error: 'Failed to search YouTube',
      message: error.message 
    });
  }
}

// Get audio stream URL for a YouTube video using Cobalt API (v9) with fallbacks
app.get('/api/youtube/audio/:id', async (req, res) => {
  try {
    const videoId = req.params.id;
    
    if (!videoId) {
      return res.status(400).json({ error: 'Video ID is required' });
    }

    // Try multiple Cobalt endpoints
    const cobaltEndpoints = [
      'https://co.wuk.sh/api/json',
      'https://cobalt.tools/api/json',
      'https://api.cobalt.tools/api/json'
    ];
    
    let audioData = null;
    let lastError = null;
    
    for (const endpoint of cobaltEndpoints) {
      try {
        console.log(`Trying Cobalt endpoint: ${endpoint}`);
        
        const response = await axios.post(endpoint, {
          url: `https://www.youtube.com/watch?v=${videoId}`,
          vCodec: 'opus',
          vQuality: '128',
          isAudioOnly: true,
          filenamePattern: 'melody_hub_{title}'
        }, {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          timeout: 10000
        });

        if (response.data && response.data.url) {
          audioData = response.data;
          break;
        }
      } catch (err) {
        lastError = err;
        console.log(`Endpoint ${endpoint} failed: ${err.message}`);
        continue;
      }
    }

    if (!audioData || !audioData.url) {
      // Fallback: Return YouTube video info and let client handle extraction
      console.log('All Cobalt endpoints failed, returning video info for client-side extraction');
      
      let title = 'Unknown';
      let author = 'Unknown';
      let thumbnail = `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`;

      try {
        const infoResponse = await axios.get(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`);
        if (infoResponse.data) {
          title = infoResponse.data.title || 'Unknown';
          author = infoResponse.data.author_name || 'Unknown';
        }
      } catch (e) {
        console.log('Could not fetch video metadata');
      }

      return res.json({
        success: true,
        videoId,
        title,
        author,
        duration: 0,
        thumbnail,
        audioUrl: null,
        fallback: true,
        message: 'Use client-side extraction (youtube_explode_dart)',
        format: {
          mimeType: 'audio/mp4',
          bitrate: 128,
          quality: 'medium'
        }
      });
    }

    // Get video info for metadata
    let title = 'Unknown';
    let author = 'Unknown';
    let duration = 0;
    let thumbnail = '';

    try {
      const infoResponse = await axios.get(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`);
      if (infoResponse.data) {
        title = infoResponse.data.title || 'Unknown';
        author = infoResponse.data.author_name || 'Unknown';
      }
      
      // Get thumbnail
      thumbnail = `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`;
    } catch (e) {
      console.log('Could not fetch video metadata');
    }

    // Return the audio URL and metadata
    res.json({
      success: true,
      videoId,
      title,
      author,
      duration,
      thumbnail,
      audioUrl: audioData.url,
      format: {
        mimeType: 'audio/opus',
        bitrate: 128,
        quality: 'medium'
      }
    });
  } catch (error) {
    console.error('Audio extraction error:', error.message);
    
    if (error.response) {
      return res.status(error.response.status).json({ 
        error: 'Failed to extract audio',
        message: error.response.data?.text || error.message 
      });
    }

    res.status(500).json({ 
      error: 'Failed to extract audio',
      message: error.message 
    });
  }
});

// Stream audio directly (proxy) - Redirect to Cobalt v9 with fallbacks
app.get('/api/youtube/stream/:id', async (req, res) => {
  try {
    const videoId = req.params.id;
    
    if (!videoId) {
      return res.status(400).json({ error: 'Video ID is required' });
    }

    // Try multiple Cobalt endpoints
    const cobaltEndpoints = [
      'https://co.wuk.sh/api/json',
      'https://cobalt.tools/api/json',
      'https://api.cobalt.tools/api/json'
    ];
    
    let streamUrl = null;
    
    for (const endpoint of cobaltEndpoints) {
      try {
        console.log(`Trying Cobalt endpoint for stream: ${endpoint}`);
        
        const response = await axios.post(endpoint, {
          url: `https://www.youtube.com/watch?v=${videoId}`,
          vCodec: 'opus',
          vQuality: '128',
          isAudioOnly: true
        }, {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          timeout: 10000
        });

        if (response.data && response.data.url) {
          streamUrl = response.data.url;
          break;
        }
      } catch (err) {
        console.log(`Stream endpoint ${endpoint} failed: ${err.message}`);
        continue;
      }
    }

    if (!streamUrl) {
      // Fallback: Return JSON with video info instead of redirect
      console.log('All Cobalt stream endpoints failed, returning video info');
      
      let title = 'Unknown';
      let author = 'Unknown';
      
      try {
        const infoResponse = await axios.get(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`);
        if (infoResponse.data) {
          title = infoResponse.data.title || 'Unknown';
          author = infoResponse.data.author_name || 'Unknown';
        }
      } catch (e) {
        console.log('Could not fetch video metadata');
      }
      
      return res.json({
        success: true,
        videoId,
        title,
        author,
        thumbnail: `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`,
        streamUrl: null,
        fallback: true,
        message: 'Use client-side extraction (youtube_explode_dart)'
      });
    }

    // Redirect to the Cobalt stream URL
    res.redirect(streamUrl);
  } catch (error) {
    console.error('Stream setup error:', error.message);
    res.status(500).json({ 
      error: 'Failed to setup stream',
      message: error.message 
    });
  }
});

// Get song details using oEmbed
app.get('/api/youtube/info/:id', async (req, res) => {
  try {
    const videoId = req.params.id;
    
    if (!videoId) {
      return res.status(400).json({ error: 'Video ID is required' });
    }

    try {
      const infoResponse = await axios.get(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`);
      
      res.json({
        success: true,
        videoId,
        title: infoResponse.data.title || 'Unknown',
        author: infoResponse.data.author_name || 'Unknown',
        description: '',
        duration: 0,
        viewCount: 0,
        publishDate: '',
        thumbnails: [
          { url: `https://img.youtube.com/vi/${videoId}/default.jpg`, width: 120, height: 90 },
          { url: `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`, width: 320, height: 180 },
          { url: `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`, width: 480, height: 360 },
          { url: `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`, width: 1280, height: 720 }
        ],
        keywords: []
      });
    } catch (e) {
      // Fallback to basic info
      res.json({
        success: true,
        videoId,
        title: 'Unknown',
        author: 'Unknown',
        description: '',
        duration: 0,
        viewCount: 0,
        publishDate: '',
        thumbnails: [
          { url: `https://img.youtube.com/vi/${videoId}/default.jpg`, width: 120, height: 90 },
          { url: `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`, width: 1280, height: 720 }
        ],
        keywords: []
      });
    }
  } catch (error) {
    console.error('Info fetch error:', error.message);
    res.status(500).json({ 
      error: 'Failed to fetch video info',
      message: error.message 
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Not found',
    path: req.path
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🎵 Melody Hub Backend running on port ${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/api/health`);
  console.log(`   Search: http://localhost:${PORT}/api/youtube/search?q=test`);
  console.log(`   Audio:  http://localhost:${PORT}/api/youtube/audio/{videoId}`);
});

module.exports = app;
