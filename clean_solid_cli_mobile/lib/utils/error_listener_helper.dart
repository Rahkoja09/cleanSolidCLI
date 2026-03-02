import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/get_projet_item.dart';

class ErrorListenerHelper {
  static void updateErrorListener(String featureName, String snakeName) {
    final filePath = p.join('lib', 'core', 'main_error_listener.dart');
    final file = File(filePath);

    if (!file.existsSync()) {
      print("Le fichier main_error_listener.dart est introuvable.");
      return;
    }

    String content = file.readAsStringSync();
    final projectName = GetProjetItem.getProjectName();

    // Préparer les nouveaux imports ------------
    final List<String> newImports = [
      "import 'package:$projectName/features/$snakeName/presentation/states/${snakeName}_states.dart';",
      "import 'package:$projectName/features/$snakeName/presentation/controller/${snakeName}_controller.dart';",
    ];

    // Ajouter les imports s'ils n'existent pas -------------------
    for (var imp in newImports) {
      if (!content.contains(imp)) {
        // On l'insère tout en haut, avant le premier import existant ----
        content = "$imp\n$content";
      }
    }

    // Vérifier si le listener existe déjà ----
    if (content.contains('${snakeName}ControllerProvider')) {
      print("Le listener pour $featureName est déjà présent.");
      return;
    }

    final listenerBlock = '''
    ref.listen<${featureName}States>(${snakeName}ControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _showFilteredError(
          context: context,
          ref: ref,
          failure: next.error!,
          action: next.action,
          title: "Erreur $featureName",
        );
      }

      if (prev?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        if (next.action?.isWriteAction == true) {
          showToast(
            context,
            description: next.action!.successMessage,
            isError: false,
            title: "Succès $featureName",
          );
        }
      }
    });

    return child;''';
    if (content.contains('return child;')) {
      content = content.replaceFirst('return child;', listenerBlock);
      file.writeAsStringSync(content);
      print("MainErrorListener mis à jour avec succès pour $featureName.");
    } else {
      print("Erreur : Impossible de trouver 'return child;' dans le fichier.");
    }
  }
}
