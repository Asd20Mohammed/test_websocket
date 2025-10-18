import 'package:flutter/material.dart';
import 'package:test_websocket/features/club/club_socket_demo.dart';
import 'package:test_websocket/features/echo/echo_websocket_demo.dart';

class WebSocketDemoHome extends StatelessWidget {
  const WebSocketDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WebSocket Playground'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Echo Server'),
              Tab(text: 'ClubApp Socket.IO'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EchoWebSocketDemo(),
            ClubSocketDemo(),
          ],
        ),
      ),
    );
  }
}
