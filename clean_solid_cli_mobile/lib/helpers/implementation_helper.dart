import 'dart:io';
import 'package:clean_solid_cli_mobile/injections/injections.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/fieldParser.dart';
import 'package:path/path.dart' as p;

class ImplementationHelper {
  static void applyImplementation({
    required String featureName,
    required String fieldsRaw,
    required String projectName,
  }) {
    final fields = FieldParser.parse(fieldsRaw);
    if (fields.isEmpty) return;

    final snakeName =
        featureName.toLowerCase(); // Format snake_case simple ---------
    final pascalName =
        featureName; // Format PascalCase ------------------------

    for (var type in ImplementationType.values) {
      try {
        final filePath = _getFilePathForType(type, snakeName);
        final file = File(filePath);

        if (!file.existsSync()) continue;

        String content = file.readAsStringSync();

        switch (type) {
          case ImplementationType.entityImpl:
            content = Injections.injectEntity(content, fields, pascalName);
            break;
          case ImplementationType.modelImpl:
            content = Injections.injectModel(content, fields, pascalName);
            break;
          case ImplementationType.remoteSourceImpl:
            content = Injections.injectRemoteSource(content, fields);
            break;
        }

        file.writeAsStringSync(content);
        print("Implémentation réussie pour : ${type.name}");
      } catch (e) {
        print("Erreur lors de l'implémentation de ${type.name} : $e");
      }
    }
  }

  static String _getFilePathForType(ImplementationType type, String snake) {
    switch (type) {
      case ImplementationType.entityImpl:
        return p.join(
          'lib',
          'features',
          snake,
          'domain',
          'entity',
          '${snake}_entity.dart',
        );
      case ImplementationType.modelImpl:
        return p.join(
          'lib',
          'features',
          snake,
          'data',
          'model',
          '${snake}_model.dart',
        );
      case ImplementationType.remoteSourceImpl:
        return p.join(
          'lib',
          'features',
          snake,
          'data',
          'source',
          '${snake}_remote_source.dart',
        );
    }
  }
}
