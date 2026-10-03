/// Découpage d'un bloc en cycles « focus / pause ».
class Pomodoro {
  const Pomodoro({required this.focusMin, required this.breakMin});

  final int focusMin;
  final int breakMin;

  /// Format compact utilisé dans le JSON : [focus, pause].
  List<int> toJson() => [focusMin, breakMin];

  factory Pomodoro.fromJson(List<dynamic> json) {
    return Pomodoro(focusMin: json[0] as int, breakMin: json[1] as int);
  }
}