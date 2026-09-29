import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

enum AlertSeverity {
  critical('CRITICAL', Colors.redAccent, HugeIcons.strokeRoundedAlertCircle),
  warning('WARNING', Colors.amberAccent, HugeIcons.strokeRoundedAlert02),
  info(
    'INFO',
    Colors.lightBlueAccent,
    HugeIcons.strokeRoundedInformationCircle,
  ),
  unknown('UNKNOWN', Colors.grey, HugeIcons.strokeRoundedHelpCircle);

  const AlertSeverity(this.value, this.color, this.icon);

  final String value;
  final Color color;
  final List<List<dynamic>> icon;

  static AlertSeverity fromString(String? raw) {
    if (raw == null) return AlertSeverity.unknown;
    return AlertSeverity.values.firstWhere(
      (e) => e.value == raw.toUpperCase().trim(),
      orElse: () => AlertSeverity.unknown,
    );
  }
}

enum AlertType {
  // --- 1. GEOVALLA ---
  geofenceBreach('GEOFENCE_BREACH', isRecovery: false),
  geofenceRestored('GEOFENCE_RESTORED', isRecovery: true),

  // --- 2. BATERÍA ---
  lowBattery('LOW_BATTERY', isRecovery: false),
  batteryCritical('BATTERY_CRITICAL', isRecovery: false),
  batteryNormal('BATTERY_NORMAL', isRecovery: true),

  // --- 3. SATÉLITES / GPS ---
  noGpsFix('NO_GPS_FIX', isRecovery: false),
  gpsFixRestored('GPS_FIX_RESTORED', isRecovery: true),

  // --- 4. RADIOENLACE LORA ---
  weakSignal('WEAK_SIGNAL', isRecovery: false),
  signalNormal('SIGNAL_NORMAL', isRecovery: true),

  // Fallback para eventos no reconocidos
  unknown('UNKNOWN', isRecovery: false);

  const AlertType(this.value, {required this.isRecovery});

  final String value;
  final bool isRecovery;

  static AlertType fromString(String? raw) {
    if (raw == null) return AlertType.unknown;
    return AlertType.values.firstWhere(
      (e) => e.value == raw.toUpperCase().trim(),
      orElse: () => AlertType.unknown,
    );
  }

  String get translationKey => 'alert_${value.toLowerCase()}';
}
