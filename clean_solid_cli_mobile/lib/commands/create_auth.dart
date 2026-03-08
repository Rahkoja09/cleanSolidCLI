import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/helpers/auth_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/injection_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/error_listener_helper.dart';

class CreateAuth extends Command {
  @override
  String get description => "Gérer l'authentification (Email, Google, etc.)";

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
  }

  @override
  void run() async {
    final bool useEmail = argResults?['email'] ?? true;
    final bool useSocial = argResults?['social'] ?? false;

    if (!useEmail && !useSocial) {
      print("Erreur : Vous devez activer au moins un mode d'authentification.");
      print(
        "Utilisation : cscm auth (pour email par défaut) ou cscm auth --social",
      );
      return;
    }

    print("Configuration de l'authentification demandée :");
    print("- Email : ${useEmail ? 'OUI' : 'NON'}");
    print("- Social : ${useSocial ? 'OUI' : 'NON'}");

    try {
      await AuthHelper.generateAuthFeature(
        useEmail: useEmail,
        useSocial: useSocial,
      );

      print("Mise à jour de l'injection de dépendances...");
      InjectionHelper.updateInjectionContainerAuth(
        useEmail: useEmail,
        useSocial: useSocial,
      );

      print("Mise à jour du ErrorListener...");
      ErrorListenerHelper.updateErrorListener("Auth", "auth");

      print("\nL'authentification a été configurée avec succès !");
    } catch (e) {
      print("Une erreur est survenue lors de la configuration de l'auth : $e");
    }
  }
}
