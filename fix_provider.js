const fs = require('fs');
const filePath = 'C:\\Users\\HP\\Downloads\\flutter project\\melody_hub\\lib\\providers\\music_provider.dart';
let content = fs.readFileSync(filePath, 'utf-8');
const originalLen = content.length;

// All replacements as [oldText, newText] pairs
const repls = [
  [
      Future<void> playPause() async {\n    if (_playlist.isEmpty) return;\n    \n    if (_isYoutubeSource && _ytController != null) {\n      try {\n        if (_isPlaying) {\n          _ytController!.pause();\n        } else {\n          _ytController!.play();\n        }\n        _isPlaying = !_isPlaying;\n        notifyListeners();\n      } catch (_) {}\n      return;\n    }\n    \n    if (_isPlaying) {,
      Future<void> playPause() async {\n    if (_playlist.isEmpty) return;\n    if (_isPlaying) {
  ],
  [
      Future<void> play() async {\n    if (_playlist.isEmpty) return;\n    if (_isYoutubeSource && _ytController != null) {\n      _ytController!.play();\n      return;\n    }\n    if (_isAudioReady) await _player.play();\n  },
      Future<void> play() async {\n    if (_playlist.isEmpty) return;\n    if (_isAudioReady) await _player.play();\n  }
  ],
  [
      Future<void> pause() async {\n    if (_isYoutubeSource && _ytController != null) {\n      _ytController!.pause();\n      return;\n    }\n    await _player.pause();\n  },
      Future<void> pause() async {\n    await _player.pause();\n  }
  ],
  [
      Future<void> seek(Duration position) async {\n    if (_isYoutubeSource && _ytController != null) {\n      _ytController!.seekTo(position);\n      return;\n    }\n    await _player.seek(position);\n  },
      Future<void> seek(Duration position) async {\n    await _player.seek(position);\n  }
  ],
  [
      void _removeYtListener() {\n    if (_ytListener != null) {\n      _ytController?.removeListener(_ytListener!);\n      _ytListener = null;\n    }\n  },
    ''
  ],
  [
        _removeYtListener();\n    _ytController?.dispose();\n    _ytController = null;\n    try {\n      await _player.stop();\n    } catch (_) {},
        try {\n      await _player.stop();\n    } catch (_) {}
  ],
  [
        if (_isAudioReady) {\n      try {\n        if (_isYoutubeSource && _ytController != null) {\n          _ytController!.play();\n        } else {\n          await _player.play();\n        }\n        _isPlaying = true;\n      } catch (e) {\n        debugPrint('Playback start failed: \');\n      }\n    },
        if (_isAudioReady) {\n      try {\n        await _player.play();\n        _isPlaying = true;\n      } catch (e) {\n        debugPrint('Playback start failed: \');\n      }\n    }
  ],
  [
        if (_isYoutubeSource && _ytController != null) {\n      _ytController!.play();\n    } else if (_isAudioReady) {\n      await _player.play();\n    }\n    _isPlaying = _isAudioReady;,
        if (_isAudioReady) {\n      await _player.play();\n    }\n    _isPlaying = _isAudioReady;
  ],
  [
        await _player.stop();\n    _ytController?.dispose();\n    _ytController = null;\n    if (_isShuffled) {,
        await _player.stop();\n    if (_isShuffled) {
  ],
  [
        await _player.stop();\n    _ytController?.dispose();\n    _ytController = null;\n    if (_currentIndex > 0) {,
        await _player.stop();\n    if (_currentIndex > 0) {
  ],
  [
        if ((_isYoutubeSource ? (_ytController?.value.position ?? Duration.zero) : _position).inSeconds > 3) {\n      if (_isYoutubeSource && _ytController != null) {\n        _ytController!.seekTo(Duration.zero);\n      } else {\n        await _player.seek(Duration.zero);\n      }\n      return;\n    }\n    await _player.stop();\n    _ytController?.dispose();\n    _ytController = null;,
        if (_position.inSeconds > 3) {\n      await _player.seek(Duration.zero);\n      return;\n    }\n    await _player.stop();
  ],
  [
        await _player.stop();\n    _ytController?.dispose();\n    _ytController = null;\n    notifyListeners();,
        await _player.stop();\n    notifyListeners();
  ],
  [
        _removeYtListener();\n    _ytController?.dispose();\n    _positionSub?.cancel();,
        _positionSub?.cancel();
  ],
  [
    'MelodyHubService.getFallbackMp3UrlForKey',
    'MelodyHubService.getFallbackYtIdForKey'
  ]
];

for (const [oldText, newText] of repls) {
  content = content.replace(oldText, newText);
}

// Fix _loadCurrentSong - replace steps 4&5
const oldStep4 =     // 4. Per-song demo MP3 (stable hash — not playlist index)\n    final audioUrl = MelodyHubService.getFallbackMp3UrlForKey(_songPlaybackKey(song));\n    try {\n      if (await stale()) return;\n      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)), preload: true);\n      if (await stale()) return;\n      _isAudioReady = true;\n      debugPrint('Playing fallback MP3 for \: \');\n      notifyListeners();\n      return;\n    } catch (e) {\n      debugPrint('Fallback MP3 failed: \');\n    }\n\n    // 5. Last resort: YouTube WebView\n    if (song.youtubeId.isNotEmpty) {\n      try {\n        _ytController = YoutubePlayerController(\n          initialVideoId: song.youtubeId,\n          flags: const YoutubePlayerFlags(\n            autoPlay: true,\n            mute: false,\n            hideControls: false,\n            showLiveFullscreenButton: false,\n          ),\n        );\n        _ytListener = () {\n          if (_ytController != null && _ytController!.value.isPlaying != _isPlaying) {\n            _isPlaying = _ytController!.value.isPlaying;\n            notifyListeners();\n          }\n        };\n        _ytController!.addListener(_ytListener!);\n        if (await stale()) return;\n        _isYoutubeSource = true;\n        _isAudioReady = true;\n        debugPrint('YouTube WebView source ready: \');\n        notifyListeners();\n        return;\n      } catch (e) {\n        debugPrint('YouTube init failed: \');\n      }\n    }\n\n    if (await stale()) return;\n    _errorMessage = 'Could not load audio for this song';\n    notifyListeners();;

const newStep4 =     // 4. Final fallback: YouTube audio stream\n    if (song.youtubeId.isNotEmpty) {\n      try {\n        if (await stale()) return;\n        final streamUrl = await _youtube.getAudioStreamUrl(song.youtubeId);\n        if (streamUrl != null && streamUrl.isNotEmpty) {\n          await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)), preload: true);\n          if (await stale()) return;\n          _isAudioReady = true;\n          debugPrint('Final fallback YouTube stream: \');\n          notifyListeners();\n          return;\n        }\n      } catch (e) {\n        debugPrint('Final fallback YouTube stream failed: \');\n      }\n    }\n\n    if (await stale()) return;\n    _errorMessage = 'Could not load audio for this song';\n    notifyListeners();;
content = content.replace(oldStep4, newStep4);

// Fix _next method - full replacement
const oldNext =   Future<void> _next() async {\n    if (_playlist.isEmpty) return;\n    if (_repeatMode == LoopMode.one) {\n      if (_isYoutubeSource && _ytController != null) {\n        _ytController!.seekTo(Duration.zero);\n        _ytController!.play();\n      } else {\n        await _player.seek(Duration.zero);\n        await _player.play();\n      }\n      return;\n    }\n    if (_isShuffled) {\n      _currentIndex = (_currentIndex + 1) % _playlist.length;\n    } else {\n      if (_currentIndex < _playlist.length - 1) {\n        _currentIndex++;\n      } else if (_repeatMode == LoopMode.all) {\n        _currentIndex = 0;\n      } else {\n        return;\n      }\n    }\n    final epoch = ++_playbackEpoch;\n    await _player.stop();\n    _ytController?.dispose();\n    _ytController = null;\n    await _loadCurrentSong(epoch: epoch);\n    if (epoch != _playbackEpoch) return;\n    if (_isYoutubeSource && _ytController != null) {\n      _ytController!.play();\n    } else if (_isAudioReady) {\n      await _player.play();\n    }\n    _isPlaying = _isAudioReady;\n    notifyListeners();\n  };
const newNext =   Future<void> _next() async {\n    if (_playlist.isEmpty) return;\n    if (_repeatMode == LoopMode.one) {\n      await _player.seek(Duration.zero);\n      await _player.play();\n      return;\n    }\n    if (_isShuffled) {\n      _currentIndex = (_currentIndex + 1) % _playlist.length;\n    } else {\n      if (_currentIndex < _playlist.length - 1) {\n        _currentIndex++;\n      } else if (_repeatMode == LoopMode.all) {\n        _currentIndex = 0;\n      } else {\n        return;\n      }\n    }\n    final epoch = ++_playbackEpoch;\n    await _player.stop();\n    await _loadCurrentSong(epoch: epoch);\n    if (epoch != _playbackEpoch) return;\n    if (_isAudioReady) {\n      await _player.play();\n    }\n    _isPlaying = _isAudioReady;\n    notifyListeners();\n  };
content = content.replace(oldNext, newNext);

// Fix downloadSong
const oldDl =     try {\n      final songIndex = _playlist.indexWhere((s) => s.youtubeId == id);\n      final key = songIndex >= 0\n          ? _songPlaybackKey(_playlist[songIndex])\n          : id;\n      final url = MelodyHubService.getFallbackMp3UrlForKey(key);\n      await DownloadService.downloadSong(\n        url: url, songId: id,\n        onProgress: (p) { _downloadProgress[id] = p; notifyListeners(); },\n      );;
const newDl =     try {\n      final streamUrl = await _youtube.getAudioStreamUrl(id);\n      final url = streamUrl ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';\n      await DownloadService.downloadSong(\n        url: url, songId: id,\n        onProgress: (p) { _downloadProgress[id] = p; notifyListeners(); },\n      );;
content = content.replace(oldDl, newDl);

// Fix loadPlaylist fallback
const oldFb =       debugPrint('Loading fallback songs...');\n      _playlist = [\n        Song(title: 'Blinding Lights', artist: 'The Weeknd', youtubeId: 'fHI8KU4kVEw', albumArt: 'https://picsum.photos/seed/song1/300/300', id: '1'),\n        Song(title: 'Shape of You', artist: 'Ed Sheeran', youtubeId: 'JGwWNGJdvx8', albumArt: 'https://picsum.photos/seed/song2/300/300', id: '2'),\n        Song(title: 'Bohemian Rhapsody', artist: 'Queen', youtubeId: 'fJ9rUzIMcZQ', albumArt: 'https://picsum.photos/seed/song3/300/300', id: '3'),\n        Song(title: 'Believer', artist: 'Imagine Dragons', youtubeId: '7wtfhZwyrcc', albumArt: 'https://picsum.photos/seed/song4/300/300', id: '4'),\n        Song(title: 'Sugar', artist: 'Maroon 5', youtubeId: '09R8_2nJtjg', albumArt: 'https://picsum.photos/seed/song5/300/300', id: '5'),\n        Song(title: 'Let Me Love You', artist: 'DJ Snake', youtubeId: 'S3JvF2JxbRU', albumArt: 'https://picsum.photos/seed/song6/300/300', id: '6'),\n        Song(title: 'See You Again', artist: 'Wiz Khalifa', youtubeId: 'RgKAFK5djSk', albumArt: 'https://picsum.photos/seed/song7/300/300', id: '7'),\n        Song(title: 'Counting Stars', artist: 'OneRepublic', youtubeId: 'hT_nvWreIhg', albumArt: 'https://picsum.photos/seed/song8/300/300', id: '8'),\n      ];\n      debugPrint('Loaded \ fallback songs');;
const newFb =       debugPrint('Loading fallback songs...');\n      _playlist = MelodyHubService.fallbackSongs.asMap().entries.map((e) {\n        final i = e.key;\n        final s = e.value;\n        return Song(\n          id: s['id']!,\n          title: s['title']!,\n          artist: s['artist']!,\n          youtubeId: s['yt']!,\n          albumArt: MelodyHubService.fallbackAlbumArt(i),\n        );\n      }).toList();\n      debugPrint('Loaded \ fallback songs');;
content = content.replace(oldFb, newFb);

fs.writeFileSync(filePath, content, 'utf-8');
console.log('MusicProvider fixed! Size: ' + originalLen + ' -> ' + content.length);
