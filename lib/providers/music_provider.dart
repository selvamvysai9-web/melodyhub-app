import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' hide LoopMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../services/melody_hub_service.dart';
import '../services/backend_config.dart';
import '../services/download_service.dart';
import '../services/audio_handler.dart';
import '../services/youtube_service.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String youtubeId;
  final String albumArt;
  final String audioPath;
  final String lyrics;
  final String language;
  final Duration duration;
  final bool isSearchResult;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeId,
    required this.albumArt,
    this.audioPath = '',
    this.lyrics = '',
    this.language = 'en',
    this.duration = const Duration(seconds: 0),
    this.isSearchResult = false,
  });

  String get effectiveAlbumArt =>
      albumArt.isNotEmpty ? albumArt : 'https://i.ytimg.com/vi/$youtubeId/hqdefault.jpg';

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'artist': artist,
    'youtubeId': youtubeId, 'albumArt': albumArt,
    'audioPath': audioPath, 'lyrics': lyrics, 'language': language,
    'duration': duration.inSeconds, 'isSearchResult': isSearchResult,
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    artist: json['artist'] as String? ?? '',
    youtubeId: json['youtubeId'] as String? ?? '',
    albumArt: json['albumArt'] as String? ?? '',
    audioPath: json['audioPath'] as String? ?? '',
    lyrics: json['lyrics'] as String? ?? '',
    language: json['language'] as String? ?? 'en',
    duration: Duration(seconds: json['duration'] as int? ?? 0),
    isSearchResult: json['isSearchResult'] as bool? ?? false,
  );
}

enum SongSortMode { defaultMode, nameAsc, nameDesc, artist }
enum LoopMode { off, all, one }

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _player = MelodyAudioHandler.instance.player;
  final MelodyHubService _api = MelodyHubService();
  final YouTubeService _youtube = YouTubeService(apiKey: dotenv.get('YOUTUBE_API_KEY'));
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ProcessingState>? _processingStateSub;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  int _currentIndex = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isShuffled = false;
  LoopMode _repeatMode = LoopMode.off;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAudioReady = false;
  List<Song> _playlist = [];
  List<Song> _searchResults = [];
  final Set<String> _downloadedIds = {};
  final Map<String, double> _downloadProgress = {};
  int _downloadCount = 0;
  double _volume = 1.0;
  SongSortMode _sortMode = SongSortMode.defaultMode;
  final List<Song> _recentlyPlayed = [];
  Timer? _sleepTimer;
  DateTime? _sleepTarget;
  final ValueNotifier<Duration?> _sleepNotifier = ValueNotifier<Duration?>(null);
  String? _searchQuery;
  String _language = 'all';
  int _playbackEpoch = 0;
  bool _searchDirectYt = false;
  List<Song> _trendingYtHits = [];

  static const List<Map<String, String>> availableLanguages = [
    {'code': 'all', 'name': 'All Languages'},
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'te', 'name': 'Telugu'},
    {'code': 'ml', 'name': 'Malayalam'},
    {'code': 'kn', 'name': 'Kannada'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'ar', 'name': 'Arabic'},
  ];

  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  List<Song> get searchResults => _searchResults;
  int get currentIndex => _currentIndex;
  Song get currentSong =>
      _playlist.isNotEmpty
          ? _playlist[_currentIndex.clamp(0, _playlist.length - 1)]
          : Song(title: 'Melody Hub', artist: '', youtubeId: '', albumArt: 'https://picsum.photos/seed/default/300', id: '');
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  LoopMode get repeatMode => _repeatMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPlaylistEmpty => _playlist.isEmpty;
  bool get isYoutubeSource => false;
  int get downloadCount => _downloadCount;
  double get volume => _volume;
  SongSortMode get sortMode => _sortMode;
  List<Song> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  DateTime? get sleepTarget => _sleepTarget;
  ValueNotifier<Duration?> get sleepNotifier => _sleepNotifier;
  String? get searchQuery => _searchQuery;
  String get language => _language;
  bool get searchDirectYt => _searchDirectYt;
  List<Song> get trendingYtHits => _trendingYtHits;

  void setSearchDirectYt(bool val) {
    _searchDirectYt = val;
    notifyListeners();
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      search(_searchQuery!);
    }
  }

  List<Song> get playlistByLanguage => _language == 'all'
      ? _playlist
      : _playlist.where((s) => s.language == _language).toList();
  double getDownloadProgress(String id) => _downloadProgress[id] ?? 0;
  bool isDownloaded(String id) => _downloadedIds.contains(id);

  MusicProvider();

  void init() {
    _init();
    _loadPrefs();
    loadPlaylist();
    _scanDownloads();
    _loadTrendingYtHits();
    final handler = MelodyAudioHandler.instance;
    handler.onNext = () => next();
    handler.onPrev = () => previous();
  }

  Future<void> _scanDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final songDir = Directory('${dir.path}/melody_hub/downloads');
      if (await songDir.exists()) {
        final files = await songDir.list().toList();
        for (final f in files) {
          if (f is File && f.path.endsWith('.mp3')) {
            final name = f.path.split('/').last.replaceAll('.mp3', '');
            _downloadedIds.add(name);
          }
        }
        _downloadCount = _downloadedIds.length;
      }
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  ValueNotifier<Duration> get positionNotifier => _positionNotifier;

  void setLanguage(String lang) {
    _language = lang;
    _savePrefs();
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('melody_backend_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        MelodyHubService.baseUrl = savedUrl;
      }
      _volume = prefs.getDouble('volume') ?? 1.0;
      _player.setVolume(_volume);
      _sortMode = SongSortMode.values[prefs.getInt('sortMode') ?? 0];
      _language = prefs.getString('language') ?? 'all';
      final recent = prefs.getStringList('recentlyPlayed');
      if (recent != null) {
        for (final r in recent) {
          try {
            final parts = r.split('|');
            if (parts.length >= 4) {
              _recentlyPlayed.add(Song(
                id: parts[0], title: parts[1], artist: parts[2],
                youtubeId: parts[3],
                albumArt: parts.length > 4 ? parts[4] : 'https://picsum.photos/seed/default/300',
              ));
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('volume', _volume);
      await prefs.setInt('sortMode', _sortMode.index);
      await prefs.setString('language', _language);
      await prefs.setStringList('recentlyPlayed', _recentlyPlayed.take(20).map((s) => '${s.id}|${s.title}|${s.artist}|${s.youtubeId}|${s.albumArt}').toList());
      await prefs.setStringList('melody_listen_history', _recentlyPlayed.take(50).map((s) => jsonEncode({'id': s.id, 'title': s.title, 'artist': s.artist, 'youtubeId': s.youtubeId})).toList());
    } catch (_) {}
  }

  Future<void> saveOfflineList(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('melody_offline_list', songs.map((s) => jsonEncode({'id': s.id, 'title': s.title, 'audioPath': s.audioPath, 'youtubeId': s.youtubeId})).toList());
    } catch (_) {}
  }

  Future<List<Song>> loadOfflineList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('melody_offline_list');
      if (data == null) return [];
      return data.map((d) {
        final j = jsonDecode(d);
        return Song(id: j['id'] ?? '', title: j['title'] ?? '', artist: '', youtubeId: j['youtubeId'] ?? '', albumArt: '', audioPath: j['audioPath'] ?? '');
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getAdCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('melody_ad_count') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> incrementAdCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (await getAdCount()) + 1;
      await prefs.setInt('melody_ad_count', count);
    } catch (_) {}
  }

  Future<bool> isAdblockDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('melody_adblock_dismissed') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setAdblockDismissed(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('melody_adblock_dismissed', value);
    } catch (_) {}
  }

  void _trackRecentlyPlayed(Song song) {
    _recentlyPlayed.removeWhere((s) => s.youtubeId == song.youtubeId);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) _recentlyPlayed.removeRange(20, _recentlyPlayed.length);
    _savePrefs();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    _savePrefs();
    notifyListeners();
  }

  void setSortMode(SongSortMode mode) {
    _sortMode = mode;
    _savePrefs();
    notifyListeners();
  }

  List<Song> get sortedPlaylist {
    switch (_sortMode) {
      case SongSortMode.nameAsc:
        return [..._playlist]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SongSortMode.nameDesc:
        return [..._playlist]..sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case SongSortMode.artist:
        return [..._playlist]..sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      default:
        return _playlist;
    }
  }

  void _init() {
    _positionSub = _player.positionStream.listen((pos) {
      _position = pos;
      _positionNotifier.value = pos;
    });
    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null && dur.inMilliseconds > 0) {
        _duration = dur;
        notifyListeners();
      }
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (_isPlaying != state.playing) {
        _isPlaying = state.playing;
        notifyListeners();
      }
    });
    _processingStateSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _next();
    });
  }

  Future<void> loadPlaylist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final songs = await _api.fetchPlaylist();
      if (songs.isNotEmpty) {
        _playlist = songs.asMap().entries.map((e) => Song(
          id: e.value.id, title: e.value.title, artist: e.value.artist,
          youtubeId: e.value.youtubeId,
          albumArt: e.value.albumArt.isNotEmpty ? e.value.albumArt : MelodyHubService.fallbackAlbumArt(e.key),
          audioPath: e.value.audioPath,
          lyrics: e.value.lyrics,
          language: e.value.language,
        )).toList();
      }
    } catch (_) {
      _errorMessage = 'Could not fetch playlist';
    }

    if (_playlist.isEmpty) {
      debugPrint('Loading fallback songs...');
      _playlist = [
        Song(title: 'Blinding Lights', artist: 'The Weeknd', youtubeId: '4NRXx6U8ABQ', albumArt: 'https://picsum.photos/seed/song1/300/300', id: '1'),
        Song(title: 'Shape of You', artist: 'Ed Sheeran', youtubeId: 'JGwWNGJdvx8', albumArt: 'https://picsum.photos/seed/song2/300/300', id: '2'),
        Song(title: 'Bohemian Rhapsody', artist: 'Queen', youtubeId: 'fJ9rUzIMcZQ', albumArt: 'https://picsum.photos/seed/song3/300/300', id: '3'),
        Song(title: 'Believer', artist: 'Imagine Dragons', youtubeId: '7wtfhZwyrcc', albumArt: 'https://picsum.photos/seed/song4/300/300', id: '4'),
        Song(title: 'Sugar', artist: 'Maroon 5', youtubeId: '09R8_2nJtjg', albumArt: 'https://picsum.photos/seed/song5/300/300', id: '5'),
        Song(title: 'Let Me Love You', artist: 'DJ Snake', youtubeId: 'S3JvF2JxbRU', albumArt: 'https://picsum.photos/seed/song6/300/300', id: '6'),
        Song(title: 'See You Again', artist: 'Wiz Khalifa', youtubeId: 'RgKAFK5djSk', albumArt: 'https://picsum.photos/seed/song7/300/300', id: '7'),
        Song(title: 'Counting Stars', artist: 'OneRepublic', youtubeId: 'hT_nvWreIhg', albumArt: 'https://picsum.photos/seed/song8/300/300', id: '8'),
      ];
      debugPrint('Loaded ${_playlist.length} fallback songs');
    }

    _isLoading = false;
    notifyListeners();
    await _loadCurrentSong(epoch: _playbackEpoch);
  }

  String _songPlaybackKey(Song song) =>
      song.youtubeId.isNotEmpty ? song.youtubeId : (song.id.isNotEmpty ? song.id : song.title);

  int indexOfSong(Song song) {
    if (song.youtubeId.isNotEmpty) {
      final byYt = _playlist.indexWhere((s) => s.youtubeId == song.youtubeId);
      if (byYt >= 0) return byYt;
    }
    if (song.id.isNotEmpty) {
      final byId = _playlist.indexWhere((s) => s.id == song.id);
      if (byId >= 0) return byId;
    }
    return _playlist.indexWhere((s) => s.title == song.title && s.artist == song.artist);
  }

  bool isSongPlaying(Song song) {
    if (!isPlaying || _playlist.isEmpty) return false;
    final current = currentSong;
    if (song.youtubeId.isNotEmpty && current.youtubeId == song.youtubeId) return true;
    if (song.id.isNotEmpty && current.id == song.id) return true;
    return current.title == song.title && current.artist == song.artist;
  }

  Future<void> playSongByReference(Song song) async {
    final index = indexOfSong(song);
    if (index >= 0) {
      await playSong(index);
      return;
    }
    _playlist.insert(0, song);
    await playSong(0);
  }

  Future<void> _loadCurrentSong({required int epoch}) async {
    if (_playlist.isEmpty) return;
    if (epoch != _playbackEpoch) return;

    _isAudioReady = false;
    _position = Duration.zero;
    notifyListeners();

    final song = currentSong;
    _trackRecentlyPlayed(song);
    MelodyAudioHandler.instance.setSong(song.title, song.artist, song.albumArt);

    Future<bool> stale() async {
      if (epoch != _playbackEpoch) return true;
      return false;
    }

    // 1. Try local download first (offline playback)
    try {
      await _player.stop();
      if (await stale()) return;
      final localPath = await DownloadService.getLocalPath(song.youtubeId);
      if (localPath != null) {
        await _player.setAudioSource(AudioSource.uri(Uri.file(localPath)), preload: true);
        if (await stale()) return;
        _isAudioReady = true;
        debugPrint('Playing from local download: ${song.title}');
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Local playback failed: $e');
    }

    // 2. Render backend audio stream
    if (song.youtubeId.isNotEmpty) {
      try {
        if (await stale()) return;
        final audioUrl = BackendConfig.stream(song.youtubeId);
        await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)), preload: true);
        if (await stale()) return;
        _isAudioReady = true;
        debugPrint('Playing from Render backend: ${song.title}');
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Render backend audio failed: $e');
      }
    }

    // 3. YouTube audio stream for this song's video id (correct per-track audio)
    if (song.youtubeId.isNotEmpty) {
      try {
        if (await stale()) return;
        final streamUrl = await _youtube.getAudioStreamUrl(song.youtubeId);
        if (streamUrl != null && streamUrl.isNotEmpty) {
          await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)), preload: true);
          if (await stale()) return;
          _isAudioReady = true;
          debugPrint('Playing YouTube stream: ${song.title} (${song.youtubeId})');
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('YouTube stream failed: $e');
      }
    }

    // 4. Backend audioPath when it looks song-specific
    if (song.audioPath.isNotEmpty && _isSongSpecificAudioPath(song)) {
      try {
        if (await stale()) return;
        final audioUri = song.audioPath.startsWith('http')
            ? Uri.parse(song.audioPath)
            : Uri.parse('${MelodyHubService.baseUrl}/${song.audioPath}');
        await _player.setAudioSource(AudioSource.uri(audioUri), preload: true);
        if (await stale()) return;
        _isAudioReady = true;
        debugPrint('Playing from backend audio: ${song.title}');
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Backend audio failed: $e');
      }
    }

    // 5. Per-song demo MP3 (stable hash — not playlist index)
    final audioUrl = MelodyHubService.getFallbackMp3UrlForKey(_songPlaybackKey(song));
    try {
      if (await stale()) return;
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)), preload: true);
      if (await stale()) return;
      _isAudioReady = true;
      debugPrint('Playing fallback MP3 for ${song.title}: $audioUrl');
      notifyListeners();
      return;
    } catch (e) {
      debugPrint('Fallback MP3 failed: $e');
    }

    if (await stale()) return;
    _errorMessage = 'Could not load audio for this song';
    notifyListeners();
  }

  bool _isSongSpecificAudioPath(Song song) {
    final path = song.audioPath.toLowerCase();
    if (path.contains('default') || path.contains('placeholder')) return false;
    if (song.youtubeId.isNotEmpty && path.contains(song.youtubeId)) return true;
    if (song.id.isNotEmpty && path.contains(song.id)) return true;
    // Avoid one shared MP3 used for every row in the catalog.
    if (path.endsWith('.mp3') || path.endsWith('.m4a') || path.endsWith('.aac')) {
      return true;
    }
    return song.youtubeId.isEmpty;
  }

  Future<void> playPause() async {
    if (_playlist.isEmpty) return;
    
    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
    } else {
      if (!_isAudioReady) {
        await _loadCurrentSong(epoch: _playbackEpoch);
      }
      if (_isAudioReady) {
        await _player.play();
        _isPlaying = true;
      }
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_playlist.isEmpty) return;
    if (_isAudioReady) await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playSong(dynamic arg) async {
    if (arg is int) {
      await _playSongByIndex(arg);
    } else if (arg is String) {
      final idx = _playlist.indexWhere((s) => s.youtubeId == arg);
      if (idx >= 0) {
        await _playSongByIndex(idx);
      } else {
        final searchIdx = _searchResults.indexWhere((s) => s.youtubeId == arg);
        if (searchIdx >= 0) {
          final sSong = _searchResults[searchIdx];
          _playlist.insert(0, sSong);
          await _playSongByIndex(0);
        } else {
          final recentIdx = _recentlyPlayed.indexWhere((s) => s.youtubeId == arg);
          if (recentIdx >= 0) {
            final rSong = _recentlyPlayed[recentIdx];
            _playlist.insert(0, rSong);
            await _playSongByIndex(0);
          } else {
            // Create a temporary loading placeholder song
            final tempSong = Song(
              id: 'yt_$arg',
              title: 'Loading YouTube Track...',
              artist: 'Please wait...',
              youtubeId: arg,
              albumArt: 'https://i.ytimg.com/vi/$arg/hqdefault.jpg',
            );
            _playlist.insert(0, tempSong);
            notifyListeners();

            // Fetch actual video details in the background using YouTube Data API v3
            _youtube.getVideoDetails([arg]).then((res) {
              if (res is YouTubeDetailsSuccess && res.videos.isNotEmpty) {
                final video = res.videos.first;
                final idx = _playlist.indexWhere((s) => s.youtubeId == arg);
                if (idx >= 0) {
                  _playlist[idx] = Song(
                    id: 'yt_$arg',
                    title: video.title,
                    artist: video.channelTitle,
                    youtubeId: arg,
                    albumArt: video.bestThumbnail,
                  );
                  notifyListeners();
                  // Instantly update local system media player session metadata
                  MelodyAudioHandler.instance.setSong(video.title, video.channelTitle, video.bestThumbnail);
                }
              }
            }).catchError((_) {});

            await _playSongByIndex(0);
          }
        }
      }
    }
  }

  Future<void> _playSongByIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    final epoch = ++_playbackEpoch;
    _currentIndex = index;
    _errorMessage = null;
    try {
      await _player.stop();
    } catch (_) {}

    final song = _playlist[index];
    _api.trackPlay(
      song.title, song.artist,
      song.youtubeId, song.albumArt,
      language: song.language,
    );
    notifyListeners();
    await _loadCurrentSong(epoch: epoch);
    if (epoch != _playbackEpoch) return;
    
    // Start playback
    if (_isAudioReady) {
      try {
        await _player.play();
        _isPlaying = true;
      } catch (e) {
        debugPrint('Playback start failed: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _next() async {
    if (_playlist.isEmpty) return;
    if (_repeatMode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    if (_isShuffled) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    } else {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else if (_repeatMode == LoopMode.all) {
        _currentIndex = 0;
      } else {
        return;
      }
    }
    final epoch = ++_playbackEpoch;
    await _player.stop();
    await _loadCurrentSong(epoch: epoch);
    if (epoch != _playbackEpoch) return;
    if (_isAudioReady) {
      await _player.play();
    }
    _isPlaying = _isAudioReady;
    notifyListeners();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    await _player.stop();
    if (_isShuffled) {
      int newIndex;
      do {
        newIndex = Random().nextInt(_playlist.length);
      } while (newIndex == _currentIndex && _playlist.length > 1);
      _currentIndex = newIndex;
    } else {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else if (_repeatMode == LoopMode.all) {
        _currentIndex = 0;
      } else {
        return;
      }
    }
    final epoch = ++_playbackEpoch;
    await _loadCurrentSong(epoch: epoch);
    if (epoch != _playbackEpoch) return;
    if (_isAudioReady) {
      await _player.play();
    }
    _isPlaying = _isAudioReady;
    notifyListeners();
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.stop();
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == LoopMode.all) {
      _currentIndex = _playlist.length - 1;
    } else {
      _currentIndex = 0;
    }
    final epoch = ++_playbackEpoch;
    await _loadCurrentSong(epoch: epoch);
    if (epoch != _playbackEpoch) return;
    if (_isAudioReady) {
      await _player.play();
    }
    _isPlaying = _isAudioReady;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case LoopMode.off: _repeatMode = LoopMode.all; break;
      case LoopMode.all: _repeatMode = LoopMode.one; break;
      case LoopMode.one: _repeatMode = LoopMode.off; break;
    }
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_searchDirectYt) {
      final ytResult = await _youtube.search(query: query, language: _language);
      _searchResults = [];
      if (ytResult is YouTubeSearchSuccess) {
        for (final yt in ytResult.videos) {
          _searchResults.add(Song(
            id: 'yt_${yt.videoId}',
            title: yt.title,
            artist: yt.channelTitle,
            youtubeId: yt.videoId,
            albumArt: yt.bestThumbnail,
            isSearchResult: true,
          ));
        }
      } else if (ytResult is YouTubeQuotaExceeded) {
        _errorMessage = 'YouTube API quota exceeded. Toggle back to Local Library mode.';
      } else if (ytResult is YouTubeApiError) {
        _errorMessage = 'YouTube API returned error: ${ytResult.message}';
      } else if (ytResult is YouTubeNetworkError) {
        _errorMessage = 'YouTube Network error: ${ytResult.message}';
      }
    } else {
      final q = query.toLowerCase();
      final source = _language == 'all' ? _playlist : playlistByLanguage;

      _searchResults = source.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.artist.toLowerCase().contains(q)
      ).toList();

      if (_searchResults.length < 3 && query.length > 2) {
        final ytResult = await _youtube.search(query: query, language: _language);
        if (ytResult is YouTubeSearchSuccess) {
          for (final yt in ytResult.videos) {
            final exists = _searchResults.any((s) => s.youtubeId == yt.videoId);
            if (!exists) {
              _searchResults.add(Song(
                id: 'yt_${yt.videoId}',
                title: yt.title,
                artist: yt.channelTitle,
                youtubeId: yt.videoId,
                albumArt: yt.bestThumbnail,
                isSearchResult: true,
              ));
            }
          }
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Replace the current queue and start playback (e.g. user playlist).
  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _playlist = List<Song>.from(songs);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    await playSong(_currentIndex);
  }

  /// Insert a track after the currently playing song.
  void addToQueue(Song song) {
    if (song.youtubeId.isEmpty) return;
    final insertAt = (_currentIndex + 1).clamp(0, _playlist.length);
    final exists = _playlist.any((s) => s.youtubeId == song.youtubeId);
    if (!exists) {
      _playlist.insert(insertAt, song);
      if (insertAt <= _currentIndex) _currentIndex++;
    }
    notifyListeners();
  }

  Future<void> addSearchResultToPlaylist(int index) async {
    if (index < 0 || index >= _searchResults.length) return;
    final song = _searchResults[index];
    final existing = indexOfSong(song);
    if (existing >= 0) {
      await playSong(existing);
      return;
    }
    _playlist.insert(0, Song(
      id: song.id, title: song.title, artist: song.artist,
      youtubeId: song.youtubeId, albumArt: song.albumArt,
    ));
    await playSong(0);
  }

  Future<void> shareSong(Song song) async {
    final url = 'https://music.youtube.com/watch?v=${song.youtubeId}';
    await SharePlus.instance.share(ShareParams(text: 'Listen to ${song.title} by ${song.artist} on Melody Hub!\n$url', subject: '${song.title} - ${song.artist}'));
  }

  Future<void> refreshDownloadCount() async {
    _downloadCount = await DownloadService.getDownloadCount();
    notifyListeners();
  }

  Future<void> downloadSong(Song song) async {
    final id = song.youtubeId;
    if (id.isEmpty || _downloadedIds.contains(id)) return;
    _downloadProgress[id] = 0;
    notifyListeners();
    try {
      final songIndex = _playlist.indexWhere((s) => s.youtubeId == id);
      final key = songIndex >= 0
          ? _songPlaybackKey(_playlist[songIndex])
          : id;
      final url = MelodyHubService.getFallbackMp3UrlForKey(key);
      await DownloadService.downloadSong(
        url: url, songId: id,
        onProgress: (p) { _downloadProgress[id] = p; notifyListeners(); },
      );
      _downloadedIds.add(id);
      _downloadCount++;
    } catch (_) {}
    _downloadProgress.remove(id);
    notifyListeners();
  }

  Future<void> deleteDownload(Song song) async {
    final id = song.youtubeId;
    if (id.isEmpty) return;
    await DownloadService.deleteSong(id);
    _downloadedIds.remove(id);
    _downloadCount = await DownloadService.getDownloadCount();
    notifyListeners();
  }

  Future<void> clearAllCache() async {
    await _player.stop();
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTarget = DateTime.now().add(duration);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _sleepTarget!.difference(DateTime.now());
      if (remaining.isNegative) {
        pause();
        cancelSleepTimer();
      } else {
        _sleepNotifier.value = remaining;
      }
    });
    _sleepNotifier.value = duration;
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTarget = null;
    _sleepNotifier.value = null;
    notifyListeners();
  }

  String formatDuration(Duration duration) {
    final mins = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _loadTrendingYtHits() async {
    try {
      final res = await _youtube.search(
        query: 'Billboard Hot 100 Music Hits 2026',
        maxResults: 10,
      );
      if (res is YouTubeSearchSuccess) {
        _trendingYtHits = res.videos.map((v) => Song(
          id: 'yt_${v.videoId}',
          title: v.title,
          artist: v.channelTitle,
          youtubeId: v.videoId,
          albumArt: v.bestThumbnail,
          isSearchResult: true,
        )).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _processingStateSub?.cancel();
    _positionNotifier.dispose();
    _sleepTimer?.cancel();
    _sleepNotifier.dispose();
    super.dispose();
  }
}
