import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/music_provider.dart';
import '../repositories/playlist_repository.dart';

Map<String, dynamic> _songToFirestoreMap(Song song) => {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'youtubeId': song.youtubeId,
      'albumArt': song.albumArt,
      'language': song.language,
      'duration': song.duration.inSeconds,
    };

Song _songFromFirestoreMap(Map<String, dynamic> json) => Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      youtubeId: json['youtubeId'] as String? ?? '',
      albumArt: json['albumArt'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      duration: Duration(seconds: json['duration'] as int? ?? 0),
    );

class UserPlaylist {
  final String id;
  String name;
  List<Song> songs;
  final int updatedAtMs;

  UserPlaylist({
    required this.id,
    required this.name,
    this.songs = const [],
    int? updatedAtMs,
  }) : updatedAtMs = updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  UserPlaylist copyWith({
    String? name,
    List<Song>? songs,
    int? updatedAtMs,
  }) {
    return UserPlaylist(
      id: id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      updatedAtMs: updatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'updatedAtMs': updatedAtMs,
        'songs': songs.map((s) => s.toJson()).toList(),
      };

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'name': name,
        'updatedAtMs': updatedAtMs,
        'songs': songs.map(_songToFirestoreMap).toList(),
      };

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] as String? ?? _generatePlaylistId(),
      name: json['name'] as String? ?? '',
      updatedAtMs: json['updatedAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      songs: (json['songs'] as List?)
              ?.map((s) => Song.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
    );
  }

  factory UserPlaylist.fromFirestoreMap(Map<String, dynamic> json) {
    final rawSongs = json['songs'] as List<dynamic>? ?? [];
    return UserPlaylist(
      id: json['id'] as String? ?? _generatePlaylistId(),
      name: json['name'] as String? ?? '',
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
      songs: rawSongs
          .whereType<Map>()
          .map((e) => _songFromFirestoreMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

String _generatePlaylistId() =>
    '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _repository = PlaylistRepository();
  final List<UserPlaylist> _playlists = [];
  int _activePlaylistIndex = -1;

  static const String _storageKey = 'user_playlists';
  static const String _localUpdatedKey = 'user_playlists_updated_at_ms';
  static const int maxPlaylists = 50;
  static const int maxSongsPerPlaylist = 500;

  String? _uid;
  bool _cloudSyncEnabled = false;
  bool _isSyncing = false;
  bool _syncError = false;
  String? _syncErrorMessage;
  int _localUpdatedAtMs = 0;
  Timer? _debouncedCloudSave;

  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);
  int get activePlaylistIndex => _activePlaylistIndex;
  bool get hasActivePlaylist => _activePlaylistIndex >= 0;
  bool get isSyncing => _isSyncing;
  bool get syncError => _syncError;
  String? get syncErrorMessage => _syncErrorMessage;
  bool get cloudSyncEnabled => _cloudSyncEnabled;

  PlaylistProvider() {
    _loadLocal();
  }

  /// Called when Firebase auth state changes (see legacy_providers).
  Future<void> onAuthChanged(User? user) async {
    final newUid = _resolveUid(user);
    if (newUid == _uid) return;

    _debouncedCloudSave?.cancel();
    _uid = newUid;
    _cloudSyncEnabled = newUid != null;
    _syncError = false;
    _syncErrorMessage = null;

    if (!_cloudSyncEnabled) {
      _playlists.clear();
      _activePlaylistIndex = -1;
      await _loadLocal();
      notifyListeners();
      return;
    }

    await _syncWithCloud();
  }

  String? _resolveUid(User? user) {
    if (user == null) return null;
    if (user.isAnonymous) return null;
    return user.uid;
  }

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _localUpdatedAtMs = prefs.getInt(_localUpdatedKey) ?? 0;
      final data = prefs.getString(_storageKey);
      if (data == null) return;
      final List<dynamic> list = jsonDecode(data);
      _playlists
        ..clear()
        ..addAll(list.map((p) => UserPlaylist.fromJson(Map<String, dynamic>.from(p as Map))));
      _ensurePlaylistIds();
      notifyListeners();
    } catch (e) {
      debugPrint('Playlist local load failed: $e');
    }
  }

  Future<void> _syncWithCloud() async {
    final uid = _uid;
    if (uid == null) return;

    _isSyncing = true;
    _syncError = false;
    _syncErrorMessage = null;
    notifyListeners();

    try {
      await _loadLocal();
      final remote = await _repository.fetch(uid);

      if (remote == null && _playlists.isNotEmpty) {
        await _pushToCloud(uid);
      } else if (remote != null) {
        final remoteUpdated = remote['updatedAtMs'] as int? ?? 0;
        final remotePlaylists = _parsePlaylistList(remote['playlists']);
        if (remoteUpdated >= _localUpdatedAtMs) {
          _applyPlaylists(remotePlaylists, remoteUpdated);
          await _persistLocal();
        } else if (_playlists.isNotEmpty) {
          await _pushToCloud(uid);
        } else {
          _applyPlaylists(remotePlaylists, remoteUpdated);
          await _persistLocal();
        }
      }
    } catch (e) {
      _syncError = true;
      _syncErrorMessage = 'Could not sync playlists';
      debugPrint('Playlist cloud sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _applyPlaylists(List<UserPlaylist> playlists, int updatedAtMs) {
    _playlists
      ..clear()
      ..addAll(playlists);
    _localUpdatedAtMs = updatedAtMs;
    _ensurePlaylistIds();
    if (_activePlaylistIndex >= _playlists.length) {
      _activePlaylistIndex = -1;
    }
  }

  List<UserPlaylist> _parsePlaylistList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => UserPlaylist.fromFirestoreMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _ensurePlaylistIds() {
    for (var i = 0; i < _playlists.length; i++) {
      if (_playlists[i].id.isEmpty) {
        final p = _playlists[i];
        _playlists[i] = UserPlaylist(
          id: _generatePlaylistId(),
          name: p.name,
          songs: p.songs,
          updatedAtMs: p.updatedAtMs,
        );
      }
    }
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, data);
      await prefs.setInt(_localUpdatedKey, _localUpdatedAtMs);
    } catch (e) {
      debugPrint('Playlist local save failed: $e');
    }
  }

  Future<void> _persist({bool scheduleCloud = true}) async {
    _localUpdatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await _persistLocal();
    notifyListeners();
    if (scheduleCloud && _cloudSyncEnabled && _uid != null) {
      _scheduleCloudSave();
    }
  }

  void _scheduleCloudSave() {
    _debouncedCloudSave?.cancel();
    _debouncedCloudSave = Timer(const Duration(seconds: 2), () {
      final uid = _uid;
      if (uid != null) _pushToCloud(uid);
    });
  }

  Future<void> _pushToCloud(String uid) async {
    try {
      await _repository.save(uid, {
        'updatedAtMs': _localUpdatedAtMs,
        'playlists': _playlists.map((p) => p.toFirestoreMap()).toList(),
      });
      _syncError = false;
      _syncErrorMessage = null;
    } catch (e) {
      _syncError = true;
      _syncErrorMessage = 'Cloud save failed — saved on device';
      debugPrint('Playlist cloud save failed: $e');
    }
    notifyListeners();
  }

  /// Force refresh from Firestore (e.g. pull-to-refresh).
  Future<void> refreshFromCloud() async {
    if (!_cloudSyncEnabled || _uid == null) return;
    await _syncWithCloud();
  }

  void createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_playlists.length >= maxPlaylists) return;
    _playlists.add(UserPlaylist(id: _generatePlaylistId(), name: trimmed));
    _persist();
  }

  void renamePlaylist(int index, String name) {
    if (index < 0 || index >= _playlists.length) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _playlists[index] = _playlists[index].copyWith(name: trimmed);
    _persist();
  }

  void deletePlaylist(int index) {
    if (index < 0 || index >= _playlists.length) return;
    _playlists.removeAt(index);
    if (_activePlaylistIndex == index) _activePlaylistIndex = -1;
    _persist();
  }

  void addSongToPlaylist(int playlistIndex, Song song) {
    if (playlistIndex < 0 || playlistIndex >= _playlists.length) return;
    if (song.youtubeId.isEmpty) return;
    final pl = _playlists[playlistIndex];
    if (pl.songs.length >= maxSongsPerPlaylist) return;
    if (pl.songs.any((s) => s.youtubeId == song.youtubeId)) return;
    _playlists[playlistIndex] = pl.copyWith(
      songs: [...pl.songs, song],
    );
    _persist();
  }

  void removeSongFromPlaylist(int playlistIndex, int songIndex) {
    if (playlistIndex < 0 || playlistIndex >= _playlists.length) return;
    final pl = _playlists[playlistIndex];
    if (songIndex < 0 || songIndex >= pl.songs.length) return;
    final list = [...pl.songs]..removeAt(songIndex);
    _playlists[playlistIndex] = pl.copyWith(songs: list);
    _persist();
  }

  void setActivePlaylist(int index) {
    _activePlaylistIndex = index;
    notifyListeners();
  }

  void clearActivePlaylist() {
    _activePlaylistIndex = -1;
    notifyListeners();
  }

  @override
  void dispose() {
    _debouncedCloudSave?.cancel();
    super.dispose();
  }
}
