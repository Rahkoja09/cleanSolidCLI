import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';
import 'package:clean_solid_cli_mobile/utils/template_resolver.dart';
import 'package:clean_solid_cli_mobile/utils/pubspec_helper.dart';

class InitCommand extends Command {
  @override
  String get description =>
      'Creer un projet Flutter complet en Clean Architecture depuis zero';

  @override
  String get name => 'init';

  InitCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Nom du projet (ex: ma_super_app)',
      mandatory: false,
    );
    argParser.addOption(
      'backend',
      abbr: 'b',
      help: 'Backend a configurer (supabase | firebase | none)',
      defaultsTo: 'supabase',
      allowed: ['supabase', 'firebase', 'none'],
    );
    argParser.addOption(
      'org',
      abbr: 'o',
      help: 'Package bundle ID (ex: com.company)',
      defaultsTo: 'com.example',
    );
    argParser.addFlag(
      'no-git',
      help: 'Skip git initialization',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final projectName =
        (argResults!['name'] as String?) ??
        (argResults!.rest.isNotEmpty ? argResults!.rest.first : null);

    if (projectName == null || projectName.trim().isEmpty) {
      throw const CliException(
        'Veuillez specifier un nom de projet.\n'
        '   Usage : cscm init <nom_du_projet>\n'
        '   Exemple : cscm init mon_app',
      );
    }

    final backend = argResults?['backend'] as String? ?? 'supabase';
    final org = argResults?['org'] as String? ?? 'com.example';
    final noGit = argResults?['no-git'] as bool? ?? false;
    final snakeName = projectName.replaceAll(' ', '_').toLowerCase();

    // Validation anti path traversal
    if (projectName.contains('..') ||
        projectName.contains('/') ||
        projectName.contains('\\')) {
      throw const CliException(
        'Le nom du projet contient des caracteres interdits.',
      );
    }

    // Validation org format
    if (!RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(org)) {
      throw CliException(
        'Format d\'org invalide: "$org".\n'
        '   Utilisez le format: com.company (ex: com.example, fr.maboite)',
      );
    }

    // Verifier qu'on est pas dans un projet existant
    if (File('pubspec.yaml').existsSync()) {
      throw CliException(
        'Un projet Flutter existe deja dans ce dossier.\n'
        '   Si vous voulez configurer CSCM, utilisez : cscm config -n $snakeName',
      );
    }

    CliUI.header('Initialisation du projet [$snakeName]');

    // ── 1. flutter create ──
    CliUI.section('Flutter create');

    if (!GitHelper.isFlutterInstalled()) {
      throw const CliException(
        'Flutter n\'est pas installe ou n\'est pas dans le PATH.\n'
        '   Installez Flutter: https://docs.flutter.dev/get-started/install',
      );
    }

    await CliUI.withSpinner('flutter create $snakeName --org $org', () async {
      final exitCode = GitHelper.flutterCreate(
        projectName: snakeName,
        org: org,
      );
      if (exitCode != 0) {
        throw CliException(
          'flutter create a echoue (exit code: $exitCode).\n'
          '   Verifiez que Flutter est correctement installe.',
        );
      }
      return null;
    });

    CliUI.success('Projet Flutter cree');

    // ── 2. Overlay clean architecture ──
    CliUI.section('Clean Architecture overlay');
    _createProjectStructure(snakeName, backend);

    // ── 3. .cscm.yaml ──
    ConfigReader.createConfig(projectName: snakeName, backend: backend);
    CliUI.success('.cscm.yaml cree');

    // ── 4. .cscm-state.yaml ──
    _createProjectState(snakeName, snakeName, backend);
    CliUI.success('.cscm-state.yaml cree');

    // ── 5. Git init ──
    if (!noGit) {
      CliUI.section('Git');
      final projectDir = snakeName;

      if (GitHelper.isGitInstalled()) {
        if (!GitHelper.isGitRepo()) {
          if (GitHelper.initRepo(directory: projectDir)) {
            CliUI.success('git init');

            final commitResult = GitHelper.commit(
              message: 'init: cscm project $snakeName with clean architecture',
              directory: projectDir,
            );
            if (commitResult != null) {
              CliUI.success('Initial commit cree');
            } else {
              CliUI.warning(
                'Initial commit echoue (peut-etre .gitignore actif)',
              );
            }
          } else {
            CliUI.warning('git init a echoue');
          }
        } else {
          CliUI.info('Git repo deja present');
        }
      } else {
        CliUI.warning('Git non installe, initialisation git ignoree');
      }
    }

    // ── 6. Summary ──
    print('');
    CliUI.success('Projet [$snakeName] cree avec succes !');
    print('');
    CliUI.nextSteps([
      'cd $snakeName',
      'flutter pub get',
      if (backend == 'supabase' || backend == 'firebase')
        'Configurer le fichier .env avec vos cles $backend',
      'cscm create ma_feature -i "nom:string,prix:double"',
    ]);
  }

  /// Overlay clean architecture files on top of the flutter create project.
  Future<void> _createProjectStructure(String name, String backend) async {
    final projectDir = Directory(name);
    final libDir = '${projectDir.path}/lib';
    final hasSupabase = backend == 'supabase';
    final pascalName = ReformateClassName.capitalizeClassName(
      featureName: name,
    );

    // --- DIRECTORIES ---
    final directories = [
      '$libDir/config/constants',
      '$libDir/config/theme',
      '$libDir/core/app',
      '$libDir/core/actions',
      '$libDir/core/di',
      '$libDir/core/error',
      '$libDir/core/network',
      '$libDir/core/router',
      '$libDir/core/services',
      '$libDir/core/utils',
      '$libDir/core/mainErrorListener',
      '$libDir/shared/widgets/popup',
      '$libDir/shared/widgets/loading',
      '$libDir/shared/widgets/buttons',
      '$libDir/shared/widgets/inputs',
      '$libDir/features',
      '${projectDir.path}/assets/medias/icons',
      '${projectDir.path}/assets/medias/animations',
      '${projectDir.path}/assets/theme',
      '${projectDir.path}/assets/fonts',
    ];

    for (final dir in directories) {
      Directory(dir).createSync(recursive: true);
      CliUI.dim(dir.replaceFirst('${projectDir.path}/', ''));
    }

    // --- CONFIG FILES ---
    await _writeTpl('$libDir/config/constants/app_const.dart', 'app_const',
        variables: {'Name': pascalName});
    await _writeTpl(
      '$libDir/config/constants/supabase_api_constants.dart',
      'supabase_api_constants',
      variables: {'name': name},
    );
    await _writeTpl(
      '$libDir/config/theme/theme_provider.dart',
      'theme_provider',
      variables: {'name': name},
    );
    await _writeTpl('$libDir/config/theme/theme_const.dart', 'theme_const');
    await _writeTpl('$libDir/config/theme/text_styles.dart', 'text_styles',
        variables: {'name': name});

    // --- CORE ---
    await _writeTpl(
      '$libDir/core/services/storage_service.dart',
      'storage_service',
    );
    await _writeTpl('$libDir/core/services/env_service.dart', 'env_service');
    await _writeTpl('$libDir/core/actions/app_action.dart', 'app_action');
    await _writeTpl(
      '$libDir/core/di/injection_container.dart',
      'injection_container',
      variables: {'name': name},
      conditionals: {'supabase': hasSupabase},
    );
    await _writeTpl('$libDir/core/error/exceptions.dart', 'exceptions');
    await _writeTpl('$libDir/core/error/failures.dart', 'failures', variables: {'name': name});
    await _writeTpl('$libDir/core/error/error_manager.dart', 'error_manager',
        variables: {'name': name});
    await _writeTpl('$libDir/core/network/network_info.dart', 'network_info');
    await _writeTpl('$libDir/core/app/app_shell.dart', 'app_shell',
        variables: {'Name': pascalName, 'name': name});
    await _writeTpl('$libDir/core/router/app_router.dart', 'app_router',
        variables: {'name': name, 'Name': pascalName});
    await _writeTpl('$libDir/core/utils/typedefs.dart', 'typedefs',
        variables: {'name': name});

    // --- ERROR LISTENER ---
    await _writeTpl(
      '$libDir/core/mainErrorListener/success_error_listener.dart',
      'success_error_listener',
      variables: {'name': name},
    );
    await _writeTpl(
      '$libDir/core/mainErrorListener/last_network_time_provider.dart',
      'last_network_time_provider',
    );

    // --- SHARED WIDGETS ---
    await _writeTpl(
      '$libDir/shared/widgets/popup/show_toast.dart',
      'show_toast',
    );
    await _writeTpl('$libDir/shared/widgets/popup/snackbar.dart', 'snackbar');
    await _writeTpl(
      '$libDir/shared/widgets/loading/loading_widget.dart',
      'loading_widget',
    );

    // --- MAIN ---
    await _writeTpl(
      '$libDir/main.dart',
      'main',
      variables: {'name': name},
      conditionals: {'supabase': hasSupabase},
    );

    // --- MERGE DEPENDENCIES INTO EXISTING pubspec.yaml ---
    _mergePubspecDependencies(name, backend, projectDir.path);

    // --- ASSETS & MISC ---
    await _writeTpl('${projectDir.path}/.env', 'env_template');
    await _writeTpl(
      '${projectDir.path}/analysis_options.yaml',
      'analysis_options',
    );

    // .gitignore already created by flutter create, append our additions
    _appendGitignore(projectDir.path);

    // .gitkeep in empty dirs
    final gitkeeps = [
      '${projectDir.path}/assets/medias/icons',
      '${projectDir.path}/assets/medias/animations',
      '${projectDir.path}/assets/fonts',
      '$libDir/features',
    ];
    for (final gk in gitkeeps) {
      File('$gk/.gitkeep').createSync();
    }
  }

  /// Merge our additional dependencies into the pubspec.yaml
  /// generated by `flutter create`, using YAML-safe parsing.
  void _mergePubspecDependencies(
    String name,
    String backend,
    String projectDir,
  ) {
    try {
      // 1. Add dependencies (skip duplicates automatically)
      final deps = <String, String>{
        'flutter_riverpod': '^2.0.0',
        'riverpod': '^2.6.1',
        'riverpod_annotation': '^2.6.1',
        'get_it': '^9.2.0',
        'go_router': '^16.0.0',
        'dartz': '^0.10.1',
        'equatable': '^2.0.7',
        'intl': '^0.19.0',
        'shared_preferences': '^2.2.3',
        'path_provider': '^2.1.5',
        'path': '^1.9.1',
        'uuid': '^4.5.1',
        'flutter_screenutil': '^5.9.3',
        'internet_connection_checker_plus': '^2.8.0',
        'loading_animation_widget': '^1.3.0',
        'toastification': '^3.0.3',
        'skeletonizer': '^1.4.3',
        'cached_network_image': '^3.4.1',
        'image_picker': '^1.1.2',
        'permission_handler': '^12.0.0+1',
        'share_plus': '^10.1.0',
      };

      if (backend == 'supabase') {
        deps['supabase_flutter'] = '^2.9.0';
      }

      PubspecHelper.addDependencies(projectDir, deps);

      // 2. Add dev_dependencies
      final devDeps = <String, String>{
        'build_runner': '^2.4.8',
        'flutter_launcher_icons': '^0.14.4',
        'mocktail': '^1.0.4',
      };

      PubspecHelper.addDevDependencies(projectDir, devDeps);

      // 3. Add assets to flutter: section
      PubspecHelper.ensureFlutterAssets(projectDir, [
        'assets/medias/icons/',
        'assets/medias/animations/',
        'assets/theme/',
      ]);

      CliUI.success('pubspec.yaml mis a jour');
    } catch (e) {
      CliUI.error('Erreur lors de la mise a jour du pubspec.yaml: $e');
    }
  }

  /// Append CSCM-specific entries to the .gitignore created by flutter create.
  void _appendGitignore(String projectDir) {
    final gitignore = File('$projectDir/.gitignore');
    if (!gitignore.existsSync()) return;

    final content = gitignore.readAsStringSync();
    if (content.contains('.env')) return; // Already added

    gitignore.writeAsStringSync(
      '$content'
      '\n'
      '# CSCM\n'
      '.env\n'
      '.cscm-features.yaml\n',
    );
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.writeAsStringSync(content);
    CliUI.fileCreated(path.split('/').last);
  }

  void _createProjectState(String projectPath, String name, String backend) {
    final stateFile = File('$projectPath/${ProjectState.stateFileName}');
    if (stateFile.existsSync()) {
      stateFile.deleteSync();
    }

    final comment =
        '# .cscm-state.yaml — auto-genere par cscm, ne pas editer a la main\n'
        '# Ce fichier suit l\'historique des actions cscm sur le projet.\n\n';
    final now = DateTime.now().toUtc().toIso8601String();
    final yaml = '''version: 1
    project_name: $name
    created_at: "$now"
    backend: $backend
    features: []
    auth:
    configured: false
    configured_at: ""
    email: false
    social: false
    files_created: []
    actions:
    - timestamp: "$now"
    command: init
    args:
    - $name
    ''';
    stateFile.writeAsStringSync(comment + yaml);
  }

  // ═══════════════════════════════════════════════════
  // TEMPLATE LOADER
  // ═══════════════════════════════════════════════════

  /// Read a template from lib/templates/init/{templateName}.txt,
  /// apply variable replacements and conditional blocks,
  /// then write to [targetPath].
  Future<void> _writeTpl(
    String targetPath,
    String templateName, {
      Map<String, String> variables = const {},
      Map<String, bool> conditionals = const {},
    }) async {
      final resolvedPath = await TemplateResolver.resolveInit(templateName);

      if (resolvedPath == null) {
        throw CliException('Template init/$templateName.txt introuvable.');
      }

    String content = File(resolvedPath).readAsStringSync();

    // Apply variable replacements ({{name}}, {{Name}}, etc.)
    for (final entry in variables.entries) {
      content = content.replaceAll('{{${entry.key}}}', entry.value);
    }

    // Process conditional blocks ({{#if var}}...{{/if}})
    for (final entry in conditionals.entries) {
      content = _processConditional(content, entry.key, entry.value);
    }

    _writeFile(targetPath, content);
  }

  /// Process `{{#if variable}}...{{/if}}` blocks.
  static String _processConditional(
    String content,
    String variable,
    bool enabled,
  ) {
    final startTag = '{{#if $variable}}';
    final endTag = '{{/if}}';

    while (content.contains(startTag)) {
      final startIndex = content.indexOf(startTag);
      final endIndex = content.indexOf(endTag, startIndex);

      if (endIndex == -1) break;

      if (enabled) {
        final blockContent = content.substring(
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
}
