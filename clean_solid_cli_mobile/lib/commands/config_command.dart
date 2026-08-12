import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';
import 'dart:io';

class ConfigCommand extends Command {
  @override
  String get description =>
      'Créer ou mettre à jour le fichier de configuration .cscm.yaml';

  @override
  String get name => 'config';

  ConfigCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Nom du projet (snake_case)',
      mandatory: false,
    );
    argParser.addOption(
      'backend',
      abbr: 'b',
      help: 'Backend à utiliser (supabase | firebase | none)',
      defaultsTo: 'supabase',
      allowed: ['supabase', 'firebase', 'none'],
    );
  }

  @override
  void run() {
    final name = argResults?['name'] as String?;

    if (name == null || name.isEmpty) {
      if (ConfigReader.configExists()) {
        final config = ConfigReader.read();
        print('📋 Configuration actuelle :');
        print('   Nom du projet  : ${config.projectName}');
        print('   Backend         : ${config.backend}');
        print('   State Mgmt      : ${config.stateManagement}');
        print('   DI              : ${config.di}');
        print('   ScreenUtil      : ${config.useScreenUtil}');
        print('   GoRouter        : ${config.useGoRouter}');
        return;
      }

      // Demander le nom interactivement
      stdout.write('Nom du projet (snake_case) : ');
      final inputName = stdin.readLineSync()?.trim();
      if (inputName == null || inputName.isEmpty) {
        print('❌ Nom du projet requis. Utilisez : cscm config -n mon_projet');
        return;
      }

      ConfigReader.createConfig(
        projectName: inputName,
        backend: argResults?['backend'] as String? ?? 'supabase',
      );
      return;
    }

    ConfigReader.createConfig(
      projectName: name,
      backend: argResults?['backend'] as String? ?? 'supabase',
    );
  }
}
