import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:clean_solid_cli_mobile/models/config.dart';

class ConfigReader {
  static const String configFileName = '.cscm.yaml';

  static bool configExists() {
    return File(configFileName).existsSync();
  }

  static CscmConfig read() {
    final file = File(configFileName);
    if (!file.existsSync()) {
      throw Exception(
        'Fichier $configFileName introuvable.\n'
        'Exécutez "cscm config" pour le créer.',
      );
    }

    final content = file.readAsStringSync();
    final yamlMap = loadYaml(content) as Map;

    return CscmConfig.fromMap(Map<String, dynamic>.from(yamlMap));
  }

  static String getProjectName() {
    try {
      return read().projectName;
    } catch (_) {
      // Fallback: lire le nom du dossier parent
      final currentDir = Directory.current.path.split(Platform.pathSeparator);
      return currentDir.isNotEmpty ? currentDir.last : 'my_app';
    }
  }

  static void createConfig({
    required String projectName,
    String backend = 'supabase',
    String stateManagement = 'riverpod',
    String di = 'get_it',
  }) {
    final file = File(configFileName);
    if (file.existsSync()) {
      print('$configFileName existe déjà.');
      return;
    }

    final snakeName = projectName.replaceAll(' ', '_').toLowerCase();
    final content = '''# CSCM Configuration
# Documentation: github.com/Rahkoja09/cleanSolidCLI

project_name: $snakeName
backend: $backend          # supabase | firebase | none
state_management: $stateManagement  # riverpod | bloc
di: $di                    # get_it | riverpod
use_screenutil: true
use_go_router: true
''';

    file.writeAsStringSync(content);
    print('$configFileName créé avec succès.');
    print('   Nom du projet : $snakeName');
  }

  static void updateConfig(Map<String, dynamic> updates) {
    final config = read();
    final map = config.toMap();
    map.addAll(updates);

    final buffer = StringBuffer();
    buffer.writeln('# CSCM Configuration');
    buffer.writeln('# Documentation: github.com/Rahkoja09/cleanSolidCLI');
    buffer.writeln();

    map.forEach((key, value) {
      if (value is String) {
        buffer.writeln('$key: $value');
      } else if (value is bool) {
        buffer.writeln('$key: $value');
      }
    });

    File(configFileName).writeAsStringSync(buffer.toString());
    print('Configuration mise à jour.');
  }
}
