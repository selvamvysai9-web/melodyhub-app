import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/music_provider.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mini_player.dart';

class SearchShell extends StatefulWidget {
  const SearchShell({super.key});

  @override
  State<SearchShell> createState() => _SearchShellState();
}

class _SearchShellState extends State<SearchShell> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final searchResults = musicProvider.searchResults;

    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildSearchModeToggle(musicProvider),
                const SizedBox(height: 12),
                _buildLanguageChips(musicProvider),
                const SizedBox(height: 16),
                Expanded(child: _buildResults(searchResults, musicProvider)),
              ],
            ),
          ),
          // MiniPlayer at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(onTap: () => context.push('/player')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        borderRadius: 28,
        child: TextField(
          controller: _searchController,
          onChanged: (q) => context.read<MusicProvider>().search(q),
          decoration: InputDecoration(
            hintText: 'What do you want to listen to?',
            prefixIcon: const Icon(Icons.search_rounded, color: AuroraTheme.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AuroraTheme.textMuted, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      context.read<MusicProvider>().search('');
                    },
                  )
                : null,
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 15, color: AuroraTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildLanguageChips(MusicProvider musicProvider) {
    final languages = MusicProvider.availableLanguages;
    final selectedLang = musicProvider.language;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: languages.map((lang) {
          final code = lang['code']!;
          final name = lang['name']!;
          final isSelected = selectedLang == code;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => musicProvider.setLanguage(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.glassLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AuroraTheme.oledBlack : AuroraTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBrowseCategories(MusicProvider musicProvider) {
    const categories = [
      ('Pop hits', 'pop music 2024'),
      ('Hip hop', 'hip hop'),
      ('Rock classics', 'rock classics'),
      ('Lo-fi chill', 'lofi hip hop'),
      ('Bollywood', 'bollywood hits'),
      ('K-pop', 'kpop'),
      ('Jazz', 'jazz'),
      ('Electronic', 'edm'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 90),
      children: [
        Icon(Icons.search_rounded, size: 48, color: AuroraTheme.textMuted.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('Browse all', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Tap a genre or search above', style: TextStyle(fontSize: 13, color: AuroraTheme.textMuted)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((c) {
            final (label, query) = c;
            return GestureDetector(
              onTap: () {
                _searchController.text = query;
                musicProvider.search(query);
              },
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 20,
                color: AuroraTheme.glassLight,
                child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults(List results, MusicProvider musicProvider) {
    if (musicProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AuroraTheme.accentCyan),
      );
    }

    if (musicProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AuroraTheme.accentPink, size: 54),
              const SizedBox(height: 16),
              Text(
                musicProvider.errorMessage!,
                style: const TextStyle(fontSize: 14, color: AuroraTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => musicProvider.clearError(),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  borderRadius: 20,
                  color: AuroraTheme.accentCyan.withValues(alpha: 0.15),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AuroraTheme.accentCyan),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        return _buildBrowseCategories(musicProvider);
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AuroraTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No results for "$query"', style: const TextStyle(fontSize: 14, color: AuroraTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 16, color: AuroraTheme.glassLight,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: song.effectiveAlbumArt.isNotEmpty
                    ? Image.network(
                        song.effectiveAlbumArt,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 48,
                            height: 48,
                            color: AuroraTheme.glassLight,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AuroraTheme.textMuted),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: AuroraTheme.glassMedium,
                          child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22),
                        ),
                      )
                    : Container(width: 48, height: 48, color: AuroraTheme.glassMedium, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted)),
              ),
              title: Text(song.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist, style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: song.isSearchResult
                  ? Container(
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_rounded, color: AuroraTheme.accentCyan, size: 24),
                        onPressed: () => musicProvider.addSearchResultToPlaylist(index),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.play_circle_rounded, color: AuroraTheme.accentCyan, size: 28),
                      onPressed: () => musicProvider.addSearchResultToPlaylist(index),
                    ),
              onTap: () => musicProvider.addSearchResultToPlaylist(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchModeToggle(MusicProvider musicProvider) {
    final directYt = musicProvider.searchDirectYt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AuroraTheme.glassLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => musicProvider.setSearchDirectYt(false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !directYt ? AuroraTheme.accentCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Local Library',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !directYt ? FontWeight.w600 : FontWeight.w500,
                        color: !directYt ? AuroraTheme.oledBlack : AuroraTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => musicProvider.setSearchDirectYt(true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: directYt ? AuroraTheme.accentCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_queue_rounded,
                          size: 16,
                          color: directYt ? AuroraTheme.oledBlack : AuroraTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'YouTube Direct',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: directYt ? FontWeight.w600 : FontWeight.w500,
                            color: directYt ? AuroraTheme.oledBlack : AuroraTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
