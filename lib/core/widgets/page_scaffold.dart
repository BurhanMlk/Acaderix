import 'package:flutter/material.dart';

/// Reusable page scaffold with optional app bar and padded body.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.actions,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.floatingActionButton,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: child == null
          ? null
          : SafeArea(
              child: Padding(padding: padding, child: child!),
            ),
    );
  }
}
