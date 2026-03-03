import 'package:clean_solid_cli_mobile/models/field.dart';

class FieldParser {
  static List<Field> parse(String input) {
    if (input.isEmpty) return [];

    final parts = input.split(',');
    final List<Field> fields = [];

    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length != 2) {
        print("Format de champ ignoré (invalide) : $part. Utilisez nom:type");
        continue;
      }

      final name = kv[0].trim();
      final type = _mapDartType(kv[1].trim());

      fields.add(Field(name: name, type: type));
    }

    return fields;
  }

  static String _mapDartType(String input) {
    switch (input.toLowerCase()) {
      case 'string':
        return 'String';
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
      case 'boolean':
        return 'bool';
      case 'datetime':
      case 'date':
        return 'DateTime';
      case 'num':
        return 'num';
      default:
        return 'dynamic';
    }
  }
}
