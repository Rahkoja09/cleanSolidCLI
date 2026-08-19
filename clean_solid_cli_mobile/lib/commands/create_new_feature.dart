import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/models/field.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/helpers/error_listener_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/file_helper.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/helpers/injection_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';
import 'package:clean_solid_cli_mobile/utils/test_generator.dart';
import 'package:clean_solid_cli_mobile/utils/interactive_prompt.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/field_parser.dart';

class CreateNewFeature extends Command {
  @override
  String get description =>
      "Creer une nouvelle feature complete avec option d'implementation CRUD";

  @override
  String get name => 'create';

  CreateNewFeature() {
    argParser.addOption(
      'fields',
      abbr: 'i',
      help:
          "Liste des champs pour generer l'Entity, le Model et les filtres (ex: nom:string,prix:double)",
      mandatory: false,
    );
    argParser.addFlag(
      'interactive',
      abbr: 't',
      help:
          'Mode interactif -- pose des questions au lieu d\'utiliser les flags',
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
      CliUI.header('Creation d\'une nouvelle feature');
      featureName = InteractivePrompt.ask('Nom de la feature', required: true);

      final wantFields = InteractivePrompt.askBool(
        'Voulez-vous definir les champs maintenant ?',
      );

      if (wantFields) {
        fieldsInput = InteractivePrompt.askFields();
      }
    } else {
      featureName = argResults!.rest.first;
      fieldsInput = argResults?['fields'] as String?;

      // Validation anti path traversal
      if (featureName.contains('..') ||
          featureName.contains('/') ||
          featureName.contains('\\')) {
        CliUI.error('Nom de feature avec caracteres interdits');
        return;
      }
    }

    final snakeFeatureName = ReformateClassName.formatToSnakeCase(featureName);
    final capitalizedName = ReformateClassName.capitalizeClassName(
      featureName: snakeFeatureName,
    );

    CliUI.header('Generation de la structure : $capitalizedName');

    // Demarrer le tracking des fichiers
    final tracker = FileTracker();
    FileHelper.startTracking(tracker);

    try {
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
          CliUI.error('Generation ${type.name} : $e');
        }
      }

      List<dynamic> parsedFields = [];

      if (fieldsInput != null && fieldsInput.isNotEmpty) {
        CliUI.section('Implementation des entites');

        try {
          final projectName = GetProjetItem.getProjectName();

          await CliUI.withSpinner('Injection des champs', () async {
            ImplementationHelper.applyImplementation(
              featureName: featureName,
              fieldsRaw: fieldsInput!,
              projectName: projectName,
            );
          });

          // Parser les champs pour le state
          parsedFields = FieldParser.parse(fieldsInput);
          for (final f in parsedFields) {
            if (f is Field) {
              tracker.trackUpdated(
                'lib/features/$snakeFeatureName/domain/entity/${snakeFeatureName}_entity.dart',
              );
              tracker.trackUpdated(
                'lib/features/$snakeFeatureName/data/model/${snakeFeatureName}_model.dart',
              );
            }
          }
        } catch (e) {
          CliUI.error('Erreur d\'implementation : $e');
        }
      }

      // Generation des tests unitaires
      try {
        CliUI.section('Tests unitaires');
        final projectName = GetProjetItem.getProjectName();
        await TestGenerator.generate(
          featureName: featureName,
          projectName: projectName,
        );
      } catch (e) {
        CliUI.error('Erreur lors de la generation des tests : $e');
      }

      // Injection de dependances
      CliUI.section('Integration');
      InjectionHelper.updateInjectionContainer(featureName, capitalizedName);
      ErrorListenerHelper.updateErrorListener(
        capitalizedName,
        snakeFeatureName,
      );

      // Logger dans le state
      if (ProjectState.stateExists()) {
        ProjectState.addFeature(
          rawName: featureName,
          snakeName: snakeFeatureName,
          pascalName: capitalizedName,
          fields: tracker.fieldsToRecords(parsedFields),
          filesCreated: tracker.created,
          filesUpdated: tracker.updated,
          sqlMigration: tracker.lastSqlMigration,
        );
      }

      // Resume
      CliUI.success('Feature [$capitalizedName] creee avec succes');
      CliUI.nextSteps([
        'Implementez l\'UI dans lib/features/$snakeFeatureName/presentation/pages/${snakeFeatureName}_page.dart',
      ]);
    } finally {
      FileHelper.stopTracking();
    }
  }
}
