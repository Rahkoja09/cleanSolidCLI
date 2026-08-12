import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/interactive_prompt.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';

class ImplementeNewFeature extends Command {
  @override
  String get description =>
      "Ajouter ou mettre à jour l'implémentation CRUD d'une feature existante";

  @override
  String get name => "implemente";

  ImplementeNewFeature() {
    argParser.addOption(
      'fields',
      abbr: 'i',
      help: "Les champs à implémenter (ex: title:string,description:string)",
      mandatory: false,
    );
  }

  @override
  void run() {
    if (argResults?.rest.isEmpty ?? true) {
      print("   Précisez le nom de la feature.");
      print("   Exemple : cscm implemente produit -i 'prix:int'");
      print("   Ou mode interactif : cscm implemente produit");
      return;
    }

    final featureName = argResults!.rest.first.toLowerCase();
    String fieldsInput = argResults?['fields'] as String? ?? '';

    final featurePath = p.join('lib', 'features', featureName);
    if (!Directory(featurePath).existsSync()) {
      print("   La feature '$featureName' n'existe pas dans lib/features/.");
      print("   Créez-la d'abord avec : cscm create $featureName");
      return;
    }

    // Si pas de champs fournis, passer en mode interactif
    if (fieldsInput.isEmpty) {
      fieldsInput = InteractivePrompt.askFields();
    }

    if (fieldsInput.isEmpty) {
      print(" == - Aucun champ fourni.");
      return;
    }

    print(
      "\n (working) : Implémentation pour la feature : ${featureName.toUpperCase()}...\n",
    );

    try {
      final projectName = GetProjetItem.getProjectName();

      ImplementationHelper.applyImplementation(
        featureName: featureName,
        fieldsRaw: fieldsInput,
        projectName: projectName,
      );

      print("\n :) Implémentation terminée avec succès !");
    } catch (e) {
      print("\n :( Erreur : $e");
    }
  }
}
