import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/services/api_service.dart';
import 'package:gymtrack/services/storage_service.dart';

// Fake in-memory storage for testing without platform channels
class FakeStorageService extends StorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveToken(String token) async {
    _data['gymtrack_auth_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _data['gymtrack_auth_token'];
  }

  @override
  Future<void> deleteToken() async {
    _data.remove('gymtrack_auth_token');
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _data['gymtrack_refresh_token'] = token;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _data['gymtrack_refresh_token'];
  }

  @override
  Future<void> deleteRefreshToken() async {
    _data.remove('gymtrack_refresh_token');
  }

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _data['gymtrack_auth_token'] = accessToken;
    _data['gymtrack_refresh_token'] = refreshToken;
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

void main() {
  late FakeStorageService fakeStorage;
  late ApiService apiService;

  setUp(() {
    fakeStorage = FakeStorageService();
    apiService = ApiService(
      storageService: fakeStorage,
      baseUrl: 'http://mock-api.local',
    );
  });

  group('ApiService Setup & Interceptors', () {
    test('attaches Authorization header when token is stored', () async {
      await fakeStorage.saveToken('test-access-token');

      // Intercept request with custom adapter
      apiService.rawDio.httpClientAdapter = _MockHttpAdapter((options) async {
        expect(options.headers['Authorization'], 'Bearer test-access-token');
        expect(options.headers['X-Request-ID'], isNotNull);
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': 'ok'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiService.get('/test');
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
    });

    test('omits Authorization header when no token is present', () async {
      apiService.rawDio.httpClientAdapter = _MockHttpAdapter((options) async {
        expect(options.headers['Authorization'], isNull);
        expect(options.headers['X-Request-ID'], isNotNull);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiService.get('/public');
      expect(response.statusCode, 200);
    });

    test('parses error response into ApiException', () async {
      apiService.rawDio.httpClientAdapter = _MockHttpAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Invalid credentials'}),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      expect(
        () async => await apiService.post('/auth/login', data: {}),
        throwsA(
          isA<DioException>().having(
            (e) => (e.error as ApiException).message,
            'error message',
            'Invalid credentials',
          ),
        ),
      );
    });

    test('streamChat correctly decodes SSE events', () async {
      apiService.rawDio.httpClientAdapter = _MockHttpAdapter((options) async {
        final ssePayload = 'data: {"chunk":"Hello"}\n\ndata: {"chunk":" World"}\n\ndata: [DONE]\n\n';
        final stream = Stream<Uint8List>.fromIterable([
          Uint8List.fromList(utf8.encode(ssePayload)),
        ]);
        return ResponseBody(
          stream,
          200,
          headers: {
            Headers.contentTypeHeader: ['text/event-stream'],
          },
        );
      });

      final events = <String>[];
      await for (final event in apiService.streamChat('/agent/chat', {'message': 'hi'})) {
        events.add(event);
      }

      expect(events.length, 2);
      expect(events[0], '{"chunk":"Hello"}');
      expect(events[1], '{"chunk":" World"}');
    });
  });
}

class _MockHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
