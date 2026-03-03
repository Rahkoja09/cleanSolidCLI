import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/architectures/architectures.dart';
import 'package:clean_solid_cli_mobile/architectures/clean/layers/clean_layers.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/helpers/error_listener_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/file_helper.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/helpers/injection_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';

class CreateNewFeature extends Command {
  @override
  String get description =>
      "Créer une nouvelle feature complète avec option d'implémentation CRUD";

  @override
  String get name => "create";

  CreateNewFeature() {
    argParser.addOption(
      'fields',
      abbr: 'i',
      help:
          "Liste des champs pour générer l'Entity, le Model et les filtres (ex: nom:string,prix:double)",
      mandatory:
          false, // On laisse le choix à l'utilisateur (il veux ou pas ilplementer avec les entty entré : -i "...")
    );
  }

  @override
  void run() async {
    final layers = CleanLayers("data", "domain", "presentation");
    final arch = Architectures("Clean", "clean architecure + SOLIDE", layers);

    if (argResults?.rest.isEmpty ?? true) {
      print("Erreur : nom de feature manquant (ex: cscm create maison).");
      return;
    }

    final featureName = argResults!.rest.first.toLowerCase();
    final fieldsInput = argResults?['fields'] as String?;

    final capitalizedName = ReformateClassName.capitalizeClassName(
      featureName: featureName,
    );

    final snakeFeatureName = ReformateClassName.formatToSnakeCase(featureName);

    print("Génération de la structure pour : $capitalizedName...");

    for (var type in FileTemplateType.values) {
      if (type == FileTemplateType.di) continue;

      try {
        final targetPath = FileHelper.generateAndGetTargetPath(
          featureName: featureName,
          templateType: type,
          architecture: arch,
        );

        FileHelper.generateFormTemplate(
          featureName: featureName,
          templateName: type.name,
          targetPath: targetPath,
        );
      } catch (e) {
        print("Erreur lors de la génération de $type : $e");
      }
    }

    if (fieldsInput != null && fieldsInput.isNotEmpty) {
      print("Implémentation des entités détectée...");

      try {
        final projectName = GetProjetItem.getProjectName();

        ImplementationHelper.applyImplementation(
          featureName: featureName,
          fieldsRaw: fieldsInput,
          projectName: projectName,
        );

        print(
          "Champs injectés avec succès dans l'Entity, le Model et la RemoteSource.",
        );
      } catch (e) {
        print("Erreur d'implémentation : $e");
      }
    } else {
      print(
        "Aucune implémentation demandée (pas de flag -i). Structure vide créée.",
      );
    }

    print("Mise à jour de l'injection de dépendances...");
    InjectionHelper.updateInjectionContainer(featureName, capitalizedName);

    print("Mise à jour du ErrorListener...");
    ErrorListenerHelper.updateErrorListener(capitalizedName, snakeFeatureName);

    print("\nFeature [$capitalizedName] terminée avec succès !");
  }
}
