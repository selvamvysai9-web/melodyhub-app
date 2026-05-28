# 🎵 Melody Hub - Admin Panel & Premium System

## Overview
Complete admin panel system with user roles, premium subscriptions, and song management.

## Features

### 🔐 Authentication & User Management
- **User Registration/Login** with JWT tokens
- **Three User Roles**: 
  - `user` - Standard free user
  - `premium` - Paid subscriber with exclusive access
  - `admin` - Full control over the platform
- **Automatic Premium Expiry** - Downgrades users when subscription expires

### 💎 Premium System
- Users can upgrade to premium via `/api/auth/upgrade-premium`
- Automatic role updates upon purchase
- Premium-only content filtering
- Subscription expiry tracking (30 days default)

### 👨‍💼 Admin Capabilities
- Upload new songs with YouTube ID
- Edit song titles, artists, lyrics
- Mark songs as premium-only
- Delete songs
- Manage all users
- Change user roles

## API Endpoints

### Authentication
```
POST /api/auth/register          - Register new user
POST /api/auth/login             - Login user
GET  /api/auth/profile           - Get current user profile (requires auth)
POST /api/auth/upgrade-premium   - Upgrade to premium (requires auth)
```

### Admin User Management (Admin Only)
```
GET  /api/auth/admin/users              - Get all users
PUT  /api/auth/admin/users/:id/role     - Update user role
POST /api/auth/admin/init               - Create initial admin user
```

### Song Management
```
GET  /api/songs                  - Get all songs (public)
GET  /api/songs/:id              - Get single song
POST /api/songs                  - Upload song (admin only)
PUT  /api/songs/:id              - Update song (admin only)
DELETE /api/songs/:id            - Delete song (admin only)
GET  /api/songs/admin/all        - Get all songs with details (admin only)
```

## Setup Instructions

### 1. MongoDB Atlas (Free Tier)
Since you're using Render and don't have a card:

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Create a free account (no credit card required)
3. Create a new cluster (M0 Free tier)
4. Click "Connect" → "Connect your application"
5. Copy the connection string (looks like: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/`)
6. Replace `<username>` and `<password>` in the connection string

### 2. Configure Environment Variables on Render

In your Render dashboard, add these environment variables:

```
YOUTUBE_API_KEY=AIzaSyDeSdCHTip_TnZndtbIzeLKGUV2k90_A_g
MONGODB_URI=mongodb+srv://your-username:your-password@cluster0.xxxxx.mongodb.net/melody-hub?retryWrites=true&w=majority
JWT_SECRET=melody-hub-secret-key-change-in-production-abc123xyz
CORS_ORIGINS=https://melody-backend-3qsr.onrender.com,http://localhost:8080
NODE_ENV=production
PORT=3000
```

### 3. Create Initial Admin User

After deploying, create the first admin user:

```bash
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/admin/init \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@melodyhub.com",
    "password": "admin123"
  }'
```

**Note**: This endpoint only works if no admin exists yet!

### 4. Test Premium Upgrade

```bash
# First login to get token
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'

# Then upgrade to premium (use token from login response)
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/upgrade-premium \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "durationMonths": 1
  }'
```

## User Flow

### Regular User Journey
1. Register/Login
2. Browse free songs
3. Try to access premium song → Gets blocked
4. Click "Buy Premium"
5. Payment simulated (in real app, integrate Stripe/Razorpay)
6. Role automatically updated to `premium`
7. Access granted to premium content
8. After 30 days → Auto-downgraded to `user`

### Admin Journey
1. Login with admin credentials
2. Access admin dashboard
3. Upload new songs with YouTube IDs
4. Edit lyrics and metadata
5. Mark songs as premium-only
6. Manage users and roles

## Security Features

- Password hashing with bcryptjs
- JWT token authentication
- Role-based access control middleware
- Automatic premium expiry checks
- CORS protection
- Input validation

## Database Schema

### User Model
```javascript
{
  username: String (unique),
  email: String (unique),
  password: String (hashed),
  role: 'user' | 'premium' | 'admin',
  isPremium: Boolean,
  premiumExpiry: Date,
  createdAt: Date
}
```

### Song Model
```javascript
{
  title: String,
  artist: String,
  youtubeId: String (unique),
  thumbnail: String,
  duration: String,
  lyrics: String,
  uploadedBy: ObjectId (ref: User),
  isPremium: Boolean,
  playCount: Number,
  createdAt: Date,
  updatedAt: Date
}
```

## Frontend Integration Example

### Check if User is Premium
```dart
bool isPremium = currentUser.role == 'premium' || 
                 (currentUser.isPremium && 
                  DateTime.now().isBefore(currentUser.premiumExpiry));
```

### Upload Song (Admin Only)
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/songs'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'title': 'Song Title',
    'artist': 'Artist Name',
    'youtubeId': 'dQw4w9WgXcQ',
    'lyrics': 'Song lyrics here...',
    'isPremium': false,
  }),
);
```

### Upgrade to Premium
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/upgrade-premium'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({'durationMonths': 1}),
);
```

## Deployment Checklist

- [ ] Create MongoDB Atlas free cluster
- [ ] Get connection string
- [ ] Add environment variables on Render
- [ ] Deploy backend
- [ ] Create initial admin user
- [ ] Test registration/login
- [ ] Test premium upgrade
- [ ] Test admin song upload
- [ ] Verify CORS settings for your Flutter app

## Troubleshooting

### "MongoDB connection error"
- Check your MongoDB URI format
- Ensure IP whitelist includes `0.0.0.0/0` (all IPs) in MongoDB Atlas
- Verify username/password are correct

### "Admin user already exists"
- The init endpoint can only be called once
- Login with existing admin instead

### "Premium not working"
- Check `premiumExpiry` date
- Ensure `isPremiumActive()` method is being called
- Verify token includes updated user data

## Next Steps

For production:
1. Integrate real payment gateway (Stripe, Razorpay, PayPal)
2. Add email verification
3. Add password reset functionality
4. Implement rate limiting
5. Add logging and monitoring
6. Set up automated backups for MongoDB

---

**Built with**: Express.js, MongoDB, JWT, bcryptjs
**License**: MIT
