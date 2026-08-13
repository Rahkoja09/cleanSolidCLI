import 'dart:io';

import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';

class InjectionHelper {
  static void updateInjectionContainer(
    String featureName,
    String capitalizedName,
  ) {
    final filePath = 'lib/core/di/injection_container.dart';
    final file = File(filePath);

    if (!file.existsSync()) {
      _createNewContainer(file);
    }

    String content = file.readAsStringSync();

    if (content.contains('_init$capitalizedName()')) {
      print(" Injection déjà présente pour $capitalizedName");
      return;
    }
    final projectName = GetProjetItem.getProjectName();
    final snakeName = featureName;

    // Imports — le bloc contient l'ancre à la fin (comportement original)
    final imports = """
import 'package:$projectName/features/$snakeName/data/repository/${snakeName}_repository_impl.dart';
import 'package:$projectName/features/$snakeName/data/source/${snakeName}_remote_source.dart';
import 'package:$projectName/features/$snakeName/domain/repository/${snakeName}_repository.dart';
import 'package:$projectName/features/$snakeName/domain/usecases/${snakeName}_usecases.dart';
// [IMPORT_ANCHOR]""";

    // Appel dans init() — le bloc contient l'ancre à la fin
    final initCall = "  _init$capitalizedName();\n  // [INIT_ANCHOR]";

    // Méthode _init — injectée via INIT_METHOD_ANCHOR
    final initMethod = """
Future<void> _init$capitalizedName() async {
  sl.registerLazySingleton<${capitalizedName}RemoteSource>(
    () => ${capitalizedName}RemoteSourceImpl(sl()),
  );
  sl.registerLazySingleton<${capitalizedName}Repository>(
    () => ${capitalizedName}RepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => ${capitalizedName}Usecases(sl()));
}

// [INIT_METHOD_ANCHOR]""";

    // Injections avec warning si ancre manquante
    content = _safeReplace(content, '// [IMPORT_ANCHOR]', imports, 'injection_container');
    content = _safeReplace(content, '  // [INIT_ANCHOR]', initCall, 'injection_container');
    content = _safeReplace(content, '// [INIT_METHOD_ANCHOR]', initMethod, 'injection_container');

    file.writeAsStringSync(content);
    print(" Injection Container mis à jour avec succès !");
  }

  static void _createNewContainer(File file) {
    file.createSync(recursive: true);
    file.writeAsStringSync("""
import 'package:get_it/get_it.dart';
// [IMPORT_ANCHOR]

final sl = GetIt.instance;

Future<void> init() async {
  // [INIT_ANCHOR]
}

// [INIT_METHOD_ANCHOR]
""");
  }

  static void updateInjectionContainerAuth({
    required bool useEmail,
    required bool useSocial,
  }) {
    final filePath = 'lib/core/di/injection_container.dart';
    final file = File(filePath);

    if (!file.existsSync()) {
      _createNewContainer(file);
    }

    String content = file.readAsStringSync();
    final projectName = GetProjetItem.getProjectName();

    String authImports = "";
    if (!content.contains('auth_remote_source.dart')) {
      authImports = """
import 'package:$projectName/features/auth/data/repository/auth_repository_impl.dart';
import 'package:$projectName/features/auth/data/source/auth_remote_source.dart';
import 'package:$projectName/features/auth/data/source/auth_remote_source_impl.dart';
import 'package:$projectName/features/auth/domain/repository/auth_repository.dart';
import 'package:$projectName/features/auth/domain/usecases/auth_usecases.dart';""";
    }

    if (useEmail && !content.contains('email_auth_service.dart')) {
      authImports +=
          "\nimport 'package:$projectName/features/auth/data/source/email_auth_service.dart';";
    }
    if (useSocial && !content.contains('social_auth_service.dart')) {
      authImports +=
          "\nimport 'package:$projectName/features/auth/data/source/social_auth_service.dart';";
    }

    if (authImports.isNotEmpty) {
      authImports += "\n// [IMPORT_ANCHOR]";
      content = _safeReplace(content, '// [IMPORT_ANCHOR]', authImports, 'injection_container (auth)');
    }

    if (!content.contains('_initAuth()')) {
      final initCall = "  _initAuth();\n  // [INIT_ANCHOR]";
      content = _safeReplace(content, '  // [INIT_ANCHOR]', initCall, 'injection_container (auth)');
    }

    final newAuthMethod = _generateAuthInitMethod(
      useEmail: useEmail,
      useSocial: useSocial,
    );

    if (content.contains('Future<void> _initAuth()')) {
      final regExp = RegExp(
        r'Future<void> _initAuth\(\) async \{[\s\S]*?\}',
        multiLine: true,
      );
      content = content.replaceFirst(regExp, newAuthMethod);
    } else {
      final authBlock = "$newAuthMethod\n// [INIT_METHOD_ANCHOR]";
      content = _safeReplace(content, '// [INIT_METHOD_ANCHOR]', authBlock, 'injection_container (auth)');
    }

    file.writeAsStringSync(content);
    print(" Injection Container : Configuration Auth mise à jour !");
  }

  /// Remplace une ancre avec warning si absente. L'ancre de remplacement
  /// doit être incluse dans [replacement] par l'appelant.
  static String _safeReplace(
    String content,
    String anchor,
    String replacement,
    String context,
  ) {
    if (!content.contains(anchor)) {
      print('  ⚠  Ancre "$anchor" introuvable dans $context. Injection ignorée.');
      return content;
    }
    return content.replaceFirst(anchor, replacement);
  }

  static String _generateAuthInitMethod({
    required bool useEmail,
    required bool useSocial,
  }) {
    String services = "";
    String remoteSourceParams = "sl()";

    if (useSocial) {
      services +=
          "  sl.registerLazySingleton(() => SocialAuthService(sl()));\n";
      remoteSourceParams += ", sl()";
    }
    if (useEmail) {
      services += "  sl.registerLazySingleton(() => EmailAuthService(sl()));\n";
      remoteSourceParams += ", sl()";
    }

    return """
Future<void> _initAuth() async {
 $services
  sl.registerLazySingleton<AuthRemoteSource>(
    () => AuthRemoteSourceImpl($remoteSourceParams),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton(() => AuthUsecases(sl()));
}
""";
  }
}
