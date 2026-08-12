class Field {
  final String name; // ex: birthDate
  final String type; // ex: DateTime ou Statut (pour enum)
  final String snakeName; // ex: birth_date
  final bool isEnum;
  final List<String> enumValues; // ex: ["EnAttente", "Validee", "Annulee"]

  Field({
    required this.name,
    required this.type,
    this.isEnum = false,
    this.enumValues = const [],
  }) : snakeName = _convertToSnakeCase(name);

  /// PascalCase class name pour un enum (ex: "statut" → "Statut", "order_status" → "OrderStatus")
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

  static String _convertToSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match m) => '${m[1]}_${m[2]!.toLowerCase()}',
        )
        .toLowerCase();
  }

  @override
  String toString() =>
      'Field($name: $type${isEnum ? ' [enum: $enumValues]' : ''})';
}
