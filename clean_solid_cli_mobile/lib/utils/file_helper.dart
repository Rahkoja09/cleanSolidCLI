import 'dart:io';

import 'package:clean_solid_cli_mobile/architectures/architectures.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:path/path.dart' as p;

class FileHelper {
  static void generateFormTemplate({
    required String featureName,
    required String templateName,
    required String targetPath,
  }) {
    final scriptPath = Platform.script.toFilePath();
    final templateDir = p.join(
      p.dirname(p.dirname(scriptPath)),
      'lib',
      'templates',
    );
    final templateFile = File(p.join(templateDir, "$templateName.txt"));

    if (!templateFile.existsSync()) {
      print(
        " Le template nommé $templateName n'existe pas à l'adresse ${templateFile.path}",
      );
      return;
    }

    String content = templateFile.readAsStringSync();

    final capitalizedClassName = ReformateClassName.capitalizeClassName(
      featureName: featureName,
    );

    content = content.replaceAll("{{name}}", capitalizedClassName);

    final file = File(targetPath);

    if (file.existsSync()) {
      print(
        "Le fichier ${p.basename(targetPath)} existe déjà. Saut de l'étape.",
      );
      return;
    }

    file.writeAsStringSync(content);
    print("Fichier généré : ${p.basename(targetPath)}");
  }

  static String generateAndGetTargetPath({
    required String featureName,
    required FileTemplateType temaplateType,
    required Architectures architecture,
  }) {
    String directoryPath;
    String fileName;
    final snakeFeatureName = ReformateClassName.formatToSnakeCase(featureName);

    switch (temaplateType) {
      case FileTemplateType.localSource:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDataName}/source";
        fileName = "${snakeFeatureName}_local_source.dart";
        break;
      case FileTemplateType.remoteSource:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDataName}/source";
        fileName = "${snakeFeatureName}_remote_source.dart";
        break;
      case FileTemplateType.controller:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getPresentationName}/controller";
        fileName = "${snakeFeatureName}_controller.dart";
        break;
      case FileTemplateType.model:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDataName}/model";
        fileName = "${snakeFeatureName}_model.dart";
        break;
      case FileTemplateType.usecase:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDomainName}/usecases";
        fileName = "${snakeFeatureName}_usecases.dart";
        break;
      case FileTemplateType.states:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getPresentationName}/states";
        fileName = "${snakeFeatureName}_states.dart";
        break;
      case FileTemplateType.repository:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDomainName}/repository";
        fileName = "${snakeFeatureName}_repository.dart";
        break;
      case FileTemplateType.repositoryImpl:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDataName}/repository";
        fileName = "${snakeFeatureName}_repository_impl.dart";
        break;
      case FileTemplateType.pages:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getPresentationName}/pages";
        fileName = "$snakeFeatureName.dart";
        break;
      case FileTemplateType.widgets:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getPresentationName}/widgets";
        fileName = "widgets.dart";
        break;
      case FileTemplateType.di:
        directoryPath = "lib/core/di";
        fileName = "injection_container.dart";
        break;
      case FileTemplateType.entity:
        directoryPath =
            "lib/features/$snakeFeatureName/${architecture.getLayers.getDomainName}/entity";
        fileName = "${snakeFeatureName}entity.dart";
        break;
    }

    final finalDirectory = Directory(directoryPath);

    if (!finalDirectory.existsSync()) {
      finalDirectory.createSync(recursive: true);
    }

    return p.join(finalDirectory.path, fileName);
  }
}
