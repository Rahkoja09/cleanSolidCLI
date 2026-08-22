import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';

class CommitCommand extends Command {
  @override
  String get name => 'commit';

  @override
  String get description => 'Commit intelligent des fichiers modifies par cscm';

  CommitCommand() {
    argParser.addOption(
      'message',
      abbr: 'm',
      help: 'Message du commit (auto-genere si absent)',
    );
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Commiter tous les fichiers modifies (pas seulement cscm)',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    if (!GitHelper.isGitInstalled()) {
      CliUI.error('Git n\'est pas installe.');
      return;
    }

    if (!GitHelper.isGitRepo()) {
      CliUI.error('Pas de depot git dans ce dossier.');
      return;
    }

    final commitAll = argResults?['all'] as bool? ?? false;
    final explicitMessage = argResults?['message'] as String?;

    // Determine files to commit
    List<String>? filesToCommit;
    String message;

    if (commitAll) {
      // Commit everything
      filesToCommit = null;
      message = explicitMessage ?? _generateAllMessage();
    } else {
      // Smart commit: only cscm-modified files
      if (!ProjectState.stateExists()) {
        CliUI.error('Aucun projet CSCM dans ce dossier.');
        return;
      }

      final state = ProjectState.load();
      filesToCommit = _collectCscmFiles(state);

      if (filesToCommit.isEmpty) {
        CliUI.warning('Aucun fichier cscm a commiter.');
        return;
      }

      message = explicitMessage ?? _generateSmartMessage(state, filesToCommit);
    }

    CliUI.header('Commit cscm');
    print('  ${CliUI.dim('message:')}  $message');
    if (filesToCommit != null && filesToCommit.length <= 20) {
      for (final f in filesToCommit) {
        print('    ${CliUI.green('+')}  $f');
      }
    } else if (filesToCommit != null) {
      print('    ${CliUI.dim('(${filesToCommit.length} files)')}');
    } else {
      print('    ${CliUI.dim('(all files)')}');
    }

    final result = GitHelper.commit(message: message, files: filesToCommit);

    if (result != null) {
      CliUI.success('Commit cree');
    } else {
      CliUI.error('Commit echoue');
    }
  }

  /// Collect all files tracked by cscm state.
  List<String> _collectCscmFiles(ProjectState state) {
    final files = <String>{};

    // State file itself
    if (File(ProjectState.stateFileName).existsSync()) {
      files.add(ProjectState.stateFileName);
    }
    if (File(ConfigReader.configFileName).existsSync()) {
      files.add(ConfigReader.configFileName);
    }

    // Core files
    final coreDir = Directory('lib/core');
    if (coreDir.existsSync()) {
      for (final entity in coreDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity.path);
        }
      }
    }

    // Feature files
    for (final feature in state.features) {
      for (final f in feature.filesCreated) {
        if (File(f).existsSync()) files.add(f);
      }
      for (final f in feature.filesUpdated) {
        if (File(f).existsSync()) files.add(f);
      }
    }

    // Auth files
    if (state.auth.configured) {
      for (final f in state.auth.filesCreated) {
        if (File(f).existsSync()) files.add(f);
      }
    }

    return files.toList();
  }

  /// Generate a message from the last action in state.
  String _generateSmartMessage(ProjectState state, List<String> files) {
    if (state.actions.isEmpty) return 'cscm: update project';

    final lastAction = state.actions.last;
    final cmd = lastAction.command;
    final args = lastAction.args.join(' ');
    final detail = lastAction.detail != null ? ' (${lastAction.detail})' : '';

    return 'cscm: $cmd $args$detail';
  }

  /// Generate a generic message for --all mode.
  String _generateAllMessage() {
    final now = DateTime.now();
    return 'cscm: snapshot ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
