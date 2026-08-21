import 'dart:io';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/template_resolver.dart';
import 'package:path/path.dart' as p;

class TestGenerator {
  static Future<int> generate({
    required String featureName,
    required String projectName,
  }) async {
    final snakeName = ReformateClassName.formatToSnakeCase(featureName);
    var generated = 0;

    generated += await _writeTestFromTemplate(
      templateName: 'repository_test',
      targetDir: p.join('test', 'features', snakeName, 'data', 'repository'),
      fileName: '${snakeName}_repository_impl_test.dart',
      projectName: projectName,
      snakeName: snakeName,
    );

    generated += await _writeTestFromTemplate(
      templateName: 'controller_test',
      targetDir: p.join(
        'test',
        'features',
        snakeName,
        'presentation',
        'controller',
      ),
      fileName: '${snakeName}_controller_test.dart',
      projectName: projectName,
      snakeName: snakeName,
    );

    if (generated > 0) {
      CliUI.info('Tests unitaires generes : $generated fichier(s)');
    } else {
      CliUI.warning('Aucun test genere (templates introuvables ou deja existants)');
    }
    return generated;
  }

  static Future<int> _writeTestFromTemplate({
    required String templateName,
    required String targetDir,
    required String fileName,
    required String projectName,
    required String snakeName,
  }) async {
    final templatePath = 'templates/create/$templateName.txt';
    final resolvedPath = await TemplateResolver.resolve(templatePath);

    if (resolvedPath == null) {
      CliUI.warning('Template $templateName introuvable.');
      return 0;
    }

    String content = File(resolvedPath).readAsStringSync();
    final pascalName = ReformateClassName.capitalizeClassName(
      featureName: snakeName,
    );
    content = content.replaceAll('{{projectName}}', projectName);
    content = content.replaceAll('{{name}}', pascalName);
    content = content.replaceAll('{{snakeName}}', snakeName);

    final targetPath = p.join(targetDir, fileName);
    final file = File(targetPath);

    if (file.existsSync()) {
      CliUI.fileSkipped(fileName);
      return 0;
    }

    Directory(targetDir).createSync(recursive: true);
    file.writeAsStringSync(content);
    CliUI.fileCreated(fileName);
    activeTracker?.trackCreated(targetPath);
    return 1;
  }
}
