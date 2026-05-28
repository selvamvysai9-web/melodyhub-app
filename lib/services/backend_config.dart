class BackendConfig {
  static const String baseUrl = "https://melody-backend-3qsr.onrender.com";

  static String search(String query) => "$baseUrl/api/youtube/search?q=${Uri.encodeComponent(query)}";

  static String stream(String videoId) => "$baseUrl/api/youtube/audio/$videoId";

  static const String songs = "$baseUrl/api/songs";
}
