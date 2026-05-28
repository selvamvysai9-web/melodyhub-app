import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/aurora_theme.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Wrap the body in a Stack so the Mini-Player can float on top
      body: Stack(
        children: [
          // The Main Content (Home, Discover, Search, Library)
          navigationShell,

          // 2. The Persistent Mini-Player floating at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // This makes it sit perfectly above your bottom navigation bar
            child: GestureDetector(
              onTap: () {
                // Later, this will navigate to your full Now Playing screen
                print("Mini Player Tapped");
              },
              child: _buildMiniPlayer(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AuroraTheme.oledBlack.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
          backgroundColor: Colors.transparent,
          selectedItemColor: AuroraTheme.accentCyan,
          unselectedItemColor: AuroraTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
          ],
        ),
      ),
    );
  }

  // 3. The Mini-Player UI
  Widget _buildMiniPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Sleek, slightly elevated dark color
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 8),
          
          // Album Art Placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Container(
              width: 45, 
              height: 45, 
              color: Colors.grey[850],
              child: const Icon(Icons.music_note_rounded, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          
          // Song Title & Artist
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Not Playing', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tap a song to listen', 
                  style: TextStyle(color: AuroraTheme.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Play/Pause Button
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            onPressed: () {
              // This will trigger your audio handler later
            }, 
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}