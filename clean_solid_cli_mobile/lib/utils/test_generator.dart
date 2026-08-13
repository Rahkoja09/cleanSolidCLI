import 'dart:io';
import 'dart:isolate';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:path/path.dart' as p;

class TestGenerator {
  static Future<void> generate({
    required String featureName,
    required String projectName,
  }) async {
    final snakeName = ReformateClassName.formatToSnakeCase(featureName);

    await _writeTestFromTemplate(
      templateName: 'repository_test',
      targetDir: p.join('test', 'features', snakeName, 'data', 'repository'),
      fileName: '${snakeName}_repository_impl_test.dart',
      projectName: projectName,
      snakeName: snakeName,
    );

    await _writeTestFromTemplate(
      templateName: 'controller_test',
      targetDir: p.join('test', 'features', snakeName, 'presentation', 'controller'),
      fileName: '${snakeName}_controller_test.dart',
      projectName: projectName,
      snakeName: snakeName,
    );

    print('  Tests unitaires generes : repository + controller');
  }

  static Future<void> _writeTestFromTemplate({
    required String templateName,
    required String targetDir,
    required String fileName,
    required String projectName,
    required String snakeName,
  }) async {
    final packageUri = Uri.parse(
      "package:clean_solid_cli_mobile/templates/create/$templateName.txt",
    );
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) {
      print("  Template $templateName introuvable.");
      return;
    }
    final templateFile = File(resolvedUri.toFilePath());
    if (!templateFile.existsSync()) {
      print("  Template $templateName.txt inexistant.");
      return;
    }

    String content = templateFile.readAsStringSync();
    final pascalName = ReformateClassName.capitalizeClassName(featureName: snakeName);
    content = content.replaceAll('{{projectName}}', projectName);
    content = content.replaceAll('{{name}}', pascalName);
    content = content.replaceAll('{{snakeName}}', snakeName);

    final targetPath = p.join(targetDir, fileName);
    final file = File(targetPath);
    if (file.existsSync()) {
      print("  $fileName existe deja. Saut.");
      return;
    }
    Directory(targetDir).createSync(recursive: true);
    file.writeAsStringSync(content);
    print("  Test genere : $fileName");
  }
}
