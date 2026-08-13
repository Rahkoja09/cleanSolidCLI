import 'package:clean_solid_cli_mobile/models/field.dart';
import 'package:clean_solid_cli_mobile/utils/anchor_helper.dart';

class EntityInjections {
  static String inject(
    String content,
    List<Field> fields,
    String name,
    String projectName,
  ) {
    final snakeName = name.toLowerCase();

    final fieldsStr = fields
        .map((f) {
          if (f.isEnum) return "  final ${f.enumClassName}? ${f.name};";
          if (f.isReference) {
            return "  final String? ${f.referenceIdName};\n  final ${f.referenceTarget}Entity? ${f.name};";
          }
          return "  final ${f.type}? ${f.name};";
        })
        .join('\n');

    final constructorStr = fields
        .map((f) {
          if (f.isReference)
            return "    this.${f.referenceIdName},\n    this.${f.name},";
          return "    this.${f.name},";
        })
        .join('\n');

    final copyWithParamsStr = fields
        .map((f) {
          if (f.isEnum) return "    ${f.enumClassName}? ${f.name},";
          if (f.isReference)
            return "    String? ${f.referenceIdName},\n    ${f.referenceTarget}Entity? ${f.name},";
          return "    ${f.type}? ${f.name},";
        })
        .join('\n');

    final copyWithReturnStr = fields
        .map((f) {
          if (f.isReference)
            return "      ${f.referenceIdName}: ${f.referenceIdName} ?? this.${f.referenceIdName},\n      ${f.name}: ${f.name} ?? this.${f.name},";
          return "      ${f.name}: ${f.name} ?? this.${f.name},";
        })
        .join('\n');

    final propsStr = fields
        .map((f) {
          if (f.isReference) return "    ${f.referenceIdName},\n    ${f.name},";
          return "    ${f.name},";
        })
        .join('\n');

    var result = content;

    // Imports des enums + references
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
      '// [FIELDS_ANCHOR]',
      fieldsStr,
      context: 'entity',
    );
    result = replaceAnchor(
      result,
      '// [CONSTRUCTOR_ANCHOR]',
      constructorStr,
      context: 'entity',
    );
    result = replaceAnchor(
      result,
      '// [COPYWITH_PARAMS_ANCHOR]',
      copyWithParamsStr,
      context: 'entity',
    );
    result = replaceAnchor(
      result,
      '// [COPYWITH_RETURN_ANCHOR]',
      copyWithReturnStr,
      context: 'entity',
    );
    result = replaceAnchor(
      result,
      '// [PROPS_ANCHOR]',
      propsStr,
      context: 'entity',
    );

    return result;
  }
}
