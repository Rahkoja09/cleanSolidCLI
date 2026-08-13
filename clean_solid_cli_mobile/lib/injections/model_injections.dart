import 'package:clean_solid_cli_mobile/models/field.dart';
import 'package:clean_solid_cli_mobile/utils/anchor_helper.dart';

class ModelInjections {
  static String inject(
    String content,
    List<Field> fields,
    String name,
    String projectName,
  ) {
    final snakeName = name.toLowerCase();

    final constructorStr = fields
        .map((f) {
          if (f.isReference)
            return "    super.${f.referenceIdName},\n    super.${f.name},";
          return "    super.${f.name},";
        })
        .join('\n');

    final fromMapStr = fields
        .map((f) {
          if (f.isEnum)
            return "      ${f.name}: data['${f.snakeName}'] != null ? ${f.enumClassName}.fromString(data['${f.snakeName}'] as String) : null,";
          if (f.isReference)
            return "      ${f.referenceIdName}: data['${f.referenceIdSnake}'] as String?,\n      ${f.name}: data['${f.name}'] != null\n          ? ${f.referenceTarget}Model.fromMap(Map<String, dynamic>.from(data['${f.name}'] as Map))\n          : null,";
          if (f.type == 'DateTime')
            return "      ${f.name}: data['${f.snakeName}'] != null ? DateTime.parse(data['${f.snakeName}']) : null,";
          return "      ${f.name}: data['${f.snakeName}'] as ${f.type}?,";
        })
        .join('\n');

    final toMapStr = fields
        .map((f) {
          if (f.isEnum) return "      '${f.snakeName}': ${f.name}?.value,";
          if (f.isReference)
            return "      '${f.referenceIdSnake}': ${f.referenceIdName},";
          if (f.type == 'DateTime')
            return "      '${f.snakeName}': ${f.name}?.toIso8601String(),";
          return "      '${f.snakeName}': ${f.name},";
        })
        .join('\n');

    final fromEntityStr = fields
        .map((f) {
          if (f.isReference)
            return "      ${f.referenceIdName}: entity.${f.referenceIdName},\n      ${f.name}: entity.${f.name},";
          return "      ${f.name}: entity.${f.name},";
        })
        .join('\n');

    var result = content;

    // Imports
    final List<String> imports = [];
    for (final f in fields.where((f) => f.isEnum)) {
      imports.add(
        "import 'package:$projectName/features/$snakeName/domain/enums/${f.name}_enum.dart';",
      );
    }
    for (final f in fields.where((f) => f.isReference)) {
      imports.add(
        "import 'package:$projectName/features/${f.referenceTargetSnake}/domain/entity/${f.referenceTargetSnake}_entity.dart';",
      );
      imports.add(
        "import 'package:$projectName/features/${f.referenceTargetSnake}/data/model/${f.referenceTargetSnake}_model.dart';",
      );
    }

    if (imports.isNotEmpty) {
      final importBlock = imports.join('\n');
      final classIndex = result.indexOf('class ');
      if (classIndex != -1) {
        final insertIndex = result.lastIndexOf('\n', classIndex);
        if (insertIndex != -1) {
          result =
              '${result.substring(0, insertIndex + 1)}$importBlock\n${result.substring(insertIndex + 1)}';
        }
      }
    }

    result = replaceAnchor(
      result,
      '// [CONSTRUCTOR_ANCHOR]',
      constructorStr,
      context: 'model',
    );
    result = replaceAnchor(
      result,
      '// [FROM_MAP_ANCHOR]',
      fromMapStr,
      context: 'model',
    );
    result = replaceAnchor(
      result,
      '// [TO_MAP_ANCHOR]',
      toMapStr,
      context: 'model',
    );
    result = replaceAnchor(
      result,
      '// [FROM_ENTITY_ANCHOR]',
      fromEntityStr,
      context: 'model',
    );

    return result;
  }
}
