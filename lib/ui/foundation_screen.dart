import 'package:flutter/material.dart';
import '../server/server_controller.dart';

class FoundationScreen extends StatelessWidget {
  final ServerController serverController;

  const FoundationScreen({
    super.key,
    required this.serverController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Shortener'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: StreamBuilder<ServerStatus>(
          stream: serverController.statusStream,
          // initialData covers the window before the first stream event.
          initialData: serverController.isRunning
              ? ServerStatus.running
              : ServerStatus.stopped,
          builder: (context, snapshot) {
            final status = snapshot.data ?? ServerStatus.stopped;
            return _ServerStatusCard(
              status: status,
              port: serverController.port,
            );
          },
        ),
      ),
    );
  }
}

class _ServerStatusCard extends StatelessWidget {
  final ServerStatus status;
  final int? port;

  const _ServerStatusCard({required this.status, required this.port});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ServerStatus.running => (Colors.green, 'Running'),
      ServerStatus.starting => (Colors.orange, 'Starting…'),
      ServerStatus.stopped => (Colors.grey, 'Stopped'),
      ServerStatus.error => (Colors.red, 'Error — no port available'),
    };

    return Card(
      margin: const EdgeInsets.all(32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Server $label',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (port != null) ...[
              const SizedBox(height: 8),
              // Display the ACTUAL bound port from serverController.port.
              // This is never hardcoded — if the server bound to 8081
              // due to port fallback, this correctly shows 8081.
              Text(
                'http://localhost:$port',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
