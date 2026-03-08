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

    final imports = """
import 'package:$projectName/features/$snakeName/data/repository/${snakeName}_repository_impl.dart';
import 'package:$projectName/features/$snakeName/data/source/${snakeName}_remote_source.dart';
import 'package:$projectName/features/$snakeName/domain/repository/${snakeName}_repository.dart';
import 'package:$projectName/features/$snakeName/domain/usecases/${snakeName}_usecases.dart';
// [IMPORT_ANCHOR]""";

    final initCall = "  _init$capitalizedName();\n  // [INIT_ANCHOR]";

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
""";

    // 4. Injection si existant -------
    content = content.replaceFirst('// [IMPORT_ANCHOR]', imports);
    content = content.replaceFirst('// [INIT_ANCHOR]', initCall);
    content = content + initMethod;

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

    // 1. Gestion des Imports spécifiques à l'Auth
    String authImports = "";
    if (!content.contains('auth_remote_source.dart')) {
      authImports = """
import 'package:$projectName/features/auth/data/repository/auth_repository_impl.dart';
import 'package:$projectName/features/auth/data/source/auth_remote_source.dart';
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
      content = content.replaceFirst('// [IMPORT_ANCHOR]', authImports);
    }

    // 2. Appel de l'initialisation dans init()
    if (!content.contains('_initAuth()')) {
      final initCall = "  _initAuth();\n  // [INIT_ANCHOR]";
      content = content.replaceFirst('// [INIT_ANCHOR]', initCall);
    }

    // 3. Construction de la méthode _initAuth()
    // Si la méthode existe déjà, on va devoir la remplacer pour mettre à jour les dépendances
    final newAuthMethod = _generateAuthInitMethod(
      useEmail: useEmail,
      useSocial: useSocial,
    );

    if (content.contains('Future<void> _initAuth()')) {
      // Remplacement de l'ancienne méthode par la nouvelle (Update)
      final regExp = RegExp(
        r'Future<void> _initAuth\(\) async \{[\s\S]*?\}',
        multiLine: true,
      );
      content = content.replaceFirst(regExp, newAuthMethod);
    } else {
      // Ajout simple à la fin du fichier (Creation)
      content = "${content.trim()}\n$newAuthMethod";
    }

    file.writeAsStringSync(content);
    print(" Injection Container : Configuration Auth mise à jour !");
  }

  static String _generateAuthInitMethod({
    required bool useEmail,
    required bool useSocial,
  }) {
    String services = "";
    String remoteSourceParams = "sl()"; // sl() pour le SupabaseClient

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
