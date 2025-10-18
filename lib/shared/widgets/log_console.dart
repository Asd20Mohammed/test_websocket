import 'package:flutter/material.dart';

class LogConsole extends StatelessWidget {
  const LogConsole({
    super.key,
    required this.headline,
    required this.logs,
    this.headlineColor,
  });

  final String headline;
  final List<String> logs;
  final Color? headlineColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: headlineColor ?? colorScheme.surfaceContainerHighest,
            child: Text(
              headline,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
