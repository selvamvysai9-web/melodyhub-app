import 'package:flutter/material.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glowing_orb.dart';

class CampfireScreen extends StatefulWidget {
  const CampfireScreen({super.key});

  @override
  State<CampfireScreen> createState() => _CampfireScreenState();
}

class _CampfireScreenState extends State<CampfireScreen> {
  final List<Map<String, String>> _messages = [
    {'user': 'Alex', 'msg': '🔥 Anyone else vibing to this?', 'time': '2m ago'},
    {'user': 'Sam', 'msg': 'This track is pure fire! 🔥🔥', 'time': '1m ago'},
    {'user': 'Jordan', 'msg': 'Add it to the Campfire playlist!', 'time': '30s ago'},
  ];

  final List<Map<String, String>> _listeners = [
    {'name': 'Alex', 'emoji': '🎧', 'color': '#00E5FF'},
    {'name': 'Sam', 'emoji': '🎵', 'color': '#BB86FC'},
    {'name': 'Jordan', 'emoji': '🔥', 'color': '#FF4081'},
    {'name': 'Riley', 'emoji': '💜', 'color': '#00E676'},
    {'name': 'Casey', 'emoji': '✨', 'color': '#FFC107'},
  ];

  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildListeners(),
                const SizedBox(height: 12),
                _buildNowPlaying(),
                const SizedBox(height: 16),
                Expanded(child: _buildChat()),
                _buildInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: AuroraTheme.oledBlack),
          Positioned(top: -80, right: -60, child: GlowingOrb(size: 200, color: AuroraTheme.accentOrange, blurRadius: 80)),
        Positioned(bottom: -60, left: -40, child: GlowingOrb(size: 160, color: AuroraTheme.accentPurple, blurRadius: 70)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4081)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Campfire', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary)),
              Text('Listen together', style: TextStyle(fontSize: 12, color: AuroraTheme.textMuted)),
            ],
          ),
          const Spacer(),
          GlassContainer(
            borderRadius: 16, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded, color: AuroraTheme.accentGreen, size: 16),
                SizedBox(width: 4),
                Text('5 listening', style: TextStyle(fontSize: 12, color: AuroraTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeners() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _listeners.map((l) => _listenerAvatar(l)).toList(),
      ),
    );
  }

  Widget _listenerAvatar(Map<String, String> listener) {
    final color = _parseColor(listener['color']!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: Center(child: Text(listener['emoji']!, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 4),
          Text(listener['name']!, style: const TextStyle(fontSize: 11, color: AuroraTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 20,
        color: AuroraTheme.glassLight,
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AuroraTheme.accentCyan.withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.music_note, color: AuroraTheme.accentCyan, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Track Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
                Text('Playing to everyone', style: TextStyle(fontSize: 12, color: AuroraTheme.textMuted)),
              ],
            ),
            const Spacer(),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: AuroraTheme.accentGreen, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AuroraTheme.accentGreen.withValues(alpha: 0.5), blurRadius: 6)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuroraTheme.glassLight,
                ),
                child: Center(child: Text(m['user']![0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AuroraTheme.accentCyan))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
                  color: AuroraTheme.glassLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m['user']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AuroraTheme.accentCyan)),
                          const Spacer(),
                          Text(m['time']!, style: const TextStyle(fontSize: 10, color: AuroraTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(m['msg']!, style: const TextStyle(fontSize: 14, color: AuroraTheme.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      child: GlassContainer(
        borderRadius: 28, color: AuroraTheme.glassLight, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: AuroraTheme.textMuted, size: 22),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: const InputDecoration(
                  hintText: 'Chat with listeners...',
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                ),
                style: const TextStyle(fontSize: 15, color: AuroraTheme.textPrimary),
              ),
            ),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(              color: AuroraTheme.accentOrange, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
