class Field {
  final String name; // ex: birthDate ------------
  final String type; // ex: DateTime- ----
  final String snakeName; // ex: birth_date --

  Field({required this.name, required this.type})
    : snakeName = _convertToSnakeCase(name);

  static String _convertToSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match m) => '${m[1]}_${m[2]!.toLowerCase()}',
        )
        .toLowerCase();
  }
}
