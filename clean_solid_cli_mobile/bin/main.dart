import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/commands/create_auth.dart';
import 'package:clean_solid_cli_mobile/commands/create_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/implemente_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/config_command.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner(
    "cscm",
    "Clean Solid CLI Mobile — Générateur de modules Flutter en Clean Architecture.\n\n"
        "Commandes disponibles :\n"
        "  cscm config -n <nom>     Créer la configuration du projet\n"
        "  cscm create <feature>    Générer une nouvelle feature\n"
        "  cscm implemente <feature> Implémenter les champs d'une feature\n"
        "  cscm auth                Générer le module d'authentification",
  );
  runner.addCommand(ConfigCommand());
  runner.addCommand(CreateNewFeature());
  runner.addCommand(ImplementeNewFeature());
  runner.addCommand(CreateAuth());
  try {
    await runner.run(arguments);
  } catch (e) {
    print("Erreur : $e");
  }
}
