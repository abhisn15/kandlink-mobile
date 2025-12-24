import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class ApiService {
  final String baseUrl = ApiEndpoints.baseUrl;
  final http.Client _client = http.Client();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get stored access token
  Future<String?> _getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // Get stored refresh token
  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  // Store tokens
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  // Clear stored tokens
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // Get headers with authorization
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'API Error: ${response.statusCode}');
    }
  }

  // Refresh token if needed
  Future<bool> _refreshTokenIfNeeded() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl${ApiEndpoints.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['data']['tokens']['accessToken'];
        final newRefreshToken = data['data']['tokens']['refreshToken'];

        await _storeTokens(newAccessToken, newRefreshToken);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }

    return false;
  }

  // Generic GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    var response = await _client.get(uri, headers: headers);

    // If unauthorized, try to refresh token
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        final newHeaders = await _getAuthHeaders();
        response = await _client.get(uri, headers: newHeaders);
      }
    }

    return _handleResponse(response);
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final headers = await _getAuthHeaders();

    var response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    // If unauthorized, try to refresh token
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        final newHeaders = await _getAuthHeaders();
        response = await _client.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: newHeaders,
          body: body != null ? json.encode(body) : null,
        );
      }
    }

    return _handleResponse(response);
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final headers = await _getAuthHeaders();

    var response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    // If unauthorized, try to refresh token
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        final newHeaders = await _getAuthHeaders();
        response = await _client.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: newHeaders,
          body: body != null ? json.encode(body) : null,
        );
      }
    }

    return _handleResponse(response);
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getAuthHeaders();

    var response = await _client.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);

    // If unauthorized, try to refresh token
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        final newHeaders = await _getAuthHeaders();
        response = await _client.delete(Uri.parse('$baseUrl$endpoint'), headers: newHeaders);
      }
    }

    return _handleResponse(response);
  }

  // Store tokens after login/register
  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storeTokens(accessToken, refreshToken);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
