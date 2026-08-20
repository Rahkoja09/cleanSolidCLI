import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'dart:io';

class ConfigCommand extends Command {
  @override
  String get description =>
      'Creer ou mettre a jour le fichier de configuration .cscm.yaml';

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
      help: 'Backend a utiliser (supabase | firebase | none)',
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
        CliUI.header('Configuration actuelle');
        print('  ${CliUI.dim('project_name:')}  ${config.projectName}');
        print('  ${CliUI.dim('backend:')}      ${config.backend}');
        print('  ${CliUI.dim('state_mgmt:')}   ${config.stateManagement}');
        print('  ${CliUI.dim('di:')}           ${config.di}');
        print('  ${CliUI.dim('screenutil:')}   ${config.useScreenUtil}');
        print('  ${CliUI.dim('go_router:')}    ${config.useGoRouter}');
        return;
      }

      // Demander le nom interactivement
      stdout.write('  Nom du projet (snake_case) : ');
      final inputName = stdin.readLineSync()?.trim();
      if (inputName == null || inputName.isEmpty) {
        CliUI.error('Nom du projet requis. Utilisez : cscm config -n mon_projet');
        return;
      }

      ConfigReader.createConfig(
        projectName: inputName,
        backend: argResults?['backend'] as String? ?? 'supabase',
      );
      CliUI.success('Configuration creee');
      return;
    }

    ConfigReader.createConfig(
      projectName: name,
      backend: argResults?['backend'] as String? ?? 'supabase',
    );
    CliUI.success('Configuration creee');
  }
}
