import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String _secret = dotenv.env['ADMIN_SECRET_KEY'] ?? "";

  Future<void> sendAdminAction(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'x-admin-secret': _secret,
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception("Admin action failed: ${response.body}");
    }
  }
}
