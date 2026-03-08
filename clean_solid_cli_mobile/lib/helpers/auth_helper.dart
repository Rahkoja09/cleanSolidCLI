import 'dart:io';
import 'dart:isolate';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:path/path.dart' as p;
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';

class AuthHelper {
  static Future<void> generateAuthFeature({
    required bool useEmail,
    required bool useSocial,
  }) async {
    print("Analyse de la feature Authentication...");

    for (var type in AuthFileType.values) {
      if (type == AuthFileType.socialService && !useSocial) continue;
      if (type == AuthFileType.emailService && !useEmail) continue;

      final targetPath = _getAuthTargetPath(type);
      await _processFile(
        type: type,
        targetPath: targetPath,
        useEmail: useEmail,
        useSocial: useSocial,
      );
    }
    print("Operation terminee avec succes.");
  }

  static Future<void> _processFile({
    required AuthFileType type,
    required String targetPath,
    required bool useEmail,
    required bool useSocial,
  }) async {
    final file = File(targetPath);
    final projectName = GetProjetItem.getProjectName();

    String templateContent = await _getTemplateContent(type);
    if (templateContent.isEmpty) {
      print("Erreur : Template introuvable pour ${type.name}");
      return;
    }

    templateContent = templateContent.replaceAll(
      "{{projectName}}",
      projectName,
    );

    if (!file.existsSync()) {
      // MODE CREATION
      String finalContent = _processConditionalBlocks(
        templateContent,
        "useEmail",
        useEmail,
      );
      finalContent = _processConditionalBlocks(
        finalContent,
        "useSocial",
        useSocial,
      );

      if (finalContent.trim().isEmpty) return;

      file.writeAsStringSync(finalContent);
      print("Genere : ${p.basename(targetPath)}");
    } else {
      // MODE UPDATE
      String existingContent = file.readAsStringSync();
      String updatedContent = existingContent;

      if (useEmail) {
        updatedContent = _injectModule(
          updatedContent,
          templateContent,
          "useEmail",
        );
      }
      if (useSocial) {
        updatedContent = _injectModule(
          updatedContent,
          templateContent,
          "useSocial",
        );
      }

      if (updatedContent != existingContent) {
        file.writeAsStringSync(updatedContent);
        print("Mis a jour : ${p.basename(targetPath)}");
      }
    }
  }

  static String _processConditionalBlocks(
    String content,
    String variable,
    bool enabled,
  ) {
    final startTag = "{{#if $variable}}";
    final endTag = "{{/if}}";

    while (content.contains(startTag)) {
      int startIndex = content.indexOf(startTag);
      int endIndex = content.indexOf(endTag, startIndex);

      if (endIndex == -1) break;

      if (enabled) {
        String blockContent = content.substring(
          startIndex + startTag.length,
          endIndex,
        );
        content = content.replaceRange(
          startIndex,
          endIndex + endTag.length,
          blockContent,
        );
      } else {
        content = content.replaceRange(
          startIndex,
          endIndex + endTag.length,
          "",
        );
      }
    }
    return content;
  }

  static String _injectModule(
    String existingContent,
    String templateContent,
    String variable,
  ) {
    final startTag = "{{#if $variable}}";
    final endTag = "{{/if}}";

    if (!templateContent.contains(startTag)) return existingContent;

    int startIdx = templateContent.indexOf(startTag) + startTag.length;
    int endIdx = templateContent.indexOf(endTag, startIdx);
    String blockToInject = templateContent.substring(startIdx, endIdx).trim();

    if (existingContent.contains(blockToInject.split('\n').first.trim())) {
      return existingContent;
    }

    final anchorName = variable == "useEmail" ? "email" : "social";
    final pattern = RegExp(r'\/\/ {{.*' + anchorName + r'.*anchor}}');

    if (existingContent.contains(pattern)) {
      return existingContent.replaceFirst(
        pattern,
        "// {{$anchorName}_anchor}\n$blockToInject\n// {{$anchorName}_anchor}",
      );
    }

    return existingContent;
  }

  static Future<String> _getTemplateContent(AuthFileType type) async {
    // Utilisation directe du nom de l'enum pour correspondre au fichier .txt
    final templateName = type.name;
    final packageUri = Uri.parse(
      'package:clean_solid_cli_mobile/templates/auth/$templateName.txt',
    );

    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) return "";

    final templateFile = File(resolvedUri.toFilePath());
    return templateFile.existsSync() ? templateFile.readAsStringSync() : "";
  }

  static String _getAuthTargetPath(AuthFileType type) {
    final root = p.join("lib", "features", "auth");
    String dir;
    String file;

    switch (type) {
      case AuthFileType.entity:
        dir = p.join(root, "domain", "entity");
        file = "auth_entity.dart";
        break;
      case AuthFileType.model:
        dir = p.join(root, "data", "model");
        file = "auth_model.dart";
        break;
      case AuthFileType.remoteSource:
        dir = p.join(root, "data", "source");
        file = "auth_remote_source.dart";
        break;
      case AuthFileType.remoteSourceImpl:
        dir = p.join(root, "data", "source");
        file = "auth_remote_source_impl.dart";
        break;
      case AuthFileType.socialService:
        dir = p.join(root, "data", "source");
        file = "social_auth_service.dart";
        break;
      case AuthFileType.emailService:
        dir = p.join(root, "data", "source");
        file = "email_auth_service.dart";
        break;
      case AuthFileType.repository:
        dir = p.join(root, "domain", "repository");
        file = "auth_repository.dart";
        break;
      case AuthFileType.repositoryImpl:
        dir = p.join(root, "data", "repository");
        file = "auth_repository_impl.dart";
        break;
      case AuthFileType.usecases:
        dir = p.join(root, "domain", "usecases");
        file = "auth_usecases.dart";
        break;
      case AuthFileType.states:
        dir = p.join(root, "presentation", "states");
        file = "auth_states.dart";
        break;
      case AuthFileType.action:
        dir = p.join(root, "domain", "actions");
        file = "auth_actions.dart";
        break;
      case AuthFileType.controller:
        dir = p.join(root, "presentation", "controller");
        file = "auth_controller.dart";
        break;
    }

    final directory = Directory(dir);
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return p.join(dir, file);
  }
}
