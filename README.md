# Melody Hub

A next-gen Aurora Glassmorphism music streaming app with AI-powered features, Firebase backend, and multi-platform support.

## Features

- 🎵 Music streaming with just_audio and audio_service
- 🎨 Aurora Glassmorphism UI with mood-based theming
- 🔐 Firebase authentication with Google Sign-In
- ☁️ Cloud Firestore for data persistence
- 🤖 AI chat integration with Gemini
- 📝 Lyrics display with synchronization
- 🎬 YouTube video integration
- 📱 Multi-platform support (iOS, Android, Web, macOS, Linux, Windows)

## Project Structure

```
melody_hub/
├── lib/                    # Dart/Flutter source code
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   ├── services/          # Business logic services
│   ├── providers/         # State management (Provider & Riverpod)
│   ├── repositories/      # Data access layer
│   ├── models/            # Data models
│   ├── theme/             # Theme and styling
│   └── router/            # Navigation routing
├── server/                # Node.js backend server
├── functions/             # Firebase Cloud Functions
├── android/               # Android platform code
├── ios/                   # iOS platform code
├── web/                   # Web platform code
├── macos/                 # macOS platform code
├── linux/                 # Linux platform code
└── windows/               # Windows platform code
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.3.0)
- Node.js 24+
- Firebase CLI
- Google Cloud Project with YouTube Data API v3 and Gemini API enabled

### Setup Instructions

#### 1. Clone and install Flutter dependencies

```bash
flutter pub get
```

#### 2. Configure Firebase

```bash
# Login to Firebase
firebase login

# Set the active Firebase project
firebase use <your-project-id>
```

#### 3. Set up environment variables

Copy `.env.example` to `.env` in the root directory and populate with your Firebase credentials:

```bash
cp .env.example .env
```

#### 4. Set up the backend server

```bash
cd server
npm install

# Copy environment template
cp .env.example .env

# Add your YouTube API key to .env
# YT_API_KEY=your_youtube_api_key_here

# Start the server
npm start
```

#### 5. Deploy Firebase Functions (optional)

```bash
firebase deploy --only functions
```

#### 6. Run the app

```bash
# Development on connected device or emulator
flutter run

# Run on a specific platform
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d linux         # Linux
flutter run -d windows       # Windows
```

## Environment Variables

### Server (.env)
- `YT_API_KEY` - YouTube Data API v3 key (required for YouTube search)
- `PORT` - Server port (default: 3000)

### Flutter App (.env)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `API_BASE_URL` - Backend server URL (default: http://localhost:3000)
- Feature flags for offline mode and analytics

## Firebase Configuration

The app requires the following Firebase services:

- **Authentication**: Enabled with Google Sign-In
- **Firestore**: Database for songs, users, playlists, and admin data
- **Cloud Functions**: AI integration and admin operations
- **Storage** (optional): For user uploads

### Firestore Security Rules

Security rules are defined in `firestore.rules`. Key rules:

- Songs: Read by authenticated users, write by admins only
- Users: Users can read/modify their own profile, admins can modify any user
- Playlists: Authenticated users can read/write their playlists
- Admins: Admin data restricted to admin users

## Troubleshooting

### API Key Issues
If YouTube search returns "API key not configured" error:
1. Ensure `YT_API_KEY` is set in `server/.env`
2. Verify the API key is valid in Google Cloud Console
3. Check that YouTube Data API v3 is enabled for the project

### Firebase Connection Issues
- Ensure Firebase project is properly configured in `google-services.json`
- Check that Firestore database is created and accessible
- Verify authentication rules in Firebase Console

### Audio Service Issues
- On Android, ensure audio_service background permission is granted
- On iOS, configure audio session categories in `ios/Runner/Info.plist`

## Build & Deployment

### Android Release Build
```bash
flutter build apk --release

# For production, update:
# 1. Application ID in android/app/build.gradle.kts
# 2. Signing configuration for release build
```

### iOS Release Build
```bash
flutter build ios --release
```

### Web Deployment
```bash
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Generate Launcher Icons
```bash
flutter pub run flutter_launcher_icons:main
```

## Contributing

Feel free to contribute by:
1. Reporting bugs
2. Suggesting features
3. Submitting pull requests

## License

This project is private and not licensed for public use.

## Support

For issues and questions, please refer to the [Flutter documentation](https://docs.flutter.dev/) and [Firebase documentation](https://firebase.google.com/docs).

