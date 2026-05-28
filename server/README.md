# Melody Hub Backend

A complete backend server for the Melody Hub music streaming app with admin panel, user authentication, premium subscriptions, and YouTube integration.

## ✨ Features

### 🔐 Authentication & User Management
- User registration and login with JWT tokens
- Password hashing with bcrypt
- Three user roles: `user`, `premium`, `admin`
- Automatic premium expiry tracking
- Auto-downgrade when subscription expires

### 💎 Premium Subscription
- Monthly subscription plans
- Automatic status verification on each request
- Premium-only content support
- Instant role updates

### 🎵 Song Management (Admin Only)
- Upload songs with YouTube ID
- Edit song metadata (title, artist, lyrics)
- Delete songs
- Mark songs as premium-only
- View upload history

### 🎶 YouTube Integration
- Search using YouTube Data API v3
- Audio extraction via Cobalt API
- Direct streaming support
- Video metadata retrieval

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment Variables
Create/edit `.env`:
```env
YOUTUBE_API_KEY=your-youtube-api-key
PORT=3000
CORS_ORIGINS=http://localhost:8080,https://your-app.com
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/melody-hub
JWT_SECRET=your-secret-key-min-32-chars
```

### 3. Start Server
```bash
node server.js
```

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | ❌ | Register new user |
| POST | `/api/auth/login` | ❌ | Login user |
| GET | `/api/auth/profile` | ✅ | Get current user profile |
| POST | `/api/auth/upgrade-premium` | ✅ | Upgrade to premium |

### Admin - User Management
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/admin/init` | ❌ | Create first admin |
| GET | `/api/auth/admin/users` | ✅ Admin | Get all users |
| PUT | `/api/auth/admin/users/:id/role` | ✅ Admin | Update user role |

### Songs
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/songs` | ❌ | Get all songs (public) |
| GET | `/api/songs/:id` | ❌ | Get single song |
| POST | `/api/songs` | ✅ Admin | Upload new song |
| PUT | `/api/songs/:id` | ✅ Admin | Update song |
| DELETE | `/api/songs/:id` | ✅ Admin | Delete song |
| GET | `/api/songs/admin/all` | ✅ Admin | Get all songs with details |

### YouTube
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/youtube/search?q=query` | ❌ | Search YouTube |
| GET | `/api/youtube/audio/:id` | ❌ | Get audio URL |
| GET | `/api/youtube/stream/:id` | ❌ | Stream audio |
| GET | `/api/youtube/info/:id` | ❌ | Get video info |

## 📝 Usage Examples

### Create First Admin
```bash
curl -X POST http://localhost:3000/api/auth/admin/init \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","email":"admin@melodyhub.com","password":"admin123"}'
```

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@example.com","password":"password123"}'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

Response includes JWT token - use it for authenticated requests:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "username": "john",
    "email": "john@example.com",
    "role": "user",
    "isPremium": false
  }
}
```

### Upgrade to Premium
```bash
curl -X POST http://localhost:3000/api/auth/upgrade-premium \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"durationMonths": 1}'
```

### Upload Song (Admin)
```bash
curl -X POST http://localhost:3000/api/songs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{
    "title": "Bohemian Rhapsody",
    "artist": "Queen",
    "youtubeId": "fJ9rUzIMcZQ",
    "lyrics": "Is this the real life?...",
    "isPremium": false
  }'
```

### Update Song Lyrics (Admin)
```bash
curl -X PUT http://localhost:3000/api/songs/SONG_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{"lyrics": "Updated lyrics..."}'
```

### Search YouTube
```bash
curl "http://localhost:3000/api/youtube/search?q=queen"
```

## 🗄️ Database Setup

### MongoDB Atlas (Recommended)
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create free cluster
3. Get connection string
4. Replace `<password>` in connection string
5. Add to `.env`:
   ```
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/melody-hub
   ```

### Local MongoDB
```bash
# Install MongoDB locally
# Then set in .env:
MONGODB_URI=mongodb://localhost:27017/melody-hub
```

## 🌐 Deploy to Render

1. Push code to GitHub
2. Connect repo in Render dashboard
3. Add environment variables:
   - `YOUTUBE_API_KEY`
   - `MONGODB_URI` (MongoDB Atlas)
   - `JWT_SECRET` (random 32+ chars)
   - `CORS_ORIGINS` (your app URLs)
4. Deploy!

## 🔒 Security Best Practices

- ✅ Change `JWT_SECRET` to strong random string
- ✅ Use MongoDB Atlas with IP whitelist
- ✅ Enable HTTPS in production
- ✅ Never commit `.env` to Git
- ✅ Use environment variables for secrets
- ✅ Implement rate limiting (recommended)

## 📦 Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (via Mongoose)
- **Authentication**: JWT + bcrypt
- **YouTube**: YouTube Data API v3
- **Audio Extraction**: Cobalt API

## 🤝 Contributing

Contributions welcome! Please follow these steps:
1. Fork the repository
2. Create feature branch
3. Make changes
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For issues or questions:
- Check documentation
- Review error logs
- Open GitHub issue

---

**Built with ❤️ for Melody Hub**
