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
    final subcommand = argResults?.rest.firstOrNull;
    final shouldRemove = argResults?['remove'] as bool? ?? false;

    // Sans sous-commande ou "list" → afficher les routes
    if (subcommand == null || subcommand == 'list' || subcommand == 'ls') {
      RouteHelper.listRoutes();
      return;
    }

    final featureName = subcommand;
    final customPath = argResults?['path'] as String?;
    final parentFeature = argResults?['parent'] as String?;
    final autoCommit = argResults?['commit'] as bool? ?? false;

    // Validation anti-traversal
    if (featureName.contains('..') ||
      featureName.contains('/') ||
      featureName.contains('\\')) {
      CliUI.error('Nom de feature invalide.');
    return;
      }

      if (shouldRemove) {
        RouteHelper.removeRoute(featureName: featureName);
      } else {
        RouteHelper.addRoute(
          featureName: featureName,
          path: customPath,
          parentFeature: parentFeature,
        );
      }

      // Auto commit
      if (autoCommit &&
        GitHelper.isGitInstalled() &&
        GitHelper.isGitRepo()) {
        final action = shouldRemove ? 'route:remove' : 'route:add';
      final result = GitHelper.commit(
        message: 'cscm: $action $featureName',
      );
      if (result != null) {
        CliUI.success('Auto-commit: $action $featureName');
      }
        }
  }
}
