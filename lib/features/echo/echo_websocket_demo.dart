import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:test_websocket/shared/widgets/log_console.dart';

class EchoWebSocketDemo extends StatefulWidget {
  const EchoWebSocketDemo({super.key});

  @override
  State<EchoWebSocketDemo> createState() => _EchoWebSocketDemoState();
}

class _EchoWebSocketDemoState extends State<EchoWebSocketDemo> {
  static const _defaultEchoUrl = 'wss://echo.websocket.events';

  final TextEditingController _urlController = TextEditingController(
    text: _defaultEchoUrl,
  );
  final TextEditingController _messageController = TextEditingController();

  final List<String> _logs = <String>[];
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnecting = false;

  bool get _connected => _channel != null && !_isConnecting;

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _connect() {
    final rawUrl = _urlController.text.trim();
    final uri = Uri.tryParse(rawUrl);

    if (uri == null || uri.scheme.isEmpty) {
      _addLog('Invalid URL: $rawUrl');
      return;
    }

    _disconnect();
    setState(() => _isConnecting = true);
    _addLog('Opening connection to $rawUrl');

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        (dynamic data) {
          _addLog('Incoming message: $data');
        },
        onError: (error) {
          _addLog('Error received: $error');
          _disconnect(silent: true);
        },
        onDone: () {
          _addLog('Connection closed by server');
          _disconnect(silent: true);
        },
      );
      _addLog('Ready: send a message to see the echo');
    } catch (error) {
      _addLog('Failed to establish connection: $error');
      _disconnect(silent: true);
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _disconnect({bool silent = false}) {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    if (!silent) {
      _addLog('Disconnected manually');
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _sendMessage() {
    if (!_connected) {
      _addLog('Connect before sending messages');
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _addLog('Enter a message before sending');
      return;
    }

    _channel?.sink.add(message);
    _addLog('Sent: $message');
    _messageController.clear();
  }

  void _addLog(String message) {
    final now = DateTime.now().toLocal().toIso8601String().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$now] $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hands-on playground for a raw WebSocket echo server. '
            'Use the public echo endpoint to test instantly.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'WebSocket URL',
              helperText: 'Change this to any endpoint that speaks WS/WSS',
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _connected || _isConnecting ? null : _connect,
                  icon: const Icon(Icons.wifi),
                  label: const Text('Connect'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _connected ? _disconnect : null,
                  icon: const Icon(Icons.wifi_off),
                  label: const Text('Disconnect'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    _messageController.text = 'Hello WebSocket';
                    _sendMessage();
                  },
                  child: const Text('Send sample message'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Message to send',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LogConsole(
              headline: _connected ? 'Connected to server' : 'Disconnected',
              logs: _logs,
              headlineColor: colorScheme.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
