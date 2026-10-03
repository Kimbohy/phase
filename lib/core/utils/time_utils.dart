/// Convertit des minutes depuis minuit (ex. 495) en texte "08:15".
String formatMinutes(int minutes) {
  final normalized = ((minutes % 1440) + 1440) % 1440;
  final hours = (normalized ~/ 60).toString().padLeft(2, '0');
  final mins = (normalized % 60).toString().padLeft(2, '0');
  return '$hours:$mins';
}

/// Lit "07:00", "7:00", "07h00" ou "7h" et renvoie les minutes depuis minuit.
/// Renvoie null si le texte n'est pas une heure valide.
int? parseTimeToMinutes(String input) {
  final match = RegExp(r'^(\d{1,2})\s*[:hH]\s*(\d{2})?$').firstMatch(input.trim());
  if (match == null) return null;

  final hour = int.parse(match.group(1)!);
  final minute = match.group(2) == null ? 0 : int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

/// Noms courts des jours. Index 0 = lundi (weekday 1).
const dayShortNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// weekday : 1 = lundi ... 7 = dimanche (même convention que DateTime.weekday).
String dayShortName(int weekday) => dayShortNames[weekday - 1];

/// "42 min" ou "1 h 05". Arrondi à la minute supérieure.
String formatDuration(Duration duration) {
  final totalMinutes = (duration.inSeconds / 60).ceil();
  if (totalMinutes < 60) return '$totalMinutes min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '$hours h ${minutes.toString().padLeft(2, '0')}';
}