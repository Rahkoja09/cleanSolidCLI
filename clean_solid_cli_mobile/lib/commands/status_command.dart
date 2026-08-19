import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';

class StatusCommand extends Command {
  @override
  String get name => 'status';

  @override
  String get description =>
      'Afficher la progression du projet et les suggestions';

  @override
  Future<void> run() async {
    if (!ProjectState.stateExists()) {
      CliUI.error('Aucun projet CSCM trouve dans ce dossier.');
      return;
    }

    final state = ProjectState.load();

    CliUI.header('Project: ${state.projectName}');

    // ── Features ──
    final featureCount = state.features.length;
    final totalFiles = state.features.fold<int>(
      0,
      (sum, f) => sum + f.filesCreated.length,
    );

    CliUI.section('Features', count: '$featureCount');

    if (featureCount == 0) {
      print('    ${CliUI.dim('(none yet)')}');
    } else {
      for (final f in state.features) {
        final fieldStr =
            f.fields.isEmpty ? '' : ' | ${f.fields.length} field(s)';
        final migrationStr =
            f.sqlMigration != null ? ' | ${CliUI.cyan('migration SQL')}' : '';
        print(
          '    ${CliUI.green('[ok]')}  ${f.pascalName.padRight(24)}${f.filesCreated.length} files$fieldStr$migrationStr',
        );
      }
    }

    // ── Auth ──
    CliUI.section('Authentification');
    if (!state.auth.configured) {
      print('    ${CliUI.yellow('[--]')}  Not configured');
    } else {
      if (state.auth.email) {
        print('    ${CliUI.green('[ok]')}  Email authentication');
      }
      if (state.auth.social) {
        print('    ${CliUI.green('[ok]')}  Social authentication');
      }
      if (state.auth.email && !state.auth.social) {
        print(
          '    ${CliUI.yellow('[--]')}  Social authentication (not configured)',
        );
      } else if (!state.auth.email && state.auth.social) {
        print(
          '    ${CliUI.yellow('[--]')}  Email authentication (not configured)',
        );
      }
    }

    // ── Fichiers generes total ──
    final coreFiles = _countCoreFiles();
    CliUI.section('Stats');
    print('    Core files       ${CliUI.green('$coreFiles')}');
    print('    Feature files    ${CliUI.green('$totalFiles')}');
    print('    Actions loggees  ${CliUI.green('${state.actions.length}')}');
    print('    Created on       ${CliUI.dim(_formatDate(state.createdAt))}');

    // ── Suggestions ──
    final suggestions = _buildSuggestions(state);
    if (suggestions.isNotEmpty) {
      CliUI.section('Suggestions');
      for (var i = 0; i < suggestions.length; i++) {
        print('    ${CliUI.cyan('[${i + 1}]')}  ${suggestions[i]}');
      }
    }
  }

  int _countCoreFiles() {
    final coreDir = Directory('lib/core');
    if (!coreDir.existsSync()) return 0;
    return coreDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .length;
  }

  List<String> _buildSuggestions(ProjectState state) {
    final suggestions = <String>[];

    if (state.features.isEmpty) {
      suggestions.add(
        'cscm create <feature> -i "field:type"    → create your first feature',
      );
    }

    if (!state.auth.configured) {
      suggestions.add(
        'cscm auth email                        → activate authentication',
      );
    } else {
      if (state.auth.email && !state.auth.social) {
        suggestions.add(
          'cscm auth social                      → add Google/Apple sign-in',
        );
      }
      if (!state.auth.email && state.auth.social) {
        suggestions.add(
          'cscm auth email                      → add email/password auth',
        );
      }
    }

    if (state.features.isNotEmpty) {
      final untested =
          state.features.where((f) {
            final testDir = Directory('test/features/${f.snakeName}');
            return !testDir.existsSync();
          }).toList();

      if (untested.length == state.features.length) {
        suggestions.add(
          'cscm test --all                       → run all test suites',
        );
      }
    }

    // References entre features
    final featureNames = state.features.map((f) => f.snakeName).toSet();
    final referenced = <String>{};
    for (final f in state.features) {
      for (final field in f.fields) {
        if (field.isReference &&
            !featureNames.contains(field.referenceTarget.toLowerCase())) {
          referenced.add(field.referenceTarget);
        }
      }
    }
    for (final ref in referenced) {
      suggestions.add(
        'cscm create ${ref.toLowerCase()} -i "..."       → missing referenced feature',
      );
    }

    return suggestions;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
