import 'package:clean_solid_cli_mobile/models/field.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';

class FieldParser {
  static const reservedFields = ['id', 'createdAt', 'updatedAt'];

  static List<Field> parse(String input) {
    if (input.isEmpty) return [];

    final parts = _splitRespectingParentheses(input);
    final List<Field> fields = [];
    int skipped = 0;

    for (var part in parts) {
      final kv = part.split(':');
      final fieldName = kv[0].trim();

      if (reservedFields.contains(fieldName)) {
        skipped++;
        continue;
      }

      if (kv.length != 2) {
        CliUI.warning('Champ "$part" ignoré — format invalide.');
        CliUI.info('Format : nom:type  (ex: nom:string, prix:double)');
        CliUI.info('Types : string, int, double, bool, datetime, num');
        CliUI.info('Spéciaux : enum(v1,v2), reference(Entity)');
        continue;
      }

      final rawType = kv[1].trim();

      final refMatch = RegExp(r'^(?:reference|ref)\((.+)\)$').firstMatch(rawType);
      if (refMatch != null) {
        final target = refMatch.group(1)!.trim();
        final targetSnake = ReformateClassName.formatToSnakeCase(target);
        fields.add(Field(
          name: fieldName, type: 'String', isReference: true,
          referenceTarget: target, referenceTargetSnake: targetSnake,
        ));
        continue;
      }

      final enumMatch = RegExp(r'^enum\((.+)\)$').firstMatch(rawType);
      if (enumMatch != null) {
        final values = enumMatch.group(1)!.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
        final className = fieldName.split('_').map((w) {
          if (w.isEmpty) return '';
          return '${w[0].toUpperCase()}${w.substring(1)}';
        }).join();
        fields.add(Field(name: fieldName, type: className, isEnum: true, enumValues: values));
      } else {
        final type = _mapDartType(rawType);
        fields.add(Field(name: fieldName, type: type));
      }
    }

    if (skipped > 0) {
      CliUI.info('$skipped champ(s) ignoré(s) — auto-généré(s) par CSCM : ${reservedFields.join(", ")}');
    }

    return fields;
  }

  static List<String> _splitRespectingParentheses(String input) {
    final List<String> parts = [];
    final buffer = StringBuffer();
    int depth = 0;
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '(') { depth++; buffer.write(char); }
      else if (char == ')') { depth--; buffer.write(char); }
      else if (char == ',' && depth == 0) { parts.add(buffer.toString().trim()); buffer.clear(); }
      else { buffer.write(char); }
    }
    if (buffer.isNotEmpty) parts.add(buffer.toString().trim());
    return parts;
  }

  static String _mapDartType(String input) {
    switch (input.toLowerCase()) {
      case 'string': return 'String';
      case 'int': return 'int';
      case 'double':
      case 'decimal': return 'double';
      case 'bool':
      case 'boolean': return 'bool';
      case 'datetime':
      case 'date': return 'DateTime';
      case 'num': return 'num';
      default:
        CliUI.warning('Type inconnu "$input" → mappé à dynamic');
        return 'dynamic';
    }
  }
}
