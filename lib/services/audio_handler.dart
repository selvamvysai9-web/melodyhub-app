import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MelodyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  static MelodyAudioHandler? _instance;

  MelodyAudioHandler() {
    _instance = this;
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: pos,
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 3],
        systemActions: const {MediaAction.seek},
      ));
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        playbackState.add(playbackState.value.copyWith(
          bufferedPosition: dur,
          controls: [
            MediaControl.skipToPrevious,
            if (_player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: const [0, 1, 3],
          systemActions: const {MediaAction.seek},
        ));
      }
    });
  }

  static MelodyAudioHandler get instance {
    if (_instance == null) {
      throw Exception("MelodyAudioHandler not initialized. Call AudioService.init first.");
    }
    return _instance!;
  }

  static void createFallback() {
    _instance = MelodyAudioHandler();
  }

  AudioPlayer get player => _player;

  Future<void> Function()? onNext;
  Future<void> Function()? onPrev;

  void setSong(String title, String artist, String? albumArt) {
    mediaItem.add(MediaItem(
      id: 'current',
      title: title,
      artist: artist,
      artUri: albumArt != null && albumArt.isNotEmpty
          ? Uri.tryParse(albumArt)
          : null,
    ));
  }

  // --- FIXED: Added try/catch for 403 Forbidden Errors ---
  Future<void> loadTrack(String audioUrl, MediaItem mediaItem) async {
    // Tell the OS what is playing
    this.mediaItem.add(mediaItem);
    
    try {
      // Safely load the raw audio URL
      await _player.setUrl(audioUrl);
      await play();
    } on PlayerException catch (e) {
      // This catches the dreaded HTTP 403 Forbidden error
      print("Just Audio Player Error: ${e.message} (Code: ${e.code})");
    } catch (e) {
      print("Unknown playback error: $e");
    }
  }

  // 3. Override standard controls so lock-screen buttons work
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (onNext != null) {
      await onNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPrev != null) {
      await onPrev!();
    }
  }
}