import 'dart:io';
import 'package:yaml/yaml.dart';

/// Centralised, YAML-parse-based pubspec.yaml editor.
///
/// Instead of fragile regex replacements, we parse → convert to plain
/// Dart Maps → modify → re-serialise.
/// This avoids mutability issues with YamlMap.
class PubspecHelper {
  // ─── SINGLE SOURCE OF TRUTH ───────────────────────────

  /// Parse a pubspec.yaml file and return a plain, mutable Map.
  static Map<String, dynamic> _parse(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('pubspec.yaml not found', path);
    }
    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    return _toPlainMap(yaml);
  }

  /// Write a map back to disk as clean YAML.
  static void _write(String path, Map<String, dynamic> data) {
    File(path).writeAsStringSync(_serialiseNode(data, 0));
  }

  // ─── PUBLIC API ──────────────────────────────────────

  /// Add packages to `dependencies` section.
  /// Skips packages that already exist (by name).
  static void addDependencies(String projectDir, Map<String, String> deps) {
    final path = '$projectDir/pubspec.yaml';
    final data = _parse(path);
    final depsMap = _getOrCreateMap(data, 'dependencies');
    for (final entry in deps.entries) {
      if (!depsMap.containsKey(entry.key)) {
        depsMap[entry.key] = entry.value;
      }
    }
    _write(path, data);
  }

  /// Add packages to `dev_dependencies` section.
  /// Skips packages that already exist (by name).
  static void addDevDependencies(
    String projectDir,
    Map<String, String> deps,
  ) {
    final path = '$projectDir/pubspec.yaml';
    final data = _parse(path);
    final depsMap = _getOrCreateMap(data, 'dev_dependencies');
    for (final entry in deps.entries) {
      if (!depsMap.containsKey(entry.key)) {
        depsMap[entry.key] = entry.value;
      }
    }
    _write(path, data);
  }

  /// Ensure `generate: true` is set in the top-level `flutter:` section.
  static void ensureGenerateTrue(String projectDir) {
    final path = '$projectDir/pubspec.yaml';
    final data = _parse(path);
    final flutter = _getOrCreateMap(data, 'flutter');
    if (flutter['generate'] != true) {
      flutter['generate'] = true;
    }
    _write(path, data);
  }

  /// Add asset paths to the `flutter:` → `assets:` list.
  static void ensureFlutterAssets(String projectDir, List<String> assets) {
    final path = '$projectDir/pubspec.yaml';
    final data = _parse(path);
    final flutter = _getOrCreateMap(data, 'flutter');

    if (flutter['uses-material-design'] != true) {
      flutter['uses-material-design'] = true;
    }

    final assetsList = _getOrCreateList(flutter, 'assets');
    final existing = assetsList.toSet();
    for (final asset in assets) {
      if (!existing.contains(asset)) {
        assetsList.add(asset);
      }
    }

    _write(path, data);
  }

  // ─── INTERNAL HELPERS ────────────────────────────────

  static Map<String, dynamic> _getOrCreateMap(
    Map<String, dynamic> data,
    String key,
  ) {
    final existing = data[key];
    if (existing is Map<String, dynamic>) return existing;
    final m = <String, dynamic>{};
    data[key] = m;
    return m;
  }

  static List<dynamic> _getOrCreateList(
    Map<String, dynamic> data,
    String key,
  ) {
    final existing = data[key];
    if (existing is List<dynamic>) return existing;
    final l = <dynamic>[];
    data[key] = l;
    return l;
  }

  /// Deep-convert a YamlMap / YamlList tree into plain Dart Maps / Lists.
  static Map<String, dynamic> _toPlainMap(YamlMap yaml) {
    final result = <String, dynamic>{};
    for (final entry in yaml.entries) {
      result[entry.key.toString()] = _toPlainValue(entry.value);
    }
    return result;
  }

  static dynamic _toPlainValue(dynamic value) {
    if (value is YamlMap) {
      return _toPlainMap(value);
    }
    if (value is YamlList) {
      return value.map(_toPlainValue).toList();
    }
    return value;
  }

  // ─── SERIALISATION ───────────────────────────────────

  static String _serialiseNode(dynamic node, int indent) {
    if (node is Map<String, dynamic>) {
      final buf = StringBuffer();
      final pad = '  ' * indent;

      for (final entry in node.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is Map<String, dynamic> && value.isNotEmpty) {
          buf.writeln('$pad$key:');
          buf.write(_serialiseNode(value, indent + 1));
        } else if (value is List && value.isNotEmpty) {
          buf.writeln('$pad$key:');
          for (final item in value) {
            buf.writeln('$pad  - $item');
          }
        } else if (value is bool) {
          buf.writeln('$pad$key: $value');
        } else if (value is num) {
          buf.writeln('$pad$key: $value');
        } else if (value is String) {
          if (value.contains(' ')) {
            buf.writeln("$pad$key: '$value'");
          } else {
            buf.writeln('$pad$key: $value');
          }
        } else if (value != null) {
          buf.writeln('$pad$key: $value');
        }
      }
      return buf.toString();
    }

    return '$node';
  }
}
