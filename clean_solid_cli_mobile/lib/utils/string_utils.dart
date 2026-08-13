class StringUtils {
  static String toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .toLowerCase();
  }

  static String toPascalCase(String input) {
    final normalized = input.replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join();
  }
}
