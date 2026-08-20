import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';

class UndoCommand extends Command {
  @override
  String get name => 'undo';

  @override
  String get description =>
      'Annuler une feature (supprime fichiers + nettoyage injection)';

  UndoCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Supprimer sans confirmation',
      defaultsTo: false,
      negatable: false,
    );
    argParser.addFlag(
      'commit',
      abbr: 'c',
      help: 'Commiter automatiquement apres l\'annulation',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    if (!ProjectState.stateExists()) {
      CliUI.error('Aucun projet CSCM trouve dans ce dossier.');
      return;
    }

    if (argResults!.rest.isEmpty) {
      CliUI.error('Usage: cscm undo <feature_name>');
      CliUI.hint('Utilisez "cscm list" pour voir les features disponibles.');
      return;
    }

    final featureName = argResults!.rest.first;
    final force = argResults?['force'] as bool? ?? false;
    final autoCommit = argResults?['commit'] as bool? ?? false;

    final state = ProjectState.load();
    final feature = state.findFeature(featureName);

    if (feature == null) {
      CliUI.error('Feature "$featureName" non trouvee.');
      CliUI.hint('Utilisez "cscm list" pour voir les features disponibles.');
      return;
    }

    CliUI.header('Undo : ${feature.pascalName}');

    // ── 1. Montrer les fichiers a supprimer ──
    final allFiles =
        [...feature.filesCreated, ...feature.filesUpdated].toSet().toList();
    final existingFiles = allFiles.where((f) => File(f).existsSync()).toList();
    final deletedFiles = allFiles.where((f) => !File(f).existsSync()).toList();

    if (existingFiles.isEmpty && deletedFiles.isEmpty) {
      CliUI.warning('Aucun fichier a supprimer.');
      _removeFromState(feature.snakeName);
      return;
    }

    print('  ${CliUI.dim('Files to remove')} (${existingFiles.length}):');
    for (final f in existingFiles) {
      print('    ${CliUI.red('remove')}  $f');
    }
    if (deletedFiles.isNotEmpty) {
      print('  ${CliUI.dim('Already deleted')} (${deletedFiles.length}):');
      for (final f in deletedFiles) {
        print('    ${CliUI.dim('gone')}    $f');
      }
    }

    // ── 2. Montrer le nettoyage injection ──
    print('');
    print('  ${CliUI.dim('Injection cleanup:')}');
    print(
      '    remove   _init${feature.pascalName}() from injection_container.dart',
    );
    print(
      '    remove   ${feature.pascalName} listener from success_error_listener.dart',
    );

    // ── 3. SQL migration ──
    if (feature.sqlMigration != null) {
      print('');
      CliUI.warning(
        'SQL migration ${feature.sqlMigration} will NOT be deleted',
      );
      print('  ${CliUI.dim('(run manually if needed)')}');
    }

    // ── 4. Confirmation ──
    if (!force) {
      print('');
      stdout.write('  ${CliUI.yellow('[y/N]')}  Confirm? ');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer != 'y') {
        CliUI.info('Annule.');
        return;
      }
    }

    // ── 5. Executer ──
    var removedCount = 0;

    // Collect files for potential commit BEFORE deleting
    final filesForCommit = <String>[...existingFiles];

    // Supprimer les fichiers
    for (final filePath in existingFiles) {
      try {
        File(filePath).deleteSync();
        removedCount++;
        _removeEmptyParentDirs(filePath);
      } catch (e) {
        CliUI.warning('Impossible de supprimer $filePath: $e');
      }
    }

    // Nettoyer injection_container.dart
    _cleanInjectionContainer(feature);
    filesForCommit.add('lib/core/di/injection_container.dart');

    // Nettoyer success_error_listener.dart
    _cleanErrorListener(feature);
    filesForCommit
        .add('lib/core/mainErrorListener/success_error_listener.dart');

    // Retirer du state
    _removeFromState(feature.snakeName);
    filesForCommit.add(ProjectState.stateFileName);

    print('');
    CliUI.success('$removedCount file(s) removed');
    CliUI.success('injection_container.dart cleaned');
    CliUI.success('success_error_listener.dart cleaned');
    CliUI.success('Feature [${feature.pascalName}] removed');

    // ── Auto commit ──
    if (autoCommit) {
      _autoCommit(feature.pascalName, filesForCommit);
    }
  }

  void _autoCommit(String featureName, List<String> files) {
    if (!GitHelper.isGitInstalled() || !GitHelper.isGitRepo()) return;

    final message = 'cscm: undo $featureName';
    final result = GitHelper.commit(message: message, files: files);
    if (result != null) {
      CliUI.success('Auto-commit: $message');
    }
  }

  void _removeEmptyParentDirs(String filePath) {
    final dir = File(filePath).parent;
    if (!dir.existsSync()) return;

    final parts = dir.path.split(Platform.pathSeparator);
    final featureIdx = parts.indexOf('features');
    if (featureIdx < 0) return;
    final stopAt = parts.length - (parts.length - featureIdx - 3).clamp(0, 10);

    var current = dir;
    while (current.path.split(Platform.pathSeparator).length > stopAt) {
      try {
        final contents = current.listSync();
        if (contents.isEmpty) {
          current.deleteSync();
          current = current.parent;
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }
  }

  void _cleanInjectionContainer(FeatureRecord feature) {
    final filePath = 'lib/core/di/injection_container.dart';
    final file = File(filePath);
    if (!file.existsSync()) return;

    String content = file.readAsStringSync();
    final pascal = feature.pascalName;

    // 1. Retirer les imports de la feature
    final importPattern = RegExp(
      "import 'package:[^/]+/features/${feature.snakeName}/[^']+';\n",
      multiLine: true,
    );
    content = content.replaceAll(importPattern, '');

    // 2. Retirer _init<Feature>() call
    content = content.replaceAll('  _init$pascal();', '');

    // 3. Retirer la methode _init<Feature> entiere
    final methodPattern = RegExp(
      r'Future<void> _init' + pascal + r'\(\) async \{[\s\S]*?\}\n',
      multiLine: true,
    );
    content = content.replaceAll(methodPattern, '');

    // 4. Nettoyer les lignes vides multiples
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    file.writeAsStringSync(content);
  }

  void _cleanErrorListener(FeatureRecord feature) {
    final filePath = 'lib/core/mainErrorListener/success_error_listener.dart';
    final file = File(filePath);
    if (!file.existsSync()) return;

    String content = file.readAsStringSync();
    final pascal = feature.pascalName;
    final snake = feature.snakeName;

    // 1. Retirer les imports de la feature
    final importPattern = RegExp(
      "import 'package:[^/]+/features/${snake}/[^']+';\n",
      multiLine: true,
    );
    content = content.replaceAll(importPattern, '');

    // 2. Retirer le bloc ref.listen<FeatureStates>(featureControllerProvider, ...);
    final listenerPattern = RegExp(
      'ref\\.listen<${pascal}States>\\(${snake}ControllerProvider, \\([^)]*\\) \\{[\\s\\S]*?\\}\\);',
      multiLine: true,
    );
    content = content.replaceAll(listenerPattern, '');

    // 3. Nettoyer les lignes vides multiples
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    file.writeAsStringSync(content);
  }

  void _removeFromState(String snakeName) {
    ProjectState.removeFeature(snakeName);
  }
}
