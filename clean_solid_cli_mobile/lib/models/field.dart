import 'package:clean_solid_cli_mobile/utils/string_utils.dart';

class Field {
  final String name; // ex: birthDate
  final String type; // ex: DateTime ou Statut (pour enum)
  final String snakeName; // ex: birth_date
  final bool isEnum;
  final List<String> enumValues; // ex: ["EnAttente", "Validee", "Annulee"]
  final bool isReference; // true si reference(Boutique)
  final String referenceTarget; // ex: "Boutique" (PascalCase)
  final String referenceTargetSnake; // ex: "boutique"

  Field({
    required this.name,
    required this.type,
    this.isEnum = false,
    this.enumValues = const [],
    this.isReference = false,
    this.referenceTarget = '',
    this.referenceTargetSnake = '',
  }) : snakeName = StringUtils.toSnakeCase(name);

  /// Nom du champ FK en camelCase (ex: "boutique" → "boutiqueId")
  String get referenceIdName => '${name}Id';

  /// Nom du champ FK en snake_case pour la DB (ex: "boutique" → "boutique_id")
  String get referenceIdSnake => '${snakeName}_id';

  /// PascalCase class name pour un enum (ex: "statut" → "Statut")
  String get enumClassName {
    if (!isEnum) return '';
    return name.split('_').map((part) {
      if (part.isEmpty) return '';
      return '${part[0].toUpperCase()}${part.substring(1)}';
    }).join();
  }

  /// Valeurs de l'enum en camelCase pour Dart (ex: "EnAttente" → "enAttente")
  List<String> get dartEnumValues {
    return enumValues.map((v) {
      if (v.isEmpty) return v;
      return '${v[0].toLowerCase()}${v.substring(1)}';
    }).toList();
  }

  @override
  String toString() =>
      'Field($name: $type${isEnum ? ' [enum: $enumValues]' : ''}${isReference ? ' [ref: $referenceTarget]' : ''})';
}
