import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/test_generator.dart';

class TestCommand extends Command {
  @override
  String get description => 'Lancer les tests (tous ou pour une feature)';

  @override
  String get name => 'test';

  TestCommand() {
    argParser.addFlag(
      'generate',
      abbr: 'g',
      help: 'Generer les tests manquants avant de les lancer',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final shouldGenerate = argResults?['generate'] as bool? ?? false;
    final featureArg =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (shouldGenerate && featureArg == null) {
      CliUI.error("--generate necessite un nom de feature.");
      CliUI.hint("Usage : cscm test <feature> --generate");
      return;
    }

    if (featureArg != null) {
      if (featureArg.contains('..') ||
          featureArg.contains('/') ||
          featureArg.contains('\\')) {
        CliUI.error("Nom de feature invalide.");
        return;
      }

      final snakeName = ReformateClassName.formatToSnakeCase(featureArg);

      if (shouldGenerate) {
        await _generateTestsIfNeeded(snakeName, featureArg);
      }

      final testDir = 'test/features/$snakeName';
      final dir = Directory(testDir);
      if (!dir.existsSync()) {
        CliUI.warning("Aucun test trouve pour la feature : $featureArg");
        return;
      }

      await _runTests(label: featureArg, args: ['test', testDir]);
    } else {
      final dir = Directory('test');
      if (!dir.existsSync()) {
        CliUI.warning("Aucun repertoire test/ trouve.");
        return;
      }

      await _runTests(label: 'toutes les features', args: ['test']);
    }
  }

  /// Lance flutter test avec un spinner, puis affiche SEULEMENT le resultat final.
  /// Toute la sortie stdout est bufferisée — rien n'est affiché pendant la compilation.
  Future<void> _runTests({
    required String label,
    required List<String> args,
  }) async {
    CliUI.header('Tests : $label');

    // ── Spinner pendant la compilation ──
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    var frame = 0;
    var showSpinner = true;

    final spinner = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!showSpinner) return;
      // Écrit le spinner sur la même ligne, puis l'efface
      stdout.write(
        '\r  ${CliUI.gray(frames[frame])}  Compilation & execution des tests...',
      );
      frame = (frame + 1) % frames.length;
    });

    // ── Lancer le process, tout bufferiser ──
    final process = await Process.start(
      'flutter',
      args,
      runInShell: true,
      mode: ProcessStartMode.normal,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    // Écouter stdout — tout accumuler, NE RIEN afficher
    final stdoutDone = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((chunk) {
          stdoutBuffer.write(chunk);
        });

    final stderrDone = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((chunk) {
          stderrBuffer.write(chunk);
        });

    final exitCode = await process.exitCode;
    await stdoutDone.cancel();
    await stderrDone.cancel();
    spinner.cancel();

    // Nettoyer la ligne du spinner
    stdout.write('\r${' ' * 70}\r');

    // ── Analyser le résultat ──
    final stdoutText = stdoutBuffer.toString();
    final lines = stdoutText.split('\n');

    // Trouver la DERNIÈRE ligne de résultat (ex: "02:04 +17: All tests passed!")
    // ou la ligne d'erreur (ex: "02:28 +0 -2: Some tests failed.")
    String? resultLine;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Les lignes de resultat flutter test finissent toujours par ":" suivi du message
      if (RegExp(r'^\d{2}:\d{2}\s+\+\d+').hasMatch(trimmed)) {
        resultLine = trimmed;
      }
    }

    if (resultLine != null) {
      stdout.writeln(resultLine);
    }

    // ── Erreurs de compilation ──
    final stderrText = stderrBuffer.toString().trim();
    if (stderrText.isNotEmpty) {
      // Extraire uniquement les lignes d'erreur pertinentes
      final errorLines =
          stderrText.split('\n').where((l) {
            final t = l.trim();
            if (t.isEmpty) return false;
            // Garder les vraies erreurs, pas les lignes de contexte
            return t.contains('Error:') ||
                t.contains('error:') ||
                t.contains('Compilation failed') ||
                t.contains('To run this test again');
          }).toList();

      if (errorLines.isNotEmpty) {
        for (final line in errorLines) {
          stderr.writeln(line);
        }
        print('');
      }
    }

    // ── Aussi chercher les erreurs dans stdout (certains cas) ──
    final stdoutErrors =
        lines.where((l) {
          final t = l.trim();
          return t.contains('Error:') &&
              !t.contains('loading') &&
              !RegExp(r'^\d{2}:\d{2}').hasMatch(t);
        }).toList();

    if (stdoutErrors.isNotEmpty) {
      for (final line in stdoutErrors) {
        stderr.writeln(line);
      }
    }

    // ── Verdict ──
    print('');
    if (exitCode == 0) {
      CliUI.success('Tous les tests passes');
    } else {
      CliUI.error('Certains tests ont echoue (exit code: $exitCode)');
    }

    //this.exitCode = exitCode;
  }

  Future<void> _generateTestsIfNeeded(
    String snakeName,
    String featureArg,
  ) async {
    final repoTest =
        'test/features/$snakeName/data/repository/${snakeName}_repository_impl_test.dart';
    final ctrlTest =
        'test/features/$snakeName/presentation/controller/${snakeName}_controller_test.dart';

    final repoExists = File(repoTest).existsSync();
    final ctrlExists = File(ctrlTest).existsSync();

    if (repoExists && ctrlExists) {
      CliUI.info("Tests deja existants pour : $featureArg");
      return;
    }

    CliUI.info("Generation des tests manquants pour : $featureArg ...");
    try {
      final projectName = _getProjectName();
      await CliUI.withSpinner('Generation des tests', () async {
        await TestGenerator.generate(
          featureName: featureArg,
          projectName: projectName,
        );
      });
    } catch (e) {
      CliUI.error("Erreur lors de la generation : $e");
    }
  }

  String _getProjectName() {
    final file = File('.cscm.yaml');
    if (file.existsSync()) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('project_name:')) {
          return line.split(':').last.trim();
        }
      }
    }
    return Directory.current.path.split('/').last;
  }
}
