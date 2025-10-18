import 'package:flutter/material.dart';
import 'package:test_websocket/app/websocket_demo_home.dart';

void main() {
  runApp(const WebSocketDemoApp());
}
class WebSocketDemoApp extends StatelessWidget {
  const WebSocketDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Playground',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WebSocketDemoHome(),
    );
  }
}
