import 'dart:io';

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

    final snakeName = featureName;

    final imports = """
import '../features/$snakeName/data/repository/${snakeName}_repository_impl.dart';
import '../features/$snakeName/data/source/${snakeName}_remote_source.dart';
import '../features/$snakeName/domain/repository/${snakeName}_repository.dart';
import '../features/$snakeName/domain/usecases/${snakeName}_usecases.dart';
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
}
