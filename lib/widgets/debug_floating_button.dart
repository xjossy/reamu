import 'package:flutter/material.dart';
import '../core/debug_config.dart';
import '../screens/debug_page.dart';

class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DebugConfig.showDebugButton) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.orange,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DebugPage(),
          ),
        );
      },
      child: const Icon(
        Icons.bug_report,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
