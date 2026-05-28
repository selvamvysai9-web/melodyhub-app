# 🎵 Melody Hub Backend - Setup Guide for Render

## ✅ What's Already Done

Your backend server (`/workspace/server`) is complete with:

1. **YouTube Data API v3 Integration** - Your API key is configured
2. **Admin Panel System** - Full user management with roles
3. **Premium Subscription System** - Automatic role updates
4. **Song Management** - Upload, edit, delete songs
5. **Authentication** - JWT-based login/register

## 📋 Steps to Deploy on Render

### Step 1: Create MongoDB Atlas (FREE - No Card Required)

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up with email (no credit card needed!)
3. Create a new cluster (choose **M0 Free tier**)
4. Wait 3-5 minutes for cluster to be ready
5. Click **"Connect"** button
6. Choose **"Connect your application"**
7. Copy the connection string (looks like):
   ```
   mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
8. **Important**: Replace `<password>` with your actual password
9. Click **"Network Access"** → **"Add IP Address"** → **"Allow Access from Anywhere"** (0.0.0.0/0)

### Step 2: Configure Render Environment Variables

In your Render Dashboard (https://dashboard.render.com/web/srv-d8bu68d7vvec73c6gaog):

1. Go to **"Environment"** tab
2. Add these variables:

```
YOUTUBE_API_KEY=AIzaSyDeSdCHTip_TnZndtbIzeLKGUV2k90_A_g
MONGODB_URI=mongodb+srv://your-username:your-password@cluster0.xxxxx.mongodb.net/melody-hub?retryWrites=true&w=majority
JWT_SECRET=melody-hub-secret-key-change-in-production-abc123xyz
CORS_ORIGINS=https://melody-backend-3qsr.onrender.com,http://localhost:8080
NODE_ENV=production
PORT=3000
```

**Replace:**
- `your-username` = Your MongoDB username
- `your-password` = Your MongoDB password  
- `cluster0.xxxxx` = Your actual cluster ID from MongoDB

### Step 3: Deploy to Render

1. Go to your Render dashboard
2. Click **"Manual Deploy"** or it will auto-deploy on push
3. Wait for deployment to complete (~2-3 minutes)
4. Check logs to ensure it says "✅ MongoDB connected"

### Step 4: Create Admin User

After deployment, run this command (replace YOUR_URL with your Render URL):

```bash
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/admin/init \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@melodyhub.com",
    "password": "Admin@123"
  }'
```

**Response should be:**
```json
{"message":"Admin user created successfully"}
```

⚠️ **Note**: This only works once! If you get "Admin user already exists", someone already created the admin.

### Step 5: Test the System

#### Test Login:
```bash
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@melodyhub.com",
    "password": "Admin@123"
  }'
```

Save the `token` from the response!

#### Test Upload Song (Admin Only):
```bash
curl -X POST https://melody-backend-3qsr.onrender.com/api/songs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "title": "Test Song",
    "artist": "Test Artist",
    "youtubeId": "dQw4w9WgXcQ",
    "lyrics": "This is a test song",
    "isPremium": false
  }'
```

#### Test Premium Upgrade:
```bash
# First register a regular user
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test@123"
  }'

# Then login and get token
# Then upgrade to premium
curl -X POST https://melody-backend-3qsr.onrender.com/api/auth/upgrade-premium \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer USER_TOKEN_HERE" \
  -d '{"durationMonths": 1}'
```

## 🔑 API Endpoints Summary

### Public Endpoints
- `GET /api/health` - Server health check
- `GET /api/youtube/search?q=song` - Search YouTube
- `GET /api/youtube/audio/{id}` - Get audio URL
- `GET /api/songs` - Get all songs
- `GET /api/songs/{id}` - Get single song

### User Endpoints (Require Login)
- `POST /api/auth/register` - Register
- `POST /api/auth/login` - Login
- `GET /api/auth/profile` - Get profile
- `POST /api/auth/upgrade-premium` - Buy premium

### Admin Endpoints (Require Admin Role)
- `POST /api/auth/admin/init` - Create first admin
- `GET /api/auth/admin/users` - Get all users
- `PUT /api/auth/admin/users/:id/role` - Change user role
- `POST /api/songs` - Upload song
- `PUT /api/songs/:id` - Edit song
- `DELETE /api/songs/:id` - Delete song
- `GET /api/songs/admin/all` - Get all songs with details

## 🎯 User Roles

| Role | Permissions |
|------|-------------|
| `user` | Browse free songs, search YouTube |
| `premium` | Access premium songs, no ads (future) |
| `admin` | Full control - upload/edit/delete songs, manage users |

## 💡 Premium System Flow

1. User registers → Gets `user` role
2. User clicks "Buy Premium" → Calls `/api/auth/upgrade-premium`
3. Backend sets: `isPremium=true`, `role=premium`, `premiumExpiry=+30 days`
4. User can now access premium content
5. After 30 days → Auto-downgraded to `user` role on next login

## 🔒 Security Features

- ✅ Passwords hashed with bcryptjs
- ✅ JWT token authentication (7-day expiry)
- ✅ Role-based access control
- ✅ CORS protection
- ✅ Automatic premium expiry checks
- ✅ Input validation

## 📱 Flutter App Integration

In your Flutter app, update the base URL to your Render URL:

```dart
// In your config file
const String baseUrl = 'https://melody-backend-3qsr.onrender.com';

// Login example
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);

// Use token for authenticated requests
final token = jsonDecode(response.body)['token'];

// Upload song (admin only)
await http.post(
  Uri.parse('$baseUrl/api/songs'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'title': title,
    'youtubeId': youtubeId,
    'isPremium': isPremium,
  }),
);
```

## 🐛 Troubleshooting

### "MongoDB connection error"
- Check URI format in Render environment variables
- Ensure Network Access allows 0.0.0.0/0 in MongoDB Atlas
- Verify username/password are correct

### "Admin user already exists"
- Endpoint can only be called once
- Login with existing admin instead

### "Invalid token"
- Token expires after 7 days
- User needs to login again

### CORS errors from Flutter
- Add your Flutter app URL to `CORS_ORIGINS` in Render
- Format: `https://your-app.com,http://localhost:8080`

## 📝 Next Steps for Production

1. **Payment Integration**: Replace simulated payment with Stripe/Razorpay
2. **Email Verification**: Add email confirmation on signup
3. **Password Reset**: Implement forgot password flow
4. **Rate Limiting**: Prevent API abuse
5. **Logging**: Add proper error tracking
6. **Backups**: Enable MongoDB automated backups

---

**Server Status**: ✅ Ready to deploy
**Database**: ⏳ Waiting for MongoDB Atlas setup
**YouTube API**: ✅ Configured and working

**Need help?** Check ADMIN_PANEL.md for detailed documentation!
