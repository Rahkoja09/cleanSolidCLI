import 'dart:io';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/get_projet_item.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/anchor_helper.dart';

class RouteHelper {
  static const _routerPath = 'lib/core/router/app_router.dart';

  // ─────────────────────────────────────────────────────────────────
  //  ADD
  // ─────────────────────────────────────────────────────────────────

  static void addRoute({
    required String featureName,
    String? path,
    String? parentFeature,
  }) {
    final file = File(_routerPath);
    if (!file.existsSync()) {
      CliUI.error('$_routerPath n\'existe pas. Faites cscm init d\'abord.');
      return;
    }

    final projectName = GetProjetItem.getProjectName();
    final snakeName = ReformateClassName.formatToSnakeCase(featureName);
    final pascalName = ReformateClassName.capitalizeClassName(
      featureName: snakeName,
    );
    final pageClassName = '${pascalName}Page';

    final pagePath =
    'lib/features/$snakeName/presentation/pages/${snakeName}_page.dart';
    if (!File(pagePath).existsSync()) {
      CliUI.error('Page introuvable : $pagePath');
      CliUI.hint('Creez la feature d\'abord : cscm create $snakeName');
      return;
    }

    String content = file.readAsStringSync();

    if (content.contains('const $pageClassName()')) {
      CliUI.info('Route pour $pascalName deja presente');
      return;
    }

    // 1. Import
    final importLine =
    "import 'package:$projectName/features/$snakeName/presentation/pages/${snakeName}_page.dart';";
    content = _addImport(content, importLine);

    // 2. Route
    if (parentFeature != null) {
      content = _addChildRoute(
        content: content,
        parentFeature: parentFeature,
        snakeName: snakeName,
        pageClassName: pageClassName,
        path: path,
      );
    } else {
      content = _addTopLevelRoute(
        content: content,
        snakeName: snakeName,
        pageClassName: pageClassName,
        path: path,
      );
    }

    file.writeAsStringSync(content);

    final displayPath = path ?? '/$snakeName';
    if (parentFeature != null) {
      final parentSnake =
      ReformateClassName.formatToSnakeCase(parentFeature);
      CliUI.success(
        'Route enfant : /$parentSnake/${path ?? snakeName} -> $pageClassName',
      );
    } else {
      CliUI.success('Route ajoutee : $displayPath -> $pageClassName');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  REMOVE
  // ─────────────────────────────────────────────────────────────────

  static void removeRoute({required String featureName}) {
    final file = File(_routerPath);
    if (!file.existsSync()) {
      CliUI.error('$_routerPath n\'existe pas.');
      return;
    }

    final snakeName = ReformateClassName.formatToSnakeCase(featureName);
    final pascalName = ReformateClassName.capitalizeClassName(
      featureName: snakeName,
    );
    final pageClassName = '${pascalName}Page';

    String content = file.readAsStringSync();

    if (!content.contains('const $pageClassName()')) {
      CliUI.warning('Aucune route pour $pascalName dans app_router.dart');
      return;
    }

    content = _removeRouteBlock(content, pageClassName);
    content = _removeImport(content, '${snakeName}_page.dart');

    file.writeAsStringSync(content);
    CliUI.success('Route supprimee : $pascalName');
  }

  // ─────────────────────────────────────────────────────────────────
  //  LIST
  // ─────────────────────────────────────────────────────────────────

  static void listRoutes() {
    final file = File(_routerPath);
    if (!file.existsSync()) {
      CliUI.error('$_routerPath n\'existe pas.');
      return;
    }

    final content = file.readAsStringSync();
    final routes = _parseRoutes(content);

    if (routes.isEmpty) {
      CliUI.warning('Aucune route enregistree.');
      return;
    }

    CliUI.header('Routes (${routes.length})');
    for (final r in routes) {
      final indent = '  ' * r.depth;
      final icon = r.depth == 0 ? '>' : '|->';
      CliUI.info('$indent $icon ${r.path.padRight(20)} ${r.page}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVE — top-level route
  // ═══════════════════════════════════════════════════════════════════

  static String _addTopLevelRoute({
    required String content,
    required String snakeName,
    required String pageClassName,
    required String? path,
  }) {
    final routePath = path ?? '/$snakeName';
    final block = """      GoRoute(
      path: '$routePath',
      builder: (context, state) => const $pageClassName(),
      ),
      // [ROUTES_ANCHOR]""";

      final result = replaceAnchor(
        content,
        '// [ROUTES_ANCHOR]',
        block,
        context: 'app_router',
      );

      if (result == content) {
        CliUI.warning(
          'ancre // [ROUTES_ANCHOR] introuvable dans app_router.dart',
        );
      }
      return result;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVE — child route
  // ═══════════════════════════════════════════════════════════════════

  static String _addChildRoute({
    required String content,
    required String parentFeature,
    required String snakeName,
    required String pageClassName,
    required String? path,
  }) {
    final parentSnake =
    ReformateClassName.formatToSnakeCase(parentFeature);
    final parentPascal = ReformateClassName.capitalizeClassName(
      featureName: parentSnake,
    );
    final childPath = path ?? snakeName;
    final childrenAnchor = '// [CHILDREN_${parentPascal}_ANCHOR]';

    // Cas 1 : l'ancre enfants existe deja
    if (content.contains(childrenAnchor)) {
      final childBlock = """          GoRoute(
        path: '$childPath',
        builder: (context, state) => const $pageClassName(),
        ),
        $childrenAnchor""";

        final result = replaceAnchor(
          content,
          childrenAnchor,
          childBlock,
          context: 'app_router (children $parentPascal)',
        );
        if (result != content) return result;
    }

    // Cas 2 : transformer la route parent existante
    final parentPattern =
    RegExp("GoRoute\\s*\\(\\s*path:\\s*'/$parentSnake'");
    final parentMatch = parentPattern.firstMatch(content);
    if (parentMatch == null) {
      CliUI.error('Route parent /$parentSnake non trouvee.');
      CliUI.hint('Ajoutez-la d\'abord : cscm route add $parentSnake');
      return content;
    }

    final parentBlock = _extractBlock(content, parentMatch.start);
    if (parentBlock == null) return content;

    final newBlock = _transformParentToHaveChildren(
      parentBlock: parentBlock,
      parentSnake: parentSnake,
      childPath: childPath,
      pageClassName: pageClassName,
      parentPascalName: parentPascal,
    );

    return content.replaceRange(
      parentMatch.start,
      parentMatch.start + parentBlock.length,
      newBlock,
    );
  }

  static String? _extractBlock(String content, int startPos) {
    var depth = 0;
    var foundOpen = false;

    for (var i = startPos; i < content.length; i++) {
      if (content[i] == '(') {
        foundOpen = true;
        depth++;
      } else if (content[i] == ')') {
        depth--;
        if (foundOpen && depth == 0) {
          var end = i + 1;
          if (end < content.length && content[end] == ',') end++;
          if (end < content.length && content[end] == '\n') end++;
          return content.substring(startPos, end);
        }
      }
    }
    return null;
  }

  static String _transformParentToHaveChildren({
    required String parentBlock,
    required String parentSnake,
    required String childPath,
    required String pageClassName,
    required String parentPascalName,
  }) {
    final builderRegex = RegExp(
      'builder:\\s*\\(context,\\s*state\\)\\s*=>\\s*const\\s*\\w+Page\\(\\),?\\s*\\n?',
    );
    String newBlock = parentBlock.replaceFirst(
      builderRegex,
      "redirect: (context, state) => '/$parentSnake/$childPath',\n",
    );

    final lastParen = newBlock.lastIndexOf(')');
    final childrenBlock = """
    children: [
    GoRoute(
      path: '$childPath',
      builder: (context, state) => const $pageClassName(),
      ),
      // [CHILDREN_${parentPascalName}_ANCHOR]
      ],""";

      return '${newBlock.substring(0, lastParen)}$childrenBlock\n      ),';
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVE — remove
  // ═══════════════════════════════════════════════════════════════════

  static String _removeRouteBlock(String content, String pageClassName) {
    final target = 'const $pageClassName()';
    final targetIdx = content.indexOf(target);
    if (targetIdx == -1) return content;

    final blockStart = content.lastIndexOf('GoRoute(', targetIdx);
    if (blockStart == -1) return content;

    final block = _extractBlock(content, blockStart);
    if (block == null) return content;

    final blockEnd = blockStart + block.length;
    final before = content.substring(0, blockStart);
    final after = content.substring(blockEnd);

    return '$before$after'.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVE — imports
  // ═══════════════════════════════════════════════════════════════════

  static String _addImport(String content, String importLine) {
    if (content.contains(importLine)) return content;

    // Trouver le dernier import existant et inserer apres
    final lines = content.split('\n');
    int lastImportIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trimLeft().startsWith('import ')) {
        lastImportIdx = i;
      }
    }
    if (lastImportIdx == -1) return content;

    lines.insert(lastImportIdx + 1, importLine);
    return lines.join('\n');
  }

  static String _removeImport(String content, String fileName) {
    final lines = content.split('\n');
    return lines.where((line) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('import ')) return true;
      if (!trimmed.contains(fileName)) return true;
      return !trimmed.endsWith(';');
    }).join('\n');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVE — parse (pour list)
  // ═══════════════════════════════════════════════════════════════════

  static List<_RouteEntry> _parseRoutes(String content) {
    final routes = <_RouteEntry>[];
    final lines = content.split('\n');
    var inRoute = false;
    var parenDepth = 0;
    String? currentPath;
    String? currentPage;
    int routeIndent = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('GoRoute(')) {
        inRoute = true;
        parenDepth = 0;
        currentPath = null;
        currentPage = null;
        routeIndent = line.length - line.trimLeft().length;
      }

      if (inRoute) {
        for (var c = 0; c < line.length; c++) {
          if (line[c] == '(') parenDepth++;
          if (line[c] == ')') parenDepth--;
        }

        // path: '/xxx' ou path: 'xxx'
        final pathMatch = RegExp("path:\\s*'([^']+)'").firstMatch(trimmed);
        if (pathMatch != null) currentPath = pathMatch.group(1);

        // const XxxPage()
        final pageMatch =
        RegExp(r'const\s+(\w+Page)\(\)').firstMatch(trimmed);
        if (pageMatch != null) currentPage = pageMatch.group(1);

        if (parenDepth == 0 && (trimmed.endsWith(')') || trimmed.endsWith('),'))) {
          if (currentPath != null && currentPage != null) {
            final depth = routeIndent <= 6 ? 0 : 1;
            routes.add(_RouteEntry(
              path: currentPath,
              page: currentPage,
              depth: depth,
            ));
          }
          inRoute = false;
        }
      }
    }

    return routes;
  }
}

class _RouteEntry {
  final String path;
  final String page;
  final int depth;
  _RouteEntry({required this.path, required this.page, required this.depth});
}
