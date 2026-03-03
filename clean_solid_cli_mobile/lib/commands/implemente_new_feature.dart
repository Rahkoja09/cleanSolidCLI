import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';

class ImplementeNewFeature extends Command {
  @override
  String get description =>
      "Ajoute ou met à jour l'implémentation CRUD d'une feature existante";

  @override
  String get name => "implemente";

  ImplementeNewFeature() {
    argParser.addOption(
      'fields',
      abbr: 'i',
      help: "Les champs à implémenter (ex: title:string,description:string)",
      mandatory: true,
    );
  }

  @override
  void run() async {
    if (argResults?.rest.isEmpty ?? true) {
      print(
        "Erreur : Précisez le nom de la feature. Exemple : cscm implemente maison -i 'prix:int'",
      );
      return;
    }

    final featureName = argResults!.rest.first.toLowerCase();
    final fieldsInput = argResults!['fields'] as String;

    final featurePath = p.join('lib', 'features', featureName);
    if (!Directory(featurePath).existsSync()) {
      print(
        "Erreur : La feature '$featureName' n'existe pas dans lib/features/.",
      );
      print("Créez-la d'abord avec : cscm create $featureName");
      return;
    }

    print(
      "Début de l'implémentation pour la feature : ${featureName.toUpperCase()}...",
    );

    try {
      final projectName = GetProjetItem.getProjectName();

      ImplementationHelper.applyImplementation(
        featureName: featureName,
        fieldsRaw: fieldsInput,
        projectName: projectName,
      );

      print("\nImplémentation terminée avec succès !");
      print("Vos fichiers Entity, Model et RemoteSource ont été mis à jour.");
    } catch (e) {
      print("Une erreur critique est survenue : $e");
    }
  }
}
