import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart' as legacy;

import 'firebase_options.dart';
import 'providers/mood_provider.dart';
import 'providers/music_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/playlist_provider.dart';
import 'services/audio_handler.dart';
import 'theme/aurora_theme.dart';
import 'router/app_router.dart';
import 'widgets/aurora_background.dart';

late AudioHandler audioHandler;

Future<void> main() async {
  // 1. Binding is mandatory for async initialization
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load Environment Variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("ERROR LOADING .ENV: $e");
    // App can continue without .env if necessary, but keep error for debugging
  }

  // 3. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
  } catch (e) {
    debugPrint("FIREBASE INIT ERROR: $e");
  }

  // 4. Initialize Audio Service
  try {
    audioHandler = await AudioService.init(
      builder: () => MelodyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.melodyhub.channel.audio',
        androidNotificationChannelName: 'Melody Hub Playback',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    debugPrint("AUDIO SERVICE INIT ERROR: $e");
    // Fallback if audio fails so app still boots
    audioHandler = await AudioService.init(
      builder: () => MelodyAudioHandler(),
      config: const AudioServiceConfig(
          androidNotificationChannelId: 'fallback',
          androidNotificationChannelName: 'Fallback'),
    );
  }

  // 5. Run App
  runApp(
    const ProviderScope(
      child: MelodyHubApp(),
    ),
  );
}

class MelodyHubApp extends ConsumerWidget {
  const MelodyHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers here
    final moodState = ref.watch(moodProvider);
    final theme = AuroraTheme.forMood(moodState.mood);

    return legacy.MultiProvider(
      providers: [
        legacy.ChangeNotifierProvider(
            create: (_) => MusicProvider()), // Ensure these exist
        legacy.ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        legacy.ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: AnimatedTheme(
        data: theme,
        duration: const Duration(milliseconds: 1500),
        child: MaterialApp.router(
          title: 'Melody Hub',
          debugShowCheckedModeBanner: false,
          theme: theme,
          routerConfig: appRouter,
          builder: (context, child) {
            return Stack(
              children: [
                const AuroraBackground(),
                if (child != null) child,
              ],
            );
          },
        ),
      ),
    );
  }
}
