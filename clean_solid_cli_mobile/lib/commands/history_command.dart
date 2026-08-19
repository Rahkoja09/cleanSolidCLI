import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';

class HistoryCommand extends Command {
  @override
  String get name => 'history';

  @override
  String get description =>
      'Afficher l\'historique de toutes les actions cscm sur le projet';

  HistoryCommand() {
    argParser.addFlag(
      'compact',
      abbr: 'c',
      help: 'Affichage compact (une ligne par action)',
      defaultsTo: false,
      negatable: false,
    );
    argParser.addOption(
      'limit',
      abbr: 'n',
      help: 'Limiter le nombre d\'actions affichees',
    );
  }

  @override
  Future<void> run() async {
    if (!ProjectState.stateExists()) {
      CliUI.error('Aucun projet CSCM trouve dans ce dossier.');
      return;
    }

    final compact = argResults?['compact'] as bool? ?? false;
    final limitStr = argResults?['limit'] as String?;
    final limit = limitStr != null ? int.tryParse(limitStr) : null;

    final state = ProjectState.load();
    CliUI.header('Historique : ${state.projectName}');

    final actions = limit != null && limit < state.actions.length
        ? state.actions.sublist(state.actions.length - limit)
        : state.actions;

    if (actions.isEmpty) {
      CliUI.info('Aucune action enregistree.');
      return;
    }

    final total = state.actions.length;
    final startIdx = total - actions.length;

    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final num = CliUI.dim('#${startIdx + i + 1}');
      final time = CliUI.dim(_formatTime(action.timestamp));
      final cmd = CliUI.bold(action.command.padRight(12));
      final argsStr = action.args.join(' ');

      if (compact) {
        print('  $num  $time  $cmd $argsStr');
      } else {
        print('  $num  $time  $cmd $argsStr');
        if (action.detail != null) {
          print('       ${CliUI.dim(action.detail!)}');
        }
      }
    }

    print('');
    CliUI.info('$total action(s) totale(s)');
  }

  String _formatTime(String iso) {
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
