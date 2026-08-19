import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/commands/create_auth.dart';
import 'package:clean_solid_cli_mobile/commands/create_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/test_command.dart';
import 'package:clean_solid_cli_mobile/commands/implemente_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/config_command.dart';
import 'package:clean_solid_cli_mobile/commands/init_command.dart';
import 'package:clean_solid_cli_mobile/commands/generate_all_command.dart';
import 'package:clean_solid_cli_mobile/commands/add_widget_command.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner(
    "cscm",
    "Clean Solid CLI Mobile — Générateur de modules Flutter en Clean Architecture.\n\n"
        "Commandes disponibles :\n"
        "  cscm init <nom>         Créer un projet complet depuis zéro\n"
        "  cscm config -n <nom>    Configurer le projet courant\n"
        "  cscm create <feature>   Générer une nouvelle feature\n"
        "  cscm implemente <feature> -i \"champ:type\"  Implémenter les champs\n"
        "  cscm generate:all       Générer toutes les features depuis un YAML\n"
        "  cscm auth [--social]    Générer le module d'authentification",
  );
  runner.addCommand(InitCommand());
  runner.addCommand(ConfigCommand());
  runner.addCommand(CreateNewFeature());
  runner.addCommand(TestCommand());
  runner.addCommand(ImplementeNewFeature());
  runner.addCommand(GenerateAllCommand());
  runner.addCommand(CreateAuth());
  runner.addCommand(AddWidgetCommand());
  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e.message);
    exitCode = 64;
  } on CliException catch (e) {
    CliUI.error(e.message);
    exitCode = e.exitCode;
  } catch (e) {
    CliUI.error(e.toString());
    exitCode = 1;
  }
}
