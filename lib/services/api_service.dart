import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class ApiService {
  // Client dapat diganti saat pengujian agar request tidak menuju server asli.
  static http.Client _client = http.Client();

  @visibleForTesting
  static void setClientForTesting(http.Client client) {
    _client = client;
  }

  @visibleForTesting
  static void resetClientForTesting() {
    _client.close();
    _client = http.Client();
  }

  // Membuat URL endpoint Laravel.
  static Uri _url(String endpoint) {
    return Uri.parse('${ApiConfig.baseUrl}$endpoint');
  }

  // Header untuk request publik.
  static Map<String, String> get _publicHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Header untuk request yang membutuhkan autentikasi.
  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token autentikasi tidak ditemukan. Silakan login.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET PUBLIC
  static Future<http.Response> get(String endpoint) {
    return _client.get(_url(endpoint), headers: {'Accept': 'application/json'});
  }

  // POST PUBLIC
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return _client.post(
      _url(endpoint),
      headers: _publicHeaders,
      body: body == null ? null : jsonEncode(body),
    );
  }

  // GET AUTHENTICATED
  static Future<http.Response> getAuthenticated(String endpoint) async {
    return _client.get(_url(endpoint), headers: await _authHeaders());
  }

  // POST AUTHENTICATED
  static Future<http.Response> postAuthenticated(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _authHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);

    return _client.post(
      _url(endpoint),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
  }

  // PUT AUTHENTICATED
  static Future<http.Response> putAuthenticated(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _client.put(
      _url(endpoint),
      headers: await _authHeaders(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  // PATCH AUTHENTICATED
  static Future<http.Response> patchAuthenticated(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _client.patch(
      _url(endpoint),
      headers: await _authHeaders(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  // DELETE AUTHENTICATED
  static Future<http.Response> deleteAuthenticated(String endpoint) async {
    return _client.delete(_url(endpoint), headers: await _authHeaders());
  }
}
