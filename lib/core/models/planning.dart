import 'block.dart';

/// L'ensemble des blocs de la semaine type.
class Planning {
  const Planning({required this.name, required this.blocks});

  static const empty = Planning(name: 'Mon planning', blocks: []);

  final String name;
  final List<Block> blocks;

  /// Blocs d'un jour (1 = lundi ... 7 = dimanche), triés par heure de début.
  List<Block> blocksForDay(int weekday) {
    return blocks.where((b) => b.days.contains(weekday)).toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
  }

  /// Ajoute le bloc, ou remplace celui qui a le même id.
  Planning withBlock(Block block) {
    final exists = blocks.any((b) => b.id == block.id);
    final updated = exists
        ? [for (final b in blocks) b.id == block.id ? block : b]
        : [...blocks, block];
    return Planning(name: name, blocks: updated);
  }

  Planning withoutBlock(String id) {
    return Planning(name: name, blocks: blocks.where((b) => b.id != id).toList());
  }

  Map<String, dynamic> toJson() => {
        'v': 1, // version du format, pour pouvoir migrer plus tard
        'name': name,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory Planning.fromJson(Map<String, dynamic> json) {
    return Planning(
      name: json['name'] as String,
      blocks: (json['blocks'] as List<dynamic>)
          .map((b) => Block.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}