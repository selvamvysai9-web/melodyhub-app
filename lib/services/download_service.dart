import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<String> downloadSong({
    required String url,
    required String songId,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final songDir = Directory('${dir.path}/melody_hub/downloads');
    if (!await songDir.exists()) await songDir.create(recursive: true);

    final filePath = '${songDir.path}/$songId.mp3';
    final file = File(filePath);

    if (await file.exists()) return filePath;

    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) throw Exception('Download failed');

      final contentLength = response.contentLength ?? -1;
      final sink = file.openWrite();
      int bytesReceived = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(bytesReceived / contentLength);
        }
      }

      await sink.close();
    } finally {
      client.close();
    }
    return filePath;
  }

  static Future<bool> isDownloaded(String songId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/melody_hub/downloads/$songId.mp3');
    return file.exists();
  }

  static Future<String?> getLocalPath(String songId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/melody_hub/downloads/$songId.mp3');
    if (await file.exists()) return file.path;
    return null;
  }

  static Future<void> deleteSong(String songId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/melody_hub/downloads/$songId.mp3');
    if (await file.exists()) await file.delete();
  }

  static Future<int> getDownloadCount() async {
    final dir = await getApplicationDocumentsDirectory();
    final songDir = Directory('${dir.path}/melody_hub/downloads');
    if (!await songDir.exists()) return 0;
    return await songDir.list().length;
  }
}
