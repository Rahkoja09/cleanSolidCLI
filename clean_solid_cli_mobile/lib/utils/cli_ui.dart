import 'dart:async';
import 'dart:io';

/// CLI output — clig.dev compliant.
/// No emojis. Color is intentional. Brief messages.
/// Auto-disables color when stdout is not a TTY or NO_COLOR is set.
class CliUI {
  // ── Colors ──────────────────────────────────────
  static const _reset = '\x1b[0m';
  static const _bold = '\x1b[1m';
  static const _dim = '\x1b[2m';
  static const _red = '\x1b[31m';
  static const _green = '\x1b[32m';
  static const _yellow = '\x1b[33m';
  static const _cyan = '\x1b[36m';
  static const _gray = '\x1b[90m';

  static final bool _color = _detectColor();

  static bool _detectColor() {
    if (Platform.environment.containsKey('NO_COLOR')) return false;
    try {
      return stdout.supportsAnsiEscapes;
    } catch (_) {
      return false;
    }
  }

  static String _c(String color, String text) =>
      _color ? '$color$text$_reset' : text;
  static String bold(String t) => _c(_bold, t);
  static String dim(String t) => _c(_dim, t);
  static String green(String t) => _c(_green, t);
  static String red(String t) => _c(_red, t);
  static String yellow(String t) => _c(_yellow, t);
  static String cyan(String t) => _c(_cyan, t);
  static String gray(String t) => _c(_gray, t);

  // ── Header ─────────────────────────────────────
  static void header(String title) {
    final line = gray('${"─" * 3} $title ${"─" * 3}');
    print('');
    print(line);
    print('');
  }

  // ── Section ────────────────────────────────────
  static void section(String title, {String? count}) {
    final suffix = count != null ? dim(' ($count)') : '';
    print('  ${bold(title)}$suffix');
    print('  ${gray('─' * title.length)}');
  }

  // ── Status ────────────────────────────────────
  static void success(String msg) => _status('ok', msg, _green);
  static void error(String msg) => _status('err', msg, _red);
  static void warning(String msg) => _status('warn', msg, _yellow);
  static void info(String msg) => _status('info', msg, _cyan);

  static void _status(String label, String msg, String color) {
    final tag = _c(color, label.padRight(5));
    print('  $tag  $msg');
  }

  // ── File ──────────────────────────────────────
  static void fileCreated(String name) => _fileLine('create', name, _green);
  static void fileSkipped(String name, {String reason = 'exists'}) =>
      _fileLine('skip', name, _gray, note: reason);
  static void fileUpdated(String name) => _fileLine('update', name, _cyan);

  static void _fileLine(
    String action,
    String name,
    String color, {
    String? note,
  }) {
    final tag = _c(color, action.padRight(7));
    final noteStr = note != null ? '  ${dim('($note)')}' : '';
    print('    $tag  $name$noteStr');
  }

  // ── Next Steps ────────────────────────────────
  static void nextSteps(List<String> steps) {
    print('');
    print('  ${bold('Next:')}');
    for (var i = 0; i < steps.length; i++) {
      print('    ${dim('${i + 1}.')}  ${steps[i]}');
    }
    print('');
  }

  // ── Hint ──────────────────────────────────────
  static void hint(String msg) {
    print('  ${dim('>')}  $msg');
  }

  // ── Summary Box (kept for compat) ─────────────
  static void summary(String content) {
    final lines = content.split('\n');
    final maxLen = lines.map((l) => l.length).fold(0, (a, b) => a > b ? a : b);
    final pad = maxLen + 4;
    print('');
    print(gray('  ┌${"─" * pad}┐'));
    for (final l in lines) {
      final inner = '  $l';
      final trailing = pad - l.length - 2;
      print(
        gray('  │') + inner + (trailing > 0 ? ' ' * trailing : '') + gray('│'),
      );
    }
    print(gray('  └${"─" * pad}┘'));
  }

  // ── Spinner ───────────────────────────────────
  static Future<T> withSpinner<T>(
    String message,
    Future<T> Function() task,
  ) async {
    const frames = ['/', '-', '\\', '|'];
    var frame = 0;
    var running = true;
    var currentLen = 0;

    final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!running) return;
      final text = '  ${cyan(frames[frame])}  $message';
      // Clear previous line
      if (currentLen > 0) {
        stdout.write('\r${" " * currentLen}\r');
      }
      stdout.write(text);
      currentLen = text.length;
      frame = (frame + 1) % frames.length;
    });
    try {
      final result = await task();
      running = false;
      timer.cancel();
      // Clear spinner line
      if (currentLen > 0) {
        stdout.write('\r${" " * currentLen}\r');
      }
      final tag = _c(_green, 'ok'.padRight(5));
      print('  $tag  $message');
      return result;
    } catch (e) {
      running = false;
      timer.cancel();
      if (currentLen > 0) {
        stdout.write('\r${" " * currentLen}\r');
      }
      final tag = _c(_red, 'err'.padRight(5));
      print('  $tag  $message');
      rethrow;
    }
  }

  /// Clear the current line (useful before printing final output).
  static void clearLine() {
    stdout.write('\r${" " * 80}\r');
  }
}
