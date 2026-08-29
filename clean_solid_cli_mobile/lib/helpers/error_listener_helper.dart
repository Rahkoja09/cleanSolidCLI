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

    if (!file.existsSync()) {
      _createListenerFile(file);
    }

    String content = file.readAsStringSync();
    final projectName = GetProjetItem.getProjectName();

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
          AppToast.success(context, SuccesErrorManager.getFriendlySuccessMessage(next.action));
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
      CliUI.warning(
        'ancre [LISTENERS_ANCHOR] manquante dans success_error_listener.dart',
      );
      CliUI.error('Impossible d\'injecter le listener pour $capitalizedName');
    }
  }

  static void _createListenerFile(File file) {
    final projectName = GetProjetItem.getProjectName();
    file.parent.createSync(recursive: true);

    final content = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$projectName/core/mainErrorListener/last_network_time_provider.dart';
import 'package:$projectName/core/error/failures.dart';
import 'package:$projectName/core/error/error_manager.dart';
import 'package:$projectName/shared/widgets/popup/snackbar.dart';
import 'package:$projectName/shared/widgets/popup/show_toast.dart';

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
      final lastErrorTime = ref.read(lastNetworkTimeProvider);
      final isNetworkError = failure is NetworkFailure || failure.code == 'Network_01';

      if (isNetworkError) {
        if (lastErrorTime == null || now.difference(lastErrorTime).inSeconds > 3) {
          ref.read(lastNetworkTimeProvider.notifier).state = now;
          final msg = SuccesErrorManager.getFriendlyErrorMessage(failure, action);
          AppSnackbar.show(context, msg, backgroundColor: Colors.red);
        }
      } else {
        final msg = SuccesErrorManager.getFriendlyErrorMessage(failure, action);
        AppToast.error(context, msg);
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
}
