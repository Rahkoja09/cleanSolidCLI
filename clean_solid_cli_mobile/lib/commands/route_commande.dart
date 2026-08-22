import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/helpers/route_helper.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';

class RouteCommand extends Command {
  @override
  String get description => 'Gerer les routes GoRouter (add / remove / list)';

  @override
  String get name => 'route';

  RouteCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Chemin de la route (ex: /profile ou detail/:id)',
    );
    argParser.addOption(
      'parent',
      abbr: 'P',
      help: 'Feature parente pour une route enfant (ex: livreur)',
    );
    argParser.addFlag(
      'remove',
      abbr: 'r',
      help: 'Supprimer la route de la feature',
      defaultsTo: false,
        negatable: false,
    );
    argParser.addFlag(
      'commit',
      abbr: 'c',
      help: 'Commiter automatiquement',
      defaultsTo: false,
        negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final rest = argResults?.rest.toList() ?? [];
    final first = rest.firstOrNull;
    final shouldRemove = argResults?['remove'] as bool? ?? false;

    // cscm route list | ls
    if (first == null || first == 'list' || first == 'ls') {
      RouteHelper.listRoutes();
      return;
    }

    // cscm route add <feature> | cscm route remove <feature>
    String featureName;
    bool isRemove = shouldRemove;

    if (first == 'add' || first == 'remove') {
      isRemove = (first == 'remove') || shouldRemove;
      if (rest.length < 2) {
        CliUI.error('Precisez le nom de la feature.');
        CliUI.hint('cscm route add <feature>');
        return;
      }
      featureName = rest[1];
    } else {
      // cscm route <feature> (add par defaut)
      featureName = first;
    }

    final customPath = argResults?['path'] as String?;
    final parentFeature = argResults?['parent'] as String?;
    final autoCommit = argResults?['commit'] as bool? ?? false;

    if (featureName.contains('..') ||
      featureName.contains('/') ||
      featureName.contains('\\')) {
      CliUI.error('Nom de feature invalide.');
    return;
      }

      if (isRemove) {
        RouteHelper.removeRoute(featureName: featureName);
      } else {
        RouteHelper.addRoute(
          featureName: featureName,
          path: customPath,
          parentFeature: parentFeature,
        );
      }

      if (autoCommit &&
        GitHelper.isGitInstalled() &&
        GitHelper.isGitRepo()) {
        final action = isRemove ? 'route:remove' : 'route:add';
      final result = GitHelper.commit(
        message: 'cscm: $action $featureName',
      );
      if (result != null) {
        CliUI.success('Auto-commit: $action $featureName');
      }
        }
  }
}
