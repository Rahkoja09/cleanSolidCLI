class ReformateClassName {
  static String capitalizeClassName({required String featureName}) {
    String normalized = featureName.replaceAll('_', ' ').replaceAll('-', ' ');
    List<String> words = normalized.split(' ');

    return words
        .map((word) {
          if (word.isEmpty) return "";
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join('');
  }

  static String formatToSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m[1]}_${m[2]}',
        )
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .toLowerCase();
  }
}
