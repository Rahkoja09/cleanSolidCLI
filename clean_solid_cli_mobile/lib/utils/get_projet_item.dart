import 'dart:io';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';

class GetProjetItem {
  static String getProjectName() {
    // 1. Source de verite : le nom du package dans pubspec.yaml
    //    C'est ce que Dart utilise pour les imports package:xxx
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsLinesSync();
      final nameLine = content.firstWhere(
        (line) => line.trim().startsWith('name:'),
        orElse: () => '',
      );
      if (nameLine.isNotEmpty) {
        final pubspecName = nameLine.split(':').last.trim();

        // Verifier que .cscm.yaml est a jour, le corriger si besoin
        _syncConfigIfNeeded(pubspecName);

        return pubspecName;
      }
    }

    // 2. Fallback : lire depuis .cscm.yaml
    if (ConfigReader.configExists()) {
      try {
        return ConfigReader.read().projectName;
      } catch (_) {}
    }

    // 3. Dernier recours : nom du dossier courant
    final currentDir = Directory.current.path.split(Platform.pathSeparator);
    return currentDir.isNotEmpty ? currentDir.last : 'my_app';
  }

  /// Si .cscm.yaml existe mais a un project_name different de pubspec.yaml,
  /// le corriger automatiquement pour eviter les incoherences.
  static void _syncConfigIfNeeded(String pubspecName) {
    if (!ConfigReader.configExists()) return;

    try {
      final config = ConfigReader.read();
      if (config.projectName != pubspecName) {
        ConfigReader.updateConfig({'project_name': pubspecName});
      }
    } catch (_) {
      // Ne pas bloquer si la config est illisible
    }
  }
}
