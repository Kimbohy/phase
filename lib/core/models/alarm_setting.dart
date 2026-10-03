/// Réglage d'alarme d'un bloc (activée à la main par l'utilisateur).
class AlarmSetting {
  const AlarmSetting({
    required this.blockId,
    required this.enabled,
    required this.offsetMin,
  });

  final String blockId;
  final bool enabled;
  final int offsetMin; // 0 = au début du bloc, 5 = 5 min avant...

  AlarmSetting copyWith({bool? enabled, int? offsetMin}) {
    return AlarmSetting(
      blockId: blockId,
      enabled: enabled ?? this.enabled,
      offsetMin: offsetMin ?? this.offsetMin,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': blockId,
    'on': enabled,
    'off': offsetMin,
  };

  factory AlarmSetting.fromJson(Map<String, dynamic> json) => AlarmSetting(
    blockId: json['id'] as String,
    enabled: json['on'] as bool,
    offsetMin: json['off'] as int,
  );
}
