import 'dart:io';

import 'package:clean_solid_cli_mobile/templates/architectures/architectures.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:path/path.dart' as p;

class FileHelper {
  static void generateFormTemplate({
    required String featureName,
    required String templateName,
    required String targetPath,
  }) {
    final templateFile = File(p.join("lib", "templates", "$templateName.text"));

    if (!templateFile.existsSync()) {
      print("Le template nomée $templateName n'existe pas");
      return;
    }

    String content = templateFile.readAsStringSync();

    final capitalizedClassName = ReformateClassName.capitalizeClassName(
      featureName: featureName,
    );

    content.replaceAll("{{name}}", capitalizedClassName);

    final file = File(targetPath);

    file.writeAsStringSync(content);
  }

  static String generateAndGetTargetPath({
    required String featureName,
    required FileTemplateType temaplateType,
    required Architectures architecture,
  }) {
    String directoryPath;
    String fileName;

    switch (temaplateType) {
      case FileTemplateType.localSource:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/source";
        fileName = "${featureName}_local_source.dart";
        break;
      case FileTemplateType.remoteSource:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/source";
        fileName = "${featureName}_remote_source.dart";
        break;
      case FileTemplateType.controller:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/controller";
        fileName = "${featureName}_controller.dart";
        break;
      case FileTemplateType.model:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/model";
        fileName = "${featureName}_model.dart";
        break;
      case FileTemplateType.usecase:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDomainName}/usecases";
        fileName = "${featureName}_usecases.dart";
        break;
      case FileTemplateType.states:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/states";
        fileName = "${featureName}_states.dart";
        break;
      case FileTemplateType.repository:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDomainName}/repository";
        fileName = "${featureName}_repository.dart";
        break;
      case FileTemplateType.repositoryImpl:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/repository";
        fileName = "${featureName}_repository_impl.dart";
        break;
      case FileTemplateType.pages:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/pages";
        fileName = "$featureName.dart";
        break;
      case FileTemplateType.widgets:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/widgets";
        fileName = "widgets.dart";
        break;
      case FileTemplateType.di:
        directoryPath = "lib/core/di";
        fileName = "dependancy_injection.dart";
        break;
      case FileTemplateType.entity:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDomainName}/entity";
        fileName = "${featureName}entity.dart";
        break;
    }

    final directory = Directory(directoryPath);
    if (directory.existsSync()) {
      print("Le chemin existe déjà!");
      return "$directory/$fileName";
    } else {
      directory.createSync(recursive: true);
    }

    return "$directory/$fileName";
  }
}
