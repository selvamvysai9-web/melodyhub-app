import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSong {
  final String id;
  final String title;
  final String artist;
  final String youtubeId;
  final String albumArt;
  final String audioPath;
  final String lyrics;
  final String language;
  final int durationSeconds;
  final DateTime createdAt;
  final String addedBy;

  const FirestoreSong({
    required this.id,
    required this.title,
    required this.artist,
    this.youtubeId = '',
    this.albumArt = '',
    this.audioPath = '',
    this.lyrics = '',
    this.language = 'en',
    this.durationSeconds = 0,
    required this.createdAt,
    this.addedBy = '',
  });

  Duration get duration => Duration(seconds: durationSeconds);

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'title': title,
    'artist': artist,
    'youtubeId': youtubeId,
    'albumArt': albumArt,
    'audioPath': audioPath,
    'lyrics': lyrics,
    'language': language,
    'durationSeconds': durationSeconds,
    'createdAt': Timestamp.fromDate(createdAt),
    'addedBy': addedBy,
  };

  factory FirestoreSong.fromFirestore(Map<String, dynamic> data) {
    final ca = data['createdAt'];
    return FirestoreSong(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      youtubeId: data['youtubeId'] as String? ?? '',
      albumArt: data['albumArt'] as String? ?? '',
      audioPath: data['audioPath'] as String? ?? '',
      lyrics: data['lyrics'] as String? ?? '',
      language: data['language'] as String? ?? 'en',
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      createdAt: ca is Timestamp ? ca.toDate() : DateTime.now(),
      addedBy: data['addedBy'] as String? ?? '',
    );
  }

  FirestoreSong copyWith({
    String? id,
    String? title,
    String? artist,
    String? youtubeId,
    String? albumArt,
    String? audioPath,
    String? lyrics,
    String? language,
    int? durationSeconds,
    DateTime? createdAt,
    String? addedBy,
  }) {
    return FirestoreSong(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      youtubeId: youtubeId ?? this.youtubeId,
      albumArt: albumArt ?? this.albumArt,
      audioPath: audioPath ?? this.audioPath,
      lyrics: lyrics ?? this.lyrics,
      language: language ?? this.language,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
