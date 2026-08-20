import 'dart:io';

/// Git utilities for cscm.
/// All git output goes to stderr to keep stdout clean for piping.
class GitHelper {
  static const _gitBin = 'git';

  /// Check if git is installed on the system.
  static bool isGitInstalled() {
    try {
      final result = Process.runSync(_gitBin, ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if current directory is a git repository.
  static bool isGitRepo() {
    try {
      final result = Process.runSync(
        _gitBin,
        ['rev-parse', '--is-inside-work-tree'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Initialize a git repository in the current directory.
  /// Returns true on success.
  static bool initRepo({String? directory}) {
    try {
      final args = ['init'];
      if (directory != null) args.add(directory);
      final result = Process.runSync(_gitBin, args);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Stage specific files and commit with a message.
  /// If [files] is empty, stages all tracked changes.
  /// Returns the commit output or null on failure.
  static String? commit({
    required String message,
    List<String>? files,
    String? directory,
  }) {
    try {
      // Stage files
      if (files != null && files.isNotEmpty) {
        final addArgs = ['add', '--', ...files];
        final addResult = Process.runSync(
          _gitBin,
          addArgs,
          workingDirectory: directory,
        );
        if (addResult.exitCode != 0) {
          stderr.writeln('  git add failed: ${addResult.stderr}');
          return null;
        }
      } else {
        // Stage all (including new files)
        final addResult = Process.runSync(
          _gitBin,
          ['add', '-A'],
          workingDirectory: directory,
        );
        if (addResult.exitCode != 0) {
          stderr.writeln('  git add failed: ${addResult.stderr}');
          return null;
        }
      }

      // Commit
      final commitResult = Process.runSync(
        _gitBin,
        ['commit', '-m', message, '--allow-empty-message'],
        workingDirectory: directory,
      );

      if (commitResult.exitCode != 0) {
        final stderrStr = commitResult.stderr.toString().trim();
        // "nothing to commit" is not an error for us
        if (stderrStr.contains('nothing to commit')) {
          return '(no changes to commit)';
        }
        stderr.writeln('  git commit failed: $stderrStr');
        return null;
      }

      return commitResult.stdout.toString().trim();
    } catch (e) {
      stderr.writeln('  git error: $e');
      return null;
    }
  }

  /// Check if there are uncommitted changes.
  static bool hasUncommittedChanges({String? directory}) {
    try {
      final result = Process.runSync(
        _gitBin,
        ['status', '--porcelain'],
        workingDirectory: directory,
      );
      return result.exitCode == 0 &&
          result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Run `flutter create` with the given options.
  /// Returns the exit code. 0 = success.
  static int flutterCreate({
    required String projectName,
    String org = 'com.example',
  }) {
    try {
      final result = Process.runSync(
        'flutter',
        ['create', projectName, '--org', org],
        runInShell: true,
      );

      // Print flutter output to stderr so it doesn't pollute stdout
      if (result.stdout.toString().isNotEmpty) {
        stderr.writeln(result.stdout);
      }
      if (result.stderr.toString().isNotEmpty) {
        stderr.writeln(result.stderr);
      }

      return result.exitCode;
    } catch (e) {
      stderr.writeln('  flutter create failed: $e');
      return 1;
    }
  }

  /// Check if flutter is installed.
  static bool isFlutterInstalled() {
    try {
      final result = Process.runSync('flutter', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Get the list of staged files.
  static List<String> getStagedFiles({String? directory}) {
    try {
      final result = Process.runSync(
        _gitBin,
        ['diff', '--cached', '--name-only'],
        workingDirectory: directory,
      );
      if (result.exitCode != 0) return [];
      return result.stdout
          .toString()
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
