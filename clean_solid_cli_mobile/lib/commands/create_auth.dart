import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/helpers/auth_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/injection_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/error_listener_helper.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';

class CreateAuth extends Command {
  @override
  String get description => "Gerer l'authentification (Email, Google, etc.)";

  @override
  String get name => "auth";

  CreateAuth() {
    argParser.addFlag(
      'email',
      defaultsTo: true,
      help: "Inclure l'authentification par Email/Password",
    );

    argParser.addFlag(
      'social',
      defaultsTo: false,
      help: "Inclure l'authentification Sociale (Google)",
    );

    argParser.addFlag(
      'commit',
      abbr: 'c',
      help: 'Commiter automatiquement apres la configuration',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final bool useEmail = argResults?['email'] ?? true;
    final bool useSocial = argResults?['social'] ?? false;
    final bool autoCommit = argResults?['commit'] ?? false;

    if (!useEmail && !useSocial) {
      CliUI.error(
        "Vous devez activer au moins un mode d'authentification.",
      );
      CliUI.hint(
        'cscm auth (pour email par defaut) ou cscm auth --social',
      );
      return;
    }

    CliUI.header('Authentification');
    CliUI.info('Email : ${useEmail ? "oui" : "non"}');
    CliUI.info('Social : ${useSocial ? "oui" : "non"}');

    try {
      final filesCreated = await AuthHelper.generateAuthFeature(
        useEmail: useEmail,
        useSocial: useSocial,
      );

      CliUI.section('Integration');
      InjectionHelper.updateInjectionContainerAuth(
        useEmail: useEmail,
        useSocial: useSocial,
      );
      ErrorListenerHelper.updateErrorListener("Auth", "auth");

      // Log dans le state
      if (ProjectState.stateExists()) {
        ProjectState.addAuth(
          email: useEmail,
          social: useSocial,
          filesCreated: filesCreated,
        );
      }

      CliUI.success('Authentification configuree avec succes');

      // Auto commit
      if (autoCommit) {
        if (GitHelper.isGitInstalled() && GitHelper.isGitRepo()) {
          final result = GitHelper.commit(
            message: 'cscm: auth (email=$useEmail, social=$useSocial)',
            files: filesCreated.isNotEmpty ? filesCreated : null,
          );
          if (result != null) {
            CliUI.success('Auto-commit: auth configure');
          }
        }
      }
    } catch (e) {
      CliUI.error("Erreur lors de la configuration de l'auth : $e");
    }
  }
}
