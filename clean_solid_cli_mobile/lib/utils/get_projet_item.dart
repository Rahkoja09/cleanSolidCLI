import 'dart:io';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';

class GetProjetItem {
  static String getProjectName() {
    // 1. Priorité : fichier de config .cscm.yaml
    if (ConfigReader.configExists()) {
      try {
        return ConfigReader.read().projectName;
      } catch (_) {}
    }

    // 2. Fallback : lire le nom depuis pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsLinesSync();
      final nameLine = content.firstWhere(
        (line) => line.trim().startsWith('name:'),
        orElse: () => '',
      );
      if (nameLine.isNotEmpty) {
        return nameLine.split(':').last.trim();
      }
    }

    // 3. Dernier recours : nom du dossier courant
    final currentDir = Directory.current.path.split(Platform.pathSeparator);
    return currentDir.isNotEmpty ? currentDir.last : 'my_app';
  }
}
