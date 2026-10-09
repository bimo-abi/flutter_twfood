import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class ApiService {
  // ============================================================
  // GET PUBLIC
  // ============================================================

  static Future<http.Response> get(String endpoint) {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return http.get(url);
  }

  // ============================================================
  // POST PUBLIC
  // ============================================================

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  // ============================================================
  // GET AUTHENTICATED
  // ============================================================

  static Future<http.Response> getAuthenticated(String endpoint) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  // ============================================================
  // POST AUTHENTICATED
  // ============================================================

  static Future<http.Response> postAuthenticated(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  // ============================================================
  // PUT AUTHENTICATED
  // ============================================================

  static Future<http.Response> putAuthenticated(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  // ============================================================
  // DELETE AUTHENTICATED
  // ============================================================

  static Future<http.Response> deleteAuthenticated(String endpoint) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return http.delete(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }
}
