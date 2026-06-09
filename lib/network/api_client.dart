import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient() : _client = http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getJsonObject(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    final response = await _sendGet(uri, headers: headers, timeout: timeout);
    return _decodeObject(response.body);
  }

  void close() {
    _client.close();
  }

  Future<http.Response> _sendGet(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiClientException(
          _messageForNonSuccess(response),
          statusCode: response.statusCode,
        );
      }

      return response;
    } on ApiClientException {
      rethrow;
    } on TimeoutException {
      throw const ApiClientException('Request timed out.');
    } on http.ClientException catch (error) {
      throw ApiClientException('Network error: ${error.message}');
    } on Object {
      throw const ApiClientException('Network error while sending request.');
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Response root is not an object.');
    } on FormatException catch (error) {
      throw ApiClientException('Failed to decode response: ${error.message}');
    }
  }

  String _messageForNonSuccess(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return 'HTTP error (${response.statusCode}): $message';
        }
      }
    } on FormatException {
      // Fall back to a generic status message below.
    }

    return 'HTTP error (${response.statusCode}).';
  }
}

class ApiClientException implements Exception {
  const ApiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
