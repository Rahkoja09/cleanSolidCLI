import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// Robust template resolver with multiple fallback strategies.
/// Fixes the fragility of Isolate.resolvePackageUri() when the package
/// is globally activated and run from a different working directory.
class TemplateResolver {
  static const _packageName = 'clean_solid_cli_mobile';

  /// Resolve a path relative to the package's lib/ directory.
  /// Example: resolve('templates/create/entity.txt')
  /// Returns the absolute file path, or null if not found.
  static Future<String?> resolve(String relativePath) async {
    // 1. Standard Isolate package URI resolution
    final uri = Uri.parse('package:$_packageName/$relativePath');
    final resolved = await Isolate.resolvePackageUri(uri);
    if (resolved != null && File.fromUri(resolved).existsSync()) {
      return resolved.toFilePath();
    }

    // 2. Manual resolution from Isolate.packageConfig
    final configUri = await Isolate.packageConfig;
    if (configUri != null) {
      final path = _resolveFromConfigUri(configUri, relativePath);
      if (path != null) return path;
    }

    // 3. Look for package_config.json near the executable
    //    (relevant for globally activated packages)
    final execDir = File(Platform.resolvedExecutable).parent.path;
    final configCandidates = <String>[
      '$execDir/.dart_tool/package_config.json',
      '$execDir/../.dart_tool/package_config.json',
      '$execDir/../../.dart_tool/package_config.json',
    ];
    for (final p in configCandidates) {
      final f = File(p);
      if (f.existsSync()) {
        final path = _resolveFromConfigUri(f.absolute.uri, relativePath);
        if (path != null) return path;
      }
    }

    // 4. Walk up from CWD looking for lib/<relativePath>
    var dir = Directory.current;
    for (var i = 0; i < 15; i++) {
      final candidate = '${dir.path}lib/$relativePath';
      if (File(candidate).existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    return null;
  }

  /// Resolve a template for the auth module.
  static Future<String?> resolveAuth(String templateName) {
    return resolve('templates/auth/$templateName.txt');
  }

  /// Resolve a template for the create module.
  static Future<String?> resolveCreate(String templateName) {
    return resolve('templates/create/$templateName.txt');
  }

  /// Read a template file and return its content, or null if not found.
  static Future<String?> readTemplate(String relativePath) async {
    final path = await resolve(relativePath);
    if (path == null) return null;
    return File(path).readAsStringSync();
  }

  // ── Private helpers ──────────────────────────────────────────────

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

          // Resolve rootUri relative to the config file's directory
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

          // Combine root + packageUri + relativePath
          final pkgUri = rootUri.resolve(pkgUriStr);
          final fullPath = pkgUri.resolve(relativePath);

          if (File.fromUri(fullPath).existsSync()) {
            return fullPath.toFilePath();
          }
        }
      }
    } catch (_) {
      // Silently fall through to next strategy
    }
    return null;
  }
}
