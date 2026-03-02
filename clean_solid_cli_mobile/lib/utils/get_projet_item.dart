import 'dart:io';

class GetProjetItem {
  static String getProjectName() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return 'e_tantana';

    final content = pubspecFile.readAsLinesSync();
    final nameLine = content.firstWhere(
      (line) => line.trim().startsWith('name:'),
    );
    return nameLine.split(':')[1].trim();
  }
}
