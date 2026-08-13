import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/config_reader.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';

class InitCommand extends Command {
  @override
  String get description =>
      'Créer un projet Flutter complet en Clean Architecture depuis zéro';

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
      help: 'Backend à configurer (supabase | firebase | none)',
      defaultsTo: 'supabase',
      allowed: ['supabase', 'firebase', 'none'],
    );
  }

  @override
  void run() {
    final projectName =
        (argResults!['name'] as String?) ??
        (argResults!.rest.isNotEmpty ? argResults!.rest.first : null);

    if (projectName == null || projectName.trim().isEmpty) {
      print('   Erreur : Veuillez spécifier un nom de projet.');
      print('   Usage : cscm init <nom_du_projet>');
      print('   Exemple : cscm init mon_app');
      exit(1);
    }

    final backend = argResults?['backend'] as String? ?? 'supabase';
    final snakeName = projectName.replaceAll(' ', '_').toLowerCase();

    // Validation anti path traversal
    if (projectName.contains('..') ||
        projectName.contains('/') ||
        projectName.contains('\\')) {
      print('  Erreur : Le nom du projet contient des caractères interdits.');
      exit(1);
    }

    // Vérifier qu'on est pas dans un projet existant
    if (File('pubspec.yaml').existsSync()) {
      print('Un projet Flutter existe déjà dans ce dossier.');
      print(
        '   Si vous voulez configurer CSCM, utilisez : cscm config -n $snakeName',
      );
      exit(1);
    }

    print('\n itialisation du projet [$snakeName]...\n');

    // 1. Créer le .cscm.yaml
    ConfigReader.createConfig(projectName: snakeName, backend: backend);

    // 2. Générer la structure complète
    _createProjectStructure(snakeName, backend);

    print('\n Projet [$snakeName] créé avec succès !');
    print('\nProchaines étapes :');
    print('   1. cd $snakeName');
    print('   2. flutter pub get');
    print(
      '   3. Configurer le fichier .env avec vos clés ${backend == 'supabase' ? 'Supabase' : backend}',
    );
    if (backend == 'supabase') {
      print(
        '   4. dart pub global activate --source path ../clean_solid_cli_mobile',
      );
    }
    print('   5. cscm create ma_feature -i "nom:string,prix:double"');
  }

  void _createProjectStructure(String name, String backend) {
    final projectDir = Directory(name);
    if (!projectDir.existsSync()) {
      projectDir.createSync(recursive: true);
    }

    final libDir = '${projectDir.path}/lib';

    // --- STRUCTURE DES DOSSIERS ---
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
      '$libDir/assets/medias/icons',
      '$libDir/assets/medias/animations',
      '$libDir/assets/theme',
      '$libDir/assets/fonts',
    ];

    for (final dir in directories) {
      Directory(dir).createSync(recursive: true);
      print('    ${dir.replaceFirst('${projectDir.path}/', '')}');
    }

    // --- FICHIERS DE CONFIG ---
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
    _writeFile('$libDir/core/utils/typedefs.dart', _typedefs());

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

    // --- ROOT FILES ---
    _writeFile('${projectDir.path}/pubspec.yaml', _pubspec(name, backend));
    _writeFile('${projectDir.path}/.env', _envTemplate());
    _writeFile('${projectDir.path}/.gitignore', _gitignore());
    _writeFile('${projectDir.path}/analysis_options.yaml', _analysisOptions());

    // Copier le .cscm.yaml dans le projet
    final configFile = File('.cscm.yaml');
    if (configFile.existsSync()) {
      configFile.copySync('${projectDir.path}/.cscm.yaml');
    }

    // Créer un .gitkeep dans les dossiers vides
    final gitkeeps = [
      '$libDir/assets/medias/icons',
      '$libDir/assets/medias/animations',
      '$libDir/assets/fonts',
      '$libDir/features',
    ];
    for (final gk in gitkeeps) {
      File('$gk/.gitkeep').createSync();
    }
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.writeAsStringSync(content);
    print('    ${path.split('/').last}');
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
  //  Renseignez vos clés dans le fichier .env
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
/// Chaque action porte un message de succès, d'erreur,
/// et indique s'il s'agit d'une action d'écriture.
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
''';

  String _exceptions() => '''
/// Exceptions serveur (API, base de données)
class ServerException implements Exception {
  final String message;
  final String? code;
  const ServerException({required this.message, this.code});
}

/// Erreur spécifique à l'API REST
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

/// Erreur réseau (pas de connexion)
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
class UnexceptedException implements Exception {
  final String message;
  const UnexceptedException({required this.message});
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
  const ServerFailure(super.message, super.code);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message, super.code);

  factory ApiFailure.fromException(dynamic exception) {
    return ApiFailure(
      exception.message as String? ?? 'Erreur API inconnue',
      exception.code as String?,
    );
  }
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, super.code);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, super.code);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, super.code);
}

class UnexceptedFailure extends Failure {
  const UnexceptedFailure(super.message, super.code);
}
''';

  String _errorManager() => '''
import '../error/failures.dart';

/// Mappe les failures en messages compréhensibles par l'utilisateur.
class SuccesErrorManager {
  static String getFriendlyErrorMessage(Failure failure, dynamic action) {
    // Messages spécifiques par code d'erreur
    switch (failure.code) {
      case '23505':
        return 'Cet élément existe déjà.';
      case '23503':
        return 'Impossible de supprimer : référencé par un autre élément.';
      case 'PGRST116':
        return 'Aucune donnée trouvée.';
      case '42P01':
        return 'Ressource introuvable.';
      case 'Network_01':
        return 'Pas de connexion Internet.';
    }

    // Message personnalisé de l'action si disponible
    if (action != null && action.errorMessage != null) {
      return action.errorMessage as String;
    }

    // Messages génériques par type de failure
    if (failure is NetworkFailure) {
      return 'Vérifiez votre connexion Internet.';
    }
    if (failure is AuthFailure) {
      return 'Erreur d\'authentification. Veuillez vous reconnecter.';
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
  Stream<bool> get onStatusChange => _connectionChecker.onStatusChange;
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
        child: Text('Page non trouvée : \${state.uri.path}'),
      ),
    ),
  );
});
''';

  String _typedefs() => '''
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
              SuccesErrorManager.getFriendlyErrorMessage(failure, action);
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

  String _pubspec(String name, String backend) {
    final deps = [
      '  flutter:',
      '    sdk: flutter',
      '  cupertino_icons: ^1.0.8',
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
    ];

    if (backend == 'supabase') {
      deps.addAll(['  supabase_flutter: ^2.9.0']);
    }

    return '''
name: $name
description: "A new Flutter project."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
 ${deps.join('\n')}

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true
  assets:
    - assets/medias/icons/
    - assets/medias/animations/
    - assets/theme/
''';
  }

  String _envTemplate() => '''
# ═══════════════════════════════════════
# Variables d'environnement
# ====== :( Ne jamais commiter ce fichier avec de vraies clés !
# ═══════════════════════════════════════

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
''';

  String _gitignore() => '''
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# VS Code related
.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# Environment
.env
''';

  String _analysisOptions() => '''
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
    prefer_single_quotes: true
    always_declare_return_types: true
''';
}
