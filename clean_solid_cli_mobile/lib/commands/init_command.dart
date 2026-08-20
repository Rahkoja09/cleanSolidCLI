import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/git_helper.dart';

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
          // cd into the created project, init git, then cd back
          // We init in the project directory
          if (GitHelper.initRepo(directory: projectDir)) {
            CliUI.success('git init');

            // Initial commit
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

    // --- DIRECTORIES ---
    final directories = [
      '$libDir/config/constants',
      '$libDir/config/theme',
      '$libDir/core/actions',
      '$libDir/core/di',
      '$libDir/core/error',
      '$libDir/core/network',
      '$libDir/core/router',
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
    _writeFile('$libDir/config/constants/app_const.dart', _appConst(name));
    _writeFile(
      '$libDir/config/constants/supabase_api_constants.dart',
      _supabaseConstants(),
    );
    _writeFile(
      '$libDir/config/theme/theme_provider.dart',
      _themeProvider(name),
    );

    // --- CORE ---
    _writeFile('$libDir/core/actions/app_action.dart', _appAction());
    _writeFile(
      '$libDir/core/di/injection_container.dart',
      _injectionContainer(name),
    );
    _writeFile('$libDir/core/error/exceptions.dart', _exceptions());
    _writeFile('$libDir/core/error/failures.dart', _failures());
    _writeFile('$libDir/core/error/error_manager.dart', _errorManager());
    _writeFile('$libDir/core/network/network_info.dart', _networkInfo());
    _writeFile('$libDir/core/router/app_router.dart', _appRouter(name));
    _writeFile('$libDir/core/utils/typedefs.dart', _typedefs(name));

    // --- ERROR LISTENER ---
    _writeFile(
      '$libDir/core/mainErrorListener/success_error_listener.dart',
      _successErrorListener(name),
    );
    _writeFile(
      '$libDir/core/mainErrorListener/last_network_time_provider.dart',
      _lastNetworkTimeProvider(),
    );

    // --- SHARED WIDGETS ---
    _writeFile('$libDir/shared/widgets/popup/show_toast.dart', _showToast());
    _writeFile('$libDir/shared/widgets/popup/snackbar.dart', _snackbar());
    _writeFile(
      '$libDir/shared/widgets/loading/loading_widget.dart',
      _loadingWidget(),
    );

    // --- MAIN ---
    _writeFile('$libDir/main.dart', _main(name, backend));

    // --- MERGE DEPENDENCIES INTO EXISTING pubspec.yaml ---
    _mergePubspecDependencies(name, backend, projectDir.path);

    // --- ASSETS & MISC ---
    _writeFile('${projectDir.path}/.env', _envTemplate());
    _writeFile('${projectDir.path}/analysis_options.yaml', _analysisOptions());

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
  /// generated by `flutter create`, preserving its structure.
  void _mergePubspecDependencies(
    String name,
    String backend,
    String projectDir,
  ) {
    final pubspecFile = File('$projectDir/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    String content = pubspecFile.readAsStringSync();

    final additionalDeps = [
      '  flutter_riverpod: ^2.0.0',
      '  riverpod: ^2.6.1',
      '  riverpod_annotation: ^2.6.1',
      '  get_it: ^9.2.0',
      '  go_router: ^16.0.0',
      '  dartz: ^0.10.1',
      '  equatable: ^2.0.7',
      '  intl: ^0.19.0',
      '  shared_preferences: ^2.2.3',
      '  path_provider: ^2.1.5',
      '  path: ^1.9.1',
      '  uuid: ^4.5.1',
      '  flutter_screenutil: ^5.9.3',
      '  internet_connection_checker_plus: ^2.8.0',
      '  loading_animation_widget: ^1.3.0',
      '  toastification: ^3.0.3',
      '  skeletonizer: ^1.4.3',
      '  cached_network_image: ^3.4.1',
      '  image_picker: ^1.1.2',
      '  permission_handler: ^12.0.0+1',
      '  share_plus: ^10.1.0',
      if (backend == 'supabase') '  supabase_flutter: ^2.9.0',
    ];

    final additionalDevDeps = [
      '  build_runner: ^2.4.8',
      '  flutter_launcher_icons: ^0.14.4',
      '  mocktail: ^1.0.4',
    ];

    // ── 1. Insert runtime deps BEFORE dev_dependencies: ──
    final devDepsMatch = RegExp(
      r'^(dev_dependencies:)',
      multiLine: true,
    ).firstMatch(content);

    if (devDepsMatch != null) {
      final depsBlock = additionalDeps.join('\n');
      // replaceRange insère à la position exacte du regex match,
      // PAS à la première sous-chaîne trouvée
      content = content.replaceRange(
        devDepsMatch.start,
        devDepsMatch.start,
        '$depsBlock\n\n',
      );
    }

    // ── 2. Insert dev deps BEFORE root-level flutter: ──
    final flutterMatch = RegExp(
      r'^(flutter:)',
      multiLine: true,
    ).firstMatch(content);

    if (flutterMatch != null) {
      final devDepsBlock = additionalDevDeps.join('\n');
      // replaceRange = position exacte du match regex (^flutter:)
      // NON replaceFirst("flutter:", ...) qui frappe  "  flutter:" dans deps
      content = content.replaceRange(
        flutterMatch.start,
        flutterMatch.start,
        '$devDepsBlock\n\n',
      );
    }

    // ── 3. Replace ENTIRE root flutter: section ──
    // Regex: ^flutter:\n suivi de lignes indentées ou vides
    final flutterSectionMatch = RegExp(
      r'^flutter:\n(?:[ \t].*\n|\n)*',
      multiLine: true,
    ).firstMatch(content);

    if (flutterSectionMatch != null) {
      content = content.replaceRange(
        flutterSectionMatch.start,
        flutterSectionMatch.end,
        'flutter:\n'
        '  uses-material-design: true\n'
        '\n'
        '  assets:\n'
        '    - assets/medias/icons/\n'
        '    - assets/medias/animations/\n'
        '    - assets/theme/\n',
      );
    }

    pubspecFile.writeAsStringSync(content);
    CliUI.success('pubspec.yaml mis a jour');
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

    // Use ProjectState.create which writes the file properly
    // But we need to temporarily cd or pass path
    // Instead, write directly
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
  // TEMPLATES
  // ═══════════════════════════════════════════════════

  String _appConst(String name) => '''
class AppConst {
  static const String appName = "${ReformateClassName.capitalizeClassName(featureName: name)}";
  static const String appVersion = "1.0.0";
}
''';

  String _supabaseConstants() => '''
class SupabaseApiConstants {
  //  Renseignez vos cles dans le fichier .env
  static const String apiUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String apiKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
''';

  String _themeProvider(String name) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4),
    brightness: Brightness.light,
  );
});
''';

  String _appAction() => '''
/// Interface de base pour toutes les actions de l'application.
/// Chaque action porte un message de succes, d'erreur,
/// et indique s'il s'agit d'une action d'ecriture.
abstract class AppAction {
  String get successMessage;
  String get errorMessage;
  bool get isWriteAction;
}
''';

  String _injectionContainer(String name) => '''
import 'package:get_it/get_it.dart';

// [IMPORT_ANCHOR]

final sl = GetIt.instance;

Future<void> init() async {
  // Initialisation des services core

  // [INIT_ANCHOR]
}

// [INIT_METHOD_ANCHOR]
''';

  String _exceptions() => '''
/// Exceptions serveur (API, base de donnees)
class ServerException implements Exception {
  final String message;
  final String? code;
  const ServerException({required this.message, this.code});
}

/// Erreur specifique a l'API REST
class ApiException implements Exception {
  final String message;
  final String? code;
  const ApiException({required this.message, this.code});
}

/// Erreur d'authentification utilisateur
class AuthUserException implements Exception {
  final String message;
  final String? code;
  const AuthUserException({required this.message, this.code});
}

/// Erreur reseau (pas de connexion)
class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}

/// Erreur de cache locale
class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

/// Erreur inattendue (catch-all)
class UnexpectedException implements Exception {
  final String message;
  const UnexpectedException({required this.message});
}
''';

  String _failures() => '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class ApiFailure extends Failure {
  const ApiFailure({required super.message, super.code});

  factory ApiFailure.fromException(dynamic exception) {
    return ApiFailure(
      message: exception.message as String? ?? 'Erreur API inconnue',
      code: exception.code as String?,
    );
  }
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
''';

  String _errorManager() => '''
import '../error/failures.dart';

/// Mappe les failures en messages comprehensibles par l'utilisateur.
class SuccessErrorManager {
  static String getFriendlyErrorMessage(Failure failure, dynamic action) {
    // Messages specifiques par code d'erreur
    switch (failure.code) {
      case '23505':
        return 'Cet element existe deja.';
      case '23503':
        return 'Impossible de supprimer : reference par un autre element.';
      case 'PGRST116':
        return 'Aucune donnee trouvee.';
      case '42P01':
        return 'Ressource introuvable.';
      case 'Network_01':
        return 'Pas de connexion Internet.';
    }

    // Message personnalise de l'action si disponible
    if (action != null && action.errorMessage != null) {
      return action.errorMessage as String;
    }

    // Messages generiques par type de failure
    if (failure is NetworkFailure) {
      return 'Verifiez votre connexion Internet.';
    }
    if (failure is AuthFailure) {
      return "Erreur d'authentification. Veuillez vous reconnecter.";
    }

    return failure.message.isNotEmpty ? failure.message : 'Une erreur est survenue.';
  }
}
''';

  String _networkInfo() => '''
import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connectionChecker;

  NetworkInfoImpl(this._connectionChecker);

  @override
  Future<bool> get isConnected => _connectionChecker.hasInternetAccess;

  @override
  Stream<bool> get onStatusChange => _connectionChecker.onStatusChange.map((s) => s == InternetStatus.connected);
}
''';

  String _appRouter(String name) => '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Ajoutez vos routes ici
      // [ROUTES_ANCHOR]
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvee : \${state.uri.path}'),
      ),
    ),
  );
});
''';

  String _typedefs(String name) => '''
import 'package:dartz/dartz.dart';
import 'package:$name/core/error/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid = Future<Either<Failure, void>>;
typedef MapData = Map<String, dynamic>;
''';

  String _successErrorListener(String name) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$name/core/error/failures.dart';
import 'package:$name/core/error/error_manager.dart';
import 'package:$name/shared/widgets/popup/show_toast.dart';
import 'package:$name/shared/widgets/popup/snackbar.dart';
import 'package:$name/core/mainErrorListener/last_network_time_provider.dart';

class SuccessErrorListener extends ConsumerWidget {
  final Widget child;
  const SuccessErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void _showFilteredError({
      required BuildContext context,
      required WidgetRef ref,
      required Failure failure,
      required dynamic action,
      required String title,
    }) {
      final now = DateTime.now();
      final lastErrorTime = ref.read(lastNetworkErrorTimeProvider);
      final isNetworkError =
          failure is NetworkFailure || failure.code == 'Network_01';

      if (isNetworkError) {
        if (lastErrorTime == null ||
            now.difference(lastErrorTime).inSeconds > 3) {
          ref.read(lastNetworkErrorTimeProvider.notifier).state = now;
          final msg =
              SuccessErrorManager.getFriendlyErrorMessage(failure, action);
          Snackbar.show(context,
              message: msg, isError: true, isPersistent: true);
        }
      } else {
        final String msg = action?.errorMessage ?? failure.message;
        showToast(context,
            description: msg, isError: true, title: title);
      }
    }

    // [LISTENERS_ANCHOR]
    return child;
  }
}
''';

  String _lastNetworkTimeProvider() => '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lastNetworkErrorTimeProvider = StateProvider<DateTime?>((ref) => null);
''';

  String _showToast() => '''
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showToast(
  BuildContext context, {
  required String description,
  required bool isError,
  String? title,
}) {
  toastification.show(
    context: context,
    type: isError ? ToastificationType.error : ToastificationType.success,
    style: ToastificationStyle.fillColored,
    title: title != null ? Text(title) : null,
    description: Text(description),
    autoCloseDuration: const Duration(seconds: 4),
    showProgressBar: false,
  );
}
''';

  String _snackbar() => '''
import 'package:flutter/material.dart';

class Snackbar {
  static void show(
    BuildContext context, {
    required String message,
    required bool isError,
    bool isPersistent = false,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: isPersistent
          ? const Duration(days: 1)
          : const Duration(seconds: 4),
      action: isPersistent
          ? SnackBarAction(
              label: 'Fermer',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
''';

  String _loadingWidget() => '''
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingWidget extends StatelessWidget {
  final double? size;
  final String? message;
  const LoadingWidget({super.key, this.size, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.fourRotatingDots(
            color: Theme.of(context).colorScheme.primary,
            size: size ?? 40,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
''';

  String _main(String name, String backend) {
    final hasSupabase = backend == 'supabase';
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:$name/config/constants/app_const.dart';
import 'package:$name/config/constants/supabase_api_constants.dart';
import 'package:$name/config/theme/theme_provider.dart';
import 'package:$name/core/router/app_router.dart';
import 'package:$name/core/di/injection_container.dart' as di;${hasSupabase ? "\nimport 'package:supabase_flutter/supabase_flutter.dart';" : ''}
import 'package:toastification/toastification.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
 ${hasSupabase ? "\n  await Supabase.initialize(\n    url: SupabaseApiConstants.apiUrl,\n    anonKey: SupabaseApiConstants.apiKey,\n    authOptions: const FlutterAuthClientOptions(\n      autoRefreshToken: true,\n      detectSessionInUri: true,\n    ),\n  );" : ""}

  await di.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return ToastificationWrapper(
          child: MaterialApp.router(
            routerConfig: router,
            theme: theme,
            debugShowCheckedModeBanner: false,
            title: AppConst.appName,
          ),
        );
      },
    );
  }
}
''';
  }

  String _envTemplate() => '''
# ═══════════════════════════════════════
# Variables d'environnement
# ====== :( Ne jamais commiter ce fichier avec de vraies cles !
# ═══════════════════════════════════════

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
''';

  String _analysisOptions() => '''
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    prefer_single_quotes: true
    always_declare_return_types: true
    prefer_final_fields: true
    prefer_final_locals: true
    unnecessary_null_comparison: true
    prefer_null_aware_operators: true
    avoid_unnecessary_containers: true
    avoid_empty_else: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_is_not_operator: true
    avoid_redundant_argument_values: true
    cancel_subscriptions: true
    close_sinks: true
    use_key_in_widget_constructors: true
    prefer_const_constructors_in_immutables: true
    sized_box_for_whitespace: true
    unnecessary_overrides: true
    unnecessary_this: true
    prefer_typing_uninitialized_variables: true
    require_trailing_commas: true
''';
}
