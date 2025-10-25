import 'package:flutter/material.dart';

/// A wrapper widget that handles pop events for a page
/// 
/// This wrapper tracks when a page is popped and calls an optional callback.
/// Useful for managing page lifecycle in flows.
class PageWrapper extends StatelessWidget {
  /// The child widget to wrap
  final Widget child;
  
  /// Whether the page can be popped normally
  final bool canPop;
  
  /// Callback called when the page is popped
  final VoidCallback? onPop;
  
  const PageWrapper({
    super.key,
    required this.child,
    this.canPop = true,
    this.onPop,
  });
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && onPop != null) {
          onPop!();
        }
      },
      child: child,
    );
  }
}

