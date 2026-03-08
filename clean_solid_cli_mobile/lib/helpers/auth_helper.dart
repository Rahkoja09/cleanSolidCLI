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
    print("\n == Analyse de la feature Authentication...");

    for (var type in AuthFileType.values) {
      // Ignorer les fichiers de services s'ils ne sont pas demandés --------
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
    print("\n == Operation terminee avec succes !");
  }

  static Future<void> _processFile({
    required AuthFileType type,
    required String targetPath,
    required bool useEmail,
    required bool useSocial,
  }) async {
    final file = File(targetPath);
    final projectName = GetProjetItem.getProjectName();

    // 1. Obtenir le contenu brut du template --------
    String templateContent = await _getTemplateContent(type);
    if (templateContent.isEmpty) return;

    // Remplacements de base
    templateContent = templateContent.replaceAll(
      "{{projectName}}",
      projectName,
    );

    if (!file.existsSync()) {
      // MODE CREATION : On génère le fichier normalement ----------
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

      file.writeAsStringSync(finalContent);
      print("🆕 Genere : ${p.basename(targetPath)}");
    } else {
      // MODE UPDATE : Le fichier existe, on injecte uniquement ce qui manque -------------
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
        print("🔄 Mis a jour : ${p.basename(targetPath)}");
      }
    }
  }

  // Injecte le contenu d'un bloc {{#if variable}} du template vers le fichier existant --------
  static String _injectModule(
    String existingContent,
    String templateContent,
    String variable,
  ) {
    final startTag = "{{#if $variable}}";
    final endTag = "{{/if}}";

    if (!templateContent.contains(startTag)) return existingContent;

    // 1. Extraire le bloc du template
    int startIdx = templateContent.indexOf(startTag) + startTag.length;
    int endIdx = templateContent.indexOf(endTag, startIdx);
    String blockToInject = templateContent.substring(startIdx, endIdx).trim();

    // 2. Trouver l'ancre correspondante dans le fichier existant --------
    // On assume que l'ancre a le même nom que le bloc (ex: social_methods_anchor) ------------
    // Pour simplifier, on cherche si le contenu est déjà là
    if (existingContent.contains(blockToInject.split('\n').first.trim())) {
      return existingContent; // Déjà injecté
    }

    // Ici, on utilise une logique simple de remplacement d'ancre -------
    // On cherche l'ancre dans le fichier existant et on remplace ------
    // Note: Dans les templates, on a mis // {{social_methods_anchor}} ----
    final anchorName = variable == "useEmail" ? "email" : "social";

    // On remplace l'ancre par l'ancre + le bloc pour garder l'ancre pour le futur ---------
    final pattern = RegExp(r'\/\/ {{.*' + anchorName + r'.*anchor}}');

    if (existingContent.contains(pattern)) {
      // On injecte le bloc entre les deux ancres trouvées ---------
      return existingContent.replaceAll(
        pattern,
        "// {{$anchorName}_anchor}\n$blockToInject\n// {{$anchorName}_anchor}",
      );
    }

    return existingContent;
  }

  static Future<String> _getTemplateContent(AuthFileType type) async {
    final templateName = _getTemplateName(type);
    final packageUri = Uri.parse(
      'package:clean_solid_cli_mobile/templates/auth/$templateName.txt',
    );
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) return "";
    final templateFile = File(resolvedUri.toFilePath());
    return templateFile.existsSync() ? templateFile.readAsStringSync() : "";
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
      int endIndex = content.indexOf(endTag, startIndex) + endTag.length;

      if (enabled) {
        String blockContent = content.substring(
          startIndex + startTag.length,
          endIndex - endTag.length,
        );
        content = content.replaceRange(startIndex, endIndex, blockContent);
      } else {
        content = content.replaceRange(startIndex, endIndex, "");
      }
    }
    return content;
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

  static String _getTemplateName(AuthFileType type) {
    return type.name.replaceAll(RegExp(r'(?=[A-Z])'), '_').toLowerCase();
  }
}
