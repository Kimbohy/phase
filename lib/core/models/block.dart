import 'pomodoro.dart';

/// Une plage horaire nommée, répétée certains jours de la semaine.
class Block {
  const Block({
    required this.id,
    required this.days,
    required this.startMin,
    required this.endMin,
    required this.name,
    this.pomodoro,
  });

  final String id;
  final Set<int> days; // 1 = lundi ... 7 = dimanche
  final int startMin; // minutes depuis 00:00
  final int endMin; // si endMin <= startMin, le bloc passe minuit
  final String name;
  final Pomodoro? pomodoro;

  bool get crossesMidnight => endMin <= startMin;

  int get durationMin =>
      crossesMidnight ? (1440 - startMin) + endMin : endMin - startMin;

  Block copyWith({
    String? name,
    Set<int>? days,
    int? startMin,
    int? endMin,
    Pomodoro? pomodoro,
    bool clearPomodoro = false,
  }) {
    return Block(
      id: id, // l'identifiant ne change jamais
      days: days ?? this.days,
      startMin: startMin ?? this.startMin,
      endMin: endMin ?? this.endMin,
      name: name ?? this.name,
      pomodoro: clearPomodoro ? null : (pomodoro ?? this.pomodoro),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'd': days.toList()..sort(),
        's': startMin,
        'e': endMin,
        'n': name,
        if (pomodoro != null) 'p': pomodoro!.toJson(),
      };

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String,
      days: (json['d'] as List<dynamic>).cast<int>().toSet(),
      startMin: json['s'] as int,
      endMin: json['e'] as int,
      name: json['n'] as String,
      pomodoro: json['p'] == null
          ? null
          : Pomodoro.fromJson(json['p'] as List<dynamic>),
    );
  }
}