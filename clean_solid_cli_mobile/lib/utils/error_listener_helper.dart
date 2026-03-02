import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/get_projet_item.dart';

class ErrorListenerHelper {
  static void updateErrorListener(String capitalizedName, String snakeName) {
    final filePath = p.join(
      'lib',
      'core',
      'mainErrorListener',
      'success_error_listener.dart',
    );
    final file = File(filePath);

    if (!file.existsSync()) {
      print(
        " Le fichier success_error_listener.dart n'existe pas encore. FileHelper doit le créer d'abord.",
      );
      return;
    }

    String content = file.readAsStringSync();
    final projectName = GetProjetItem.getProjectName();

    if (!content.contains('_showFilteredError')) {
      content = _injectBaseBoilerplate(content);
    }

    final List<String> newImports = [
      "import 'package:$projectName/features/$snakeName/presentation/states/${snakeName}_states.dart';",
      "import 'package:$projectName/features/$snakeName/presentation/controller/${snakeName}_controller.dart';",
    ];

    for (var imp in newImports) {
      if (!content.contains(imp)) {
        content = "$imp\n$content";
      }
    }

    if (content.contains('${snakeName}ControllerProvider')) {
      print("Le listener pour $capitalizedName est déjà présent.");
      return;
    }

    final listenerBlock = '''
    ref.listen<${capitalizedName}States>(${snakeName}ControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _showFilteredError(
          context: context,
          ref: ref,
          failure: next.error!,
          action: next.action,
          title: "Erreur $capitalizedName",
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
            title: "Succès $capitalizedName",
          );
        }
      }
    });

    return child;''';

    if (content.contains('return child;')) {
      content = content.replaceFirst('return child;', listenerBlock);
      file.writeAsStringSync(content);
      print("success_error_listener.dart mis à jour pour $capitalizedName.");
    } else {
      print(
        "Erreur : Structure du build() invalide (return child; introuvable).",
      );
    }
  }

  static String _injectBaseBoilerplate(String content) {
    const buildStart = 'Widget build(BuildContext context, WidgetRef ref) {';

    const baseFunction = '''
    void _showFilteredError({
      required BuildContext context,
      required WidgetRef ref,
      required Failure failure,
      required dynamic action,
      required String title,
    }) {
      final now = DateTime.now();
      final lastErrorTime = ref.read(lastNetworkErrorTimeProvider);
      final isNetworkError = failure is NetworkFailure || failure.code == 'Network_01';

      if (isNetworkError) {
        if (lastErrorTime == null || now.difference(lastErrorTime).inSeconds > 3) {
          ref.read(lastNetworkErrorTimeProvider.notifier).state = now;
          final msg = SuccesErrorManager.getFriendlyErrorMessage(failure, action);
          Snackbar.show(context, message: msg, isError: true, isPersistent: true);
        }
      } else {
        final String msg = action?.errorMessage ?? failure.message;
        showToast(context, description: msg, isError: true, title: title);
      }
    }
''';

    if (content.contains(buildStart)) {
      return content.replaceFirst(buildStart, '$buildStart\n$baseFunction');
    }
    return content;
  }
}
