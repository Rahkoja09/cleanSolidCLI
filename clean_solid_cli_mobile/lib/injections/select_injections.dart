import 'package:clean_solid_cli_mobile/models/field.dart';

class SelectInjections {
  /// Remplace .select("*") et .select() par .select("*, relation(table)") pour le eager loading.
  /// Utilise replaceAll pour traiter TOUTES les occurrences (insert, update, search, getById).
  static String inject(String content, List<Field> fields) {
    final refFields = fields.where((f) => f.isReference).toList();
    if (refFields.isEmpty) return content;

    final relations = refFields
        .map((f) => '${f.name}(${f.referenceTargetSnake}s)')
        .join(', ');

    // 1. Remplacer TOUS les .select("*") (search/getAll)
    content = content.replaceAll('.select("*")', '.select("*, $relations")');

    // 2. Remplacer TOUS les .select() (insert, update, getById)
    content = content.replaceAll('.select()', '.select("*, $relations")');

    return content;
  }
}
