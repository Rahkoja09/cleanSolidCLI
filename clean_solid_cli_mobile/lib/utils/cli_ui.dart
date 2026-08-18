import 'dart:async';
import 'dart:io';

/// Affichage console professionnel — couleurs sémantiques, pas d'emojis.
class CliUI {
  static const _reset = '\x1b[0m';
  static const _bold = '\x1b[1m';
  static const _dim = '\x1b[2m';
  static const _red = '\x1b[31m';
  static const _green = '\x1b[32m';
  static const _yellow = '\x1b[33m';
  static const _cyan = '\x1b[36m';
  static const _gray = '\x1b[90m';

  static String _c(String color, String text) => '$color$text$_reset';
  static String bold(String t) => _c(_bold, t);
  static String dim(String t) => _c(_dim, t);
  static String green(String t) => _c(_green, t);
  static String red(String t) => _c(_red, t);
  static String yellow(String t) => _c(_yellow, t);
  static String cyan(String t) => _c(_cyan, t);
  static String gray(String t) => _c(_gray, t);

  static const int _w = 50;

  // ─── Header ────────────────────────────────
  static void header(String title, {String? subtitle}) {
    final line = '─' * (_w - 4);
    print('');
    print(gray('  ┌$line┐'));
    print(gray('  │') + bold('  CSCM · $title') + ' ' * (_w - 11 - title.length) + gray('│'));
    if (subtitle != null) {
      print(gray('  │') + '  $subtitle' + ' ' * (_w - 4 - subtitle.length) + gray('│'));
    }
    print(gray('  └$line┘'));
    print('');
  }

  // ─── Section ───────────────────────────────
  static void section(String title, {String? count}) {
    final suffix = count != null ? dim(' ($count)') : '';
    print('');
    print('  ${bold(title)}$suffix');
    print(gray('  ' + '─' * 44));
  }

  // ─── Status ────────────────────────────────
  static void success(String msg) => print('  ${green("✓")}  $msg');
  static void error(String msg) => print('  ${red("✗")}  $msg');
  static void warning(String msg) => print('  ${yellow("!")}  $msg');
  static void info(String msg) => print('  ${cyan("i")}  $msg');

  // ─── File ──────────────────────────────────
  static void fileCreated(String name) => print('  ${green("✓")}  $name');
  static void fileSkipped(String name, {String reason = 'exists'}) =>
      print('  ${gray("-")}  $name  ${dim("($reason)")}');
  static void fileUpdated(String name) => print('  ${cyan("↻")}  $name');

  // ─── Summary Box ───────────────────────────
  static void summary(String content) {
    final line = '─' * (_w - 4);
    print('');
    print(gray('  ┌$line┐'));
    for (final l in content.split('\n')) {
      final inner = '  $l';
      final pad = _w - 4 - l.length - 2;
      print(gray('  │') + inner + (pad > 0 ? ' ' * pad : '') + gray('│'));
    }
    print(gray('  └$line┘'));
  }

  // ─── Next Steps ────────────────────────────
  static void nextSteps(List<String> steps) {
    print('');
    print('  ${bold("Prochaines étapes")}');
    for (var i = 0; i < steps.length; i++) {
      print('    ${cyan("${i + 1}.")}  ${steps[i]}');
    }
    print('');
  }

  // ─── Hint ──────────────────────────────────
  static void hint(String msg) {
    print('');
    print('  ${cyan("→")}  $msg');
  }

  // ─── Spinner ───────────────────────────────
  static Future<T> withSpinner<T>(String message, Future<T> Function() task) async {
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    var frame = 0;
    var running = true;
    final timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!running) return;
      stdout.write('\r  ${gray(frames[frame])}  $message');
      frame = (frame + 1) % frames.length;
    });
    try {
      final result = await task();
      running = false;
      timer.cancel();
      stdout.write('\r  ${green("✓")}  $message\n');
      return result;
    } catch (e) {
      running = false;
      timer.cancel();
      stdout.write('\r  ${red("✗")}  $message\n');
      rethrow;
    }
  }
}
