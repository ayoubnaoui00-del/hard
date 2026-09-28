import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? code;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.code,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message, code: $code)';
}

class ApiService {
  final StorageService _storageService;
  final void Function()? _onUnauthorized;
  late final Dio _dio;
  late final Dio _tokenDio;

  final _uuid = const Uuid();
  Completer<String?>? _refreshCompleter;

  ApiService({
    required StorageService storageService,
    void Function()? onUnauthorized,
    String? baseUrl,
  })  : _storageService = storageService,
        _onUnauthorized = onUnauthorized {
    final defaultBaseUrl = baseUrl ?? AppConstants.apiBaseUrl;

    final baseOptions = BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(baseOptions);
    _tokenDio = Dio(baseOptions); // Dedicated instance without interceptors for refreshing

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Add unique Request ID for tracing
          options.headers['X-Request-ID'] = _uuid.v4();

          // 2. Attach Authorization header if access token exists
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException err, handler) async {
          final statusCode = err.response?.statusCode;
          final requestPath = err.requestOptions.path;

          // Don't intercept auth login/register/refresh endpoints on 401
          final isAuthEndpoint = requestPath.contains('/auth/login') ||
              requestPath.contains('/auth/register') ||
              requestPath.contains('/auth/refresh');

          if (statusCode == 401 && !isAuthEndpoint) {
            final refreshedToken = await _handleTokenRefresh();
            if (refreshedToken != null) {
              // Retry original request with newly acquired access token
              final opts = Options(
                method: err.requestOptions.method,
                headers: Map<String, dynamic>.from(err.requestOptions.headers)
                  ..['Authorization'] = 'Bearer $refreshedToken',
                responseType: err.requestOptions.responseType,
                contentType: err.requestOptions.contentType,
              );

              try {
                final retryResponse = await _dio.request(
                  err.requestOptions.path,
                  data: err.requestOptions.data,
                  queryParameters: err.requestOptions.queryParameters,
                  options: opts,
                );
                return handler.resolve(retryResponse);
              } on DioException catch (retryErr) {
                return handler.reject(retryErr);
              }
            } else {
              _onUnauthorized?.call();
            }
          }

          // Format clean ApiException
          final parsedError = _parseError(err);
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              response: err.response,
              type: err.type,
              error: parsedError,
            ),
          );
        },
      ),
    );
  }

  /// Handles synchronized token refresh to prevent concurrent refresh storms
  Future<String?> _handleTokenRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final currentRefreshToken = await _storageService.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        await _storageService.clearAll();
        _refreshCompleter!.complete(null);
        return null;
      }

      final response = await _tokenDio.post(
        '/auth/refresh',
        data: {'refreshToken': currentRefreshToken},
      );

      if (response.statusCode == 200 && response.data?['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        await _storageService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      } else {
        await _storageService.clearAll();
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] Token refresh failed: $e');
      await _storageService.clearAll();
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Parse backend error responses into an ApiException
  ApiException _parseError(DioException err) {
    final status = err.response?.statusCode;
    final resData = err.response?.data;

    String message = 'An unexpected error occurred';
    String? code;

    if (resData is Map<String, dynamic>) {
      if (resData['error'] != null) {
        message = resData['error'].toString();
      } else if (resData['message'] != null) {
        message = resData['message'].toString();
      }
      if (resData['code'] != null) {
        code = resData['code'].toString();
      }
    } else {
      switch (status) {
        case 400:
          message = 'Bad request';
          break;
        case 401:
          message = 'Unauthorized. Please log in again.';
          break;
        case 403:
          message = 'Access denied. You do not have permission.';
          break;
        case 404:
          message = 'The requested resource was not found.';
          break;
        case 500:
          message = 'Internal server error. Please try again later.';
          break;
        default:
          if (err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout) {
            message = 'Connection timed out. Please check your network.';
          } else if (err.type == DioExceptionType.connectionError) {
            message = 'Cannot connect to server. Please check your network.';
          }
      }
    }

    return ApiException(
      message: message,
      statusCode: status,
      data: resData,
      code: code,
    );
  }

  // --- Core HTTP Methods ---

  Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      endpoint,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Server-Sent Events (SSE) stream for AI Agent Chat
  Stream<String> streamChat(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      endpoint,
      data: body,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    final stream = response.data?.stream;
    if (stream == null) return;

    String buffer = '';

    await for (final chunk in stream) {
      final decoded = utf8.decode(chunk);
      buffer += decoded;

      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // Retain remainder if chunk ended mid-line

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('data: ')) {
          final eventData = trimmed.substring(6).trim();
          if (eventData == '[DONE]') {
            return;
          }
          yield eventData;
        }
      }
    }
  }

  Dio get rawDio => _dio;
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiService(
    storageService: storageService,
    onUnauthorized: () {
      // Clear local auth session state on unauthorized
    },
  );
});
