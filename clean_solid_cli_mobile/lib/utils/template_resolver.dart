import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

class TemplateResolver {
  static const _packageName = 'clean_solid_cli_mobile';
  static String? _sourcePath; // cache du chemin source

  static Future<String?> resolve(String relativePath) async {
    // 1. Si on a trouvé le source, lire directement
    final src = _sourcePath ?? await _findSourcePath();
    if (src != null) {
      final candidate = p.join(src, 'lib', relativePath);
      if (File(candidate).existsSync()) return candidate;
    }

    // 2. Isolate standard
    try {
      final uri = Uri.parse('package:$_packageName/$relativePath');
      final resolved = await Isolate.resolvePackageUri(uri);
      if (resolved != null && File.fromUri(resolved).existsSync()) {
        return resolved.toFilePath();
      }
    } catch (_) {}

    // 3. Isolate.packageConfig
    try {
      final configUri = await Isolate.packageConfig;
      if (configUri != null) {
        final path = _resolveFromConfigUri(configUri, relativePath);
        if (path != null) return path;
      }
    } catch (_) {}

    // 4. Remonter depuis CWD
    var dir = Directory.current;
    for (var i = 0; i < 15; i++) {
      final candidate = p.join(dir.path, 'lib', relativePath);
      if (File(candidate).existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    return null;
  }

  /// Trouve le chemin source du package activé globalement
  static Future<String?> _findSourcePath() async {
    // Cherche le package dans le cache global de Dart
    final home = Platform.environment['HOME'] ?? '';
    final candidates = <String>[
      p.join(home, '.dart_tool', 'pub', 'global_packages', _packageName),
      p.join(home, '.pub-cache', 'global_packages', _packageName),
      '/opt/homebrew', // macOS Homebrew
    ];

    for (final candidate in candidates) {
      if (Directory(candidate).existsSync()) {
        final templatesDir = p.join(candidate, 'lib', 'templates');
        if (Directory(templatesDir).existsSync()) {
          _sourcePath = candidate;
          return candidate;
        }
      }
    }

    return null;
  }

  static Future<String?> resolveAuth(String templateName) =>
      resolve('templates/auth/$templateName.txt');

  static Future<String?> resolveCreate(String templateName) =>
      resolve('templates/create/$templateName.txt');

  static Future<String?> readTemplate(String relativePath) async {
    final path = await resolve(relativePath);
    if (path == null) return null;
    return File(path).readAsStringSync();
  }

  static String? _resolveFromConfigUri(Uri configUri, String relativePath) {
    try {
      final file = File.fromUri(configUri);
      if (!file.existsSync()) return null;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final packages = json['packages'] as List<dynamic>?;
      if (packages == null) return null;
      final configDir = configUri.resolve('./');
      for (final pkg in packages) {
        if (pkg['name'] == _packageName) {
          final rootUriStr = pkg['rootUri'] as String? ?? '';
          final pkgUriStr = pkg['packageUri'] as String? ?? 'lib/';
          Uri rootUri;
          if (rootUriStr.startsWith('file:') ||
              rootUriStr.startsWith('/') ||
              Platform.isWindows && rootUriStr.contains(':\\')) {
            rootUri = Uri.parse(rootUriStr);
          } else {
            rootUri = configDir.resolve(rootUriStr);
          }
          if (!rootUri.path.endsWith('/')) {
            rootUri = Uri.parse('${rootUri.path}/');
          }
          final pkgUri = rootUri.resolve(pkgUriStr);
          final fullPath = pkgUri.resolve(relativePath);
          if (File.fromUri(fullPath).existsSync()) {
            return fullPath.toFilePath();
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
