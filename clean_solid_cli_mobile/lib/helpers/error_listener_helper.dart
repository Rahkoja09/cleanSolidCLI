import 'dart:io';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:path/path.dart' as p;

class ErrorListenerHelper {
  static void updateErrorListener(String capitalizedName, String snakeName) {
    final filePath = p.join(
      'lib',
      'core',
      'mainErrorListener',
      'success_error_listener.dart',
    );
    final file = File(filePath);

    // FIX: créer le fichier s'il n'existe pas (première feature du projet)
    if (!file.existsSync()) {
      _createListenerFile(file);
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
      CliUI.info('$capitalizedName listener deja present');
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
            title: "Succes $capitalizedName",
          );
        }
      }
    });''';

    if (content.contains('// [LISTENERS_ANCHOR]')) {
      content = content.replaceFirst(
        '// [LISTENERS_ANCHOR]',
        '$listenerBlock\n    // [LISTENERS_ANCHOR]',
      );
      file.writeAsStringSync(content);
      CliUI.success('ErrorListener mis a jour pour $capitalizedName');
    } else {
      // FIX: au lieu d'abandonner, injecter le boilerplate puis réessayer
      CliUI.warning(
        'ancre [LISTENERS_ANCHOR] manquante, injection du boilerplate...',
      );
      content = _injectBaseBoilerplate(content);
      if (content.contains('// [LISTENERS_ANCHOR]')) {
        content = content.replaceFirst(
          '// [LISTENERS_ANCHOR]',
          '$listenerBlock\n    // [LISTENERS_ANCHOR]',
        );
        file.writeAsStringSync(content);
        CliUI.success(
          'ErrorListener mis a jour pour $capitalizedName (apres injection du boilerplate)',
        );
      } else {
        CliUI.error('Impossible d\'injecter le listener pour $capitalizedName');
      }
    }
  }

  // FIX NOUVEAU: créer le fichier avec le boilerplate et l'ancre
  static void _createListenerFile(File file) {
    final projectName = GetProjetItem.getProjectName();
    file.parent.createSync(recursive: true);

    final content = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$projectName/core/utils/typedefs.dart';
import 'package:$projectName/core/mainErrorListener/last_network_time_provider.dart';
import 'package:$projectName/core/exceptions/failures.dart';
import 'package:$projectName/core/mainErrorListener/success_error_manager.dart';
import 'package:$projectName/shared/widgets/popup/snackbar.dart';
import 'package:$projectName/shared/widgets/popup/toastification.dart';

class SuccessErrorListener extends ConsumerWidget {
  const SuccessErrorListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final msg = SuccessErrorManager.getFriendlyErrorMessage(failure, action);
          Snackbar.show(context, message: msg, isError: true, isPersistent: true);
        }
      } else {
        final String msg = action?.errorMessage ?? failure.message;
        showToast(context, description: msg, isError: true, title: title);
      }
    }

    // [LISTENERS_ANCHOR]

    return child;
  }
}
''';
    file.writeAsStringSync(content);
    CliUI.fileCreated('success_error_listener.dart');
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
          final msg = SuccessErrorManager.getFriendlyErrorMessage(failure, action);
          Snackbar.show(context, message: msg, isError: true, isPersistent: true);
        }
      } else {
        final String msg = action?.errorMessage ?? failure.message;
        showToast(context, description: msg, isError: true, title: title);
      }
    }

    // [LISTENERS_ANCHOR]
''';

    if (content.contains(buildStart)) {
      return content.replaceFirst(buildStart, '$buildStart\n$baseFunction');
    }
    return content;
  }
}
