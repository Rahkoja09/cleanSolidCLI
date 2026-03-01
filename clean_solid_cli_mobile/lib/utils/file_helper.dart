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

  static void generateTargePathAndHaveFileName({
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
        fileName = "${featureName}Local_source.dart";
        break;
      case FileTemplateType.remoteSource:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/source";
        fileName = "${featureName}Remote_source.dart";
        break;
      case FileTemplateType.controller:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/controller";
        fileName = "${featureName}_controller.dart";
        break;
      case FileTemplateType.model:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/model";
        break;
      case FileTemplateType.usecase:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDomainName}/usecases";
        break;
      case FileTemplateType.states:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/states";
        break;
      case FileTemplateType.repository:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDomainName}/repository";
        break;
      case FileTemplateType.repositoryImpl:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDataName}/repository";
        break;
      case FileTemplateType.pages:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/pages";
        break;
      case FileTemplateType.widgets:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getPresentationName}/widgets";
        break;
      case FileTemplateType.di:
        directoryPath = "lib/core/di";
        break;
      case FileTemplateType.entity:
        directoryPath =
            "lib/features/$featureName/${architecture.getLayers.getDomainName}/entity";
        break;
    }
    final directory = Directory(directoryPath);
    directory.createSync(recursive: true);
  }
}
