import 'dart:async';
import 'dart:io';

/// CSCM CLI output.
///
/// Design principles:
/// - Minimal
/// - Technical
/// - Consistent
/// - No emojis
/// - ANSI when available
/// - Fully usable with NO_COLOR
class CliUI {
  // ═══════════════════════════════════════════════
  // ANSI
  // ═══════════════════════════════════════════════

  static const _reset = '\x1b[0m';

  static const _bold = '\x1b[1m';
  static const _dim = '\x1b[2m';

  static const _red = '\x1b[31m';
  static const _green = '\x1b[32m';
  static const _yellow = '\x1b[33m';

  static const _cyan = '\x1b[36m';
  static const _magenta = '\x1b[35m';

  static const _gray = '\x1b[90m';

  static final bool _color = _detectColor();

  static bool _detectColor() {
    if (Platform.environment.containsKey('NO_COLOR')) {
      return false;
    }

    try {
      return stdout.supportsAnsiEscapes;
    } catch (_) {
      return false;
    }
  }

  static String _c(String color, String text) {
    if (!_color) return text;
    return '$color$text$_reset';
  }

  static String bold(String text) => _c(_bold, text);
  static String dim(String text) => _c(_dim, text);

  static String red(String text) => _c(_red, text);
  static String green(String text) => _c(_green, text);
  static String yellow(String text) => _c(_yellow, text);

  static String cyan(String text) => _c(_cyan, text);
  static String magenta(String text) => _c(_magenta, text);
  static String gray(String text) => _c(_gray, text);

  // ═══════════════════════════════════════════════
  // LOGO
  // ═══════════════════════════════════════════════

  static void logo({
    String subtitle = 'Command Line Interface',
    String? version,
  }) {
    print('');

    final versionText = version != null ? ' ${dim('v$version')}' : '';

    print(gray('  ╭──────────────────────────────────────────────╮'));
    print(
      gray('  │') +
          '                                              ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '    ${magenta('██████╗')}${cyan('███████╗')} ${magenta('██████╗')}${cyan('███╗   ███╗')}   ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '   ${magenta('██╔════╝')}${cyan('██╔════╝')}${magenta('██╔════╝')}${cyan('████╗ ████║')}   ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '   ${magenta('██║     ')}${cyan('███████╗')}${magenta('██║     ')}${cyan('██╔████╔██║')}   ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '   ${magenta('██║     ')}${cyan('╚════██║')}${magenta('██║     ')}${cyan('██║╚██╔╝██║')}   ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '   ${magenta('╚██████╗')}${cyan('███████║')}${magenta('╚██████╗')}${cyan('██║ ╚═╝ ██║')}   ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '    ${magenta('╚═════╝')}${cyan('╚══════╝')} ${magenta('╚═════╝')}${cyan('╚═╝     ╚═╝')}   ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '                                              ' +
          gray('│'),
    );

    print(
      gray('  │') +
          '    ${dim(subtitle)}$versionText${' ' * _logoPadding(subtitle, version)}' +
          gray('│'),
    );

    print(
      gray('  │') +
          '                                              ' +
          gray('│'),
    );
    print(gray('  ╰──────────────────────────────────────────────╯'));

    print('');
  }

  static int _logoPadding(String subtitle, String? version) {
    final content =
        4 + subtitle.length + (version != null ? 4 + version.length : 0);
    return (44 - content).clamp(0, 44);
  }

  // ═══════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════

  static void header(String title, {String? description}) {
    print('');

    print('  ${magenta('◆')} ${bold(title.toUpperCase())}');

    print('  ${gray('─' * (title.length + 2))}');

    if (description != null && description.isNotEmpty) {
      print('  ${dim(description)}');
    }

    print('');
  }

  // ═══════════════════════════════════════════════
  // SECTION
  // ═══════════════════════════════════════════════

  static void section(String title, {String? count}) {
    final suffix = count != null ? ' ${dim('[$count]')}' : '';

    print('');
    print('  ${cyan('◆')} ${bold(title)}$suffix');

    print('    ${gray('─' * title.length)}');

    print('');
  }

  // ═══════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════

  static void success(String message) {
    _status('ok', message, _green);
  }

  static void error(String message) {
    _status('err', message, _red);
  }

  static void warning(String message) {
    _status('warn', message, _yellow);
  }

  static void info(String message) {
    _status('info', message, _cyan);
  }

  static void _status(String label, String message, String color) {
    final tag = _c(color, label.padRight(5));

    print('  $tag  $message');
  }

  // ═══════════════════════════════════════════════
  // FILES
  // ═══════════════════════════════════════════════

  static void fileCreated(String name) {
    _fileLine('create', name, _green);
  }

  static void fileUpdated(String name) {
    _fileLine('update', name, _cyan);
  }

  static void fileSkipped(String name, {String reason = 'exists'}) {
    _fileLine('skip', name, _gray, note: reason);
  }

  static void fileDeleted(String name) {
    _fileLine('delete', name, _red);
  }

  static void _fileLine(
    String action,
    String name,
    String color, {
    String? note,
  }) {
    final tag = _c(color, action.padRight(7));

    final noteText = note != null ? '  ${dim('($note)')}' : '';

    print('    ${gray('├─')} $tag  $name$noteText');
  }

  // ═══════════════════════════════════════════════
  // TREE
  // ═══════════════════════════════════════════════

  static void tree(String root, List<String> items) {
    print('');

    print('  ${magenta('◆')} ${bold(root)}');

    for (var i = 0; i < items.length; i++) {
      final last = i == items.length - 1;

      final branch = last ? '└─' : '├─';

      print('    ${gray(branch)} ${items[i]}');
    }

    print('');
  }

  // ═══════════════════════════════════════════════
  // NEXT STEPS
  // ═══════════════════════════════════════════════

  static void nextSteps(List<String> steps) {
    if (steps.isEmpty) return;

    print('');
    print('  ${cyan('◆')} ${bold('Next steps')}');

    print('');

    for (var i = 0; i < steps.length; i++) {
      final number = (i + 1).toString().padLeft(2);

      print('    ${dim(number)}  ${steps[i]}');
    }

    print('');
  }

  // ═══════════════════════════════════════════════
  // HINT
  // ═══════════════════════════════════════════════

  static void hint(String message) {
    print('  ${gray('›')}  ${dim(message)}');
  }

  // ═══════════════════════════════════════════════
  // COMMAND
  // ═══════════════════════════════════════════════

  static void command(String command, {String? description}) {
    print(
      '    ${magenta('\$')} ${bold(command)}'
      '${description != null ? '  ${dim(description)}' : ''}',
    );
  }

  // ═══════════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════════

  static void summary(String content, {String? title}) {
    final lines = content.split('\n');

    final visibleLengths = lines.map((line) => line.length);

    final maxLength = visibleLengths.fold<int>(0, (a, b) => a > b ? a : b);

    final width = maxLength + 4;

    print('');

    if (title != null) {
      print('  ${magenta('╭')} ${bold(title)}');
    } else {
      print('  ${magenta('╭')}${gray('─' * width)}${magenta('╮')}');
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final padding = width - line.length - 2;

      print(
        '  ${magenta('│')} '
        '$line'
        '${' ' * (padding > 0 ? padding : 0)} '
        '${magenta('│')}',
      );
    }

    print('  ${magenta('╰')}${gray('─' * width)}${magenta('╯')}');

    print('');
  }

  // ═══════════════════════════════════════════════
  // PROGRESS
  // ═══════════════════════════════════════════════

  static void progress(String message, int current, int total) {
    if (total <= 0) return;

    final percentage = ((current / total) * 100).clamp(0, 100).toInt();

    const width = 24;

    final filled = ((percentage / 100) * width).round();

    final empty = width - filled;

    final bar =
        '${magenta('█' * filled)}'
        '${gray('░' * empty)}';

    stdout.write(
      '\r  $bar '
      '${percentage.toString().padLeft(3)}% '
      '${dim(message)}',
    );

    if (current >= total) {
      print('');
    }
  }

  // ═══════════════════════════════════════════════
  // SPINNER
  // ═══════════════════════════════════════════════

  static Future<T> withSpinner<T>(
    String message,
    Future<T> Function() task,
  ) async {
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

    var frame = 0;
    var running = true;

    final timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!running) return;

      stdout.write('\r  ${cyan(frames[frame])}  $message');

      frame = (frame + 1) % frames.length;
    });

    try {
      final result = await task();

      running = false;
      timer.cancel();

      clearLine();

      success(message);

      return result;
    } catch (_) {
      running = false;
      timer.cancel();

      clearLine();

      error(message);

      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // DIVIDER
  // ═══════════════════════════════════════════════

  static void divider() {
    print('  ${gray('─' * 46)}');
  }

  // ═══════════════════════════════════════════════
  // CLEAR LINE
  // ═══════════════════════════════════════════════

  static void clearLine() {
    stdout.write('\r${' ' * 80}\r');
  }

  // ═══════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════

  static void footer({String? message}) {
    print('');

    if (message != null) {
      print('  ${gray('─' * 46)}');

      print('  ${dim(message)}');
    }

    print('');
  }
}
