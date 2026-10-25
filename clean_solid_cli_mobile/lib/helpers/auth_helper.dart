import 'dart:io';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/template_resolver.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:path/path.dart' as p;

class AuthHelper {
  static Future<List<String>> generateAuthFeature({
    required bool useEmail,
    required bool useSocial,
  }) async {
    CliUI.header("Configuration de l'authentification");

    final filesCreated = <String>[];

    for (var type in AuthFileType.values) {
      if (type == AuthFileType.socialService && !useSocial) continue;
      if (type == AuthFileType.emailService && !useEmail) continue;

      final targetPath = _getAuthTargetPath(type);
      final created = await _processFile(
        type: type,
        targetPath: targetPath,
        useEmail: useEmail,
        useSocial: useSocial,
      );
      if (created) {
        filesCreated.add(targetPath);
      }
    }

    return filesCreated;
  }

  static Future<bool> _processFile({
    required AuthFileType type,
    required String targetPath,
    required bool useEmail,
    required bool useSocial,
  }) async {
    final file = File(targetPath);
    final projectName = GetProjetItem.getProjectName();

    String? templateContent = await TemplateResolver.readTemplate(
      'templates/auth/${type.name}.txt',
    );
    if (templateContent == null || templateContent.isEmpty) {
      CliUI.warning('template ${type.name} introuvable');
      return false;
    }

    templateContent = templateContent.replaceAll(
      '{{projectName}}',
      projectName,
    );

    if (!file.existsSync()) {
      // MODE CREATION
      String finalContent = _processConditionalBlocks(
        templateContent,
        'useEmail',
        useEmail,
      );
      finalContent = _processConditionalBlocks(
        finalContent,
        'useSocial',
        useSocial,
      );

      if (finalContent.trim().isEmpty) return false;

      file.writeAsStringSync(finalContent);
      CliUI.fileCreated(p.basename(targetPath));
      return true;
    } else {
      // MODE UPDATE
      String existingContent = file.readAsStringSync();
      String updatedContent = existingContent;

      if (useEmail) {
        updatedContent = _injectModule(
          updatedContent,
          templateContent,
          'useEmail',
        );
      }
      if (useSocial) {
        updatedContent = _injectModule(
          updatedContent,
          templateContent,
          'useSocial',
        );
      }

      if (updatedContent != existingContent) {
        file.writeAsStringSync(updatedContent);
        CliUI.fileUpdated(p.basename(targetPath));
        return true;
      }
      return false;
    }
  }

  static String _processConditionalBlocks(
    String content,
    String variable,
    bool enabled,
  ) {
    final startTag = '{{#if $variable}}';
    final endTag = '{{/if}}';

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
          '',
        );
      }
    }
    return content;
  }

  /// Injecte tous les blocs conditionnels d'un module (social/email)
  /// dans un fichier existant, en se basant sur les ancres qui precedent
  /// chaque bloc dans le template.
  ///
  /// Exemple de structure dans le template :
  ///   // {{social_controller_methods_anchor}}
  ///   {{#if useSocial}}
  ///     ...contenu...
  ///   {{/if}}
  ///     // {{social_controller_methods_anchor}}
  ///
  /// L'ancre exacte (texte integral) est preservee dans le fichier existant.
  static String _injectModule(
    String existingContent,
    String templateContent,
    String variable,
  ) {
    final startTag = '{{#if $variable}}';
    final endTag = '{{/if}}';

    if (!templateContent.contains(startTag)) return existingContent;

    int searchFrom = 0;

    while (true) {
      // Trouver le prochain bloc conditionnel
      final blockStart = templateContent.indexOf(startTag, searchFrom);
      if (blockStart == -1) break;

      final contentStart = blockStart + startTag.length;
      final blockEnd = templateContent.indexOf(endTag, contentStart);
      if (blockEnd == -1) break;

      final blockContent = templateContent
          .substring(contentStart, blockEnd)
          .trim();

      // Trouver l'ancre qui precede ce bloc (derniere ligne avant le startTag)
      final textBefore = templateContent.substring(0, blockStart).trimRight();
      final lastNewline = textBefore.lastIndexOf('\n');
      final anchorLine = (lastNewline >= 0
          ? textBefore.substring(lastNewline + 1)
          : textBefore).trim();

      // Verifier que c'est bien une ancre : // {{...}}
      if (!RegExp(r'^//\s*\{\{.+\}\}$').hasMatch(anchorLine)) {
        searchFrom = blockEnd + endTag.length;
        continue;
      }

      // Dedup : verifier si la premiere ligne du bloc existe deja
      final firstLine = blockContent.split('\n').first.trim();
      if (existingContent.contains(firstLine)) {
        searchFrom = blockEnd + endTag.length;
        continue;
      }

      // Trouver cette ancre exacte dans le fichier existant et injecter apres
      final escapedAnchor = RegExp.escape(anchorLine);
      final anchorPattern = RegExp(escapedAnchor);

      if (existingContent.contains(anchorPattern)) {
        existingContent = existingContent.replaceFirst(
          anchorPattern,
          '$anchorLine\n$blockContent',
        );
      } else {
        CliUI.warning(
          'Ancre "$anchorLine" introuvable dans le fichier existant',
        );
      }

      searchFrom = blockEnd + endTag.length;
    }

    return existingContent;
  }

  static String _getAuthTargetPath(AuthFileType type) {
    final root = p.join('lib', 'features', 'auth');
    String dir;
    String file;

    switch (type) {
      case AuthFileType.entity:
        dir = p.join(root, 'domain', 'entity');
        file = 'auth_entity.dart';
      case AuthFileType.model:
        dir = p.join(root, 'data', 'model');
        file = 'auth_model.dart';
      case AuthFileType.remoteSource:
        dir = p.join(root, 'data', 'source');
        file = 'auth_remote_source.dart';
      case AuthFileType.remoteSourceImpl:
        dir = p.join(root, 'data', 'source');
        file = 'auth_remote_source_impl.dart';
      case AuthFileType.socialService:
        dir = p.join(root, 'data', 'source');
        file = 'social_auth_service.dart';
      case AuthFileType.emailService:
        dir = p.join(root, 'data', 'source');
        file = 'email_auth_service.dart';
      case AuthFileType.repository:
        dir = p.join(root, 'domain', 'repository');
        file = 'auth_repository.dart';
      case AuthFileType.repositoryImpl:
        dir = p.join(root, 'data', 'repository');
        file = 'auth_repository_impl.dart';
      case AuthFileType.usecases:
        dir = p.join(root, 'domain', 'usecases');
        file = 'auth_usecases.dart';
      case AuthFileType.states:
        dir = p.join(root, 'presentation', 'states');
        file = 'auth_states.dart';
      case AuthFileType.action:
        dir = p.join(root, 'domain', 'actions');
        file = 'auth_actions.dart';
      case AuthFileType.controller:
        dir = p.join(root, 'presentation', 'controller');
        file = 'auth_controller.dart';
    }

    final directory = Directory(dir);
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return p.join(dir, file);
  }
}
