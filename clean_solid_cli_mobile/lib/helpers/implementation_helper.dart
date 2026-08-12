import 'dart:io';
import 'package:clean_solid_cli_mobile/injections/injections.dart';
import 'package:clean_solid_cli_mobile/models/field.dart';
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

    final snakeName = featureName.toLowerCase();
    final pascalName = featureName;

    // 1. Generer les fichiers enum
    _generateEnumFiles(fields, snakeName);

    // 2. Injecter dans entity, model, remoteSource
    for (var type in ImplementationType.values) {
      try {
        final filePath = _getFilePathForType(type, snakeName);
        final file = File(filePath);

        if (!file.existsSync()) continue;

        String content = file.readAsStringSync();

        switch (type) {
          case ImplementationType.entityImpl:
            content = Injections.injectEntity(
              content,
              fields,
              pascalName,
              projectName,
            );
            break;
          case ImplementationType.modelImpl:
            content = Injections.injectModel(
              content,
              fields,
              pascalName,
              projectName,
            );
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

  static void _generateEnumFiles(List<Field> fields, String snakeName) {
    final enumFields = fields.where((f) => f.isEnum).toList();
    if (enumFields.isEmpty) return;

    final enumDir = Directory('lib/features/$snakeName/domain/enums');
    if (!enumDir.existsSync()) {
      enumDir.createSync(recursive: true);
    }

    for (final field in enumFields) {
      final filePath =
          'lib/features/$snakeName/domain/enums/${field.name}_enum.dart';
      final file = File(filePath);

      if (file.existsSync()) {
        print("  Enum ${field.enumClassName} existe déjà. Saut.");
        continue;
      }

      final content = _buildEnumContent(field);
      file.writeAsStringSync(content);
      print("  Enum généré : ${field.name}_enum.dart");
    }
  }

  static String _buildEnumContent(Field field) {
    final className = field.enumClassName;
    final values = field.dartEnumValues.map((v) => '  $v,').join('\n');

    return '''enum $className {
 $values

  String get value => name;

  static $className? fromString(String? value) {
    if (value == null) return null;
    return $className.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown $className value: \$value'),
    );
  }
}
''';
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
