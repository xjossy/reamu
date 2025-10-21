import 'package:flutter/material.dart';
import '../core/debug_config.dart';
import '../screens/debug_page.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  
  const DebugOverlay({
    super.key,
    required this.child,
  });

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (DebugConfig.showDebugButton) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDebugButton();
      });
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showDebugButton() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 16,
        right: 16,
        child: Material(
          type: MaterialType.transparency,
          child: FloatingActionButton(
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
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
