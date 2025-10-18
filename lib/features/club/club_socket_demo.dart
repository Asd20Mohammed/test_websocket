import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:test_websocket/shared/widgets/log_console.dart';

class ClubSocketDemo extends StatefulWidget {
  const ClubSocketDemo({super.key});

  @override
  State<ClubSocketDemo> createState() => _ClubSocketDemoState();
}

class _ClubSocketDemoState extends State<ClubSocketDemo> {
  static const List<String> _interestingEvents = [
    'club:joined',
    'club:left',
    'club:updated',
    'club:deleted',
    'club:user_joined',
    'club:user_left',
    'club:users_count',
    'member:added',
    'member:removed',
    'member:role_updated',
    'member:staff_added',
    'member:staff_removed',
    'member:membership_updated',
  ];

  final TextEditingController _baseUrlController = TextEditingController(
    text: 'http://localhost:3000',
  );
  final TextEditingController _pathController = TextEditingController(
    text: '/ws',
  );
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _clubIdController = TextEditingController(
    text: 'club-123',
  );

  final List<String> _logs = <String>[];
  io.Socket? _socket;
  bool _joinOnConnect = true;
  bool _joinedRoom = false;

  bool get _connected => _socket?.connected ?? false;

  @override
  void dispose() {
    _socket?.dispose();
    _baseUrlController.dispose();
    _pathController.dispose();
    _tokenController.dispose();
    _clubIdController.dispose();
    super.dispose();
  }

  void _connect() {
    final baseUrl = _baseUrlController.text.trim();
    final path = _pathController.text.trim().isEmpty
        ? '/ws'
        : _pathController.text.trim();
    final token = _tokenController.text.trim();

    if (baseUrl.isEmpty) {
      _addLog('Please enter the server base URL');
      return;
    }

    _disconnect(silent: true);
    _addLog('Connecting to $baseUrl$path');

    final builder = io.OptionBuilder()
        .setTransports(const ['websocket', 'polling'])
        .setPath(path)
        .enableAutoConnect()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(1000);

    if (token.isNotEmpty) {
      builder.setAuth({'token': token});
    }

    final options = builder.build();
    final socket = io.io(baseUrl, options);
    _socket = socket;

    socket.onConnect((_) {
      _addLog('Connected: socket id ${socket.id}');
      if (_joinOnConnect) {
        _joinClub();
      }
      setState(() {});
    });

    socket.onDisconnect((reason) {
      _addLog('Disconnected: $reason');
      setState(() {
        _joinedRoom = false;
      });
    });

    socket.onConnectError((error) {
      _addLog('Connection failed: ${_formatPayload(error)}');
    });

    socket.onError((error) {
      _addLog('Socket error: ${_formatPayload(error)}');
    });

    socket.onReconnect((attempt) {
      _addLog('Reconnected after attempt $attempt');
    });

    socket.onReconnectAttempt((attempt) {
      _addLog('Reconnect attempt $attempt');
    });

    socket.onReconnectError((error) {
      _addLog('Reconnect failed: ${_formatPayload(error)}');
    });

    socket.onReconnectFailed((_) {
      _addLog('Stopped retrying to connect');
    });

    socket.onAny((event, dynamic data) {
      if (_interestingEvents.contains(event)) {
        _addLog('Event $event\n${_formatPayload(data)}');
      }
    });

    socket.on('club:joined', (data) {
      setState(() => _joinedRoom = true);
      _addLog('Joined room successfully: ${_formatPayload(data)}');
    });

    socket.on('club:left', (data) {
      setState(() => _joinedRoom = false);
      _addLog('Left room: ${_formatPayload(data)}');
    });
  }

  void _disconnect({bool silent = false}) {
    _socket?.dispose();
    _socket = null;
    if (!silent) {
      _addLog('Disconnected manually');
    }
    setState(() {
      _joinedRoom = false;
    });
  }

  void _joinClub() {
    final clubId = _clubIdController.text.trim();
    if (!_connected) {
      _addLog('Connect to the server before joining a room');
      return;
    }
    if (clubId.isEmpty) {
      _addLog('Enter a clubId first');
      return;
    }
    _socket?.emit('club:join', {'clubId': clubId});
    _addLog('Emitted club:join for $clubId');
  }

  void _leaveClub() {
    final clubId = _clubIdController.text.trim();
    if (!_connected) {
      _addLog('No active connection');
      return;
    }
    if (!_joinedRoom) {
      _addLog('You are not in a room yet');
      return;
    }
    _socket?.emit('club:leave', {'clubId': clubId});
    _addLog('Emitted club:leave for $clubId');
  }

  void _requestUserCount() {
    final clubId = _clubIdController.text.trim();
    if (!_connected) {
      _addLog('Connect to the server first');
      return;
    }
    if (clubId.isEmpty) {
      _addLog('Enter a clubId before requesting the count');
      return;
    }
    _socket?.emit('club:get_users_count', {'clubId': clubId});
    _addLog('Requested active user count for $clubId');
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  void _addLog(String message) {
    final now = DateTime.now().toLocal().toIso8601String().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$now] $message');
    });
  }

  String _formatPayload(dynamic data) {
    if (data == null) {
      return 'No payload';
    }
    if (data is String) {
      return data;
    }
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Socket.IO playground for the ClubApp server.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(_connected ? 'Connected' : 'Disconnected'),
                backgroundColor: _connected
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                avatar: Icon(
                  _connected ? Icons.check_circle : Icons.cancel,
                  color: _connected ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
              Chip(
                label: Text(
                  _joinedRoom
                      ? 'In room: ${_clubIdController.text}'
                      : 'Not joined to a room',
                ),
                backgroundColor: _joinedRoom
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                avatar: Icon(
                  _joinedRoom ? Icons.meeting_room : Icons.door_front_door,
                  color: _joinedRoom ? Colors.blue : Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL (ex: http://localhost:3000)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: 'Socket.IO path (usually /ws)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'JWT Token',
              helperText: 'Paste the JWT issued by the login API',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clubIdController,
            decoration: const InputDecoration(
              labelText: 'Club ID',
              helperText: 'Used when joining a club room',
            ),
          ),
          CheckboxListTile(
            value: _joinOnConnect,
            onChanged: (value) =>
                setState(() => _joinOnConnect = value ?? true),
            title: const Text('Join room automatically after connect'),
            contentPadding: EdgeInsets.zero,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _connected ? null : _connect,
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
                OutlinedButton.icon(
                  onPressed: _joinedRoom ? _leaveClub : _joinClub,
                  icon: Icon(
                    _joinedRoom ? Icons.logout : Icons.meeting_room_outlined,
                  ),
                  label: Text(_joinedRoom ? 'Leave room' : 'Join room'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _requestUserCount,
                icon: const Icon(Icons.people),
                label: const Text('Request user count'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _clearLogs,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear log'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LogConsole(
              headline: 'Event log',
              logs: _logs,
              headlineColor: colorScheme.secondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
