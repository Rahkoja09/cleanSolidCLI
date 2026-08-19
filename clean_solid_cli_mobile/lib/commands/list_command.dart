import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';

class ListCommand extends Command {
  @override
  String get name => 'list';

  @override
  String get description =>
      'Lister toutes les features du projet avec leurs details';

  @override
  Future<void> run() async {
    if (!ProjectState.stateExists()) {
      CliUI.error('Aucun projet CSCM trouve dans ce dossier.');
      return;
    }

    final state = ProjectState.load();
    CliUI.header('Features du projet : ${state.projectName}');

    if (state.features.isEmpty) {
      CliUI.info('Aucune feature creee.');
      CliUI.hint('cscm create <feature> -i "champ:type"');
      return;
    }

    for (final feature in state.features) {
      final fieldCount = feature.fields.length;
      final fileCount = feature.filesCreated.length;
      final updatedCount = feature.filesUpdated.length;

      CliUI.section(feature.pascalName);

      print('  ${CliUI.dim('snake_name:')}  ${feature.snakeName}');
      print('  ${CliUI.dim('created:')}    ${_formatDate(feature.createdAt)}');
      print(
          '  ${CliUI.dim('files:')}      ${CliUI.green('$fileCount created')}${updatedCount > 0 ? ', ${CliUI.cyan('$updatedCount updated')}' : ''}');

      if (fieldCount > 0) {
        print('  ${CliUI.dim('fields ($fieldCount):')}');
        for (final field in feature.fields) {
          final type = field.isEnum
              ? '${CliUI.yellow('enum')}(${field.enumValues.join(', ')})'
              : field.isReference
                  ? '${CliUI.cyan('ref')}(${field.referenceTarget})'
                  : CliUI.green(field.type);
          print('    ${field.name.padRight(24)}$type');
        }
      }

      if (feature.sqlMigration != null) {
        print(
            '  ${CliUI.dim('migration:')}  ${feature.sqlMigration}');
      }
    }

    if (state.auth.configured) {
      CliUI.section('Authentification');
      final modes = <String>[];
      if (state.auth.email) modes.add('Email');
      if (state.auth.social) modes.add('Social');
      print(
          '  ${CliUI.green('configured')}  ${modes.join(' + ')}  (${state.auth.filesCreated.length} files)');
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
