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
import 'package:clean_solid_cli_mobile/commands/list_command.dart';
import 'package:clean_solid_cli_mobile/commands/history_command.dart';
import 'package:clean_solid_cli_mobile/commands/undo_command.dart';
import 'package:clean_solid_cli_mobile/commands/status_command.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner(
    "cscm",
    "Clean Solid CLI Mobile — Generateur de modules Flutter en Clean Architecture.\n\n"
        "Commandes disponibles :\n"
        "  cscm init <nom>         Creer un projet complet depuis zero\n"
        "  cscm config -n <nom>    Configurer le projet courant\n"
        "  cscm create <feature>   Generer une nouvelle feature\n"
        "  cscm implemente <feature> -i \"champ:type\"  Implementer les champs\n"
        "  cscm generate:all       Generer toutes les features depuis un YAML\n"
        "  cscm auth [--social]    Generer le module d'authentification\n"
        "  cscm list               Lister les features du projet\n"
        "  cscm history            Historique des actions cscm\n"
        "  cscm undo <feature>      Annuler une feature\n"
        "  cscm status             Progression et suggestions\n",
  );
  runner.addCommand(InitCommand());
  runner.addCommand(ConfigCommand());
  runner.addCommand(CreateNewFeature());
  runner.addCommand(TestCommand());
  runner.addCommand(ImplementeNewFeature());
  runner.addCommand(GenerateAllCommand());
  runner.addCommand(CreateAuth());
  runner.addCommand(AddWidgetCommand());
  runner.addCommand(ListCommand());
  runner.addCommand(HistoryCommand());
  runner.addCommand(UndoCommand());
  runner.addCommand(StatusCommand());
  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e);
    exitCode = 64;
  } on CliException catch (e) {
    print("  Erreur : ${e.message}");
    exitCode = e.exitCode;
  } catch (e) {
    print("  Erreur : $e");
    exitCode = 1;
  }
}
