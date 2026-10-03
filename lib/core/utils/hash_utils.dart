/// Hash FNV-1a 32 bits. Contrairement à String.hashCode, le résultat est
/// garanti identique d'une exécution à l'autre : on s'en sert pour fabriquer
/// des identifiants stables.
int stableHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Identifiant stable d'un bloc créé par l'import (même texte = même id).
/// Ça permet de conserver les alarmes quand on réimporte le même planning.
String makeBlockId(String name, int startMin, Set<int> days) {
  final sortedDays = (days.toList()..sort()).join();
  return stableHash('$name|$startMin|$sortedDays').toRadixString(16);
}