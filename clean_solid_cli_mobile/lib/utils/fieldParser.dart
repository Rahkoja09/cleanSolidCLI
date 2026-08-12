import 'package:clean_solid_cli_mobile/models/field.dart';

class FieldParser {
  static List<Field> parse(String input) {
    if (input.isEmpty) return [];

    final parts = _splitRespectingParentheses(input);
    final List<Field> fields = [];

    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length != 2) {
        print("Format de champ ignoré (invalide) : $part. Utilisez nom:type");
        continue;
      }

      final name = kv[0].trim();
      final rawType = kv[1].trim();

      // Detection des enums : statut:enum(EnAttente,Validee,Annulee)
      final enumMatch = RegExp(r'^enum\((.+)\)$').firstMatch(rawType);
      if (enumMatch != null) {
        final values =
            enumMatch
                .group(1)!
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList();
        final className =
            name.split('_').map((w) {
              if (w.isEmpty) return '';
              return '${w[0].toUpperCase()}${w.substring(1)}';
            }).join();
        fields.add(
          Field(name: name, type: className, isEnum: true, enumValues: values),
        );
      } else {
        final type = _mapDartType(rawType);
        fields.add(Field(name: name, type: type));
      }
    }

    return fields;
  }

  /// Split sur les virgules SAUF celles entre parentheses
  static List<String> _splitRespectingParentheses(String input) {
    final List<String> parts = [];
    final buffer = StringBuffer();
    int depth = 0;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '(') {
        depth++;
        buffer.write(char);
      } else if (char == ')') {
        depth--;
        buffer.write(char);
      } else if (char == ',' && depth == 0) {
        parts.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }

    return parts;
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
