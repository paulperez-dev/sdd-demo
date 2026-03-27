import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../server/server_controller.dart';

/// Main URL shortener screen.
///
/// Replaces FoundationScreen after Phase 2 wiring.
/// Accepts a long URL from the user, POSTs to the embedded server's
/// /shorten endpoint, and displays the generated short URL.
class ShortenerScreen extends StatefulWidget {
  final ServerController serverController;

  const ShortenerScreen({super.key, required this.serverController});

  @override
  State<ShortenerScreen> createState() => _ShortenerScreenState();
}

class _ShortenerScreenState extends State<ShortenerScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _loading = false;
  String? _shortUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _shorten() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _loading = true;
      _shortUrl = null;
      _errorMessage = null;
    });

    try {
      final port = widget.serverController.port;
      if (port == null) {
        setState(() {
          _errorMessage = 'Server is not running';
          _loading = false;
        });
        return;
      }

      final client = HttpClient();
      try {
        final request = await client.post('localhost', port, '/shorten');
        request.headers.contentType = ContentType.text;
        request.write(input);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final json = jsonDecode(body) as Map<String, dynamic>;
          setState(() {
            _shortUrl = json['shortUrl'] as String;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage = body.isNotEmpty ? body : 'Error ${response.statusCode}';
            _loading = false;
          });
        }
      } finally {
        client.close();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Request failed: $e';
        _loading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_shortUrl == null) return;
    Clipboard.setData(ClipboardData(text: _shortUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Short URL copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Shortener'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<ServerStatus>(
        stream: widget.serverController.statusStream,
        initialData: widget.serverController.isRunning
            ? ServerStatus.running
            : ServerStatus.stopped,
        builder: (context, snapshot) {
          final status = snapshot.data ?? ServerStatus.stopped;
          final serverRunning = status == ServerStatus.running;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server status indicator (retained from FoundationScreen).
                _ServerStatusBadge(
                  status: status,
                  port: widget.serverController.port,
                ),
                const SizedBox(height: 24),

                // URL input field.
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: serverRunning && !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Paste a URL to shorten',
                    hintText: 'https://example.com/very/long/path',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _shorten(),
                ),
                const SizedBox(height: 16),

                // Shorten button.
                FilledButton(
                  onPressed: serverRunning && !_loading ? _shorten : null,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Shorten'),
                ),

                // Result area.
                if (_shortUrl != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _shortUrl!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy to clipboard',
                            onPressed: _copyToClipboard,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Error display.
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Compact server status badge reusing the foundation pattern.
class _ServerStatusBadge extends StatelessWidget {
  final ServerStatus status;
  final int? port;

  const _ServerStatusBadge({required this.status, required this.port});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ServerStatus.running => (Colors.green, 'Running'),
      ServerStatus.starting => (Colors.orange, 'Starting\u2026'),
      ServerStatus.stopped => (Colors.grey, 'Stopped'),
      ServerStatus.error => (Colors.red, 'Error \u2014 no port available'),
    };

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('Server $label',
            style: Theme.of(context).textTheme.bodySmall),
        if (port != null) ...[
          const SizedBox(width: 8),
          Text('http://localhost:$port',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamily: 'monospace')),
        ],
      ],
    );
  }
}
