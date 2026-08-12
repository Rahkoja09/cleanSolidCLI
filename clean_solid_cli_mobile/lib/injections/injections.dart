import 'package:clean_solid_cli_mobile/models/field.dart';

class Injections {
  static String injectEntity(
    String content,
    List<Field> fields,
    String name,
    String projectName,
  ) {
    final snakeName = name.toLowerCase();

    // Pour les references, on genere 2 champs : boutiqueId (String?) + boutique (BoutiqueEntity?)
    final fieldsStr = fields
        .map((f) {
          if (f.isEnum) {
            return "  final ${f.enumClassName}? ${f.name};";
          }
          if (f.isReference) {
            return "  final String? ${f.referenceIdName};\n"
                "  final ${f.referenceTarget}Entity? ${f.name};";
          }
          return "  final ${f.type}? ${f.name};";
        })
        .join('\n');

    final constructorStr = fields
        .map((f) {
          if (f.isReference) {
            return "    this.${f.referenceIdName},\n    this.${f.name},";
          }
          return "    this.${f.name},";
        })
        .join('\n');

    final copyWithParamsStr = fields
        .map((f) {
          if (f.isEnum) {
            return "    ${f.enumClassName}? ${f.name},";
          }
          if (f.isReference) {
            return "    String? ${f.referenceIdName},\n"
                "    ${f.referenceTarget}Entity? ${f.name},";
          }
          return "    ${f.type}? ${f.name},";
        })
        .join('\n');

    final copyWithReturnStr = fields
        .map((f) {
          if (f.isReference) {
            return "      ${f.referenceIdName}: ${f.referenceIdName} ?? this.${f.referenceIdName},\n"
                "      ${f.name}: ${f.name} ?? this.${f.name},";
          }
          return "      ${f.name}: ${f.name} ?? this.${f.name},";
        })
        .join('\n');

    final propsStr = fields
        .map((f) {
          if (f.isReference) {
            return "    ${f.referenceIdName},\n    ${f.name},";
          }
          return "    ${f.name},";
        })
        .join('\n');

    var result = content;

    // Collecter tous les imports a injecter (enums + references)
    final List<String> imports = [];

    // Imports des enums
    for (final f in fields.where((f) => f.isEnum)) {
      imports.add(
        "import 'package:$projectName/features/$snakeName/domain/enums/${f.name}_enum.dart';",
      );
    }

    // Imports des entities referencees
    for (final f in fields.where((f) => f.isReference)) {
      imports.add(
        "import 'package:$projectName/features/${f.referenceTargetSnake}/domain/entity/${f.referenceTargetSnake}_entity.dart';",
      );
    }

    // Injecter les imports avant 'class '
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

    return result
        .replaceFirst('// [FIELDS_ANCHOR]', '$fieldsStr\n  // [FIELDS_ANCHOR]')
        .replaceFirst(
          '// [CONSTRUCTOR_ANCHOR]',
          '$constructorStr\n    // [CONSTRUCTOR_ANCHOR]',
        )
        .replaceFirst(
          '// [COPYWITH_PARAMS_ANCHOR]',
          '$copyWithParamsStr\n    // [COPYWITH_PARAMS_ANCHOR]',
        )
        .replaceFirst(
          '// [COPYWITH_RETURN_ANCHOR]',
          '$copyWithReturnStr\n      // [COPYWITH_RETURN_ANCHOR]',
        )
        .replaceFirst('// [PROPS_ANCHOR]', '$propsStr\n    // [PROPS_ANCHOR]');
  }

  static String injectModel(
    String content,
    List<Field> fields,
    String name,
    String projectName,
  ) {
    final snakeName = name.toLowerCase();

    // Constructor : pour references, super.boutiqueId + super.boutique
    final constructorStr = fields
        .map((f) {
          if (f.isReference) {
            return "    super.${f.referenceIdName},\n    super.${f.name},";
          }
          return "    super.${f.name},";
        })
        .join('\n');

    // fromMap : pour references, parser boutique_id (String FK) + boutique (nested object)
    final fromMapStr = fields
        .map((f) {
          if (f.isEnum) {
            return "      ${f.name}: data['${f.snakeName}'] != null ? ${f.enumClassName}.fromString(data['${f.snakeName}'] as String) : null,";
          }
          if (f.isReference) {
            return "      ${f.referenceIdName}: data['${f.referenceIdSnake}'] as String?,\n"
                "      ${f.name}: data['${f.name}'] != null\n"
                "          ? ${f.referenceTarget}Model.fromMap("
                "Map<String, dynamic>.from(data['${f.name}'] as Map))\n"
                "          : null,";
          }
          if (f.type == 'DateTime') {
            return "      ${f.name}: data['${f.snakeName}'] != null ? DateTime.parse(data['${f.snakeName}']) : null,";
          }
          return "      ${f.name}: data['${f.snakeName}'] as ${f.type}?,";
        })
        .join('\n');

    // toMap : pour references, seul le FK est envoye en DB
    final toMapStr = fields
        .map((f) {
          if (f.isEnum) {
            return "      '${f.snakeName}': ${f.name}?.value,";
          }
          if (f.isReference) {
            return "      '${f.referenceIdSnake}': ${f.referenceIdName},";
          }
          if (f.type == 'DateTime') {
            return "      '${f.snakeName}': ${f.name}?.toIso8601String(),";
          }
          return "      '${f.snakeName}': ${f.name},";
        })
        .join('\n');

    // fromEntity : pour references, copier les 2 champs
    final fromEntityStr = fields
        .map((f) {
          if (f.isReference) {
            return "      ${f.referenceIdName}: entity.${f.referenceIdName},\n"
                "      ${f.name}: entity.${f.name},";
          }
          return "      ${f.name}: entity.${f.name},";
        })
        .join('\n');

    var result = content;

    // Collecter tous les imports a injecter (enums + references)
    final List<String> imports = [];

    // Imports des enums
    for (final f in fields.where((f) => f.isEnum)) {
      imports.add(
        "import 'package:$projectName/features/$snakeName/domain/enums/${f.name}_enum.dart';",
      );
    }

    // Imports des entities + models referencees
    for (final f in fields.where((f) => f.isReference)) {
      imports.add(
        "import 'package:$projectName/features/${f.referenceTargetSnake}/domain/entity/${f.referenceTargetSnake}_entity.dart';",
      );
      imports.add(
        "import 'package:$projectName/features/${f.referenceTargetSnake}/data/model/${f.referenceTargetSnake}_model.dart';",
      );
    }

    // Injecter les imports avant 'class '
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

    return result
        .replaceFirst(
          '// [CONSTRUCTOR_ANCHOR]',
          '$constructorStr\n    // [CONSTRUCTOR_ANCHOR]',
        )
        .replaceFirst(
          '// [FROM_MAP_ANCHOR]',
          '$fromMapStr\n      // [FROM_MAP_ANCHOR]',
        )
        .replaceFirst(
          '// [TO_MAP_ANCHOR]',
          '$toMapStr\n      // [TO_MAP_ANCHOR]',
        )
        .replaceFirst(
          '// [FROM_ENTITY_ANCHOR]',
          '$fromEntityStr\n      // [FROM_ENTITY_ANCHOR]',
        );
  }

  static String injectRemoteSource(String content, List<Field> fields) {
    // Filtres : pour references, filtrer sur boutique_id avec criteria.boutiqueId
    final filtersStr = fields
        .map((f) {
          String fieldName;
          String dbCol;
          String filterLogic;

          if (f.isReference) {
            fieldName = f.referenceIdName;
            dbCol = f.referenceIdSnake;
            filterLogic = 'query = query.eq("$dbCol", $fieldName);';
          } else if (f.type == 'String') {
            fieldName = f.name;
            dbCol = f.snakeName;
            filterLogic = 'query = query.ilike("$dbCol", "%\$$fieldName%");';
          } else {
            fieldName = f.name;
            dbCol = f.snakeName;
            filterLogic = 'query = query.eq("$dbCol", $fieldName);';
          }
          return '''
        final $fieldName = criteria.$fieldName;
        if ($fieldName != null) {
          $filterLogic
        }''';
        })
        .join('\n');

    var result = content.replaceFirst(
      '// [FILTERS_ANCHOR]',
      '$filtersStr\n        // [FILTERS_ANCHOR]',
    );

    // Injecter les relations dans les select si presentes
    result = injectSelect(result, fields);

    return result;
  }

  /// Remplace .select("*") par .select("*, boutique(*)") et
  /// .select() par .select("boutique(*)") pour le eager loading des relations.
  static String injectSelect(String content, List<Field> fields) {
    final refFields = fields.where((f) => f.isReference).toList();
    if (refFields.isEmpty) return content;

    // Construire la liste des relations : "*, boutique(*), categorie(*)"
    final relations = refFields
        .map((f) => '${f.name}(${f.referenceTargetSnake}s)')
        .join(', ');
    final selectWithRelations = '*, $relations';

    // 1. Remplacer .select("*") par .select("*, boutique(*)")
    content = content.replaceFirst(
      '.select("*")',
      '.select("$selectWithRelations")',
    );

    // 2. Remplacer les autres .select() (sans argument) par .select("boutique(*)")
    // Ces appels apparaissent dans insert, update, getById
    if (refFields.isNotEmpty) {
      content = content.replaceAll('.select()', '.select("$relations")');
    }

    return content;
  }
}
