import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// Server lifecycle states surfaced to the UI.
enum ServerStatus { stopped, starting, running, error }

/// ServerController manages the embedded shelf HTTP server lifecycle.
///
/// Design decisions:
/// - Binds to 127.0.0.1 (InternetAddress.loopbackIPv4) ONLY — never 0.0.0.0
///   (binding to 0.0.0.0 would expose the server to the local network)
/// - Port-scan fallback: tries ports [8080, 8081, 8082] in order
/// - Wraps HttpServer.bind in try/catch for SocketException (Pitfall 1)
/// - stop() calls server.close(forceClose: true) (Pitfall 2)
/// - Server runs on the main isolate event loop (shelf_io is non-blocking async)
class ServerController {
  static const List<int> _candidatePorts = [8080, 8081, 8082];

  HttpServer? _server;
  int? _port;

  final _statusController = StreamController<ServerStatus>.broadcast();

  /// Stream of server lifecycle status changes for the UI to observe.
  Stream<ServerStatus> get statusStream => _statusController.stream;

  /// The port the server is actually bound to. Null if not running.
  int? get port => _port;

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// Start the embedded HTTP server.
  ///
  /// Tries ports [8080, 8081, 8082] in order. If all fail, emits
  /// [ServerStatus.error] and throws a [StateError].
  Future<void> start() async {
    if (_server != null) return; // already running — idempotent
    _statusController.add(ServerStatus.starting);

    final handler = _buildHandler();

    for (final candidatePort in _candidatePorts) {
      final server = await _tryBind(handler, candidatePort);
      if (server != null) {
        _server = server;
        _port = server.port;
        _statusController.add(ServerStatus.running);
        return;
      }
    }

    // All candidate ports failed.
    _statusController.add(ServerStatus.error);
    throw StateError(
      'Could not bind to any of $_candidatePorts. '
      'Check that no other process is using these ports.',
    );
  }

  /// Stop the embedded HTTP server cleanly.
  ///
  /// Uses forceClose: true to ensure the port is released immediately,
  /// preventing "Address already in use" errors on hot restart (Pitfall 2).
  Future<void> stop() async {
    if (_server == null) return; // already stopped — idempotent
    await _server!.close(force: true);
    _server = null;
    _port = null;
    _statusController.add(ServerStatus.stopped);
  }

  /// Dispose of the status stream. Call after stop().
  Future<void> dispose() async {
    await stop();
    await _statusController.close();
  }

  /// Attempt to bind to a specific port. Returns null on SocketException
  /// (port already in use), allowing the caller to try the next port.
  Future<HttpServer?> _tryBind(Handler handler, int port) async {
    try {
      return await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4, // 127.0.0.1, never 0.0.0.0
        port,
        shared: false,
      );
    } on SocketException {
      // Port is occupied — caller will try the next candidate.
      return null;
    }
  }

  /// Build the shelf request handler.
  ///
  /// Foundation phase: minimal handler with a health-check route only.
  /// URL shortener routes (POST /shorten, GET /[slug]) are added in Phase 2.
  Handler _buildHandler() {
    final router = Router();

    router.get('/health', (Request request) {
      return Response.ok('OK');
    });

    // Fallback for unmatched routes.
    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Not found');
    });

    return const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }
}
