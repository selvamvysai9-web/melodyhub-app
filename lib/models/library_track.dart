import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryTrack {
  final String title;
  final String artist;
  final String videoId;
  final String thumbnail;
  final String addedBy;
  final DateTime? addedAt;

  const LibraryTrack({
    required this.title,
    required this.artist,
    required this.videoId,
    required this.thumbnail,
    required this.addedBy,
    this.addedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'videoId': videoId,
      'thumbnail': thumbnail,
      'addedBy': addedBy,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory LibraryTrack.fromFirestore(Map<String, dynamic> data) {
    final addedAtRaw = data['addedAt'];
    DateTime? addedAt;
    if (addedAtRaw is Timestamp) {
      addedAt = addedAtRaw.toDate();
    }
    return LibraryTrack(
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      videoId: data['videoId'] as String? ?? '',
      thumbnail: data['thumbnail'] as String? ?? '',
      addedBy: data['addedBy'] as String? ?? 'Melody Hub User',
      addedAt: addedAt,
    );
  }
}
