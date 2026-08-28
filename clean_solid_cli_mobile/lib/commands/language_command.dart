import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';

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

    // ── 5. Update main.dart ──
    CliUI.section('main.dart');
    _updateMainForL10n(projectName);
    CliUI.success('main.dart mis a jour pour i18n');

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
  // PUBSPEC UPDATE
  // ═══════════════════════════════════════════════════

  void _updatePubspecForL10n() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    String content = pubspecFile.readAsStringSync();
    bool changed = false;

    // 1. generate: true sous le TOP-LEVEL flutter: (celui en bas,
    //    pas celui sous dependencies:)
    if (!content.contains('generate: true')) {
      final lastFlutterIdx = content.lastIndexOf('flutter:\n');
      if (lastFlutterIdx != -1) {
        content = content.replaceRange(
          lastFlutterIdx,
          lastFlutterIdx + 'flutter:\n'.length,
          'flutter:\n  generate: true\n',
        );
        changed = true;
      }
    }

    // 2. flutter_localizations dans dependencies
    if (!content.contains('flutter_localizations')) {
      final l10nDeps = '  flutter_localizations:\n'
      '    sdk: flutter\n';

      final devDepsMatch = RegExp(
        r'^(dev_dependencies:)',
        multiLine: true,
      ).firstMatch(content);

      if (devDepsMatch != null) {
        content = content.replaceFirst(
          devDepsMatch.group(0)!,
          '$l10nDeps\n${devDepsMatch.group(0)!}',
        );
      } else {
        content = '$content\n$l10nDeps';
      }
      changed = true;
    }

    // 3. intl si pas deja present
    if (!content.contains('intl:')) {
      final intlDep = '  intl: ^0.19.0\n';
      // Inserer avant dev_dependencies
      final devDepsMatch = RegExp(
        r'^(dev_dependencies:)',
        multiLine: true,
      ).firstMatch(content);

      if (devDepsMatch != null) {
        content = content.replaceFirst(
          devDepsMatch.group(0)!,
          '$intlDep\n${devDepsMatch.group(0)!}',
        );
      } else {
        content = '$content\n$intlDep';
      }
      changed = true;
    }

    if (changed) {
      pubspecFile.writeAsStringSync(content);
    }
  }

  // ═══════════════════════════════════════════════════
  // MAIN.DART UPDATE
  // ═══════════════════════════════════════════════════

  void _updateMainForL10n(String projectName) {
    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) return;

    String content = mainFile.readAsStringSync();
    bool changed = false;

    // 1. Ajouter les imports manquants
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
      // Trouver le dernier import et inserer apres
      final importMatches =
      RegExp(r"^import '\'package:", multiLine: true)
      .allMatches(content)
      .toList();

      if (importMatches.isNotEmpty) {
        final lastMatch = importMatches.last;
        final endOfLine = content.indexOf('\n', lastMatch.start);
        final insertStr = missingImports.map((i) => '$i\n').join();
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

    // 2. Ajouter localizationsDelegates et supportedLocales dans MaterialApp.router
    if (!content.contains('localizationsDelegates')) {
      final l10nBlock = '          localizationsDelegates: const [\n'
      '            AppLocalizations.delegate,\n'
      '            GlobalMaterialLocalizations.delegate,\n'
      '            GlobalWidgetsLocalizations.delegate,\n'
      '            GlobalCupertinoLocalizations.delegate,\n'
      '          ],\n'
      '          supportedLocales: AppLocalizations.supportedLocales,\n'
      '          locale: ref.watch(localeProvider),\n';

      // Inserer avant routerConfig:
      if (content.contains('routerConfig:')) {
        content = content.replaceFirst(
          'routerConfig:',
          '$l10nBlock          routerConfig:',
        );
      }
      changed = true;
    }

    if (changed) {
      mainFile.writeAsStringSync(content);
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
