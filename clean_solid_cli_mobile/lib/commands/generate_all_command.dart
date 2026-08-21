import 'dart:collection';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/state_manager.dart';
import 'package:yaml/yaml.dart';
import 'package:clean_solid_cli_mobile/helpers/error_listener_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/file_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/implementation_helper.dart';
import 'package:clean_solid_cli_mobile/helpers/injection_helper.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/field_parser.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';

class GenerateAllCommand extends Command {
  @override
  String get description =>
      "Générer toutes les features à partir d'un fichier YAML";

  @override
  String get name => 'generate:all';

  GenerateAllCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Chemin vers le fichier YAML de définition',
      defaultsTo: '.cscm-features.yaml',
    );
  }

  @override
  void run() async {
    final filePath = argResults?['file'] as String? ?? '.cscm-features.yaml';
    final file = File(filePath);

    if (!file.existsSync()) {
      print(' Fichier $filePath introuvable.');
      print(
        '   Créez un fichier .cscm-features.yaml avec vos définitions de features.',
      );
      print(
        '   Exemple : https://github.com/Rahkoja09/cleanSolidCLI#generate-all',
      );
      throw Exception('Fichier $filePath introuvable.');
    }

    // 1. Lire et parser le YAML
    final yamlContent = file.readAsStringSync();
    final yaml = loadYaml(yamlContent);
    if (yaml is! Map) {
      throw const CliException(
        'Le fichier YAML doit contenir un dictionnaire.',
      );
    }
    final yamlMap = yaml;
    final featuresRaw = yamlMap['features'];

    if (featuresRaw == null) {
      print(' Clé "features" introuvable dans $filePath.');
      throw Exception('Clé "features" introuvable.');
    }

    final features = _parseFeatures(featuresRaw);

    if (features.isEmpty) {
      print(' Aucune feature trouvée dans $filePath.');
      throw Exception('Aucune feature trouvée.');
    }

    // 2. Tri topologique (les références sont générées en premier)
    final sorted = _topologicalSort(features);

    if (sorted == null) {
      print(' Cycle de dépendances détecté entre les features !');
      throw Exception('Cycle de dépendances détecté.');
    }

    // 3. Préparer l'architecture
    final projectName = GetProjetItem.getProjectName();
    print('\n Génération de ${sorted.length} feature(s)...\n');

    // 4. Générer chaque feature
    for (final feature in sorted) {
      _generateFeature(feature, projectName);
    }

    print(' Toutes les features ont été générées avec succès !');
  }

  Future<void> _generateFeature(
    _FeatureDef feature,
    String projectName,
  ) async {
    final snakeFeatureName = ReformateClassName.formatToSnakeCase(feature.name);
    final capitalizedName = ReformateClassName.capitalizeClassName(
      featureName: snakeFeatureName,
    );

    print(' ${capitalizedName}...');

    // Générer les templates (entity, model, remote source, etc.)
    for (var type in FileTemplateType.values) {
      if (type == FileTemplateType.di) continue;

      try {
        final targetPath = FileHelper.generateAndGetTargetPath(
          featureName: feature.name,
          templateType: type,
        );

        await FileHelper.generateFormTemplate(
          featureName: feature.name,
          templateName: type.name,
          targetPath: targetPath,
        );
      } catch (_) {
        // Fichier existe déjà ou autre erreur — on continue
      }
    }

    // Injecter les champs si fournis
    if (feature.fieldsRaw.isNotEmpty) {
      try {
        ImplementationHelper.applyImplementation(
          featureName: feature.name,
          fieldsRaw: feature.fieldsRaw,
          projectName: projectName,
        );
        print('  Champs injectés.');
      } catch (e) {
        print(" Erreur d'implémentation : $e");
      }
    }

    // Mettre à jour l'injection de dépendances
    InjectionHelper.updateInjectionContainer(feature.name, capitalizedName);

    // Mettre à jour le ErrorListener
    ErrorListenerHelper.updateErrorListener(capitalizedName, snakeFeatureName);

    print(' ${capitalizedName} terminé.\n');
  }

  // ═══════════════════════════════════════════════════
  // PARSING
  // ═══════════════════════════════════════════════════

  /// Supporte 3 formats YAML :
  /// 1. Map :   features: { boutique: { fields: "..." }, produit: { fields: "..." } }
  /// 2. Liste : features: [ { name: boutique, fields: "..." }, ... ]
  /// 3. Liste avec fields en array : fields: [ "nom:string", "prix:double" ]
  List<_FeatureDef> _parseFeatures(dynamic featuresRaw) {
    final features = <_FeatureDef>[];

    if (featuresRaw is YamlMap) {
      // Format map
      for (final entry in featuresRaw.entries) {
        final name = entry.key.toString().trim();
        String fields = '';
        final value = entry.value;

        if (value is YamlMap) {
          fields = _extractFields(value['fields']);
        } else if (value is String) {
          fields = value.trim();
        }

        if (name.isNotEmpty) {
          features.add(_FeatureDef(name: name, fieldsRaw: fields));
        }
      }
    } else if (featuresRaw is YamlList) {
      // Format liste
      for (final item in featuresRaw) {
        if (item is YamlMap) {
          final name = (item['name'] as String?)?.trim();
          if (name == null || name.isEmpty) continue;

          final fields = _extractFields(item['fields']);
          features.add(_FeatureDef(name: name, fieldsRaw: fields));
        }
      }
    }

    return features;
  }

  /// Extrait les champs depuis string ou liste YAML
  String _extractFields(dynamic fieldsRaw) {
    if (fieldsRaw is String) {
      return fieldsRaw.trim();
    } else if (fieldsRaw is YamlList) {
      return fieldsRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join(',');
    }
    return '';
  }

  // ═══════════════════════════════════════════════════
  // TOPOLOGICAL SORT (Kahn's algorithm)
  // ═══════════════════════════════════════════════════

  /// Trie les features pour que les dépendances (references) soient générées en premier.
  /// Retourne null si un cycle est détecté.
  List<_FeatureDef>? _topologicalSort(List<_FeatureDef> features) {
    final featureMap = <String, _FeatureDef>{};
    final featureNames = <String>{};

    for (final f in features) {
      final key = f.name.toLowerCase();
      featureMap[key] = f;
      featureNames.add(key);
    }

    // Construire le graphe de dépendances
    // dependencies[A] = ensemble des features dont A dépend
    final dependencies = <String, Set<String>>{};
    for (final f in features) {
      final deps = <String>{};
      if (f.fieldsRaw.isNotEmpty) {
        final parsedFields = FieldParser.parse(f.fieldsRaw);
        for (final field in parsedFields) {
          if (field.isReference &&
              featureNames.contains(field.referenceTargetSnake)) {
            deps.add(field.referenceTargetSnake);
          }
        }
      }
      dependencies[f.name.toLowerCase()] = deps;
    }

    // Calcul des in-degrees
    final inDegree = <String, int>{};
    for (final name in featureNames) {
      inDegree[name] = dependencies[name]!.length;
    }

    // Construire reverseDeps : qui dépend de moi ?
    final reverseDeps = <String, List<String>>{};
    for (final name in featureNames) {
      reverseDeps[name] = [];
    }
    for (final entry in dependencies.entries) {
      for (final dep in entry.value) {
        reverseDeps[dep]!.add(entry.key);
      }
    }

    // Queue des noeuds sans dépendances
    final queue = ListQueue<String>();
    for (final entry in inDegree.entries) {
      if (entry.value == 0) queue.add(entry.key);
    }

    final sortedKeys = <String>[];

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      sortedKeys.add(current);

      // Réduire l'in-degree de tous ceux qui dépendent de current
      for (final dependent in reverseDeps[current]!) {
        inDegree[dependent] = inDegree[dependent]! - 1;
        if (inDegree[dependent] == 0) {
          queue.add(dependent);
        }
      }
    }

    // Vérifier s'il y a un cycle
    if (sortedKeys.length != features.length) {
      return null;
    }

    return sortedKeys.map((key) => featureMap[key]!).toList();
  }
}

class _FeatureDef {
  final String name;
  final String fieldsRaw;

  _FeatureDef({required this.name, required this.fieldsRaw});
}
