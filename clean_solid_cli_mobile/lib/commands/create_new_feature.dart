import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/helpers/error_listener_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/file_helper.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/helpers/injection_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';
import 'package:clean_solid_cli_mobile/utils/test_generator.dart';
import 'package:clean_solid_cli_mobile/utils/interactive_prompt.dart';

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
      mandatory: false,
    );
    argParser.addFlag(
      'interactive',
      abbr: 't',
      help:
          'Mode interactif — pose des questions au lieu d\'utiliser les flags',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final isInteractive = argResults?['interactive'] as bool? ?? false;
    String featureName;
    String? fieldsInput;

    if (isInteractive || (argResults?.rest.isEmpty ?? true)) {
      // --- MODE INTERACTIF ---
      print('\n Création d\'une nouvelle feature\n');
      featureName = InteractivePrompt.ask('Nom de la feature', required: true);

      final wantFields = InteractivePrompt.askBool(
        'Voulez-vous définir les champs maintenant ?',
      );

      if (wantFields) {
        fieldsInput = InteractivePrompt.askFields();
      }
    } else {
      // --- MODE FLAGS ---
      featureName = argResults!.rest.first;
      fieldsInput = argResults?['fields'] as String?;

      // Validation anti path traversal
      if (featureName.contains('..') ||
          featureName.contains('/') ||
          featureName.contains('\\')) {
        print(
          '  Erreur : Le nom de feature contient des caractères interdits.',
        );
        return;
      }
    }

    final snakeFeatureName = ReformateClassName.formatToSnakeCase(featureName);
    final capitalizedName = ReformateClassName.capitalizeClassName(
      featureName: snakeFeatureName,
    );

    print(
      "\n  : Génération de la structure pour : $capitalizedName...\n",
    );

    for (var type in FileTemplateType.values) {
      if (type == FileTemplateType.di) continue;

      try {
        final targetPath = FileHelper.generateAndGetTargetPath(
          featureName: featureName,
          templateType: type,
        );

        await FileHelper.generateFormTemplate(
          featureName: featureName,
          templateName: type.name,
          targetPath: targetPath,
        );
      } catch (e) {
        print(" :( Erreur lors de la génération de ${type.name} : $e");
      }
    }

    if (fieldsInput != null && fieldsInput.isNotEmpty) {
      print("\n  Implémentation des entités...\n");

      try {
        final projectName = GetProjetItem.getProjectName();

        ImplementationHelper.applyImplementation(
          featureName: featureName,
          fieldsRaw: fieldsInput,
          projectName: projectName,
        );

        print("  Champs injectés dans l'Entity, le Model et le RemoteSource.");
      } catch (e) {
        print("Erreur d'implémentation : $e");
      }
    }

        // Generation des tests unitaires
    try {
      final projectName = GetProjetItem.getProjectName();
      await TestGenerator.generate(
        featureName: featureName,
        projectName: projectName,
      );
    } catch (e) {
      print("Erreur lors de la generation des tests : \$e");
    }

print("\nMise à jour de l'injection de dépendances...");
    InjectionHelper.updateInjectionContainer(featureName, capitalizedName);

    print("Mise à jour du ErrorListener...");
    ErrorListenerHelper.updateErrorListener(capitalizedName, snakeFeatureName);

    print("\n Feature [$capitalizedName] créée avec succès !\n");
    print("   Prochaine étape : implémentez l'UI dans ");
    print(
      "   lib/features/$snakeFeatureName/presentation/pages/${snakeFeatureName}_page.dart\n",
    );
  }
}
