import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier managing the selected branch scope in the Academy Admin portal.
/// `null` represents "All Branches" (overall academy-wide sum).
class SelectedBranchNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final selectedBranchIdProvider =
    NotifierProvider<SelectedBranchNotifier, String?>(
  SelectedBranchNotifier.new,
);
