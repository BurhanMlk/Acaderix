import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlatformSettingsState {
  const PlatformSettingsState({
    this.isMaintenanceActive = false,
    this.maintenanceMessage =
        'Acaderix platform is undergoing scheduled maintenance. Services will resume shortly.',
    this.allowRegistrations = true,
  });

  final bool isMaintenanceActive;
  final String maintenanceMessage;
  final bool allowRegistrations;

  PlatformSettingsState copyWith({
    bool? isMaintenanceActive,
    String? maintenanceMessage,
    bool? allowRegistrations,
  }) {
    return PlatformSettingsState(
      isMaintenanceActive: isMaintenanceActive ?? this.isMaintenanceActive,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      allowRegistrations: allowRegistrations ?? this.allowRegistrations,
    );
  }
}

class PlatformSettingsNotifier extends Notifier<PlatformSettingsState> {
  @override
  PlatformSettingsState build() {
    return const PlatformSettingsState();
  }

  void toggleMaintenance(bool value, {String? customMessage}) {
    state = state.copyWith(
      isMaintenanceActive: value,
      maintenanceMessage: customMessage ?? state.maintenanceMessage,
    );
  }

  void toggleAllowRegistrations(bool value) {
    state = state.copyWith(allowRegistrations: value);
  }
}

final platformSettingsProvider =
    NotifierProvider<PlatformSettingsNotifier, PlatformSettingsState>(
  PlatformSettingsNotifier.new,
);
