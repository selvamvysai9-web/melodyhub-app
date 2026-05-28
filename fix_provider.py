import re

path = r'C:\Users\HP\Downloads\flutter project\melody_hub\lib\providers\music_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

original_len = len(content)

# 1. Fix playPause - remove YT controller block
old_playpause = '''  Future<void> playPause() async {
    if (_playlist.isEmpty) return;
    
    if (_isYoutubeSource && _ytController != null) {
      try {
        if (_isPlaying) {
          _ytController!.pause();
        } else {
          _ytController!.play();
        }
        _isPlaying = !_isPlaying;
        notifyListeners();
      } catch (_) {}
      return;
    }
    
    if (_isPlaying) {'''
new_playpause = '''  Future<void> playPause() async {
    if (_playlist.isEmpty) return;
    if (_isPlaying) {'''
content = content.replace(old_playpause, new_playpause)

# 2. Fix play method
old_play = '''  Future<void> play() async {
    if (_playlist.isEmpty) return;
    if (_isYoutubeSource && _ytController != null) {
      _ytController!.play();
      return;
    }
    if (_isAudioReady) await _player.play();
  }'''
new_play = '''  Future<void> play() async {
    if (_playlist.isEmpty) return;
    if (_isAudioReady) await _player.play();
  }'''
content = content.replace(old_play, new_play)

# 3. Fix pause method
old_pause = '''  Future<void> pause() async {
    if (_isYoutubeSource && _ytController != null) {
      _ytController!.pause();
      return;
    }
    await _player.pause();
  }'''
new_pause = '''  Future<void> pause() async {
    await _player.pause();
  }'''
content = content.replace(old_pause, new_pause)

# 4. Fix seek method
old_seek = '''  Future<void> seek(Duration position) async {
    if (_isYoutubeSource && _ytController != null) {
      _ytController!.seekTo(position);
      return;
    }
    await _player.seek(position);
  }'''
new_seek = '''  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }'''
content = content.replace(old_seek, new_seek)

# 5. Fix _removeYtListener
old_remove_yt = '''  void _removeYtListener() {
    if (_ytListener != null) {
      _ytController?.removeListener(_ytListener!);
      _ytListener = null;
    }
  }'''
content = content.replace(old_remove_yt, '')

# 6. Fix _loadCurrentSong - remove steps 4 and 5
old_load_end = '''    // 4. Per-song demo MP3 (stable hash — not playlist index)
    final audioUrl = MelodyHubService.getFallbackMp3UrlForKey(_songPlaybackKey(song));
    try {
      if (await stale()) return;
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)), preload: true);
      if (await stale()) return;
      _isAudioReady = true;
      debugPrint('Playing fallback MP3 for \: \');
      notifyListeners();
      return;
    } catch (e) {
      debugPrint('Fallback MP3 failed: ');
    }

    // 5. Last resort: YouTube WebView
    if (song.youtubeId.isNotEmpty) {
      try {
        _ytController = YoutubePlayerController(
          initialVideoId: song.youtubeId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            hideControls: false,
            showLiveFullscreenButton: false,
          ),
        );
        _ytListener = () {
          if (_ytController != null && _ytController!.value.isPlaying != _isPlaying) {
            _isPlaying = _ytController!.value.isPlaying;
            notifyListeners();
          }
        };
        _ytController!.addListener(_ytListener!);
        if (await stale()) return;
        _isYoutubeSource = true;
        _isAudioReady = true;
        debugPrint('YouTube WebView source ready: \');
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('YouTube init failed: ');
      }
    }

    if (await stale()) return;
    _errorMessage = 'Could not load audio for this song';
    notifyListeners();'''
new_load_end = '''    // 4. Final fallback: try audio from YouTube (youtube_explode_dart)
    if (song.youtubeId.isNotEmpty) {
      try {
        if (await stale()) return;
        final streamUrl = await _youtube.getAudioStreamUrl(song.youtubeId);
        if (streamUrl != null && streamUrl.isNotEmpty) {
          await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)), preload: true);
          if (await stale()) return;
          _isAudioReady = true;
          debugPrint('Final fallback YouTube stream: \');
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Final fallback YouTube stream failed: ');
      }
    }

    if (await stale()) return;
    _errorMessage = 'Could not load audio for this song';
    notifyListeners();'''
content = content.replace(old_load_end, new_load_end)

# 7. Fix _playSongByIndex - remove YT cleanup
old_playsongindex = '''    _removeYtListener();
    _ytController?.dispose();
    _ytController = null;
    try {
      await _player.stop();
    } catch (_) {}'''
new_playsongindex = '''    try {
      await _player.stop();
    } catch (_) {}'''
content = content.replace(old_playsongindex, new_playsongindex)

# 8. Fix playSongByIndex - remove YT playback
old_ytcheck2 = '''    if (_isAudioReady) {
      try {
        if (_isYoutubeSource && _ytController != null) {
          _ytController!.play();
        } else {
          await _player.play();
        }
        _isPlaying = true;
      } catch (e) {
        debugPrint('Playback start failed: ');
      }
    }'''
new_ytcheck2 = '''    if (_isAudioReady) {
      try {
        await _player.play();
        _isPlaying = true;
      } catch (e) {
        debugPrint('Playback start failed: ');
      }
    }'''
content = content.replace(old_ytcheck2, new_ytcheck2)

# 9. Fix _next method
old_next_method = '''  Future<void> _next() async {
    if (_playlist.isEmpty) return;
    if (_repeatMode == LoopMode.one) {
      if (_isYoutubeSource && _ytController != null) {
        _ytController!.seekTo(Duration.zero);
        _ytController!.play();
      } else {
        await _player.seek(Duration.zero);
        await _player.play();
      }
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
    _ytController?.dispose();
    _ytController = null;
    await _loadCurrentSong(epoch: epoch);
    if (epoch != _playbackEpoch) return;
    if (_isYoutubeSource && _ytController != null) {
      _ytController!.play();
    } else if (_isAudioReady) {
      await _player.play();
    }
    _isPlaying = _isAudioReady;
    notifyListeners();
  }'''
new_next_method = '''  Future<void> _next() async {
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
  }'''
content = content.replace(old_next_method, new_next_method)

# 10. Fix next() controller cleanup
old_ytclean1 = '''    await _player.stop();
    _ytController?.dispose();
    _ytController = null;
    if (_isShuffled) {'''
new_ytclean1 = '''    await _player.stop();
    if (_isShuffled) {'''
content = content.replace(old_ytclean1, new_ytclean1)

old_ytclean2 = '''    await _player.stop();
    _ytController?.dispose();
    _ytController = null;
    if (_currentIndex > 0) {'''
new_ytclean2 = '''    await _player.stop();
    if (_currentIndex > 0) {'''
content = content.replace(old_ytclean2, new_ytclean2)

# 11. Fix next()/previous() end - remove YT checks
old_next_end = '''    if (_isYoutubeSource && _ytController != null) {
      _ytController!.play();
    } else if (_isAudioReady) {
      await _player.play();
    }
    _isPlaying = _isAudioReady;'''
new_next_end = '''    if (_isAudioReady) {
      await _player.play();
    }
    _isPlaying = _isAudioReady;'''
content = content.replace(old_next_end, new_next_end)

# 12. Fix previous YT seek
old_prev_seek = '''    if ((_isYoutubeSource ? (_ytController?.value.position ?? Duration.zero) : _position).inSeconds > 3) {
      if (_isYoutubeSource && _ytController != null) {
        _ytController!.seekTo(Duration.zero);
      } else {
        await _player.seek(Duration.zero);
      }
      return;
    }
    await _player.stop();
    _ytController?.dispose();
    _ytController = null;'''
new_prev_seek = '''    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.stop();'''
content = content.replace(old_prev_seek, new_prev_seek)

# 13. Fix loadPlaylist fallback
old_load_fallback = '''      debugPrint('Loading fallback songs...');
      _playlist = [
        Song(title: 'Blinding Lights', artist: 'The Weeknd', youtubeId: 'fHI8KU4kVEw', albumArt: 'https://picsum.photos/seed/song1/300/300', id: '1'),
        Song(title: 'Shape of You', artist: 'Ed Sheeran', youtubeId: 'JGwWNGJdvx8', albumArt: 'https://picsum.photos/seed/song2/300/300', id: '2'),
        Song(title: 'Bohemian Rhapsody', artist: 'Queen', youtubeId: 'fJ9rUzIMcZQ', albumArt: 'https://picsum.photos/seed/song3/300/300', id: '3'),
        Song(title: 'Believer', artist: 'Imagine Dragons', youtubeId: '7wtfhZwyrcc', albumArt: 'https://picsum.photos/seed/song4/300/300', id: '4'),
        Song(title: 'Sugar', artist: 'Maroon 5', youtubeId: '09R8_2nJtjg', albumArt: 'https://picsum.photos/seed/song5/300/300', id: '5'),
        Song(title: 'Let Me Love You', artist: 'DJ Snake', youtubeId: 'S3JvF2JxbRU', albumArt: 'https://picsum.photos/seed/song6/300/300', id: '6'),
        Song(title: 'See You Again', artist: 'Wiz Khalifa', youtubeId: 'RgKAFK5djSk', albumArt: 'https://picsum.photos/seed/song7/300/300', id: '7'),
        Song(title: 'Counting Stars', artist: 'OneRepublic', youtubeId: 'hT_nvWreIhg', albumArt: 'https://picsum.photos/seed/song8/300/300', id: '8'),
      ];
      debugPrint('Loaded \ fallback songs');'''
new_load_fallback = '''      debugPrint('Loading fallback songs...');
      _playlist = MelodyHubService.fallbackSongs.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Song(
          id: s['id']!,
          title: s['title']!,
          artist: s['artist']!,
          youtubeId: s['yt']!,
          albumArt: MelodyHubService.fallbackAlbumArt(i),
        );
      }).toList();
      debugPrint('Loaded \ fallback songs');'''
content = content.replace(old_load_fallback, new_load_fallback)

# 14. Fix downloadSong
old_download = '''    try {
      final songIndex = _playlist.indexWhere((s) => s.youtubeId == id);
      final key = songIndex >= 0
          ? _songPlaybackKey(_playlist[songIndex])
          : id;
      final url = MelodyHubService.getFallbackMp3UrlForKey(key);
      await DownloadService.downloadSong(
        url: url, songId: id,
        onProgress: (p) { _downloadProgress[id] = p; notifyListeners(); },
      );'''
new_download = '''    try {
      final streamUrl = await _youtube.getAudioStreamUrl(id);
      final url = streamUrl ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      await DownloadService.downloadSong(
        url: url, songId: id,
        onProgress: (p) { _downloadProgress[id] = p; notifyListeners(); },
      );'''
content = content.replace(old_download, new_download)

# 15. Fix clearAllCache
old_clear_cache = '''    await _player.stop();
    _ytController?.dispose();
    _ytController = null;
    notifyListeners();'''
new_clear_cache = '''    await _player.stop();
    notifyListeners();'''
content = content.replace(old_clear_cache, new_clear_cache)

# 16. Fix dispose
old_dispose = '''    _removeYtListener();
    _ytController?.dispose();
    _positionSub?.cancel();'''
new_dispose = '''    _positionSub?.cancel();'''
content = content.replace(old_dispose, new_dispose)

# 17. Fix fallback calls
old_fallback_call = '''MelodyHubService.getFallbackMp3UrlForKey(_songPlaybackKey(song))'''
content = content.replace(old_fallback_call, '''MelodyHubService.getFallbackYtIdForKey(_songPlaybackKey(song))''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('All 17 fixes applied!')
print(f'Size reduced from {original_len} to {len(content)} chars')
