import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;
  final DateTime createdAt;
  final List<String> savedPlaylists;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL = '',
    required this.createdAt,
    this.savedPlaylists = const [],
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoURL': photoURL,
    'createdAt': Timestamp.fromDate(createdAt),
    'savedPlaylists': savedPlaylists,
  };

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.parse(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    return UserProfile(
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoURL: data['photoURL'] as String? ?? '',
      createdAt: createdAt,
      savedPlaylists: (data['savedPlaylists'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    DateTime? createdAt,
    List<String>? savedPlaylists,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      savedPlaylists: savedPlaylists ?? this.savedPlaylists,
    );
  }
}
