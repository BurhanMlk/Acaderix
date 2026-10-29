import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state.dart';
import 'error_state.dart';
import 'skeleton.dart';

/// Renders loading, error, empty and data states for a `List<T>` [AsyncValue].
class AsyncListState<T> extends StatelessWidget {
  const AsyncListState({
    super.key,
    required this.value,
    required this.builder,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.onRetry,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(List<T> items) builder;
  final String emptyTitle;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const SkeletonList(),
      error: (error, _) =>
          ErrorState(message: error.toString(), onRetry: onRetry),
      data: (items) => items.isEmpty
          ? EmptyState(title: emptyTitle, message: emptyMessage)
          : builder(items),
    );
  }
}
