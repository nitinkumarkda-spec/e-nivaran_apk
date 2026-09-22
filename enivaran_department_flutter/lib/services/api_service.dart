import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service class to handle remote network requests and portal connectivity checks.
class ApiService {
  /// Verify connectivity to the KDA e-Nivaran web portal server.
  static Future<bool> checkServerConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve summary statistics or status payload if available from backend API.
  static Future<Map<String, dynamic>?> fetchSummaryStats() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.apiBase}/stats'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Gracefully fall back on offline / cached data
    }
    return null;
  }
}
