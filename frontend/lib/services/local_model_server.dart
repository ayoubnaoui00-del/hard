import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lightweight, in-app HTTP server that streams local 3D assets to the WebGL canvas.
/// This ensures 100% offline, zero-lag local WebGL rendering without WebView CORS restrictions.
class LocalModelServer {
  static HttpServer? _server;
  static int? get port => _server?.port;
  static String? get baseUrl => _server != null ? 'http://127.0.0.1:${_server!.port}' : null;

  /// Starts the loopback HTTP server on an available port if not already running.
  static Future<int> start() async {
    if (_server != null) return _server!.port;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handleRequest, onError: (err) {
        // Silently handle loopback stream errors
      });
      return _server!.port;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    // Add full CORS headers for WebGL & fetch
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final rawPath = request.uri.path;
    final path = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;

    try {
      if (path.isEmpty || path == 'index.html') {
        final content = await rootBundle.loadString('assets/models/web_viewer/index.html');
        request.response.headers.contentType = ContentType.html;
        request.response.write(content);
      } else if (path.endsWith('.glb')) {
        // Stream the 25MB anatomy.glb efficiently
        final byteData = await rootBundle.load('assets/models/anatomy.glb');
        request.response.headers.contentType = ContentType('model', 'gltf-binary');
        request.response.headers.contentLength = byteData.lengthInBytes;
        request.response.add(byteData.buffer.asUint8List());
      } else if (path.startsWith('assets/')) {
        final assetPath = 'assets/models/web_viewer/$path';
        final byteData = await rootBundle.load(assetPath);
        if (path.endsWith('.js')) {
          request.response.headers.contentType = ContentType('application', 'javascript', charset: 'utf-8');
        } else if (path.endsWith('.css')) {
          request.response.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
        }
        request.response.headers.contentLength = byteData.lengthInBytes;
        request.response.add(byteData.buffer.asUint8List());
      } else if (path == 'mesh_mapping.json') {
        final content = await rootBundle.loadString('assets/models/mesh_mapping.json');
        request.response.headers.contentType = ContentType.json;
        request.response.write(content);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
    } catch (e) {
      debugPrint('LocalModelServer error serving $path: $e');
      request.response.statusCode = HttpStatus.notFound;
    }

    await request.response.close();
  }

  /// Stops the local server
  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
