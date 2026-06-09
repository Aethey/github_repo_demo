import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:github_repository_list_app/network/api_client.dart';

void main() {
  test('ApiClient returns decoded JSON object for a successful GET', () async {
    final server = await _TestServer.start((request) async {
      expect(request.method, 'GET');
      expect(request.headers.value('x-test-header'), 'enabled');

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<String, Object>{'ok': true, 'count': 3}));
    });
    addTearDown(server.close);

    final client = ApiClient();
    addTearDown(client.close);

    final json = await client.getJsonObject(
      server.uri,
      headers: const <String, String>{'x-test-header': 'enabled'},
      timeout: const Duration(seconds: 1),
    );

    expect(json, <String, Object>{'ok': true, 'count': 3});
  });

  test('ApiClient throws ApiClientException for non-2xx responses', () async {
    final server = await _TestServer.start((request) async {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<String, Object>{'message': 'rate limited'}));
    });
    addTearDown(server.close);

    final client = ApiClient();
    addTearDown(client.close);

    expect(
      () => client.getJsonObject(
        server.uri,
        headers: const <String, String>{},
        timeout: const Duration(seconds: 1),
      ),
      throwsA(
        isA<ApiClientException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              contains('rate limited'),
            ),
      ),
    );
  });

  test('ApiClient throws ApiClientException for invalid JSON', () async {
    final server = await _TestServer.start((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('not json');
    });
    addTearDown(server.close);

    final client = ApiClient();
    addTearDown(client.close);

    expect(
      () => client.getJsonObject(
        server.uri,
        headers: const <String, String>{},
        timeout: const Duration(seconds: 1),
      ),
      throwsA(
        isA<ApiClientException>().having(
          (error) => error.message,
          'message',
          contains('Failed to decode response'),
        ),
      ),
    );
  });
}

class _TestServer {
  const _TestServer(this._server);

  final HttpServer _server;

  Uri get uri {
    return Uri.parse('http://localhost:${_server.port}/test');
  }

  static Future<_TestServer> start(
    Future<void> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        await handler(request);
      } finally {
        await request.response.close();
      }
    });
    return _TestServer(server);
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}
