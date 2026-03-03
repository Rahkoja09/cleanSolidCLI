import 'package:clean_solid_cli_mobile/models/field.dart';

class Injections {
  static String injectEntity(String content, List<Field> fields, String name) {
    final fieldsStr = fields
        .map((f) => "  final ${f.type}? ${f.name};")
        .join('\n');
    final constructorStr = fields.map((f) => "    this.${f.name},").join('\n');
    final copyWithParamsStr = fields
        .map((f) => "    ${f.type}? ${f.name},")
        .join('\n');
    final copyWithReturnStr = fields
        .map((f) => "      ${f.name}: ${f.name} ?? this.${f.name},")
        .join('\n');
    final propsStr = fields.map((f) => "    ${f.name},").join('\n');

    return content
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

  static String injectModel(String content, List<Field> fields, String name) {
    // Pour le constructeur : super.nom ----------
    final constructorStr = fields.map((f) => "    super.${f.name},").join('\n');

    // 2. Pour fromMap : nom: data['snake_name'] as Type? -----------
    final fromMapStr = fields
        .map((f) {
          if (f.type == 'DateTime') {
            return "      ${f.name}: data['${f.snakeName}'] != null ? DateTime.parse(data['${f.snakeName}']) : null,";
          }
          return "      ${f.name}: data['${f.snakeName}'] as ${f.type}?,";
        })
        .join('\n');

    //our toMap : 'snake_name': nom ------
    final toMapStr = fields
        .map((f) {
          if (f.type == 'DateTime') {
            return "      '${f.snakeName}': ${f.name}?.toIso8601String(),";
          }
          return "      '${f.snakeName}': ${f.name},";
        })
        .join('\n');

    //Pour fromEntity : nom: entity.nom --
    final fromEntityStr = fields
        .map((f) => "      ${f.name}: entity.${f.name},")
        .join('\n');

    return content
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
    final filtersStr = fields
        .map((f) {
          String filterLogic;

          if (f.type == 'String') {
            filterLogic =
                'query = query.ilike("${f.snakeName}", "%\$${f.name}%");';
          } else {
            filterLogic = 'query = query.eq("${f.snakeName}", ${f.name});';
          }

          return '''
        final ${f.name} = criteria.${f.name};
        if (${f.name} != null) {
          $filterLogic
        }''';
        })
        .join('\n');

    return content.replaceFirst(
      '// [FILTERS_ANCHOR]',
      '$filtersStr\n        // [FILTERS_ANCHOR]',
    );
  }
}
