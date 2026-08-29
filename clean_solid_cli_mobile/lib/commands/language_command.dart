import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/pubspec_helper.dart';

class LanguageCommand extends Command {
  @override
  String get description =>
      'Ajouter le support multilingue (i18n) au projet';

  @override
  String get name => 'language';

  LanguageCommand() {
    argParser.addOption(
      'locales',
      abbr: 'i',
      help: 'Liste des locales (separes par virgule). Premiere = langue par defaut.',
    );
    argParser.addFlag(
      'commit',
      abbr: 'c',
      help: 'Commiter automatiquement apres la configuration',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final localesStr = argResults?['locales'] as String?;
    final autoCommit = argResults?['commit'] as bool? ?? false;

    // ── Validation ──
    if (localesStr == null || localesStr.trim().isEmpty) {
      throw const CliException(
        'Veuillez specifier les locales.\n'
        '   Usage : cscm language -i fr,en,mlg\n'
        '   Exemple : cscm language -i fr,en',
      );
    }

    final locales = localesStr
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    if (locales.length < 2) {
      throw const CliException(
        'Specifiez au moins 2 locales.\n'
        '   Exemple : cscm language -i fr,en',
      );
    }

    for (final loc in locales) {
      if (!RegExp(r'^[a-z]{2}([_-][a-zA-Z]{2,4})?$').hasMatch(loc)) {
        throw CliException(
          'Locale invalide: "$loc". Format: fr, en, mlg, etc.',
        );
      }
    }

    final defaultLocale = locales.first;
    final projectName = GetProjetItem.getProjectName();

    CliUI.header('Internationalisation (i18n)');
    CliUI.info('Locale par defaut : $defaultLocale');
    CliUI.info('Locales supportees : ${locales.join(", ")}');

    final filesCreated = <String>[];

    // ── 1. l10n.yaml ──
    CliUI.section('Configuration l10n');
    if (!_fileExists('l10n.yaml')) {
      _createL10nYaml(defaultLocale, locales);
      CliUI.fileCreated('l10n.yaml');
      filesCreated.add('l10n.yaml');
    } else {
      CliUI.fileSkipped('l10n.yaml (deja existant)');
    }

    // ── 2. ARB files ──
    CliUI.section('Fichiers ARB');
    final arbDir = 'lib/l10n';
    Directory(arbDir).createSync(recursive: true);

    final mainArbPath = '$arbDir/app_${defaultLocale}.arb';
    if (!_fileExists(mainArbPath)) {
      _createMainArb(mainArbPath, defaultLocale);
      CliUI.fileCreated('app_${defaultLocale}.arb');
      filesCreated.add(mainArbPath);
    } else {
      CliUI.fileSkipped('app_${defaultLocale}.arb (deja existant)');
    }

    for (int i = 1; i < locales.length; i++) {
      final loc = locales[i];
      final arbPath = '$arbDir/app_${loc}.arb';
      if (!_fileExists(arbPath)) {
        _createEmptyArb(arbPath, loc);
        CliUI.fileCreated('app_${loc}.arb');
        filesCreated.add(arbPath);
      } else {
        CliUI.fileSkipped('app_${loc}.arb (deja existant)');
      }
    }

    // ── 3. Locale Provider ──
    CliUI.section('Locale Provider');
    final providerDir = 'lib/config/locale';
    Directory(providerDir).createSync(recursive: true);
    final providerPath = '$providerDir/locale_provider.dart';
    if (!_fileExists(providerPath)) {
      _createLocaleProvider(providerPath, defaultLocale, projectName);
      CliUI.fileCreated('locale_provider.dart');
      filesCreated.add(providerPath);
    } else {
      CliUI.fileSkipped('locale_provider.dart (deja existant)');
    }

    // ── 4. Update pubspec.yaml ──
    CliUI.section('pubspec.yaml');
    _updatePubspecForL10n();
    CliUI.success('pubspec.yaml mis a jour pour i18n');

    // ── 5. Update app_shell.dart ──
    CliUI.section('app_shell.dart');
    _updateAppShellForL10n(projectName);
    CliUI.success('app_shell.dart mis a jour pour i18n');

    // ── 6. Update .cscm-state.yaml ──
    if (ProjectState.stateExists()) {
      _updateStateL10n(locales);
      CliUI.success('.cscm-state.yaml mis a jour');
    }

    CliUI.success('Internationalisation configuree avec succes !');
    CliUI.nextSteps([
      'flutter pub get',
      'flutter gen-l10n',
      'Utilisez context.l10n.hello dans vos widgets',
    ]);

    // ── Auto commit ──
    if (autoCommit && filesCreated.isNotEmpty) {
      CliUI.hint('Utilisez: git add . && git commit -m "cscm: language ${locales.join(",")}"');
    }
  }

  // ═══════════════════════════════════════════════════
  // FILE GENERATION
  // ═══════════════════════════════════════════════════

  void _createL10nYaml(String defaultLocale, List<String> allLocales) {
    final content = '# Flutter i18n Configuration\n'
        'arb-dir: lib/l10n\n'
        'template-arb-file: app_${defaultLocale}.arb\n'
        'output-localization-file: app_localizations.dart\n'
        'output-class: AppLocalizations\n'
        'synthetic-package: false\n'
        'output-dir: lib/l10n\n'
        'preferred-supported-locales: [${allLocales.map((l) => "'$l'").join(', ')}]';

    File('l10n.yaml').writeAsStringSync(content);
  }

  void _createMainArb(String path, String locale) {
    final content = '{\n'
        '  "@@locale": "$locale",\n'
        '\n'
        '  "appTitle": "My App",\n'
        '  "@appTitle": {\n'
        '    "description": "Le titre principal de l\'application"\n'
        '  },\n'
        '\n'
        '  "hello": "Bonjour",\n'
        '  "@hello": {\n'
        '    "description": "Message d\'accueil generique"\n'
        '  },\n'
        '\n'
        '  "loading": "Chargement...",\n'
        '  "@loading": {\n'
        '    "description": "Message de chargement"\n'
        '  },\n'
        '\n'
        '  "error": "Une erreur est survenue",\n'
        '  "@error": {\n'
        '    "description": "Message d\'erreur generique"\n'
        '  },\n'
        '\n'
        '  "retry": "Reessayer",\n'
        '  "@retry": {\n'
        '    "description": "Bouton reessayer"\n'
        '  },\n'
        '\n'
        '  "cancel": "Annuler",\n'
        '  "@cancel": {\n'
        '    "description": "Bouton annuler"\n'
        '  },\n'
        '\n'
        '  "confirm": "Confirmer",\n'
        '  "@confirm": {\n'
        '    "description": "Bouton confirmer"\n'
        '  },\n'
        '\n'
        '  "save": "Enregistrer",\n'
        '  "@save": {\n'
        '    "description": "Bouton enregistrer"\n'
        '  },\n'
        '\n'
        '  "delete": "Supprimer",\n'
        '  "@delete": {\n'
        '    "description": "Bouton supprimer"\n'
        '  },\n'
        '\n'
        '  "noInternet": "Pas de connexion internet",\n'
        '  "@noInternet": {\n'
        '    "description": "Message pas d\'internet"\n'
        '  },\n'
        '\n'
        '  "unexpectedError": "Erreur inattendue",\n'
        '  "@unexpectedError": {\n'
        '    "description": "Message d\'erreur inattendue"\n'
        '  },\n'
        '\n'
        '  "success": "Succes",\n'
        '  "@success": {\n'
        '    "description": "Message de succes generique"\n'
        '  }\n'
        '}';

    File(path).writeAsStringSync(content);
  }

  void _createEmptyArb(String path, String locale) {
    // Empty ARBs: NO @@locale — Flutter infers it from the filename.
    final content = '{\n'
        '  "appTitle": "My App",\n'
        '  "hello": "",\n'
        '  "loading": "",\n'
        '  "error": "",\n'
        '  "retry": "",\n'
        '  "cancel": "",\n'
        '  "confirm": "",\n'
        '  "save": "",\n'
        '  "delete": "",\n'
        '  "noInternet": "",\n'
        '  "unexpectedError": "",\n'
        '  "success": ""\n'
        '}';

    File(path).writeAsStringSync(content);
  }

  void _createLocaleProvider(
    String path,
    String defaultLocale,
    String projectName,
  ) {
    final content = "import 'package:flutter/material.dart';\n"
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
        "import 'package:$projectName/l10n/app_localizations.dart';\n"
        '\n'
        'class LocaleNotifier extends StateNotifier<Locale> {\n'
        "  LocaleNotifier() : super(const Locale('$defaultLocale'));\n"
        '\n'
        '  void setLocale(Locale locale) {\n'
        '    state = locale;\n'
        '  }\n'
        '}\n'
        '\n'
        'final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(\n'
        '  (ref) => LocaleNotifier(),\n'
        ');\n'
        '\n'
        '/// Extension pour acceder facilement aux traductions.\n'
        'extension AppLocalizationExtension on BuildContext {\n'
        '  AppLocalizations get l10n => AppLocalizations.of(this)!;\n'
        '}';

    File(path).writeAsStringSync(content);
  }

  // ═══════════════════════════════════════════════════
  // PUBSPEC UPDATE (YAML-safe)
  // ═══════════════════════════════════════════════════

  void _updatePubspecForL10n() {
    try {
      // 1. generate: true in the flutter: section
      PubspecHelper.ensureGenerateTrue('.');

      // 2. flutter_localizations (SDK dependency — special handling)
      _ensureSdkDependency('flutter_localizations');

      // 3. intl if not already present (init already adds it,
      //    but if language is run on a non-cscm project, add it)
      final pubspecFile = File('pubspec.yaml');
      String content = pubspecFile.readAsStringSync();
      if (!content.contains('intl:')) {
        PubspecHelper.addDependencies('.', {'intl': '^0.19.0'});
      }
    } catch (e) {
      CliUI.error('Erreur pubspec.yaml: $e');
    }
  }

  /// Special helper for SDK dependencies like flutter_localizations
  /// which have a map value `{sdk: flutter}` instead of a version string.
  void _ensureSdkDependency(String packageName) {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    String content = pubspecFile.readAsStringSync();
    if (content.contains('$packageName:')) return;

    // Insert before dev_dependencies:
    final devDepsMatch = RegExp(
      r'^(dev_dependencies:)',
      multiLine: true,
    ).firstMatch(content);

    if (devDepsMatch != null) {
      final sdkDep = '  $packageName:\n    sdk: flutter\n';
      content = content.replaceFirst(
        devDepsMatch.group(0)!,
        '$sdkDep\n${devDepsMatch.group(0)}',
      );
    } else {
      content += '\n  $packageName:\n    sdk: flutter\n';
    }

    pubspecFile.writeAsStringSync(content);
  }

  // ═══════════════════════════════════════════════════
  // APP_SHELL UPDATE (for l10n)
  // ═══════════════════════════════════════════════════

  void _updateAppShellForL10n(String projectName) {
    final shellFile = File('lib/core/app/app_shell.dart');
    if (!shellFile.existsSync()) return;

    String content = shellFile.readAsStringSync();
    bool changed = false;

    // 1. Add missing imports
    final missingImports = <String>[];

    if (!content.contains("import 'package:flutter_localizations")) {
      missingImports
          .add("import 'package:flutter_localizations/flutter_localizations.dart';");
    }
    if (!content.contains("import 'package:$projectName/l10n/app_localizations")) {
      missingImports
          .add("import 'package:$projectName/l10n/app_localizations.dart';");
    }
    if (!content.contains("import 'package:$projectName/config/locale/locale_provider")) {
      missingImports
          .add("import 'package:$projectName/config/locale/locale_provider.dart';");
    }

    if (missingImports.isNotEmpty) {
      final importMatches =
          RegExp(r"^import '", multiLine: true)
              .allMatches(content)
              .toList();

      if (importMatches.isNotEmpty) {
        final lastMatch = importMatches.last;
        final endOfLine = content.indexOf('\n', lastMatch.start);
        final insertStr = missingImports.map((i) => '$i\n').join('');
        content = content.replaceRange(
          endOfLine + 1,
          endOfLine + 1,
          insertStr,
        );
      } else {
        content = '${missingImports.join('\n')}\n$content';
      }
      changed = true;
    }

    // 2. Add localizationsDelegates and supportedLocales in MaterialApp.router
    if (!content.contains('localizationsDelegates')) {
      final l10nBlock = '          localizationsDelegates: const [\n'
          '            AppLocalizations.delegate,\n'
          '            GlobalMaterialLocalizations.delegate,\n'
          '            GlobalWidgetsLocalizations.delegate,\n'
          '            GlobalCupertinoLocalizations.delegate,\n'
          '          ],\n'
          '          supportedLocales: AppLocalizations.supportedLocales,\n'
          '          locale: ref.watch(localeProvider),\n';

      if (content.contains('routerConfig:')) {
        content = content.replaceFirst(
          'routerConfig:',
          '$l10nBlock          routerConfig:',
        );
      }
      changed = true;
    }

    if (changed) {
      shellFile.writeAsStringSync(content);
    }
  }

  // ═══════════════════════════════════════════════════
  // STATE UPDATE
  // ═══════════════════════════════════════════════════

  void _updateStateL10n(List<String> locales) {
    try {
      final state = ProjectState.load();
      final now = DateTime.now().toUtc().toIso8601String();

      state.actions.add(ActionRecord(
        timestamp: now,
        command: 'language',
        args: ['-i', locales.join(',')],
        detail: '${locales.length} locale(s)',
      ));

      ProjectState.save(state);
    } catch (_) {
      // Ne pas bloquer si le state est illisible
    }
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  bool _fileExists(String path) => File(path).existsSync();
}
