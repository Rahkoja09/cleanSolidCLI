import 'dart:io';
import 'dart:isolate';

import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:path/path.dart' as p;

class FileHelper {
  static Future<void> generateFormTemplate({
    required String featureName,
    required String templateName,
    required String targetPath,
  }) async {
    final packageUri = Uri.parse(
      'package:clean_solid_cli_mobile/templates/create/$templateName.txt',
    );
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);

    if (resolvedUri == null) {
      print("  Impossible de résoudre le template $templateName");
      return;
    }

    final templateFile = File(resolvedUri.toFilePath());
    if (!templateFile.existsSync()) {
      print("  Le template n'existe pas : ${templateFile.path}");
      return;
    }

    String content = templateFile.readAsStringSync();

    final projectName = GetProjetItem.getProjectName();
    final snakeFeatureName = ReformateClassName.formatToSnakeCase(featureName);
    final capitalizedClassName = ReformateClassName.capitalizeClassName(
      featureName: snakeFeatureName,
    );

    content = content.replaceAll("{{projectName}}", projectName);
    content = content.replaceAll("{{name}}", capitalizedClassName);
    content = content.replaceAll("{{snakeName}}", snakeFeatureName);

    final file = File(targetPath);
    if (file.existsSync()) {
      print("  ${p.basename(targetPath)} existe déjà. Saut.");
      return;
    }

    file.writeAsStringSync(content);
    print("  Fichier généré : ${p.basename(targetPath)}");
  }

  static String generateAndGetTargetPath({
    required String featureName,
    required FileTemplateType templateType,
  }) {
    if (featureName.contains('..') ||
        featureName.contains('/') ||
        featureName.contains('\\')) {
      throw ArgumentError(
        'Le nom de feature contient des caractères interdits.',
      );
    }

    final snakeFeatureName = ReformateClassName.formatToSnakeCase(featureName);
    final featureRoot = p.join("lib", "features", snakeFeatureName);

    String directoryPath;
    String fileName;

    switch (templateType) {
      case FileTemplateType.remoteSource:
        directoryPath = p.join(featureRoot, "data", "source");
        fileName = "${snakeFeatureName}_remote_source.dart";
      case FileTemplateType.controller:
        directoryPath = p.join(featureRoot, "presentation", "controller");
        fileName = "${snakeFeatureName}_controller.dart";
      case FileTemplateType.model:
        directoryPath = p.join(featureRoot, "data", "model");
        fileName = "${snakeFeatureName}_model.dart";
      case FileTemplateType.usecase:
        directoryPath = p.join(featureRoot, "domain", "usecases");
        fileName = "${snakeFeatureName}_usecases.dart";
      case FileTemplateType.states:
        directoryPath = p.join(featureRoot, "presentation", "states");
        fileName = "${snakeFeatureName}_states.dart";
      case FileTemplateType.repository:
        directoryPath = p.join(featureRoot, "domain", "repository");
        fileName = "${snakeFeatureName}_repository.dart";
      case FileTemplateType.repositoryImpl:
        directoryPath = p.join(featureRoot, "data", "repository");
        fileName = "${snakeFeatureName}_repository_impl.dart";
      case FileTemplateType.pages:
        directoryPath = p.join(featureRoot, "presentation", "pages");
        fileName = "${snakeFeatureName}_page.dart";
      case FileTemplateType.di:
        directoryPath = p.join("lib", "core", "di");
        fileName = "injection_container.dart";
      case FileTemplateType.entity:
        directoryPath = p.join(featureRoot, "domain", "entity");
        fileName = "${snakeFeatureName}_entity.dart";
      case FileTemplateType.action:
        directoryPath = p.join(featureRoot, "domain", "actions");
        fileName = "${snakeFeatureName}_actions.dart";
      case FileTemplateType.successErrorListener:
        directoryPath = p.join("lib", "core", "mainErrorListener");
        fileName = "success_error_listener.dart";
      case FileTemplateType.lastNetworkTimeProvider:
        directoryPath = p.join("lib", "core", "mainErrorListener");
        fileName = "last_network_time_provider.dart";
    }

    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return p.join(directoryPath, fileName);
  }
}
