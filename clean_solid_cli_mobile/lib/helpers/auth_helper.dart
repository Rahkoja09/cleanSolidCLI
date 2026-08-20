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

  static String _injectModule(
    String existingContent,
    String templateContent,
    String variable,
  ) {
    final startTag = '{{#if $variable}}';
    final endTag = '{{/if}}';

    if (!templateContent.contains(startTag)) return existingContent;

    int startIdx = templateContent.indexOf(startTag) + startTag.length;
    int endIdx = templateContent.indexOf(endTag, startIdx);
    String blockToInject = templateContent.substring(startIdx, endIdx).trim();

    if (existingContent.contains(blockToInject.split('\n').first.trim())) {
      return existingContent;
    }

    final anchorName = variable == 'useEmail' ? 'email' : 'social';
    final pattern = RegExp(r'// {{.*' + anchorName + r'.*anchor}}');

    if (existingContent.contains(pattern)) {
      return existingContent.replaceFirst(
        pattern,
        '// {{$anchorName}_anchor}\n$blockToInject\n// {{$anchorName}_anchor}',
      );
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
