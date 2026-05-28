import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/aurora_theme.dart';

/// Spotify-style "Add to playlist" bottom sheet.
void showAddToPlaylistSheet(BuildContext context, Song song) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AuroraTheme.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddToPlaylistSheet(song: song),
  );
}

class _AddToPlaylistSheet extends StatefulWidget {
  const _AddToPlaylistSheet({required this.song});

  final Song song;

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistProvider>().playlists;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuroraTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.song.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AuroraTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.song.artist,
              style: const TextStyle(fontSize: 13, color: AuroraTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            const Text(
              'Add to playlist',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AuroraTheme.accentCyan,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            if (_creating) ...[
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: AuroraTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: AuroraTheme.textMuted.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: AuroraTheme.glassLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _creating = false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      final pl = context.read<PlaylistProvider>();
                      pl.createPlaylist(name);
                      pl.addSongToPlaylist(pl.playlists.length - 1, widget.song);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to "$name"')),
                      );
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ] else
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AuroraTheme.glassLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded, color: AuroraTheme.textPrimary),
                ),
                title: const Text(
                  'New playlist',
                  style: TextStyle(color: AuroraTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () => setState(() => _creating = true),
              ),
            if (playlists.isEmpty && !_creating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No playlists yet — create one above',
                    style: TextStyle(color: AuroraTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    final hasSong = pl.songs.any((s) => s.youtubeId == widget.song.youtubeId);
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AuroraTheme.accentCyan.withValues(alpha: 0.4),
                              AuroraTheme.accentPurple.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.queue_music_rounded, color: Colors.white),
                      ),
                      title: Text(
                        pl.name,
                        style: const TextStyle(color: AuroraTheme.textPrimary),
                      ),
                      subtitle: Text(
                        '${pl.songs.length} songs',
                        style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 12),
                      ),
                      trailing: hasSong
                          ? const Icon(Icons.check_rounded, color: AuroraTheme.accentGreen)
                          : null,
                      onTap: hasSong
                          ? null
                          : () {
                              context.read<PlaylistProvider>().addSongToPlaylist(index, widget.song);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to "${pl.name}"')),
                              );
                            },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
