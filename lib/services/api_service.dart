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
  static Future<http.Response> get(String endpoint) async {
    final headers = <String, String>{'Accept': 'application/json'};
    // Token opsional: endpoint katalog tetap publik, tetapi harga grosir
    // hanya dikirim Laravel untuk akun Toko/Horeca yang telah disetujui.
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return _client.get(_url(endpoint), headers: headers);
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

  // MULTIPART PUBLIC untuk registrasi yang menyertakan dokumen.
  static Future<http.Response> multipartPublic(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, String> filePaths,
  }) async {
    final request = http.MultipartRequest('POST', _url(endpoint));
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    for (final entry in filePaths.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }

    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }

  // MULTIPART AUTHENTICATED (unggah foto/file ke API Laravel).
  static Future<http.Response> multipartAuthenticated(
    String endpoint, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token autentikasi tidak ditemukan. Silakan login.');
    }

    final request = http.MultipartRequest('POST', _url(endpoint));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);

    if (fileField != null && filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
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
