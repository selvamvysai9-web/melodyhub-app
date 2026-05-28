import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/music_provider.dart';
import '../services/melody_hub_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final MelodyHubService _api = MelodyHubService();
  final Set<String> _likedIds = {};
  final List<Song> _likedSongs = [];

  Set<String> get likedIds => _likedIds;
  List<Song> get likedSongs => List.unmodifiable(_likedSongs);
  bool isLiked(String youtubeId) => _likedIds.contains(youtubeId);
  int get count => _likedSongs.length;

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('favorites');
      if (data != null && data.isNotEmpty) {
        final ids = data.split(',').where((e) => e.isNotEmpty).toSet();
        _likedIds.addAll(ids);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleLike(Song song) async {
    final wasLiked = _likedIds.contains(song.youtubeId);
    if (wasLiked) {
      _likedIds.remove(song.youtubeId);
      _likedSongs.removeWhere((s) => s.youtubeId == song.youtubeId);
    } else {
      _likedIds.add(song.youtubeId);
      _likedSongs.insert(0, song);
    }
    await _save();
    await _api.toggleLike(song.id.isNotEmpty ? song.id : song.youtubeId);
    notifyListeners();
  }

  Future<void> removeLiked(String youtubeId) async {
    _likedIds.remove(youtubeId);
    _likedSongs.removeWhere((s) => s.youtubeId == youtubeId);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites', _likedIds.join(','));
    } catch (_) {}
  }
}
