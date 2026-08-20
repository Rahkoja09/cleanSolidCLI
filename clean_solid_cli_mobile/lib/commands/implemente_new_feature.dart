import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/interactive_prompt.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/file_helper.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class ImplementeNewFeature extends Command {
  @override
  String get description =>
      "Ajouter ou mettre a jour l'implementation CRUD d'une feature existante";

  @override
  String get name => "implemente";

  ImplementeNewFeature() {
    argParser.addOption(
      'fields',
      abbr: 'i',
      help: "Les champs a implementer (ex: title:string,description:string)",
      mandatory: false,
    );
    argParser.addFlag(
      'commit',
      abbr: 'c',
      help: 'Commiter automatiquement apres l\'implementation',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  void run() {
    if (argResults?.rest.isEmpty ?? true) {
      CliUI.error('Precisez le nom de la feature.');
      CliUI.hint('cscm implemente produit -i "prix:int"');
      CliUI.hint('cscm implemente produit  (mode interactif)');
      return;
    }

    final featureName = argResults!.rest.first.toLowerCase();
    final autoCommit = argResults?['commit'] as bool? ?? false;
    String fieldsInput = argResults?['fields'] as String? ?? '';

    final featurePath = p.join('lib', 'features', featureName);
    if (!Directory(featurePath).existsSync()) {
      CliUI.error("La feature '$featureName' n'existe pas dans lib/features/.");
      CliUI.hint("Creez-la d'abord avec : cscm create $featureName");
      return;
    }

    // Si pas de champs fournis, passer en mode interactif
    if (fieldsInput.isEmpty) {
      fieldsInput = InteractivePrompt.askFields();
    }

    if (fieldsInput.isEmpty) {
      CliUI.warning('Aucun champ fourni.');
      return;
    }

    CliUI.header('Implementation : $featureName');

    try {
      final projectName = GetProjetItem.getProjectName();
      final snakeName = ReformateClassName.formatToSnakeCase(featureName);

      // Track the files that will be updated
      final tracker = FileTracker();
      FileHelper.startTracking(tracker);

      ImplementationHelper.applyImplementation(
        featureName: featureName,
        fieldsRaw: fieldsInput,
        projectName: projectName,
      );

      FileHelper.stopTracking();

      // Update state if exists
      if (ProjectState.stateExists()) {
        final state = ProjectState.load();
        final feature = state.findFeature(featureName);
        if (feature != null) {
          // Re-save the state with updated files
          // (the implementation modifies existing files)
          ProjectState.save(state);
        }
      }

      CliUI.success('Implementation terminee avec succes');

      // Auto commit
      if (autoCommit &&
          GitHelper.isGitInstalled() &&
          GitHelper.isGitRepo()) {
        final result = GitHelper.commit(
          message: 'cscm: implemente $featureName',
        );
        if (result != null) {
          CliUI.success('Auto-commit: implemente $featureName');
        }
      }
    } catch (e) {
      CliUI.error('Erreur : $e');
    }
  }
}
